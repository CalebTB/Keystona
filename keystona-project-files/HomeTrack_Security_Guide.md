# HomeTrack — Security Guide

**Version:** 1.0  
**Date:** February 23, 2026  
**Status:** Active — Every agent follows this before writing any code that touches auth, data, or network  
**Author:** Caleb (Founder & Product Owner)  
**Cross-references:** SRS §7.2–7.3, Database Schema (RLS policies, Storage Buckets), SKILL.md (Critical Rules), API Contract §16 (Rate Limits), Error Handling Guide §15 (Error Logging)

---

## 1. Overview

Keystona stores sensitive homeowner data: insurance policies, mortgage documents, property addresses, emergency contacts, and OCR-extracted text that may contain policy numbers, SSNs, and financial details. A security breach doesn't just expose data — it exposes people's homes.

This guide is the single source of truth for security decisions. It consolidates and extends the security requirements scattered across the SRS, Database Schema, SKILL.md, and API Contract into one actionable reference. When this guide conflicts with another document, this guide wins.

### 1.1 Threat Model Summary

| Threat | Likelihood | Impact | Primary Defense |
|--------|-----------|--------|-----------------|
| Unauthorized data access (broken RLS) | Medium | Critical | Row Level Security + property_id scoping |
| PII leakage via crash reports/logs | High | High | Sentry beforeSend scrubbing + log sanitization |
| Stolen/expired session tokens | Medium | High | 7-day expiry + biometric re-lock + refresh token rotation |
| Malicious file uploads | Medium | Medium | MIME validation + size limits + storage bucket policies |
| SQL injection via user input | Low (Supabase SDK mitigates) | Critical | Parameterized queries only + input validation |
| XSS via OCR text display | Medium | Medium | Flutter's built-in escaping + never rendering raw HTML |
| Unauthorized storage access | Low | High | Signed URLs with expiration + user-scoped file paths |
| Account takeover | Medium | Critical | Email verification + OAuth + biometric lock |

### 1.2 Security Principles

1. **Defense in depth.** Never rely on a single layer. RLS at the database, auth at the API, validation at the client.
2. **Least privilege.** Every query, function, and storage access uses the minimum permissions needed.
3. **Fail closed.** If auth state is uncertain, deny access. If RLS evaluation fails, deny the query.
4. **Never trust the client.** All authorization happens server-side via RLS and Edge Functions. Client-side checks are UX conveniences, not security boundaries.
5. **PII is toxic.** Treat all user-generated content as potentially containing PII. Never log it, never include it in error reports, never send it to analytics.

---

## 2. Authentication

### 2.1 Auth Providers

| Provider | Implementation | Notes |
|----------|---------------|-------|
| Email + Password | Supabase Auth (GoTrue) | Primary auth method |
| Apple Sign In | Supabase Auth OAuth | Required for App Store if offering any social login |
| Google Sign In | Supabase Auth OAuth | Convenience option |

All three providers are configured through Supabase Auth. The app MUST support all three at launch — Apple Sign In is required by Apple's App Store Review Guidelines (§4.8) when any third-party social login is offered.

### 2.2 Email Verification

Email verification is **required before app access**. The flow:

```
1. User signs up with email + password
2. Supabase sends verification email
3. App shows "Check your email" screen with:
   - "Resend verification" button (rate limited: 1 per 60 seconds)
   - "Use a different email" link
4. User taps verification link → deep link back to app
5. App detects verified session → proceeds to onboarding
```

**Rules:**
- Unverified users CANNOT access any app screen except the verification prompt
- Supabase Auth's `email_confirmed_at` field is the source of truth
- OAuth users (Apple, Google) are auto-verified (email comes from the provider)
- Verification links expire after 24 hours
- After 3 failed resend attempts, show "Contact support" instead

**Deep link security for verification:**
```dart
// ✅ Verify the deep link origin
// Supabase handles this via its own redirect URL configuration
// Configure in Supabase Dashboard → Auth → URL Configuration:
//   Site URL: keystona://auth-callback
//   Redirect URLs: keystona://auth-callback, https://app.keystona.com/auth/callback

// ✅ Never trust URL parameters directly — always validate the session
final session = supabase.auth.currentSession;
if (session != null && session.user.emailConfirmedAt != null) {
  // Verified — proceed
}
// ❌ Never: if (deepLinkParams['verified'] == 'true')
```

### 2.3 Session Management

| Setting | Value | Rationale |
|---------|-------|-----------|
| Access token lifetime | 1 hour | Short-lived, auto-refreshed by Supabase SDK |
| Refresh token lifetime | 7 days | Balanced security/convenience — user re-authenticates weekly |
| Refresh token rotation | Enabled | Each refresh issues a new refresh token and invalidates the old one |
| Refresh token reuse detection | Enabled | If a revoked refresh token is used, ALL sessions for that user are invalidated (potential token theft) |

**Configure in Supabase Dashboard → Auth → Settings:**
```
JWT Expiry: 3600 (1 hour)
Refresh Token Rotation: Enabled
Refresh Token Reuse Interval: 0 (immediate invalidation)
```

**Client-side session handling:**
```dart
// ✅ Supabase SDK handles token refresh automatically
// Just listen for auth state changes
supabase.auth.onAuthStateChange.listen((data) {
  final event = data.event;
  final session = data.session;
  
  switch (event) {
    case AuthChangeEvent.signedIn:
      // Navigate to app
      break;
    case AuthChangeEvent.tokenRefreshed:
      // SDK handled it — no action needed
      break;
    case AuthChangeEvent.signedOut:
      // Navigate to login
      break;
    case AuthChangeEvent.userDeleted:
      // Clear local data, navigate to login
      break;
  }
});

// ❌ Never store tokens manually
// ❌ Never pass tokens in URL parameters
// ❌ Never log tokens
```

### 2.4 Biometric Authentication

After initial login, the app uses biometric authentication (Face ID / Touch ID on iOS, fingerprint/face on Android) to unlock the app on subsequent opens.

**Flow:**
```
1. User completes initial login (email/password or OAuth)
2. App prompts: "Enable Face ID / fingerprint to unlock Keystona?"
3. If accepted: store a flag in secure storage (NOT the password)
4. On next app open:
   a. Check if biometric flag exists
   b. If yes: show biometric prompt
   c. If biometric succeeds: restore Supabase session from secure storage
   d. If biometric fails 3 times: fall back to full login
   e. If session is expired (>7 days): require full login regardless of biometrics
5. If declined: app opens directly to the session (standard token-based auth)
```

**Implementation rules:**
- Use `flutter_secure_storage` for storing the session refresh token — NOT SharedPreferences
- Biometric is a convenience lock, not an auth method. The real auth is the Supabase session token.
- If the refresh token is expired, biometric unlock fails gracefully → full login screen
- Users can disable biometric in Settings → Account
- Never store the user's password locally, even encrypted

```dart
// ✅ Secure storage for refresh token
final storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
);

// Store after successful login
await storage.write(key: 'refresh_token', value: session.refreshToken);

// Retrieve after biometric success
final refreshToken = await storage.read(key: 'refresh_token');
if (refreshToken != null) {
  await supabase.auth.setSession(refreshToken);
}

// ❌ Never: SharedPreferences.setString('token', session.accessToken)
// ❌ Never: store passwords locally
```

### 2.5 Logout and Session Cleanup

When a user logs out (or their session is invalidated):

```dart
Future<void> logout() async {
  // 1. Sign out from Supabase (invalidates refresh token server-side)
  await supabase.auth.signOut();
  
  // 2. Clear secure storage
  final storage = FlutterSecureStorage();
  await storage.deleteAll();
  
  // 3. Clear any cached data
  await clearLocalCache();  // Riverpod state, image cache, etc.
  
  // 4. Clear Emergency Hub offline database
  await emergencyDb.clearAll();
  
  // 5. Navigate to login screen (clear navigation stack)
  router.go('/login');
}
```

**Rules:**
- On logout, ALL local data must be cleared — no residual user data
- On account deletion request, the same cleanup runs plus a 30-day server-side grace period
- If a token refresh fails with a 401, treat it as a forced logout

### 2.6 OAuth Security

**Apple Sign In:**
- Use `sign_in_with_apple` package for iOS, Supabase OAuth for Android/web
- Apple may provide a "private relay" email — store it, it works like a normal email
- Never request more scopes than needed: `email` and `fullName` only
- Apple only sends the user's name on the FIRST sign-in — capture and store it immediately

**Google Sign In:**
- Use `google_sign_in` package → pass ID token to Supabase
- Request `email` and `profile` scopes only
- Verify ID token server-side (Supabase handles this)

**Common OAuth rules:**
- Never store OAuth access tokens from Apple/Google — Supabase exchanges them for its own session
- If an OAuth provider is disconnected mid-flow, show a friendly error and return to login
- OAuth users skip email verification (provider already verified the email)

---

## 3. Input Validation & Sanitization

### 3.1 Why This Matters with Supabase

Supabase's PostgREST layer and client SDK use parameterized queries, which prevents classical SQL injection. However, input validation is still critical for:
- Preventing stored XSS (malicious content in text fields rendered later)
- Enforcing business rules (file size, field lengths, valid formats)
- Protecting Edge Functions that construct dynamic queries
- Preventing abuse (oversized payloads, rapid submissions)

### 3.2 Client-Side Validation Rules

Every form input in the app must be validated before submission. These are UX validations — they don't replace server-side enforcement.

**Text fields:**

| Field Type | Max Length | Allowed Characters | Validation |
|------------|-----------|-------------------|------------|
| Display name | 100 chars | Letters, spaces, hyphens, apostrophes | No HTML tags, no URLs |
| Email | 254 chars | Standard email format | RFC 5322 regex |
| Password | 128 chars | Any printable | Min 8 chars, at least 1 uppercase, 1 lowercase, 1 number |
| Document name | 200 chars | Any printable | Trim whitespace, no control characters |
| Task name | 200 chars | Any printable | Trim whitespace |
| Notes / descriptions | 5,000 chars | Any printable | Trim whitespace |
| Address fields | 200 chars per field | Any printable | No validation beyond length |
| Phone numbers | 20 chars | Digits, +, -, (, ), spaces | Loose format — international numbers vary |
| Policy numbers | 50 chars | Alphanumeric, hyphens, spaces | No special validation |

**Numeric fields:**

| Field Type | Range | Validation |
|------------|-------|------------|
| Estimated cost | 0 – 10,000,000 | Non-negative, max 2 decimal places |
| Year installed | 1900 – current year + 1 | Integer |
| Budget amount | 0 – 100,000,000 | Non-negative, max 2 decimal places |

**Date fields:**
- Must be valid ISO 8601 dates
- "Installed date" cannot be in the future
- "Expiration date" must be after the current date (warning if past, but allow for recording expired docs)
- "Due date" can be any date

### 3.3 Server-Side Validation (Edge Functions)

Edge Functions that accept user input MUST validate independently of the client:

```typescript
// ✅ Edge Function input validation pattern
function validateInput(body: unknown): { valid: boolean; errors: string[] } {
  const errors: string[] = [];
  
  if (!body || typeof body !== 'object') {
    return { valid: false, errors: ['Invalid request body'] };
  }
  
  const { name, property_id, category_id } = body as Record<string, unknown>;
  
  // Required fields
  if (!property_id || typeof property_id !== 'string') {
    errors.push('property_id is required');
  }
  
  // UUID format validation
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (property_id && !uuidRegex.test(property_id as string)) {
    errors.push('property_id must be a valid UUID');
  }
  
  // String length limits
  if (name && (typeof name !== 'string' || (name as string).length > 200)) {
    errors.push('name must be a string under 200 characters');
  }
  
  // Strip HTML tags from text fields
  if (name && typeof name === 'string') {
    const stripped = (name as string).replace(/<[^>]*>/g, '');
    if (stripped !== name) {
      errors.push('HTML tags are not allowed in name');
    }
  }
  
  return { valid: errors.length === 0, errors };
}
```

### 3.4 HTML/XSS Prevention

Flutter's widget system does not render raw HTML by default, which provides natural XSS protection. However:

**Rules:**
- **Never use `Html` widget or `flutter_html` package** to render user-generated content. Display all user text as plain `Text` widgets.
- **Never render OCR text as HTML.** OCR output may contain HTML-like fragments from scanned documents. Always display as plain text.
- **Never use `Uri.parse()` on user-provided URLs without validation.** If the app eventually supports links in notes, validate the scheme (only `https://`).
- **Never use `dart:js` or `webview` to render user content.** If a webview is ever needed (e.g., payment flow), it must only load known, trusted URLs.

```dart
// ✅ Display OCR text safely
Text(
  document.ocrText ?? '',
  maxLines: 10,
  overflow: TextOverflow.ellipsis,
)

// ❌ Never render user content as HTML
// HtmlWidget(document.ocrText)  — BANNED
```

### 3.5 File Upload Validation

File uploads are validated at three layers:

**Layer 1 — Client-side (UX):**
```dart
// Check file size before upload
if (file.lengthSync() > 25 * 1024 * 1024) {  // 25MB
  showError('File too large. Maximum size is 25MB.');
  return;
}

// Check MIME type
final allowedTypes = ['application/pdf', 'image/jpeg', 'image/png', 'image/heic', 'image/webp'];
if (!allowedTypes.contains(file.mimeType)) {
  showError('File type not supported.');
  return;
}
```

**Layer 2 — Storage bucket policy (enforcement):**
Storage buckets enforce size limits and MIME types at the Supabase level. See Database Schema §12 for bucket configurations. Even if the client is bypassed, the server rejects invalid files.

**Layer 3 — Edge Function processing:**
The OCR Edge Function validates the file again before processing:
```typescript
// Verify file is actually the claimed type (magic bytes check)
const buffer = await file.arrayBuffer();
const header = new Uint8Array(buffer.slice(0, 4));

// PDF magic bytes: %PDF
const isPdf = header[0] === 0x25 && header[1] === 0x50 && header[2] === 0x44 && header[3] === 0x46;
// JPEG magic bytes: FF D8 FF
const isJpeg = header[0] === 0xFF && header[1] === 0xD8 && header[2] === 0xFF;
// PNG magic bytes: 89 50 4E 47
const isPng = header[0] === 0x89 && header[1] === 0x50 && header[2] === 0x4E && header[3] === 0x47;

if (!isPdf && !isJpeg && !isPng) {
  throw new Error('File content does not match claimed MIME type');
}
```

### 3.6 Rate Limiting

Client-side rate limiting prevents abuse and protects the backend:

| Action | Client-Side Limit | Server-Side Enforcement |
|--------|------------------|------------------------|
| Login attempts | 5 per minute, then 60-second lockout | Supabase Auth built-in rate limiting |
| Password reset requests | 1 per 60 seconds | Supabase Auth rate limiting |
| Document uploads | 3 concurrent, 20 per hour | Storage bucket + RPC guard |
| Search queries | Debounced 300ms | 10 req/sec per user |
| Task completions | 1 per second per task | RLS + updated_at check |
| Email verification resend | 1 per 60 seconds | Supabase Auth rate limiting |

---

## 4. Data Access Security

### 4.1 Row Level Security (RLS) — The Core Defense

RLS is the primary security boundary. Every user-data table has policies that restrict access to the authenticated user's own data. RLS cannot be bypassed from the client SDK — it's enforced at the PostgreSQL level.

**The fundamental pattern:**
```sql
-- Every user-data table follows this pattern
CREATE POLICY "Users can view own data"
  ON {table} FOR SELECT
  USING (user_id = auth.uid() AND deleted_at IS NULL);
```

**Critical RLS rules for agents:**

1. **Every new table with user data MUST have RLS enabled.** No exceptions. `ALTER TABLE {table} ENABLE ROW LEVEL SECURITY;`
2. **Every new table MUST have at least SELECT and INSERT policies.** UPDATE and DELETE policies as needed.
3. **Never use `SECURITY DEFINER` on client-callable functions** unless explicitly required (e.g., cross-user operations like household invites).
4. **Lookup tables (categories, templates) have NO user restriction** — they're read-only global data.
5. **Test RLS by trying to access another user's data.** Every feature PR must include a manual test: log in as User A, attempt to query User B's property_id.

### 4.2 Property-Scoped Access

All user data is scoped to a `property_id`. The access chain is:

```
auth.uid() → profiles.id → properties.user_id → {all data tables}.property_id
```

**Rules:**
- Client queries MUST filter by `property_id` first (hits the primary index)
- RLS policies validate that the `property_id` belongs to `auth.uid()` (or household member)
- Never allow a client to pass a `user_id` parameter — always derive from `auth.uid()` server-side

### 4.3 Household Member Access

When household sharing is implemented, RLS policies expand to include household members:

```sql
-- The helper function checks both ownership and household membership
CREATE OR REPLACE FUNCTION user_has_property_access(p_property_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM properties WHERE id = p_property_id AND user_id = auth.uid() AND deleted_at IS NULL
  ) OR EXISTS (
    SELECT 1 FROM household_members
    WHERE property_id = p_property_id
      AND member_user_id = auth.uid()
      AND invite_status = 'accepted'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Rules:**
- Household members get READ access equivalent to the owner
- Household members CANNOT delete the property, transfer ownership, or manage billing
- Household member policies are applied via Migration 008b (see Database Schema)

### 4.4 Storage Access Security

All storage buckets are **private** — no public URLs. Files are accessed via signed URLs with expiration.

**File path structure:** `{user_id}/{property_id}/{filename}`

This structure ensures:
- RLS policies on `storage.objects` validate `auth.uid()` matches the first folder segment
- Even if someone guesses a file path, they can't access it without a valid signed URL AND a matching auth session
- Signed URLs expire (default: 1 hour) and cannot be reused after expiration

```dart
// ✅ Generate signed URL for viewing
final signedUrl = await supabase.storage
    .from('documents')
    .createSignedUrl(filePath, 3600);  // 1 hour expiry

// ✅ Generate signed URL for downloading
final signedUrl = await supabase.storage
    .from('documents')
    .createSignedUrl(filePath, 300);  // 5 minutes for download

// ❌ Never use getPublicUrl() for user documents
// ❌ Never cache signed URLs beyond their expiry
// ❌ Never pass signed URLs to third parties
```

### 4.5 Edge Function Security

Edge Functions run server-side with elevated privileges. They require extra caution.

**Rules:**
1. **Always verify the auth token** at the start of every Edge Function:
```typescript
const authHeader = req.headers.get('Authorization');
const { data: { user }, error } = await supabase.auth.getUser(
  authHeader?.replace('Bearer ', '')
);
if (error || !user) {
  return new Response('Unauthorized', { status: 401 });
}
```

2. **Never trust client-supplied user_id.** Extract from the auth token:
```typescript
// ✅ Get user from token
const userId = user.id;

// ❌ Never: const userId = body.user_id;
```

3. **Use `SECURITY DEFINER` sparingly.** Only for operations that need cross-user access (e.g., household invites, admin operations). Document WHY it's needed in a comment.

4. **Validate webhook signatures** for external services:
```typescript
// RevenueCat webhook validation
const signature = req.headers.get('X-RevenueCat-Signature');
const expectedSignature = computeHmac(rawBody, REVENUECAT_WEBHOOK_SECRET);
if (signature !== expectedSignature) {
  return new Response('Invalid signature', { status: 403 });
}
```

5. **Environment variables for secrets.** Never hardcode API keys:
```typescript
// ✅ From environment
const apiKey = Deno.env.get('GOOGLE_VISION_API_KEY');

// ❌ Never: const apiKey = 'AIzaSy...';
```

---

## 5. Sensitive Data Handling

### 5.1 PII Classification

Keystona handles data that ranges from non-sensitive to highly sensitive:

| Sensitivity | Data Type | Examples | Handling |
|-------------|-----------|---------|----------|
| **Critical** | Financial identifiers | SSNs in OCR text, bank account numbers | Never stored intentionally. If detected in OCR, flagged but not indexed. Never logged. |
| **High** | Insurance details | Policy numbers, claims phone, coverage amounts | Stored encrypted at rest (Supabase default AES-256). Never logged. Never in error reports. |
| **High** | Property details | Full address, purchase price, mortgage info | Stored encrypted at rest. Never sent to analytics. |
| **Medium** | Personal info | Name, email, phone number | Stored in profiles. Email used for auth. Never in error reports beyond user ID. |
| **Medium** | Document content | OCR text, document names, notes | May contain any PII. Treat as high sensitivity. Never logged. |
| **Low** | App behavior | Feature usage, screen views, task completion counts | Safe for analytics (PostHog). No PII attached. |
| **None** | System data | App version, device model, OS version | Safe for error reports and analytics. |

### 5.2 What Is NEVER Stored

The following data is never stored in Keystona's database, even if provided by the user:

- **Passwords** — handled entirely by Supabase Auth (bcrypt hashed)
- **Credit card numbers** — handled entirely by RevenueCat/Stripe
- **OAuth tokens from Apple/Google** — exchanged for Supabase session, then discarded
- **Biometric data** — handled by the device OS, never leaves the device
- **Full SSNs** — if detected in OCR text, the OCR pipeline should NOT index these. The raw document is stored (encrypted), but extracted text should redact SSN patterns.

### 5.3 What Is NEVER Logged

These fields must NEVER appear in application logs, crash reports, or analytics:

| Field | Why |
|-------|-----|
| `ocr_text` | May contain SSNs, policy numbers, financial data |
| `notes` (any table) | User may enter sensitive details |
| `serial_number` | Appliance identification |
| `policy_number` | Insurance identification |
| `claims_phone` | Could be used for social engineering |
| `email` | PII — use `user_id` for log correlation instead |
| `display_name` | PII |
| `phone` (emergency contacts) | PII |
| `address` fields | PII |
| JWT tokens | Auth credentials |
| File contents | May contain anything |

### 5.4 Sentry Configuration

Sentry is the crash reporting tool. It must be configured to strip PII before reports leave the device.

```dart
// ✅ Sentry initialization with PII scrubbing
await SentryFlutter.init(
  (options) {
    options.dsn = const String.fromEnvironment('SENTRY_DSN');
    options.environment = const String.fromEnvironment('ENV', defaultValue: 'development');
    
    // Strip PII from all events
    options.beforeSend = (event, {hint}) {
      return _scrubPii(event);
    };
    
    // Strip PII from breadcrumbs
    options.beforeBreadcrumb = (breadcrumb, {hint}) {
      return _scrubBreadcrumb(breadcrumb);
    };
    
    // Never send default PII
    options.sendDefaultPii = false;
    
    // Don't attach screenshots (may contain sensitive data)
    options.attachScreenshot = false;
    
    // Don't attach view hierarchy (may contain text field values)
    options.attachViewHierarchy = false;
    
    // Performance monitoring (no PII concerns)
    options.tracesSampleRate = 0.2;  // 20% of transactions
  },
);

SentryEvent _scrubPii(SentryEvent event) {
  // Remove user email — keep only user ID for correlation
  final user = event.user;
  if (user != null) {
    event = event.copyWith(
      user: SentryUser(id: user.id),  // Only keep ID
    );
  }
  
  // Scrub known PII patterns from exception messages
  var message = event.throwable?.toString() ?? '';
  message = _redactPatterns(message);
  
  // Scrub breadcrumb data
  final scrubbed = event.breadcrumbs?.map((b) {
    if (b.data != null) {
      final clean = Map<String, dynamic>.from(b.data!);
      // Remove any keys that might contain PII
      clean.removeWhere((key, _) => _isPiiKey(key));
      return b.copyWith(data: clean);
    }
    return b;
  }).toList();
  
  return event.copyWith(breadcrumbs: scrubbed);
}

String _redactPatterns(String text) {
  // SSN pattern: XXX-XX-XXXX
  text = text.replaceAll(RegExp(r'\b\d{3}-\d{2}-\d{4}\b'), '[REDACTED-SSN]');
  // Email pattern
  text = text.replaceAll(RegExp(r'\b[\w.+-]+@[\w-]+\.[\w.]+\b'), '[REDACTED-EMAIL]');
  // Phone pattern (US)
  text = text.replaceAll(RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b'), '[REDACTED-PHONE]');
  // Policy number pattern (common formats)
  text = text.replaceAll(RegExp(r'\b[A-Z]{2,3}-?\d{6,12}\b'), '[REDACTED-POLICY]');
  return text;
}

bool _isPiiKey(String key) {
  final piiKeys = {
    'email', 'name', 'phone', 'address', 'ssn', 'policy_number',
    'serial_number', 'ocr_text', 'notes', 'display_name', 'claims_phone',
    'password', 'token', 'refresh_token', 'access_token',
  };
  return piiKeys.contains(key.toLowerCase());
}
```

### 5.5 PostHog Analytics Configuration

PostHog tracks product analytics. It must never receive PII.

```dart
// ✅ PostHog initialization
PostHog.init(
  apiKey: const String.fromEnvironment('POSTHOG_KEY'),
  config: PostHogConfig(
    host: 'https://app.posthog.com',
    // Identify by user ID only — never email or name
  ),
);

// ✅ Identify user (ID only)
PostHog.identify(userId: supabase.auth.currentUser!.id);

// ✅ Track events (no PII in properties)
PostHog.capture(
  eventName: 'task_completed',
  properties: {
    'task_category': 'hvac',       // OK: category, not task name
    'completion_type': 'quick',     // OK: completion method
    'property_type': 'single_family', // OK: generic property type
    'days_overdue': 3,              // OK: numeric
  },
);

// ❌ Never include PII in analytics
// PostHog.capture(eventName: 'task_completed', properties: {
//   'task_name': 'Fix leak at 123 Main St',  // BANNED: contains address
//   'user_email': user.email,                  // BANNED: PII
//   'document_name': 'State Farm Policy',      // BANNED: could identify user
// });
```

**Safe analytics properties:**

| Safe to Track | Example Value | Why Safe |
|---------------|--------------|---------|
| Feature usage | `screen_viewed: 'documents'` | No PII |
| Action counts | `tasks_completed_this_week: 5` | Aggregate number |
| Subscription tier | `tier: 'premium'` | No PII |
| Property type | `type: 'single_family'` | Generic category |
| Climate zone | `zone: 4` | Not personally identifying |
| Device info | `platform: 'ios', os_version: '17.2'` | No PII |
| Error types | `error: 'upload_failed'` | No PII (never include error messages) |

### 5.6 Application Logging

For development and debugging, the app uses structured logging. PII rules apply:

```dart
// ✅ Safe logging
logger.info('Document uploaded', {
  'user_id': userId,           // OK: needed for debugging
  'property_id': propertyId,   // OK: needed for debugging
  'category': 'insurance',     // OK: generic category
  'file_size_bytes': 2340000,  // OK: numeric
  'mime_type': 'application/pdf', // OK: technical
});

// ❌ Never log PII
// logger.info('Document uploaded: ${document.name} by ${user.email}');
// logger.error('OCR failed for text: ${document.ocrText}');
// logger.debug('User ${user.displayName} at ${property.address}');
```

**In production builds:** Disable all debug-level logging. Only error-level logs should fire, and they must go through the Sentry PII scrubber.

---

## 6. Data Encryption

### 6.1 Encryption at Rest

| Layer | Encryption | Provider |
|-------|-----------|----------|
| Database (PostgreSQL) | AES-256 | Supabase managed (transparent disk encryption) |
| Storage (files) | AES-256 | Supabase Storage (S3-compatible encryption) |
| Local secure storage | Keychain (iOS) / EncryptedSharedPreferences (Android) | `flutter_secure_storage` |
| Emergency Hub offline DB | SQLCipher (AES-256-CBC) | `sqflite_sqlcipher` package |

### 6.2 Encryption in Transit

| Connection | Protocol | Enforcement |
|-----------|----------|-------------|
| App → Supabase | TLS 1.3 | Supabase enforces HTTPS-only |
| App → Google Cloud Vision (OCR) | TLS 1.3 | Google enforces HTTPS |
| App → RevenueCat | TLS 1.3 | RevenueCat enforces HTTPS |
| App → Firebase (FCM) | TLS 1.3 | Firebase enforces HTTPS |

**iOS App Transport Security (ATS):** Enabled by default in Flutter iOS builds. Do NOT add ATS exceptions to `Info.plist` unless absolutely required (and document why).

**Android Network Security Config:** Already configured via Flutter. No cleartext traffic allowed.

### 6.3 Emergency Hub Offline Database

The Emergency Hub stores data locally for offline access. This data includes addresses, shutoff locations, contact phone numbers, and insurance info — all sensitive.

```dart
// ✅ Use SQLCipher for the offline Emergency Hub database
final db = await openDatabase(
  'emergency_hub.db',
  password: await _getOrGenerateEncryptionKey(),
  // Key stored in flutter_secure_storage, NOT hardcoded
);
```

**The encryption key:**
- Generated once using `Uint8List.fromList(List.generate(32, (_) => Random.secure().nextInt(256)))`
- Stored in `flutter_secure_storage` under key `emergency_db_key`
- If the key is lost (user clears app data), the database is recreated from the server on next sync

---

## 7. CCPA Compliance

### 7.1 Requirements (from SRS §7.3)

| Right | Implementation |
|-------|---------------|
| Right to Know | Data export via Settings → Data & Privacy → Export My Data |
| Right to Delete | Account deletion via Settings → Data & Privacy → Delete Account |
| Right to Opt-Out | No data selling — nothing to opt out of. Analytics use anonymous IDs. |

### 7.2 Data Export

The `export-user-data` Edge Function generates a ZIP file containing:
- `profile.json` — user profile data
- `property.json` — property details
- `documents/` — all uploaded documents (original files)
- `systems.json` — system records
- `appliances.json` — appliance records
- `tasks.json` — maintenance task records with completion history
- `emergency.json` — shutoff locations, contacts, insurance info (no photos in export — too large)

**Rules:**
- Export is triggered by the user from Settings
- Processing happens asynchronously — user gets a push notification when ready
- Export download link expires after 24 hours
- Export includes ALL user data — nothing withheld
- OCR text IS included in the document metadata (it's the user's data)

### 7.3 Account Deletion

Account deletion follows a 30-day grace period:

```
Day 0: User requests deletion → account_status set to 'pending_deletion'
  - All active sessions invalidated
  - User can still log in and cancel
  - App shows "Your account is scheduled for deletion on [date]" banner
Day 30: Cron function executes hard delete
  - All database records deleted (CASCADE)
  - All storage files deleted
  - Supabase auth user deleted
  - Sentry data deletion request submitted
  - PostHog data deletion request submitted
```

**Rules:**
- User can cancel anytime during the 30-day window
- No data is actually deleted until day 30
- Household members are notified when an owner requests deletion
- After hard delete, the email address can be reused for a new account

---

## 8. Pre-Deployment Security Checklist

Every agent must verify these items before submitting code that touches auth, data, or network. This checklist applies to every PR, not just security-specific work.

### 8.1 Authentication

- [ ] No tokens stored in SharedPreferences (use `flutter_secure_storage` only)
- [ ] No tokens logged or printed to console
- [ ] No tokens passed as URL parameters
- [ ] OAuth flows use Supabase Auth (not custom token handling)
- [ ] Logout clears ALL local data (secure storage, cache, offline DB)
- [ ] Auth state changes are handled (signedIn, signedOut, tokenRefreshed)
- [ ] Unverified users cannot access app screens

### 8.2 Data Access

- [ ] New tables have RLS enabled with appropriate policies
- [ ] All queries filter by `property_id` first
- [ ] All queries on soft-delete tables check `deleted_at IS NULL`
- [ ] No `SELECT *` on list screens — only needed columns
- [ ] No N+1 queries — use nested selects
- [ ] No client-supplied `user_id` used for authorization (use `auth.uid()`)

### 8.3 Input Validation

- [ ] All form inputs validate length, format, and allowed characters
- [ ] File uploads check size and MIME type before upload
- [ ] Edge Functions validate all input parameters independently
- [ ] No raw HTML rendering of user-generated content
- [ ] No `Uri.parse()` on unvalidated user input

### 8.4 Sensitive Data

- [ ] No PII in log statements (no names, emails, addresses, OCR text)
- [ ] No PII in analytics events (only user_id for identification)
- [ ] No PII in error reports (Sentry beforeSend scrubs all fields)
- [ ] Sentry `sendDefaultPii` is `false`
- [ ] Sentry `attachScreenshot` is `false`
- [ ] No secrets hardcoded in code (use environment variables)

### 8.5 Storage

- [ ] File paths follow `{user_id}/{property_id}/` structure
- [ ] Only signed URLs used for file access (never public URLs)
- [ ] Signed URLs have appropriate expiry (1 hour for viewing, 5 minutes for download)
- [ ] No signed URLs cached beyond expiry
- [ ] Storage bucket MIME type and size limits are correct

### 8.6 Network

- [ ] No cleartext HTTP connections (HTTPS only)
- [ ] No ATS exceptions in iOS `Info.plist` (unless documented and justified)
- [ ] External API keys stored in environment variables, not code
- [ ] Webhook endpoints verify signatures before processing

---

## 9. Cross-References

| Topic | Document | Section |
|-------|----------|---------|
| Security requirements | SRS | §7.2 (Security), §7.3 (Privacy) |
| RLS policies (all tables) | Database Schema | Every migration file |
| Storage bucket policies | Database Schema | §12 |
| Supabase agent critical rules | SKILL.md | Critical Rules |
| Rate limits | API Contract | §16 |
| Error logging patterns | Error Handling Guide | §15 |
| Signed URL patterns | SKILL.md | Storage Operations |
| Account deletion flow | API Contract | §14.1 (Edge Functions) |
| Offline database | Error Handling Guide | §5 |
| OCR processing pipeline | API Contract | §14.2 |

---

*End of Security Guide*  
*HomeTrack (Keystona) — Version 1.0 — February 2026*
