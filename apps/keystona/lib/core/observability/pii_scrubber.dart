/// PII redaction for anything leaving the device.
///
/// Required by `HomeTrack_Security_Guide.md` §5.4 and the §8 PR checklist:
/// no names, emails, OCR text or addresses may appear in crash reports or
/// analytics events.
///
/// Deliberately keeps what is diagnostically useful — error codes, table and
/// constraint names, HTTP statuses, UUIDs — because a report scrubbed to
/// uselessness gets ignored, and UUIDs are identifiers rather than personal
/// data. The goal is "debuggable but anonymous", not "empty".
///
/// Pure functions with no Sentry dependency, so the rules are unit-testable
/// in isolation. See `sentry_init.dart` for where they are wired in.
abstract final class PiiScrubber {
  static const String redacted = '[redacted]';

  // ── Text patterns ─────────────────────────────────────────────────────────
  //
  // Order matters: narrower patterns run before broader ones so a broad rule
  // cannot swallow text a narrow rule would have labelled more precisely.

  /// Each entry maps a match to its replacement.
  ///
  /// A mapper rather than a plain string because `String.replaceAll` does NOT
  /// perform `$1` group substitution — it would emit the literal `$1`. All
  /// substitution goes through `replaceAllMapped` so group-aware rules (the
  /// Postgres `Key (col)=(value)` case) behave correctly.
  ///
  /// Dart has no inline `(?i)` flag either; case-insensitivity is the
  /// `caseSensitive: false` constructor argument.
  static final List<(RegExp, String Function(Match))> _patterns = [
    // JWTs and bearer tokens. First — these can contain an email in the
    // payload and must never survive.
    (
      RegExp(r'eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]+'),
      (_) => '[jwt]'
    ),
    (
      RegExp(r'\bbearer\s+[A-Za-z0-9._\-]+', caseSensitive: false),
      (_) => 'Bearer [token]'
    ),

    // Postgres error detail echoes the offending value:
    //   DETAIL: Key (email)=(someone@example.com) already exists.
    // Keep the column name, drop the value — the column is the useful part.
    (
      RegExp(r'Key \(([^)]+)\)=\([^)]*\)'),
      (m) => 'Key (${m.group(1)})=($redacted)'
    ),

    // Emails.
    (RegExp(r'\b[\w.+-]+@[\w-]+\.[\w.-]+\b'), (_) => '[email]'),

    // Phone numbers — +1 (555) 123-4567, 555-123-4567, 5551234567.
    (
      RegExp(r'(\+?\d{1,2}[\s.-]?)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}\b'),
      (_) => '[phone]'
    ),

    // Street addresses: a number followed by words and a street suffix.
    (
      RegExp(
        r'\b\d{1,6}\s+([A-Za-z0-9.]+\s+){0,4}'
        r'(Street|St|Avenue|Ave|Road|Rd|Drive|Dr|Lane|Ln|Boulevard|Blvd|Court|Ct|Terrace|Ter|Place|Pl|Way|Circle|Cir|Highway|Hwy|Parkway|Pkwy)\b\.?',
        caseSensitive: false,
      ),
      (_) => '[address]'
    ),

    // ZIP codes — context-required, deliberately.
    //
    // A bare `\d{5}` also matches Postgres error codes (42501, 23505), HTTP
    // bodies and ids, and blanket-redacting those makes reports useless. So a
    // ZIP is only redacted when something marks it as one: a preceding state
    // abbreviation ("Austin TX 78704") or a zip/postal keyword.
    //
    // Known limitation: a bare five-digit number with no surrounding context
    // survives. Accepted — five digits alone identify nobody, whereas losing
    // every error code costs real debuggability. Structured address fields are
    // caught by [isPiiKey] regardless of this rule.
    (
      RegExp(r'\b([A-Z]{2})\s+(\d{5})(-\d{4})?\b'),
      (m) => '${m.group(1)} [zip]'
    ),
    (
      RegExp(r'\b(zip|postal)(\s*code)?\s*:?\s*(\d{5})(-\d{4})?\b',
          caseSensitive: false),
      (m) => '${m.group(1)} [zip]'
    ),
  ];

  /// Redacts PII patterns from free text while leaving diagnostics intact.
  ///
  /// Safe on null and empty input. Returns the input unchanged when nothing
  /// matched, so callers can cheaply detect a no-op.
  static String redactText(String? input) {
    if (input == null || input.isEmpty) return '';
    var out = input;
    for (final (pattern, replace) in _patterns) {
      out = out.replaceAllMapped(pattern, replace);
    }
    return out;
  }

  // ── Structured keys ───────────────────────────────────────────────────────
  //
  // Exact column/field names drawn from the actual schema. Matched
  // case-insensitively against the whole key, plus the substring rules below.

  static const Set<String> _piiKeys = {
    // Identity
    'email', 'email_address', 'name', 'full_name', 'first_name', 'last_name',
    'display_name', 'username', 'password', 'encrypted_password',
    // Address — properties
    'address', 'address_line1', 'address_line2', 'city', 'state',
    'zip', 'zip_code', 'postal_code', 'latitude', 'longitude',
    // Phones
    'phone', 'phone_primary', 'phone_secondary', 'phone_number',
    'gas_company_phone', 'claims_phone', 'agent_phone', 'contractor_phone',
    // Emergency contacts / insurance / contractors
    'company_name', 'agent_name', 'agent_email', 'carrier', 'policy_number',
    'contractor_name', 'contractor_company', 'installer', 'retailer', 'vendor',
    // Free text that may contain anything, incl. OCR output
    'notes', 'review_notes', 'caption', 'description', 'instructions',
    'special_instructions', 'location_description', 'ocr_text', 'raw_text',
    'scanned_text', 'skip_reason', 'content', 'title',
    // Device / hardware identifiers
    'serial_number', 'device_id', 'fcm_token', 'push_token',
  };

  /// Substring rules for keys the exact set cannot anticipate.
  static const List<String> _piiKeyFragments = [
    'email', 'phone', 'password', 'secret', 'token', 'address',
    'ocr', 'serial', 'apikey', 'api_key', 'authorization',
  ];

  /// Whether a map key should have its value redacted.
  ///
  /// Explicitly allows `*_id`, `*_at` and `*_count` style keys through —
  /// UUIDs, timestamps and counts are the backbone of a usable report.
  static bool isPiiKey(String key) {
    final k = key.toLowerCase();
    if (_piiKeys.contains(k)) return true;
    // user_id / property_id / created_at are safe and worth keeping.
    if (k.endsWith('_id') || k == 'id' || k.endsWith('_at')) return false;
    return _piiKeyFragments.any(k.contains);
  }

  /// Redacts PII from a structured payload.
  ///
  /// Values under a PII key are replaced outright. Everything else is walked
  /// recursively, with string leaves passed through [redactText] so PII
  /// embedded in an innocuously-named field is still caught.
  static Map<String, dynamic> redactMap(Map<String, dynamic>? data) {
    if (data == null) return <String, dynamic>{};
    return data.map((key, value) {
      if (isPiiKey(key)) return MapEntry(key, redacted);
      return MapEntry(key, _redactValue(value));
    });
  }

  static dynamic _redactValue(dynamic value) => switch (value) {
        String s => redactText(s),
        Map<String, dynamic> m => redactMap(m),
        // Nested maps from JSON decoding arrive as Map<dynamic, dynamic>.
        Map m => redactMap(m.map((k, v) => MapEntry(k.toString(), v))),
        List l => l.map(_redactValue).toList(),
        _ => value,
      };
}
