# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Keystona** is a Flutter mobile app for home management. It helps homeowners organize documents, track maintenance, manage emergencies, and monitor home health through a composite score.

**Stack:** Flutter (mobile) · Supabase (backend) · RevenueCat + Stripe (payments) · Firebase (FCM) · Sentry (errors) · PostHog (analytics)

**Brand:** Keystona — "The smart way to manage your home"
- Deep Navy: #1A2B4A · Gold Accent: #C9A84C · Warm Off-White: #FAF8F5
- Typography: Outfit (headlines) · Plus Jakarta Sans (body)

## Navigation

5 permanent tabs: **Home · Docs · Tasks · Projects · Settings**
Emergency Hub accessible via quick-action button on Home tab (not a tab).

## Development Commands

This repository contains specifications and documentation for Keystona. The actual Flutter/Supabase code will be in a separate repository once foundation work begins.

Current structure:
- `keystona-project-files/` — Complete technical specifications
- `.claude/agents/` — Specialized AI agents for different development tasks
- `.claude/skills/` — Reusable skills for common workflows

## Agents

Use specialized agents for different aspects of development:

| Agent | Use For | File |
|-------|---------|------|
| `flutter-keystona-dev` | Screens, widgets, forms, navigation, UI | `.claude/agents/flutter-keystona-dev.md` |
| `supabase-backend-specialist` | Queries, RLS, Edge Functions, storage, RPCs | `.claude/agents/supabase-backend-specialist.md` |
| `integration-wiring` | Cross-feature wiring, routing, shared state | `.claude/agents/integration-wiring.md` |
| `keystona-qa-specialist` | Tests, verification, security boundary checks | `.claude/agents/keystona-qa-specialist.md` |
| `dashboard-home-builder` | Home tab (complex — 8 states, 7 sections) | `.claude/agents/dashboard-home-builder.md` |

Invoke agents from CLI:
```bash
claude "Build the Document Vault list screen" --agent flutter-keystona-dev
claude "Create the check-overdue-tasks Edge Function" --agent supabase-backend-specialist
claude "Wire up cross-feature navigation" --agent integration-wiring
claude "Write tests for task completion flow" --agent keystona-qa-specialist
claude "Build the Home tab dashboard" --agent dashboard-home-builder
```

## Skills

Use skills for common workflows:

| Skill | Use For |
|-------|---------|
| `plan-and-build` | **Start here for any issue** — plans with look-ahead at dependent issues, then builds |
| `feature-agent` | Build complete features from start to finish (used inside plan-and-build) |
| `flutter-agent` | Flutter/Dart coding with iOS-first adaptive widgets |
| `supabase-agent` | Supabase queries, RLS policies, Edge Functions |
| `migration-writer` | Database migrations with RLS policies |
| `code-review` | Comprehensive code review checklist |
| `compound` | Full learning extraction (patterns, decisions, lessons) |
| `quick-compound` | Fast learning extraction after tasks |

Invoke skills from CLI:
```bash
/feature-agent
/flutter-agent
/supabase-agent
/migration-writer
/code-review
/compound
/quick-compound
```

## Architecture

### Feature Structure
```
lib/features/[feature_name]/
├── models/       # Freezed data classes
├── providers/    # Riverpod AsyncNotifierProvider
├── screens/      # Full page widgets
├── widgets/      # Feature-specific components
└── services/     # Feature business logic (rare)
```

### Key Patterns

**State Management:** Riverpod with AsyncNotifier
- `ref.watch()` in `build()` methods only
- `ref.read()` in event handlers (`onTap`, `onPressed`)
- `autoDispose` for screen-specific providers
- `.select()` to watch specific fields, not entire objects

**Screen Requirements:** Every screen MUST have
- Skeleton loading state (matching content layout)
- Error state with retry
- Empty state matching the **Empty States Catalog** exactly
- Pull-to-refresh (if scrollable list)

**Platform UI:** iOS-first adaptive widgets
- Use Cupertino on iOS, Material on Android
- Use adaptive helpers in `lib/core/widgets/adaptive/`
- Never write platform checks directly
- See Platform UI Guide for complete component matrix

**Database Queries:**
- Always filter by `property_id` first
- Always check `deleted_at IS NULL` for soft-delete tables
- Select only needed columns (never `SELECT *` on lists)
- Use nested selects to avoid N+1 queries
- RLS is the auth layer — all tables have policies

**Performance:**
- Every interaction under 1 second
- All `const` opportunities used
- `CachedNetworkImage` only (never `Image.network`)
- Lists use `.builder()` constructors
- Search is debounced (300ms)

**Security:**
- Never log PII (no names, emails, OCR text, addresses)
- Auth: email + Apple + Google, 7-day sessions, biometric unlock
- Input validation at client AND server
- See Security Guide §8 checklist before every PR

## Documentation Index

Comprehensive specifications in `keystona-project-files/`:

| Document | What It Covers |
|----------|---------------|
| **HomeTrack_SRS.md** | Requirements, design system, non-functional requirements |
| **HomeTrack_Database_Schema.md** | All migrations (001–011), RLS policies, storage buckets |
| **HomeTrack_API_Contract.md** | All endpoints, Edge Functions, rate limits |
| **HomeTrack_Sprint_Plan.md** | Phases 0–9, agent assignments, acceptance criteria |
| **HomeTrack_Platform_UI_Guide.md** | Component matrix, adaptive widgets, iOS patterns |
| **HomeTrack_Performance_Guide.md** | Time budgets, caching, widget optimization |
| **HomeTrack_Error_Handling.md** | Loading, errors, offline, forms, empty states |
| **HomeTrack_Environment_Setup.md** | Dev toolchain, project structure, parallel dev guide |
| **HomeTrack_Dashboard_Spec.md** | Home tab layout, hero, insights, urgent banner, onboarding |
| **HomeTrack_Health_Score_Algorithm.md** | Three-pillar scoring, formulas, worked examples |
| **HomeTrack_Empty_States_Catalog.md** | 25 screen empty states with exact copy and patterns |
| **HomeTrack_Dashboard_States.md** | 8 states, visibility matrix, transitions |
| **HomeTrack_Notification_Priority.md** | P1/P2/P3 tiers, digest, back-off, quiet hours |
| **HomeTrack_Security_Guide.md** | Auth, validation, PII handling, Sentry config, checklist |

## Key Conventions

### Flutter
- iOS-first adaptive widgets (Cupertino on iOS, Material on Android)
- Every screen: skeleton → error → empty → content
- Empty states must match Empty States Catalog exactly
- Performance: under 1 second for all interactions
- `const` everywhere possible

### Supabase
- RLS on every user-data table — this IS the auth layer
- Filter by `property_id` first, check `deleted_at IS NULL`
- Never `SELECT *` on lists, never N+1 queries
- Signed URLs for all file access (never public)
- Edge Functions verify auth token before anything else

### Security
- Never log PII (no names, emails, OCR text, addresses)
- Input validation at client AND server
- Auth: `auth.uid()` in RLS policies, never trust client-supplied `user_id`
- See Security Guide §8 checklist before every PR

## Patterns

<!-- Format:
- **[Pattern Name]**: [Brief description] → See `[file path]`
-->
- **Semantic Color Palette**: All colors in `AppColors` as `abstract final class` constants — no hex values in widgets or theme → `lib/core/theme/app_colors.dart`
- **Pre-built TextStyles as getters**: `AppTextStyles` uses `static TextStyle get` (not `const`) because `GoogleFonts.*` constructs at runtime → `lib/core/theme/app_text_styles.dart`
- **4px Spacing Grid**: All spacing, radii, padding via `AppSizes`, `AppRadius`, `AppPadding` — never hardcoded → `lib/core/theme/app_sizes.dart`
- **Theme references design tokens only**: `app_theme.dart` contains no raw Colors, TextStyles, or numbers — always `AppColors.*`, `AppTextStyles.*`, `AppSizes.*`
- **Barrel Export**: `lib/core/widgets/widgets.dart` re-exports all widgets — features do one import instead of many → `lib/core/widgets/widgets.dart`
- **Static Service Pattern**: Pure logic classes use `abstract final class` with static methods — no instantiation, no state (SnackbarService, PhotoPicker, AppDateUtils, CurrencyFormatter, Validators)
- **Services throw, UI catches**: AuthService/StorageService throw on failure with no UI concerns — callers catch and route to SnackbarService
- **Riverpod providers co-located**: All service providers in `lib/services/providers/service_providers.dart`, not scattered across features
- **AppRoutes constants class**: All route strings as `static const` in `abstract final class AppRoutes` — never hardcode path strings in features → `lib/core/router/app_router.dart`
- **Static routes before param routes**: `/documents/upload` declared before `/documents/:documentId` — prevents static segments being swallowed by param matcher
- **routerProvider watches auth**: `Provider<GoRouter>` watches `isAuthenticatedProvider` — router rebuilds automatically on sign-in/out, redirect fires on every navigation
- **PlaceholderScreen pattern**: Single reusable widget for all unbuilt routes keeps route tree complete without stub files per feature → `lib/core/widgets/placeholder_screen.dart`
- **goBranch with initialLocation**: `goBranch(index, initialLocation: index == currentIndex)` — active tab tap pops to root, other tabs preserve state
- **Auth screens skip AppScaffold**: Landing screens (login, signup) use plain `Scaffold` with no app bar — `AppScaffold` only for sub-screens
- **ConsumerStatefulWidget for forms**: Forms need both Riverpod ref (services) and local state (loading, controllers) → `ConsumerStatefulWidget` is the correct base
- **Loading state on submit button**: Disable button + swap label for `CircularProgressIndicator` during async call — prevents double-submit
- **Confirm password validated against controller**: Validator closes over `_passwordController.text` directly — no cross-field form validator needed
- **Best-effort completion pattern**: `completeOnboarding()` in try/finally — failed metadata write never blocks navigation, user retries via settings
- **Side-by-side fields in Row**: Short fields (State/ZIP, Bedrooms/Bathrooms) use `Row` + `Flexible` — cleaner than full-width for 2-char inputs
- **ValueKey for dropdown auto-fill**: `ValueKey(_value)` on `DropdownButtonFormField` forces rebuild when value is programmatically set from outside
- **AsyncNotifier for DB writes**: Feature data mutations use `AsyncNotifier` + `AsyncValue.guard` — caller inspects state after notifier call completes
- **Router-driven auth navigation**: After sign-in/sign-up never call `context.go()` — remove it and let `routerProvider` redirect automatically when `isAuthenticatedProvider` updates → `lib/core/router/app_router.dart`
- **Onboarding routes in publicRoutes**: Onboarding screens must be in `_publicRoutes` so the auth guard doesn't intercept during the auth-stream update window → `lib/core/router/app_router.dart`
- **Freezed v3 `abstract class` pattern**: Must use `@freezed abstract class Foo with _$Foo` — Freezed v3 generates abstract getters in the mixin so `class` (non-abstract) fails to compile → `lib/features/documents/models/document.dart`
- **`@riverpod` codegen for all feature providers**: Use `@riverpod` annotation + `class FooNotifier extends _$FooNotifier` — codegen generates `fooProvider` and `fooProvider.notifier`; never write manual `AsyncNotifierProvider` → `lib/features/documents/providers/documents_provider.dart`
- **Downstream-annotated model fields**: Every model field used only by a future issue gets a `/// [#N] used for {purpose}` doc comment — guides agents building dependent issues without reading multiple files → `lib/features/documents/models/document.dart`
- **UnimplementedError stubs for downstream provider methods**: `throw UnimplementedError('method() implemented by issue #N')` in provider stubs — agents building dependent issues know exactly which method to fill in and why → `lib/features/documents/providers/documents_provider.dart`
- **Shimmer skeleton matches card layout exactly**: `DocumentListSkeleton` mirrors `DocumentCard` height (80px) and internal layout (48×48 thumb + 3 text lines) — seamless loading→content transition with no layout jump → `lib/features/documents/widgets/document_list_skeleton.dart`
- **`.maybeSingle()` for optional single-row queries**: Returns `null` on 0 rows instead of throwing `PGRST116` — always use for queries where 0 rows is a valid state (e.g. user has no property yet); guard with `if (row == null) return []`

## Decisions

<!-- Format:
- **[Decision]**: Chose [X] over [Y] because [reason]
-->
- **`abstract final class` for design tokens**: Chose over plain `class` because it prevents instantiation and signals pure namespace intent
- **`get` over `const` for TextStyles**: `GoogleFonts.*` returns runtime instances so TextStyle constants must be getters, not `const` fields
- **OfflineBanner self-contained**: Chose `ConsumerWidget` watching `isOnlineProvider` internally over requiring parent to pass state — simplifies every screen
- **`hideCurrentSnackBar()` before showing**: Prevents snackbar stacking when errors fire rapidly
- **`context.go()` for auth transitions**: Auth nav (login→dashboard, signup→onboarding) uses `go()` not `push()` — replaces stack so no back button returns to auth after sign-in
- **`ref.read()` for one-shot service calls**: Auth screen calls `ref.read(authServiceProvider).signIn()` directly — no notifier needed for simple fire-and-forget actions
- **`StatefulShellRoute.indexedStack` over `ShellRoute`**: Preserves scroll/state per tab — `ShellRoute` rebuilds on every tab switch
- **`BottomNavigationBar` over `NavigationBar`**: Material 2 bar matches iOS feel better for MVP — upgrade to `NavigationBar` in polish phase
- **Auth providers separate from router**: Router watches auth providers, doesn't own auth logic — cleaner separation of concerns
- **`StateProvider` from legacy import**: Riverpod v3 moved `StateProvider` to `legacy.dart` — use `NotifierProvider` for all new state going forward
- **`initialValue` over `value` on dropdowns**: `DropdownButtonFormField.value` deprecated in Flutter 3.33+ — always use `initialValue`
- **`completeOnboarding()` as top-level function**: Called from 3 screens with no shared state — top-level async function cleaner than a provider method
- **`String.fromEnvironment` needs `defaultValue` for dev**: No default = empty string at runtime when `--dart-define-from-file` is omitted → always add `defaultValue` for dev credentials in `config.dart`
- **Supabase `external_email_enabled` off by default**: New projects ship with email/password auth disabled — enable via Management API or Dashboard before first run
- **`updateDocument()` not `update()` for provider methods**: `AsyncNotifier` has a built-in `update(T Function(T) fn)` method — feature methods named `update()` silently shadow it causing type errors; use descriptive names like `updateDocument()`, `updateTask()`
- **`SliverToBoxAdapter` over `SliverPersistentHeader` inside `CupertinoPageScaffold`**: Pinned persistent headers conflict with `CupertinoSliverNavigationBar` geometry — use `SliverToBoxAdapter` for filter bars; sticky behavior can be added later via `NestedScrollView`
- **`@riverpod` codegen naming convention**: Codegen generates `fooProvider` (not `fooNotifierProvider`) and `fooProvider.notifier` (not `fooProvider.notifier`) — match these generated names exactly when calling `ref.watch()` / `ref.read()`

## Lessons

<!-- Format:
- **[Issue]**: [What happened] → [How to prevent]
-->
- **`intl` version conflict on pub get**: `form_builder_validators ^10.x` pins `intl ^0.19.0` conflicting with Flutter SDK's `intl 0.20.2` → Run `flutter pub upgrade --major-versions` to resolve all deps to latest compatible versions
- **`TODO(...)` triggers dart lint**: The `todo` lint rule flags `TODO(name):` comments → Use plain `// note:` style for deferred work
- **Riverpod 3.x removed `.valueOrNull`**: Use `.value` directly on `AsyncValue` — `.valueOrNull` no longer exists
- **`StateProvider` requires legacy import in Riverpod v3**: `package:flutter_riverpod/legacy.dart` needed — prefer `NotifierProvider` to avoid this
- **`DropdownButtonFormField.value` deprecated**: Flutter 3.33+ → always use `initialValue`; add `ValueKey` if value is set programmatically
- **`FileOptions` needs explicit import**: Requires `import 'package:supabase_flutter/supabase_flutter.dart'` — not resolved through transitive imports
- **Email regex in single-quoted strings**: Regex containing `'` inside a single-quoted Dart string causes parse errors → Use double-quoted or raw double-quoted strings (`r"..."`)
- **iOS deployment target 13 → 15 required**: `firebase_core` requires minimum iOS 15.0 — bump `Podfile` platform and all `IPHONEOS_DEPLOYMENT_TARGET` entries in `project.pbxproj` before first build
- **`pod install` required on fresh clone**: `flutter run` alone won't install pods on a new machine → run `flutter pub get && cd ios && pod install --repo-update` first
- **Router race condition on auth navigation**: `context.go('/dashboard')` fires before `isAuthenticatedProvider` stream updates — router sees stale `isAuthenticated = false` and redirects back to login → remove manual `context.go` after auth calls, let router self-redirect
- **Supabase `external_email_enabled` off by default**: Must `PATCH /v1/projects/{ref}/config/auth` with `{"external_email_enabled": true}` or toggle in Dashboard → Auth → Providers before email/password auth works
- **CocoaPods specs repo needs update for new Firebase**: `firebase_core` 4.x requires Firebase SDK 12.8.0 — run `pod repo update` if CocoaPods can't find the spec
- **`SliverPersistentHeader(pinned: true)` crashes inside `CupertinoPageScaffold`**: `layoutExtent > paintExtent` geometry error + cascading `!semantics.parentDataDirty` assertion + null check — root cause is `CupertinoSliverNavigationBar` reporting non-standard sliver geometry; replace with `SliverToBoxAdapter`
- **Empty migration files create phantom applied state**: `supabase db push` records migration names in `schema_migrations` even when files are empty — tables are never created; always verify with `execute_sql SELECT table_name FROM information_schema.tables` after applying
- **`handle_new_user` trigger only fires on new signups**: Users who signed up before the `profiles` table existed have no profile row; backfill with `INSERT INTO profiles SELECT id, email, ... FROM auth.users WHERE id NOT IN (SELECT id FROM profiles) ON CONFLICT DO NOTHING` after applying migrations
- **Supabase `.single()` throws `PGRST116` on 0 rows**: Error cascades as an unhandled exception → error state in UI; use `.maybeSingle()` and guard with `if (row == null) return []` for any query where the user may not have data yet (pre-onboarding)
- **Freezed v3 requires `abstract class`**: `@freezed class Foo with _$Foo` fails — Freezed v3 generates abstract property getters in `_$Foo` that the concrete class can't satisfy; always use `@freezed abstract class Foo with _$Foo`

## Philosophy

**Ship complete** — When Keystona launches, all 5 feature pillars will be fully polished and ready for the App Store. No soft launch, no partial feature set.

**Feature-first development** — Work through the Sprint Plan phases in order. Each phase has clear acceptance criteria. Some phases can be parallelized across agents.

**Document everything** — Use `/compound` or `/quick-compound` after completing work to extract learnings, patterns, decisions, and lessons into this CLAUDE.md file.

**Agent-native architecture** — Agents are first-class citizens. Any action a user can take, an agent can take. Anything a user can see, an agent can see.
