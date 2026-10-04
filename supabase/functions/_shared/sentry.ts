// Sentry for Supabase Edge Functions.
//
// Design constraint that shapes this whole file: @sentry/deno is beta and
// Sentry does not document Supabase Edge Function support. This repo also has
// no Docker, so `supabase functions serve` cannot run and the integration
// cannot be exercised before deploy.
//
// Therefore the rule is: monitoring may fail, a function may not.
//
//   - The SDK is loaded with a DYNAMIC import inside try/catch. A static
//     `import * as Sentry from "npm:@sentry/deno"` that fails to resolve takes
//     the whole module down at cold start, and no try/catch can rescue that.
//   - Every Sentry call is individually guarded.
//   - A missing DSN disables everything silently.
//
// Worst case is "no telemetry", never "scan-label returns 500 for everyone".
//
// Deliberately NOT included: prompt or response capture for the Anthropic
// calls. scan-label sends base64 photographs of user documents, and
// Security Guide §5.4 names OCR text as never-log PII. This module reports
// failures, latency and token counts — not model inputs or outputs.

// deno-lint-ignore no-explicit-any
type SentryModule = any;

let _sentry: SentryModule | null = null;
let _initialized = false;

const DSN = Deno.env.get("SENTRY_DSN") ?? "";
const ENVIRONMENT = Deno.env.get("SENTRY_ENVIRONMENT") ?? "production";

/// Mirrors the Flutter PiiScrubber rules. Edge Functions see the same data —
/// Postgres errors echo column values, and item descriptions reach the prompt.
const _PII_PATTERNS: Array<[RegExp, string]> = [
  // JWTs first: the payload can embed an email.
  [/eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]+/g, "[jwt]"],
  [/\bbearer\s+[A-Za-z0-9._-]+/gi, "Bearer [token]"],
  // Postgres echoes the offending value: keep the column, drop the value.
  [/Key \(([^)]+)\)=\([^)]*\)/g, "Key ($1)=([redacted])"],
  [/\b[\w.+-]+@[\w-]+\.[\w.-]+\b/g, "[email]"],
  [/(\+?\d{1,2}[\s.-]?)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}\b/g, "[phone]"],
  [
    /\b\d{1,6}\s+([A-Za-z0-9.]+\s+){0,4}(Street|St|Avenue|Ave|Road|Rd|Drive|Dr|Lane|Ln|Boulevard|Blvd|Court|Ct|Terrace|Ter|Place|Pl|Way|Circle|Cir|Highway|Hwy|Parkway|Pkwy)\b\.?/gi,
    "[address]",
  ],
  // Context-required ZIP, so Postgres error codes like 42501 survive.
  [/\b([A-Z]{2})\s+\d{5}(-\d{4})?\b/g, "$1 [zip]"],
];

export function redact(input: string | null | undefined): string {
  if (!input) return "";
  let out = input;
  for (const [pattern, replacement] of _PII_PATTERNS) {
    out = out.replace(pattern, replacement);
  }
  return out;
}

/// Loads and initializes the SDK at most once. Never throws.
async function _ensureInit(): Promise<SentryModule | null> {
  if (_initialized) return _sentry;
  _initialized = true;

  if (!DSN) return null;

  try {
    const mod = await import("npm:@sentry/deno");
    mod.init({
      dsn: DSN,
      environment: ENVIRONMENT,
      // Edge invocations are short; sample generously but not fully.
      tracesSampleRate: 0.2,
      // Never send IP or user identifiers from the server side.
      sendDefaultPii: false,
      // Drop breadcrumbs at the source, before they ever reach an event.
      //
      // The console integration is the critical one: every function calls
      // console.error("...", err) with the RAW error immediately before
      // captureError. That becomes a console breadcrumb, which would carry
      // the exact PII that beforeSend strips out of exception.values — the
      // same field is scrubbed in one place and leaked in another. Console
      // breadcrumbs are pure duplication of the exception here, so they are
      // dropped outright rather than redacted.
      beforeBreadcrumb: (crumb: SentryModule) => {
        try {
          if (!crumb) return null;
          if (crumb.category === "console") return null;
          return {
            ...crumb,
            message: redact(crumb.message),
            // fetch/xhr breadcrumb data holds URLs, query strings and bodies.
            // The category and status are the useful part; the payload is not.
            data: undefined,
          };
        } catch {
          return null;
        }
      },
      beforeSend: (event: SentryModule) => {
        try {
          if (event?.exception?.values) {
            for (const v of event.exception.values) {
              if (v?.value) v.value = redact(v.value);
            }
          }
          if (event?.message) event.message = redact(event.message);

          // Defence in depth: beforeBreadcrumb should already have cleaned
          // these, but a breadcrumb added by another path would bypass it.
          if (Array.isArray(event?.breadcrumbs)) {
            event.breadcrumbs = event.breadcrumbs.map((b: SentryModule) => ({
              ...b,
              message: redact(b?.message),
              data: undefined,
            }));
          }

          // Free-form fields set by the SDK or by feature code. Request data
          // carries auth headers and query strings; extra and contexts are
          // unbounded. None are worth the exposure on a short edge handler.
          delete event.request;
          delete event.extra;
          delete event.contexts;

          if (event?.tags) {
            for (const [k, v] of Object.entries(event.tags)) {
              if (typeof v === "string") event.tags[k] = redact(v);
            }
          }
          if (event?.transaction) event.transaction = redact(event.transaction);
          if (event?.culprit) event.culprit = redact(event.culprit);

          // Server name identifies infrastructure, not useful here.
          event.server_name = undefined;
          if (event?.user) event.user = { id: event.user.id };
          return event;
        } catch {
          // A scrubber that throws must drop the event, not send it raw.
          return null;
        }
      },
    });
    _sentry = mod;
    return _sentry;
  } catch {
    // Resolution or init failed. Monitoring is unavailable; carry on.
    return null;
  }
}

/// Reports an error. Never throws, never rejects.
export async function captureError(
  err: unknown,
  context: Record<string, string | number | boolean> = {},
): Promise<void> {
  try {
    const sentry = await _ensureInit();
    if (!sentry) return;
    sentry.withScope((scope: SentryModule) => {
      for (const [k, v] of Object.entries(context)) {
        scope.setTag(k, typeof v === "string" ? redact(v) : v);
      }
      sentry.captureException(err);
    });
    // Edge isolates can be torn down immediately after the response, so the
    // envelope has to be handed off before this resolves.
    await sentry.flush(2000);
  } catch {
    // ignore
  }
}

/// Records a completed invocation: duration, outcome, and optional token use.
/// Token counts come from the Anthropic response metadata — counts only, never
/// prompt or completion text.
export async function captureInvocation(opts: {
  fn: string;
  ok: boolean;
  durationMs: number;
  status?: number;
  inputTokens?: number;
  outputTokens?: number;
}): Promise<void> {
  try {
    const sentry = await _ensureInit();
    if (!sentry) return;
    sentry.withScope((scope: SentryModule) => {
      scope.setTag("fn", opts.fn);
      scope.setTag("ok", opts.ok);
      scope.setContext("invocation", {
        duration_ms: Math.round(opts.durationMs),
        status: opts.status,
        input_tokens: opts.inputTokens,
        output_tokens: opts.outputTokens,
      });
      // Only surface slow or failed runs; a healthy fast call is noise.
      if (!opts.ok) {
        sentry.captureMessage(`${opts.fn} failed`, "error");
      } else if (opts.durationMs > 10000) {
        sentry.captureMessage(`${opts.fn} slow (${Math.round(opts.durationMs)}ms)`, "warning");
      }
    });
    await sentry.flush(2000);
  } catch {
    // ignore
  }
}
