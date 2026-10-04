import 'package:sentry_flutter/sentry_flutter.dart';

import '../config.dart';
import 'pii_scrubber.dart';

/// Sentry initialization for Keystona.
///
/// Implements `HomeTrack_Security_Guide.md` §5.4 and the three hard
/// requirements in the §8 PR checklist: `sendDefaultPii` false,
/// `attachScreenshot` false, `attachViewHierarchy` false.
///
/// Every outbound event passes through [PiiScrubber] first. Keystona stores
/// addresses, phone numbers, insurance details and OCR text, and Supabase
/// errors echo column values back verbatim — so an unscrubbed crash report
/// is a plausible PII breach, not a theoretical one.
abstract final class SentryInit {
  /// Whether crash reporting should run at all.
  ///
  /// Requires a DSN and a non-development build. Gating on environment keeps
  /// simulator hot-reload noise out of the project and off the quota; gating
  /// on the DSN means this is safe to call before one is configured, so the
  /// wiring can land before the Sentry project exists.
  static bool get isEnabled =>
      AppConfig.sentryDsn.isNotEmpty && !AppConfig.isDevelopment;

  /// Runs [appRunner] with Sentry active, or directly if disabled.
  ///
  /// [appRunner] must contain every other startup step. Sentry only observes
  /// errors thrown inside it, so Supabase/RevenueCat initialization belongs
  /// in there too — that is where startup crashes actually happen.
  static Future<void> run(Future<void> Function() appRunner) async {
    if (!isEnabled) {
      await appRunner();
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = AppConfig.sentryDsn;
        options.environment = AppConfig.appEnv;

        // ── §8 checklist: these three are non-negotiable ──────────────────
        // All three are also the v9 defaults, but they are set explicitly so
        // an upstream default change cannot silently start leaking data.
        options.sendDefaultPii = false;
        options.attachScreenshot = false;
        options.attachViewHierarchy = false;

        // ── PII scrubbing ─────────────────────────────────────────────────
        options.beforeSend = (event, hint) => _scrubEvent(event);
        options.beforeBreadcrumb =
            (breadcrumb, hint) => _scrubBreadcrumb(breadcrumb);

        // 20% of transactions per §5.4 — enough signal without the volume.
        options.tracesSampleRate = 0.2;

        // Local logging stays off; errors reach Sentry, not the console.
        options.debug = false;
      },
      appRunner: appRunner,
    );
  }

  // ── Scrubbing ───────────────────────────────────────────────────────────

  /// Strips PII from every field of an event that can carry it.
  ///
  /// Exposed for testing — the point of this file is the scrubbing, so it has
  /// to be assertable without standing up a real Sentry client.
  static SentryEvent scrubEvent(SentryEvent event) => _scrubEvent(event);

  // Fields are assigned directly rather than via copyWith: copyWith is
  // deprecated across the v9 protocol classes in favour of mutation.
  static SentryEvent _scrubEvent(SentryEvent event) {
    // Keep only the user id. It is the correlation key that makes a report
    // actionable, and an opaque id is not personal data — but email,
    // username, name, ip and geo all are.
    final user = event.user;
    if (user != null) event.user = SentryUser(id: user.id);

    // Exception values carry the message text, which is where Postgres echoes
    // column values and auth errors echo emails.
    for (final e in event.exceptions ?? const <SentryException>[]) {
      e.value = PiiScrubber.redactText(e.value);
    }

    final message = event.message;
    if (message != null) {
      message.formatted = PiiScrubber.redactText(message.formatted);
      // Params are interpolated into the message, so they are just as likely
      // to hold PII as the message itself.
      message.params = message.params
          ?.map((p) => p is String ? PiiScrubber.redactText(p) : p)
          .toList();
    }

    event.breadcrumbs =
        event.breadcrumbs?.map(_scrubBreadcrumb).nonNulls.toList();

    // Free-form maps set by feature code — treat as untrusted.
    event.tags = event.tags?.map((k, v) => MapEntry(
          k,
          PiiScrubber.isPiiKey(k)
              ? PiiScrubber.redacted
              : PiiScrubber.redactText(v),
        ));

    // Request url, headers, cookies and query strings can all carry tokens.
    // A Flutter client has no inbound request context worth keeping, so this
    // is dropped outright rather than selectively cleaned.
    event.request = null;

    // Device/host name can identify a person's machine.
    event.serverName = null;

    event.transaction = event.transaction == null
        ? null
        : PiiScrubber.redactText(event.transaction);
    event.culprit =
        event.culprit == null ? null : PiiScrubber.redactText(event.culprit);

    return event;
  }

  /// Exposed for testing, same reasoning as [scrubEvent].
  static Breadcrumb? scrubBreadcrumb(Breadcrumb? b) => _scrubBreadcrumb(b);

  static Breadcrumb? _scrubBreadcrumb(Breadcrumb? breadcrumb) {
    if (breadcrumb == null) return null;
    breadcrumb.message = PiiScrubber.redactText(breadcrumb.message);
    final data = breadcrumb.data;
    if (data != null) breadcrumb.data = PiiScrubber.redactMap(data);
    return breadcrumb;
  }
}
