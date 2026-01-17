# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Keystona** is a comprehensive home management platform helping homeowners organize documents, track maintenance, monitor property value, and manage home-related tasks.

**Technology Stack:**
- **Mobile**: Flutter (iOS & Android)
- **Web**: Next.js 14+ with App Router
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Edge Functions)
- **Payments**: RevenueCat (mobile) + Stripe (web)
- **Analytics**: PostHog
- **External APIs**: ATTOM (property data), Google Cloud Vision (OCR), OpenWeatherMap (weather alerts)

## Repository Structure

This repository contains both planning/specifications AND implementation:
- `hometrack_mobile/` - **Flutter mobile app (PRIMARY IMPLEMENTATION)** - Use this directory for all Flutter development
- `hometrack_web/` - Next.js web app (future implementation)
- `hometrack_supabase/` - Supabase migrations and Edge Functions (future implementation)
- Feature specifications (`*_FeatureSpec.md`)
- Technical architecture ([Keystona_TechnicalArchitecture.md](Keystona_TechnicalArchitecture.md))
- Wireframes (`.html` files)
- Agent definitions (`.claude/agents/`)
- Development guides

**IMPORTANT:** All Flutter development work happens in `/Users/calebbyers/Code/Keystona/hometrack_mobile/`

## Core Architecture Principles

### Multi-Platform Strategy
- **Mobile and web share the same backend** but have independent frontends
- Mobile is optimized for on-the-go access and offline capabilities
- Web is optimized for desktop workflows and bulk operations
- Both platforms sync through Supabase real-time

### Offline-First Design
- **Emergency Hub must work without internet** - uses SQLite for local persistence
- Other features support offline mode with background sync
- Always show sync status indicators to users

### Security-First Database
- **Every table must have Row Level Security (RLS) enabled**
- Users can only access their own data via `auth.uid()` checks
- Use signed URLs with expiration for file access
- Never store payment information (handled by RevenueCat/Stripe)

### Scalable Storage Strategy
- **Phase 1 (0-10K users)**: Supabase Storage
- **Phase 2 (10K-100K users)**: Migrate to Cloudflare R2 (zero egress fees)
- **Phase 3 (100K+ users)**: Multi-tier storage (R2 hot + Backblaze B2 cold)

## Development Workflow

### When Implementing Features

1. **Read the feature spec first** - All features have detailed specs in `*_FeatureSpec.md`
2. **Reference the technical architecture** - See [Keystona_TechnicalArchitecture.md](Keystona_TechnicalArchitecture.md)
3. **Use specialized agents** - See `.claude/agents/` for agent definitions:
   - `flutter-ui-builder` - Mobile UI components
   - `nextjs-web-builder` - Web pages and components
   - `supabase-backend-architect` - Database schema and RLS
   - `api-integration-specialist` - External API connections
   - `document-processor` - File upload and OCR pipelines
   - `notification-scheduler` - Reminders and alerts
   - `testing-qa-agent` - Test generation
   - `devops-cicd-orchestrator` - Deployment pipelines

4. **Follow the design system** - Keystona Premium Home Theme:
   - Primary: Deep Blue (#1E3A5F)
   - Accent: Warm Gold (#D4A574)
   - Spacing: 4px base unit (4, 8, 12, 16, 24, 32, 48)
   - Border radius: 8px standard, 12px cards, 16px modals

### Code Style
- Prefer duplication over premature abstraction
- Simple, clear code over clever code
- Self-documenting names; comments only when non-obvious

### Git Workflow - CRITICAL REQUIREMENTS

**NEVER PUSH DIRECTLY TO MAIN BRANCH**

Always follow this workflow:
1. Create a feature branch: `git checkout -b feature/your-feature-name`
2. Make your changes and commit frequently
3. Push to the feature branch: `git push origin feature/your-feature-name`
4. Create a Pull Request for review
5. Only merge to main through approved PRs

**Branch Naming Convention:**
- Features: `feature/authentication-mvp`, `feature/document-vault`
- Bugs: `bugfix/fix-session-persistence`
- Hotfixes: `hotfix/critical-crash-fix`

**Commit Message Format:**
```
Brief description of change (imperative mood)

Optional detailed explanation of what and why.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

### Before You Code

1. Create a feature branch (NEVER work on main)
2. Check for existing patterns: `git log --oneline -20`
3. Look for similar features in codebase
4. Reference feature specs in the repository
5. Plan before implementing

### Code Organization Patterns

#### Flutter (Mobile)
**Location:** `/Users/calebbyers/Code/Keystona/hometrack_mobile/lib/`

```
hometrack_mobile/
  lib/
    core/
      config/        # Supabase client, app configuration
      theme/         # App theme and design system
    features/
      feature_name/
        models/      # Data classes
        providers/   # Riverpod state management
        screens/     # Full page views
        widgets/     # Reusable components
        services/    # Business logic
    main.dart        # App entry point
  test/
    features/
      feature_name/
        *_test.dart  # Tests (must end with _test.dart)
```

**State Management:**
- **Current Approach (Auth MVP):** Manual Riverpod providers (`Provider`, `StreamProvider`, `FutureProvider`)
- **Future Features:** Evaluate code generation with `@riverpod` annotation for new features
- **When to Use Each:**
  - **Manual Providers:** Simple providers, quick MVPs, learning Riverpod basics
  - **Code Generation:** Complex state with AsyncNotifier, features with many providers, when developer experience matters more than setup simplicity
- **Migration:** Don't rewrite working manual providers - only use codegen for new features

#### Next.js (Web)
```
app/
  (dashboard)/
    feature_name/
      page.tsx        # Route pages
      [id]/page.tsx   # Dynamic routes
  api/
    feature_name/     # API routes
components/
  ui/                 # Base components
  features/           # Feature-specific components
```

**Conventions:** Server Components by default, Client Components only when needed (interactivity, hooks).

#### Supabase
```
supabase/
  migrations/         # SQL migration files
  functions/          # Edge Functions (Deno)
    function-name/
      index.ts
```

## Common Commands

### Flutter Development
**Project Location:** `/Users/calebbyers/Code/Keystona/hometrack_mobile/`

```bash
# Setup and development
cd /Users/calebbyers/Code/Keystona/hometrack_mobile
flutter pub get                    # Install dependencies
flutter run                        # Run on connected device
flutter analyze                    # Static analysis
flutter test                       # Run unit tests

# Building
flutter build apk --release        # Android APK
flutter build appbundle            # Android App Bundle (for Play Store)
flutter build ios --release        # iOS build
flutter build ios --debug --no-codesign  # iOS debug build (also runs pod install)
```

### Next.js Development
```bash
# Development
npm install                        # Install dependencies
npm run dev                        # Start dev server (localhost:3000)
npm run build                      # Production build
npm run lint                       # ESLint check
npm run type-check                 # TypeScript validation
```

### Supabase Development
```bash
# Local development
npx supabase start                 # Start local Supabase instance
npx supabase stop                  # Stop local instance
npx supabase status                # Show URLs and keys

# Database operations
npx supabase db reset              # Reset to clean state
npx supabase db push               # Push migrations to remote
npx supabase db pull               # Pull remote schema
npx supabase migration new <name>  # Create new migration
npx supabase db diff               # Generate migration from changes

# Edge Functions
npx supabase functions serve       # Run functions locally
npx supabase functions deploy      # Deploy all functions
```

## Patterns

### Pattern: Supabase SecureLocalStorage for Session Management
Supabase sessions must be stored using hardware-backed encryption instead of SharedPreferences.

```dart
// lib/core/config/supabase_client.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureLocalStorage extends LocalStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<void> initialize() async {
    // No initialization needed
  }

  @override
  Future<String?> accessToken() async {
    return await _storage.read(key: 'supabase.auth.token');
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _storage.write(
      key: 'supabase.auth.token',
      value: persistSessionString,
    );
  }

  @override
  Future<void> removePersistedSession() async {
    await _storage.delete(key: 'supabase.auth.token');
  }

  @override
  Future<bool> hasAccessToken() async {
    final token = await accessToken();
    return token != null;
  }
}

// Usage in initialization
await Supabase.initialize(
  url: supabaseUrl,
  anonKey: supabaseAnonKey,
  authOptions: FlutterAuthClientOptions(
    authFlowType: AuthFlowType.pkce,
    localStorage: SecureLocalStorage(), // Custom secure storage
  ),
);
```

**Why:** Default Supabase storage uses SharedPreferences which stores data unencrypted. FlutterSecureStorage provides hardware-backed encryption (iOS Keychain, Android Keystore) for sensitive authentication tokens.

### Pattern: Sealed Class Error Handling
Use sealed classes for exhaustive, type-safe error handling without silent failures.

```dart
// features/auth/models/auth_result.dart
sealed class AuthResult<T> {
  const AuthResult();
}

class AuthSuccess<T> extends AuthResult<T> {
  final T data;
  const AuthSuccess(this.data);
}

class AuthFailure<T> extends AuthResult<T> {
  final AuthError error;
  const AuthFailure(this.error);
}

sealed class AuthError {
  final String message;
  const AuthError(this.message);
}

class NetworkError extends AuthError {
  const NetworkError() : super('No internet connection. Please try again.');
}

class InvalidCredentialsError extends AuthError {
  const InvalidCredentialsError() : super('Invalid email or password.');
}

// Usage with exhaustive pattern matching
final result = await authService.signIn(email: email, password: password);

switch (result) {
  case AuthSuccess(:final data):
    // Handle success - compiler ensures you handle this
  case AuthFailure(:final error):
    // Handle error - compiler ensures you handle this
}
```

**Why:** Sealed classes with pattern matching prevent forgotten error cases at compile-time, unlike traditional try-catch which can silently fail.

### Pattern: Exception-to-Error Mapping
Map low-level SDK exceptions to user-friendly, actionable error types.

```dart
// features/auth/services/auth_service.dart
AuthError _mapAuthException(AuthException e) {
  if (e.message.contains('Invalid login credentials')) {
    return const InvalidCredentialsError();
  } else if (e.message.contains('User already registered')) {
    return const EmailAlreadyExistsError();
  } else if (e.message.contains('Password should be')) {
    return const WeakPasswordError();
  } else {
    return UnknownError(e.message);
  }
}

Future<AuthResult<UserModel>> signUp({
  required String email,
  required String password,
  required String fullName,
}) async {
  try {
    final response = await _auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    if (response.user == null) {
      return const AuthFailure(UnknownError('Failed to create account'));
    }

    return AuthSuccess(UserModel.fromSupabaseUser(response.user!));
  } on AuthException catch (e) {
    return AuthFailure(_mapAuthException(e)); // Map to user-friendly errors
  } catch (e) {
    return AuthFailure(UnknownError(e.toString()));
  }
}
```

**Why:** SDK exceptions contain technical messages ("Invalid login credentials") that need translation to user-friendly errors ("Invalid email or password"). Centralized mapping prevents duplicate error handling logic across the app.

### Pattern: Manual Riverpod Providers (No Code Generation)
For MVPs, use manual Riverpod providers to avoid build_runner complexity.

```dart
// features/auth/providers/auth_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) => user != null ? UserModel.fromSupabaseUser(user) : null,
    loading: () => null,
    error: (_, __) => null,
  );
});
```

**Why:** Code generation adds build complexity and watch mode requirements. Manual providers are sufficient for MVPs and can be migrated to codegen later if needed.

**Future Direction:** For features beyond the authentication MVP, evaluate using Riverpod code generation (`@riverpod` annotation with `riverpod_generator`) for improved developer experience and reduced boilerplate. The existing auth code will remain with manual providers - don't rewrite working code.

## Critical Implementation Patterns

### Pattern: Supabase Row Level Security
Every table must have RLS enabled with policies restricting access to the user's own data.

```sql
-- Enable RLS on table
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Users can only see their own documents
CREATE POLICY "Users see own documents" ON documents
  FOR SELECT USING (
    property_id IN (
      SELECT id FROM properties WHERE user_id = auth.uid()
    )
  );

-- Users can only insert their own documents
CREATE POLICY "Users insert own documents" ON documents
  FOR INSERT WITH CHECK (
    property_id IN (
      SELECT id FROM properties WHERE user_id = auth.uid()
    )
  );
```

### Pattern: Flutter Offline-First Data
For Emergency Hub and critical features, always implement local persistence with background sync.

```dart
// 1. Define local and remote data sources
class EmergencyRepository {
  final LocalDatabase _local;
  final SupabaseClient _remote;

  Future<List<Emergency>> getEmergencies() async {
    // Try local first
    final localData = await _local.getEmergencies();

    // Attempt background sync if online
    _syncInBackground();

    return localData;
  }

  Future<void> _syncInBackground() async {
    if (await _hasConnection()) {
      final remoteData = await _remote.from('emergency_info').select();
      await _local.updateEmergencies(remoteData);
    }
  }
}
```

### Pattern: Next.js Server Actions with Supabase
Use Server Actions for mutations that require server-side validation or security.

```typescript
// app/actions/documents.ts
'use server'

import { createClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'

export async function deleteDocument(documentId: string) {
  const supabase = createClient()

  // Supabase RLS will enforce authorization
  const { error } = await supabase
    .from('documents')
    .delete()
    .eq('id', documentId)

  if (error) throw error

  revalidatePath('/documents')
}
```

### Pattern: External API Integration with Caching
Always cache external API responses to minimize costs and improve performance.

```typescript
// Edge Function example
import { createClient } from '@supabase/supabase-js'

export async function getHomeValue(address: string) {
  const supabase = createClient(SUPABASE_URL, SUPABASE_KEY)

  // Check cache first (24 hour TTL for home values)
  const { data: cached } = await supabase
    .from('api_cache')
    .select('value')
    .eq('key', `attom:value:${address}`)
    .gte('cached_at', new Date(Date.now() - 24*60*60*1000))
    .single()

  if (cached) return cached.value

  // Fetch from ATTOM API
  const response = await fetch(ATTOM_API_URL, {
    headers: { 'apikey': ATTOM_API_KEY }
  })
  const value = await response.json()

  // Store in cache
  await supabase.from('api_cache').upsert({
    key: `attom:value:${address}`,
    value,
    cached_at: new Date()
  })

  return value
}
```

## Key Architectural Decisions

### Decision: Supabase for MVP Backend
**Context:** Needed a backend that enables rapid development while maintaining a clear migration path to AWS at scale.

**Chosen:** Supabase (PostgreSQL + Auth + Storage + Functions)

**Rationale:**
- Built on PostgreSQL (industry standard, easy to migrate)
- Integrated authentication with RLS support
- Generous free tier, predictable pricing
- Edge Functions for serverless compute
- Real-time subscriptions for cross-device sync

**Trade-offs:**
- Storage limited to 100GB on Pro plan (requires R2 migration at ~10K users)
- Connection pool limits (requires RDS migration at ~200K users)
- Vendor dependency (mitigated by PostgreSQL standard and export tools)

### Decision: Separate Mobile and Web Codebases
**Context:** Need both mobile apps and a web dashboard.

**Chosen:** Flutter for mobile, Next.js for web (separate codebases sharing same API)

**Rationale:**
- Mobile and web have fundamentally different UX requirements
- Flutter excels at mobile but web experience is suboptimal
- Next.js provides superior web experience with SEO and server-side rendering
- Shared Supabase backend keeps business logic consistent

**Trade-offs:**
- Code duplication for UI components (mitigated by shared design system)
- Need to maintain two frontends (accepted for better UX)

### Decision: RevenueCat for Multi-Platform Payments
**Context:** Need to handle App Store, Play Store, and web payments with a single source of truth.

**Chosen:** RevenueCat + Stripe

**Rationale:**
- RevenueCat abstracts App Store and Play Store complexities
- Handles receipt validation, webhooks, and subscription status
- Single API for checking subscription state across platforms
- Stripe integration for web payments

**Trade-offs:**
- Additional service dependency (accepted for significantly reduced complexity)
- Small per-transaction fee (worth it for time saved)

### Decision: flutter_dotenv for Environment Configuration
**Context:** Need to configure Supabase URL and anon key without hardcoding credentials in source code.

**Chosen:** `flutter_dotenv` package for runtime environment variable loading

**Alternatives Considered:**
1. **String.fromEnvironment()** - Compile-time only, requires `--dart-define` flags in every command
2. **Hardcoded values** - Explicitly rejected by user, security risk
3. **JSON config files** - More complex, no environment-specific support

**Rationale:**
- Runtime loading from `.env.development` / `.env.production` files
- Standard pattern familiar to web developers
- Simple API: `dotenv.env['KEY']`
- Supports multiple environments without build configuration

**Trade-offs:**
- Requires declaring .env files in pubspec.yaml assets
- Not as "pure" as compile-time constants but more practical for MVP

### Decision: Supabase user_metadata for User Profile Data
**Context:** Need to store user's full name during signup.

**Chosen:** Use Supabase's built-in `auth.users.user_metadata` JSON field

**Alternatives Considered:**
1. **Separate users_metadata table** - Risk of orphaned records if signup fails partway
2. **profiles table** - Requires separate transaction, more complex error handling

**Rationale:**
- Atomic operation - metadata saved with user creation
- No orphaned records if transaction fails
- Built-in Supabase feature designed for this use case
- Simpler error handling (single transaction)

**Trade-offs:**
- JSON field less structured than relational table (acceptable for MVP with only full_name)
- Can migrate to profiles table later if complex user data is needed

### Decision: Manual Riverpod Providers vs Code Generation
**Context:** Need state management for authentication but want to ship MVP quickly.

**Chosen:** Manual Riverpod providers without `riverpod_generator`

**Alternatives Considered:**
1. **riverpod_generator with build_runner** - Industry best practice but adds complexity
2. **Provider package** - Older, less type-safe
3. **BLoC pattern** - More boilerplate

**Rationale:**
- No build_runner watch mode required during development
- Simpler project setup for MVP
- Still get Riverpod's benefits (type safety, compile-time dependency tracking)
- Can migrate to codegen later if codebase grows

**Trade-offs:**
- Manual boilerplate for providers (acceptable for MVP scope)
- No auto-dispose or family providers (not needed yet)
- Follows hybrid approach: simplify until proven necessary

**Going Forward:**
- **Keep auth MVP as-is** - Don't rewrite working manual providers
- **For new features** - Evaluate code generation on a case-by-case basis:
  - Use **manual providers** when: Simple state, few providers, quick prototypes
  - Use **code generation** when: Complex AsyncNotifier patterns, many interdependent providers, long-term feature development
- **Setup for codegen** (if needed):
  ```yaml
  dependencies:
    riverpod_annotation: ^2.3.0
  dev_dependencies:
    riverpod_generator: ^2.3.0
    build_runner: ^2.4.0
  ```
  Run: `dart run build_runner watch --delete-conflicting-outputs`
- **Migration not required** - Both approaches coexist in the same codebase

## Testing Strategy

### Unit Tests
- **Flutter**: Write widget tests for all custom components
- **Next.js**: Test utility functions and API routes with Jest
- **Supabase**: Test RLS policies with `SET ROLE` queries

### Integration Tests
- **Critical flows**: Document upload → OCR → categorization
- **Payment flows**: Subscription purchase → webhook → entitlement grant
- **Offline scenarios**: Emergency Hub data availability without network

### Before Production Deployment
- [ ] All RLS policies tested and verified
- [ ] Offline Emergency Hub functionality confirmed
- [ ] Payment webhooks tested in sandbox
- [ ] Analytics events instrumented and validated
- [ ] Error tracking (Sentry) configured
- [ ] Performance monitoring enabled (PostHog)

## Feature-Specific Notes

### Document Vault
- OCR processing via Google Cloud Vision in Edge Function
- Category detection using keyword matching
- Expiration date extraction with regex patterns
- Full-text search on `ocr_text` column using PostgreSQL `to_tsvector`

### Maintenance Calendar
- Climate-based scheduling uses ZIP code → climate zone mapping
- Recurrence patterns stored as JSON: `{ frequency: 'monthly', interval: 6 }`
- Home Health Score calculated from overdue tasks percentage

### Emergency Hub
- **MUST work offline** - uses SQLite with Supabase sync
- High-contrast mode for emergency situations
- Photo compression to max 500KB per image
- One-tap calling for emergency contacts

### Home Value Tracking
- ATTOM API calls cached for 24 hours
- Equity calculation: `currentValue - mortgageBalance`
- Historical tracking stored in `home_value_history` table
- Monthly email notifications for >1% value changes

## Resource Files

For detailed information, refer to:
- [Keystona_TechnicalArchitecture.md](Keystona_TechnicalArchitecture.md) - Complete technical architecture
- [DocumentVault_FeatureSpec.md](DocumentVault_FeatureSpec.md) - Document management feature
- [MaintenanceCalendar_FeatureSpec.md](MaintenanceCalendar_FeatureSpec.md) - Maintenance scheduling
- [EmergencyHub_FeatureSpec.md](EmergencyHub_FeatureSpec.md) - Emergency information (offline-first)
- [HomeValueTracking_FeatureSpec.md](HomeValueTracking_FeatureSpec.md) - Property valuation tracking
- [HomeProfile_FeatureSpec.md](HomeProfile_FeatureSpec.md) - Home profile management
- [Keystona_Agent_Quick_Reference.md](Keystona_Agent_Quick_Reference.md) - Agent usage guide

## Lessons

### Lesson: String.fromEnvironment Only Works at Compile-Time
**Symptom:** Supabase initialization fails with "No host specified in URI /auth/v1/signup?" when using `String.fromEnvironment('SUPABASE_URL')`.

**Root cause:** `String.fromEnvironment()` reads compile-time constants passed via `--dart-define` flags, NOT runtime .env files. Without `--dart-define`, it returns empty strings.

**Prevention:**
- Use `flutter_dotenv` package for runtime environment variables
- Load dotenv BEFORE initializing Supabase in main.dart:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env.development'); // Load FIRST
  await initializeSupabase(); // Then initialize
  runApp(const MyApp());
}
```
- Read values with `dotenv.env['KEY']`
- Never hardcode credentials in source code

### Lesson: Supabase LocalStorage Interface Requirements
**Symptom:** Authentication works but sessions don't persist securely across app restarts.

**Root cause:** Supabase's default storage uses SharedPreferences (unencrypted). Custom storage must implement the `LocalStorage` interface with specific methods.

**Prevention:**
- Always implement custom `LocalStorage` extending Supabase's interface
- Use FlutterSecureStorage for hardware-backed encryption
- Implement all required methods: `initialize()`, `accessToken()`, `persistSession()`, `removePersistedSession()`, `hasAccessToken()`
- Pass custom storage to `FlutterAuthClientOptions`:
```dart
authOptions: FlutterAuthClientOptions(
  authFlowType: AuthFlowType.pkce,
  localStorage: SecureLocalStorage(),
)
```

### Lesson: iOS Build Requires Podfile Generation
**Symptom:** Build error "Module 'app_links' not found" after adding Flutter dependencies.

**Root cause:** New Flutter plugins require iOS Podfile updates. Running `flutter pub get` only updates Dart dependencies, not native iOS CocoaPods.

**Prevention:**
- After adding new dependencies with native code (Supabase, secure storage), run:
```bash
flutter build ios --debug --no-codesign
```
- This automatically runs `pod install` and generates plugin registrant files
- Alternatively, manually run `cd ios && pod install` if only iOS changes are needed

### Lesson: Environment Files Must Be in Assets
**Symptom:** `flutter_dotenv` throws "Unable to load asset: .env.development" at runtime.

**Root cause:** The .env file exists in the project root but isn't declared in `pubspec.yaml` assets section. Flutter doesn't bundle files unless explicitly declared.

**Prevention:**
- Add .env files to assets in pubspec.yaml:
```yaml
flutter:
  assets:
    - .env.development
```
- Create `.env.development.example` (committed to git) as template
- Add `.env.development` to `.gitignore` (contains secrets)
- Verify file is in project root, not subdirectory

### Lesson: Sealed Classes Require Dart 3.0+
**Symptom:** "The 'sealed' modifier can only be used in libraries with language version 3.0 or greater" error.

**Root cause:** Sealed classes are a Dart 3.0+ feature. Project SDK constraint must be `>=3.0.0`.

**Prevention:**
- Ensure `pubspec.yaml` has SDK constraint:
```yaml
environment:
  sdk: ^3.10.4  # Must be 3.0.0 or higher
```
- Sealed classes enable exhaustive pattern matching for type-safe error handling
- Alternative for Dart 2.x: Use abstract classes with factory constructors (but no exhaustiveness checking)

---

## Custom Claude Code Commands

This repository includes custom slash commands in `.claude/skills/`:
- `/compound` - Extract and document patterns, decisions, and lessons from completed work
- `/quick-compound` - Fast learnings extraction for quick iterations
