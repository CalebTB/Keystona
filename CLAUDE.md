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
- **Capture notifier before async gap**: When a `WidgetRef` is used across an async gap (e.g. after `await picker`), store `ref.read(provider.notifier)` in a local variable before the `await` — the widget may unmount during the gap, invalidating `ref` → `lib/features/documents/widgets/upload_source_sheet.dart`
- **Completer to outlast modal dismissal**: `showCupertinoModalPopup` resolves as soon as the sheet is dismissed, before async picker work completes — use a `Completer<void>` inside `show()` so the method awaits actual picker completion, not just modal close → `lib/features/documents/widgets/upload_source_sheet.dart`
- **`build.yaml` for Supabase snake_case**: `json_serializable` defaults to exact Dart field names (camelCase) but Supabase returns snake_case column names — add `build.yaml` with `field_rename: snake` so generated `fromJson` matches Supabase keys → `apps/keystona/build.yaml`
- **Wizard state as ephemeral Freezed model**: Multi-step wizard state (no JSON persistence needed) uses `@freezed abstract class` without `fromJson`/`toJson` — only needs `.freezed.dart`, no `.g.dart` → `lib/features/documents/models/document_upload_state.dart`
- **Re-run build_runner after cross-worktree merge**: When merging a branch that adds new `@riverpod`/`@freezed` providers into a worktree that predates them, generated `.g.dart` files won't exist — always run `dart run build_runner build --delete-conflicting-outputs` after merging main into a feature branch
- **`_save()` no-param method uses `this.context`**: Calling `_save()` (not `_save(context)`) lets the linter recognize `this.context` as guarded by `mounted` — avoids `use_build_context_synchronously` warning after `await` → `lib/features/maintenance/screens/task_completion_form_screen.dart`
- **`context.pop(value)` to return typed result to caller**: Form screens pop with the created record's ID (`context.pop(completionId)`) — caller uses `context.push<String>(route)` and awaits the typed return; no shared state or callback needed → `lib/features/maintenance/screens/task_completion_form_screen.dart`
- **`Image.file(File(photo.path))` for local picker thumbnails**: Use `dart:io` `File(xFile.path)` + `Image.file()` for locally-picked photos on mobile — `Image.network()` and `Image.memory()` don't apply to local file paths → `lib/features/maintenance/screens/task_completion_form_screen.dart`
- **Conditional spread in form data map**: `if (condition) ...{'key': value}` in a `Map<String, dynamic>` literal — cleaner than `addAll` calls for optional fields that should only be included when non-empty → `lib/features/maintenance/screens/task_completion_form_screen.dart`
- **`static show()` with `WidgetRef ref` parameter**: When a picker sheet needs to watch a Riverpod provider internally, pass `WidgetRef ref` as a named param to `static show()` — the sheet is a `ConsumerStatefulWidget` constructed with the ref's data → `lib/features/maintenance/screens/task_completion_form_screen.dart`
- **`CustomPaint` arc gauge with score-based color**: `_ArcPainter` uses `startAngle = 135°`, `sweepTotal = 270°`; active sweep = `total * (score / 100)`; color selected from `AppColors.healthGood/Fair/Poor` → `lib/features/maintenance/widgets/health_score_widget.dart`
- **`fromRpc()` factory on Freezed model**: RPC responses don't follow the same naming as table rows — use a named `fromRpc(Map<String, dynamic>)` factory instead of `fromJson` to avoid `build.yaml` `field_rename` ambiguity and keep the model free of `.g.dart` → `lib/features/maintenance/models/home_health_score.dart`
- **`empty()` factory as RPC null guard**: When RPC returns null (no property / unauthenticated), `HomeHealthScore.empty()` returns score 100, trend stable, all counts 0 — prevents null propagation into UI → `lib/features/maintenance/models/home_health_score.dart`
- **Keyed family provider for detail screens**: `@riverpod class FooDetailNotifier extends _$FooDetailNotifier` with `build(String id)` — codegen creates `fooDetailProvider(id)` keyed by ID, auto-disposed on pop → `lib/features/documents/providers/document_detail_provider.dart`
- **`static show()` on bottom sheets**: Edit/confirm sheets expose a `static Future<T?> show(BuildContext context, ...)` factory — callers never instantiate the widget directly, keeps call sites clean → `lib/features/documents/widgets/edit_metadata_sheet.dart`
- **`Theme.of(context).platform` for adaptive check**: Use `Theme.of(context).platform == TargetPlatform.iOS` in `ConsumerWidget.build()` for one-off platform branching — avoids importing `dart:io` just for `Platform.isIOS` → `lib/features/documents/screens/document_detail_screen.dart`
- **`ref.invalidateSelf()` + `await future` for post-mutation refresh**: After a write operation, call `ref.invalidateSelf()` then `await future` to block until the provider has re-fetched — detail screen always shows persisted data, never stale optimistic state → `lib/features/documents/providers/document_detail_provider.dart`
- **Debounced search bar as isolated ConsumerStatefulWidget**: Search bar owns its own `Timer` debounce and `TextEditingController` — parent just passes `onChanged(String?)` callback; 300ms debounce prevents rapid re-fetches on every keystroke → `lib/features/documents/widgets/document_search_bar.dart`
- **Adaptive search split into private platform widgets**: `_IOSSearchBar` (CupertinoSearchTextField) and `_AndroidSearchBar` (TextField) are private `StatelessWidget` classes within the same file — keeps the public API clean and isolates platform logic → `lib/features/documents/widgets/document_search_bar.dart`
- **Freemium gate at widget level with PRO badge**: For gated features, show a gold PRO badge inline on the search bar (free tier) and a locked snippet row with UpgradeSheet tap on result cards — gates awareness at point of use, not at navigation → `lib/features/documents/widgets/document_search_bar.dart`, `document_search_result_card.dart`
- **Snippets stored in notifier private map, not in model**: OCR snippets from `ts_headline` are transient search metadata — stored in `Map<String, String> _snippets` on the notifier, cleared on search reset, accessed via `snippetFor(id)` — never pollutes the persistent `Document` model → `lib/features/documents/providers/documents_provider.dart`
- **`isPremiumProvider` stub in service_providers.dart**: Simple `Provider<bool>((ref) => false)` stub that wires premium checks from day 1 — replace body with RevenueCat `CustomerInfo` stream in Phase 8; all widgets are already gating on it → `lib/services/providers/service_providers.dart`
- **`ts_headline` marker stripping**: PostgreSQL `ts_headline` wraps matched terms in `**term**` — strip with `snippet.replaceAll('**', '')` for plain display; preserve raw string if you later want bold highlighting with `TextSpan` parsing → `lib/features/documents/widgets/document_search_result_card.dart`
- **Icon catalog as `abstract final class` with string keys**: Store icon name strings in DB, map to `IconData` in a const Map inside an `abstract final class` — add new icons in one place, fallback via `forKey(key)` static method → `lib/features/documents/widgets/category_form_sheet.dart`
- **Color catalog as `const List<String>` of hex strings**: Preset color options stored as hex strings, parsed to `Color` at render time with `Color(int.parse('FF$clean', radix: 16))` — hex stored in DB, `Color` never persisted → `lib/features/documents/widgets/category_form_sheet.dart`
- **Top-level `showCategoryFormSheet()` function**: Adaptive sheet presenter as a top-level function (not `static show()`) when it needs to branch between `showCupertinoModalPopup` and `showModalBottomSheet` — platform check done once, both sheet types called with the same widget → `lib/features/documents/widgets/category_form_sheet.dart`
- **`isSystem` gate on expansion + tap behavior**: `category.isSystem` used to branch both the expand arrow visibility and tap handler — non-system (custom) categories skip inline expansion entirely and go straight to next step → `lib/features/documents/widgets/upload_category_step.dart`
- **Bulk-update-then-delete for referential integrity**: Before deleting a category, `UPDATE documents SET category_id = fallbackId WHERE category_id = id` — ensures no orphaned documents; RLS on `document_categories` prevents deleting system rows as a secondary guard → `lib/features/documents/providers/document_categories_provider.dart`
- **`sort_order` derived from existing max**: `create()` computes `maxOrder + 1` by folding over `state.value` — new categories always append after existing ones without a separate sequence or trigger → `lib/features/documents/providers/document_categories_provider.dart`
- **`TaskDetail` composite model for detail screens**: A separate `@freezed abstract class` combining the primary model + related list (e.g. `MaintenanceTask` + `List<TaskCompletion>`) assembled in the provider — no `fromJson` since it's never persisted, so omit the `.g.dart` part declaration → `lib/features/maintenance/models/task_detail.dart`
- **Undo snackbar with returned completion ID**: Write methods that create records return the new row's ID (`Future<String> quickCompleteTask()`) — caller captures it before the snackbar, passes it to the undo handler; no need to store ID in state → `lib/features/maintenance/screens/task_detail_screen.dart`
- **`ref.invalidate(sibling) + ref.invalidateSelf()` for cross-provider sync**: After a write in a detail provider, invalidate BOTH the detail provider AND the sibling list provider so the list screen reflects the change without a manual pull-to-refresh → `lib/features/maintenance/providers/task_detail_provider.dart`
- **DATE column serialized as split ISO string**: Supabase DATE columns (no time component) must be sent as `"YYYY-MM-DD"` — use `DateTime.now().toIso8601String().split('T')[0]`; do NOT send a full timestamp or Postgres will reject it → `lib/features/maintenance/providers/task_detail_provider.dart`
- **Status restoration computed at undo time**: `undoQuickComplete` computes the correct restored status (`overdue` vs `scheduled`) from the due date at the moment undo is triggered — avoids storing pre-completion status in a separate field or in widget state → `lib/features/maintenance/providers/task_detail_provider.dart`
- **`typedef PickerOption = ({String id, String name})`**: Dart 3 record typedef for simple id+name picker pairs — avoids a full model class for dropdowns that only need identity + label; defined in the provider file so both provider and screen share the type → `lib/features/maintenance/providers/task_form_providers.dart`
- **Newline-delimited textarea for `List<String>` fields**: Tools/supplies stored as `List<String>` in Supabase (JSONB array) but edited as a multiline `TextFormField` — join with `'\n'` in `initState`, split + trim + filter blanks on save; one line = one item → `lib/features/maintenance/screens/task_form_screen.dart`
- **Generic `_pickEnumIOS<T>()` for all adaptive enum pickers**: A single generic method wraps `CupertinoActionSheet` with `options: List<T>`, `labelOf: T Function(T)`, `onSelected: void Function(T)` — one implementation handles category, recurrence, priority, difficulty, diy_or_pro → `lib/features/maintenance/screens/task_form_screen.dart`
- **iOS FAB via `Stack` + `Positioned` on `CupertinoPageScaffold`**: `CupertinoPageScaffold` has no `floatingActionButton` slot — wrap its body in a `Stack`, add `Positioned(bottom: 16, right: 16, child: FAB)` for iOS; Android uses `Scaffold.floatingActionButton` normally → `lib/features/maintenance/screens/maintenance_screen.dart`
- **`bool get _isEditing => widget.existingTask != null`**: Simple getter in `ConsumerState` to branch create vs edit mode — drives nav bar title, save method (`addTask` vs `updateTask`), and controller pre-population in `initState` → `lib/features/maintenance/screens/task_form_screen.dart`
- **Property ID fetched once in `initState`, stored as nullable field**: Async property lookup runs in `initState`, result stored as `String? _propertyId` — pickers watch `AsyncData([])` when null and switch to real data once the ID resolves; never blocks the first frame → `lib/features/maintenance/screens/task_form_screen.dart`
- **`NoPropertyException` sentinel via typedef**: Private `_NoPropertyException` exported as `typedef NoPropertyException = _NoPropertyException` — screen catches it to show empty state instead of generic error without exposing private symbol across files → `lib/features/home_profile/providers/home_profile_provider.dart`
- **Parallel Supabase queries with `Future.wait`**: Systems + appliances counts fetched concurrently after property row lands — single await for both results; eliminates sequential round-trip latency on overview screens → `lib/features/home_profile/providers/home_profile_provider.dart`
- **Nearing-EOL count in Dart over RPC**: Lightweight system rows (5 columns) fetched and classified in Dart using `(ageYears / avgLifespan) >= 0.75` — avoids an extra RPC, uses same formula as #48 lifespan screen so counts always agree → `lib/features/home_profile/providers/home_profile_provider.dart`

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
- **Two-client Edge Function pattern**: Create one admin client (`SUPABASE_SERVICE_ROLE_KEY`) for DB reads/writes, but use `supabase.auth.getUser(token)` on that client to verify JWT first — never trust client-supplied `user_id`; always derive identity from the verified token
- **Seasonal due date for template tasks**: Compute due date as `{target_month}-01` of current or next year — use template's `default_month` if set, else season midpoint (spring=4, summer=7, fall=10, winter=12); roll to next year only if `target_month < currentMonth`
- **`SliverToBoxAdapter` over `SliverPersistentHeader` inside `CupertinoPageScaffold`**: Pinned persistent headers conflict with `CupertinoSliverNavigationBar` geometry — use `SliverToBoxAdapter` for filter bars; sticky behavior can be added later via `NestedScrollView`
- **Back arrow only on wizard steps with a prior wizard page**: First step of a multi-step flow has no meaningful prior page — show Cancel only; back arrow only on steps 2+ where it navigates within the flow
- **`@riverpod` codegen naming convention**: Codegen generates `fooProvider` (not `fooNotifierProvider`) and `fooProvider.notifier` (not `fooProvider.notifier`) — match these generated names exactly when calling `ref.watch()` / `ref.read()`
- **Freemium tier branching inside `_performSearch`**: `ref.read(isPremiumProvider)` inside the private search helper selects the RPC (premium) vs ILIKE (free) path — a single `setSearchQuery()` entry point delegates to the right backend transparently → `lib/features/documents/providers/documents_provider.dart`
- **Shared `_FormBody` between iOS and Android sheet variants**: Platform-specific sheet wrappers (`_IOSSheet`, `_AndroidSheet`) both render the same `_FormBody` private widget — platform differences (header style, save button position) isolated to the wrapper, not the form fields → `lib/features/documents/widgets/category_form_sheet.dart`
- **Single icon catalog via `CategoryIcons.forKey()`**: All icon-string → `IconData` lookups go through one map; no widget owns a local switch — add new keys to `CategoryIcons.all` and call `forKey()` everywhere → `lib/features/documents/widgets/category_form_sheet.dart`
- **`quickCompleteTask()` returns ID over void**: Chose `Future<String>` (returns completion ID) over `Future<void>` so callers can pass it to the undo handler in the same interaction without any extra state — makes the method non-fire-and-forget but enables robust undo
- **Composite detail model over fat primary model**: Chose separate `TaskDetail(task, completions)` over adding `completions` to `MaintenanceTask` — keeps the list model lean (no list-screen N+1), detail model assembled only when the detail screen opens
- **`PickerOption` record typedef over a model class**: Chose `typedef PickerOption = ({String id, String name})` over a named class for picker pairs — zero overhead, self-documenting, no file needed; sufficient when the data never leaves the form
- **Newline textarea over chip-add-remove for list fields**: Chose multiline textarea for tools/supplies over a chip UI — simpler implementation, works for short lists, avoids managing an `ObservableList` in state; join on init, split on save
- **TypeScript climate-zone filter over SQL array filter**: Fetched all templates then filtered in-process rather than using Supabase SDK `.or()` on a SMALLINT[] column — the `NULL = all zones` semantic is cleaner to express in TypeScript than in the SDK's filter API
- **`Deno.serve()` over `serve()` import in Edge Functions**: Modern Deno API doesn't require importing from `deno.land/std` — no version pinning needed in deno.json, cleaner boilerplate
- **`context.push<String>()` typed return over callback/shared state**: Chose typed push/pop to relay the completion ID from form back to detail screen — cleaner than a provider field or a callback closure; works naturally with GoRouter's `push` return value
- **Error state silently hides score widget**: Chose `SizedBox.shrink()` on score widget error over an error card — score is a non-critical enhancement; a broken RPC call shouldn't disrupt the task list below it
- **`SECURITY DEFINER` RPC with immediate ownership check**: RPC runs with elevated privileges but verifies `properties.user_id = auth.uid()` before any data read — client-supplied `p_property_id` validated against authenticated session, not trusted directly
- **`due_date < CURRENT_DATE AND NOT IN (completed, skipped)` over `status = 'overdue'` in RPCs**: Task status column lags behind reality (updated by background job) — using the date directly is always accurate and matches what Flutter displays; prefer date-based predicates in aggregate RPCs over status-based ones for time-sensitive classifications
- **`/home` as tab root, not `/dashboard`**: Chose to remove the `/dashboard` placeholder and make `/home` the branch's first route and `initialLocation` — a separate `/dashboard` constant is unnecessary coupling; the Home tab IS the home screen

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
- **`showCupertinoModalPopup` requires `rootNavigator: true` to dismiss**: Modal is pushed onto root navigator; `Navigator.of(context).pop()` resolves to GoRouter's inner navigator, empties its stack and crashes with "no pages left to show" → always dismiss with `Navigator.of(context, rootNavigator: true).pop()`
- **Freezed v3 requires `abstract class`**: `@freezed class Foo with _$Foo` fails — Freezed v3 generates abstract property getters in `_$Foo` that the concrete class can't satisfy; always use `@freezed abstract class Foo with _$Foo`
- **`WidgetRef` invalid after modal dismissal + async**: Tapping an action in `CupertinoActionSheet` calls `.pop()` (dismisses sheet) then awaits an async picker — by the time the picker returns the sheet widget is unmounted and `ref` throws "Used Ref after disposed" → capture `ref.read(provider.notifier)` before the `.pop()` call
- **`showCupertinoModalPopup` resolves on dismiss, not on picker completion**: Sheet close and picker return are independent async events — `show()` returns before the picker completes, causing `filePicked == false` check to pop the parent screen → wrap the full picker flow in a `Completer` and await it after `showCupertinoModalPopup`
- **`json_serializable` camelCase vs Supabase snake_case**: All Freezed models generated without `build.yaml` will have camelCase JSON keys — every `fromJson` call against raw Supabase data silently returns nulls for multi-word fields, causing `TypeError: null is not X` on required fields → always add `build.yaml` with `field_rename: snake` before running `build_runner` for any project that reads from Supabase
- **Dev testing requires seeded property**: Upload and document queries resolve `property_id` first — if the test user has no property row the upload throws "No property found" and shows generic error → seed a property row for test users via `INSERT INTO properties (...)` in Supabase dashboard before testing document features
- **Nested select must include all required model fields**: `type:document_types(id, name)` missing `category_id` and `sort_order` caused `TypeError: null is not String/int` inside `DocumentType.fromJson` — always check every `required` field in the target model against the nested select column list before shipping
- **`pdfx` for in-app PDF rendering, `photo_view` for image zoom**: Standard packages for document preview in Keystona — `pdfx: ^2.9.2` handles PDF pages + pinch-to-zoom; `photo_view: ^0.15.0` handles image zoom → `apps/keystona/pubspec.yaml`
- **Rebase conflict between sequential worktrees on shared provider**: #22 and #23 both modified `documents_provider.dart` — #22 added CRUD methods, #23 implemented `setSearchQuery` + `_performSearch`; resolution keeps main's `add()` implementation + the new feature branch's additions; always read both sides carefully before accepting either → `lib/features/documents/providers/documents_provider.dart`
- **`TextField` inside `showCupertinoModalPopup` crashes with "No Material widget found"**: `showCupertinoModalPopup` provides only a Cupertino widget tree — Material widgets like `TextField` assert at build time if there's no `Material` ancestor → wrap the sheet root in `Material(type: MaterialType.transparency)` to provide the ancestor without any visual change
- **Missing Supabase migration = provider stuck in loading forever**: A missing table causes PostgREST to return an error that AsyncNotifier never surfaces clearly — screen stays on skeleton; always apply migrations for each new phase before testing → verify with `execute_sql SELECT table_name FROM information_schema.tables` after each migration batch
- **Apply migrations in dependency order**: `maintenance_tasks` references `systems` and `appliances` — Migration 006 will fail if Migration 005 hasn't been applied first; always apply migrations sequentially (005 → 006 → 007...)
- **`showCupertinoModalPopup` content overflows without height constraint**: The popup gives its child unconstrained vertical space — a `Column` with `mainAxisSize: MainAxisSize.min` inside still overflows if content is tall; wrap content in `ConstrainedBox(maxHeight: MediaQuery.of(context).size.height * 0.85)` + `SingleChildScrollView` → `lib/features/documents/widgets/category_form_sheet.dart`
- **Expand arrow on custom categories implies subcategories**: All category tiles showing `keyboard_arrow_down` made users expect custom categories to expand into subtypes — gate the arrow and expansion on `category.isSystem`; custom categories should tap-to-select immediately → `lib/features/documents/widgets/upload_category_step.dart`
- **`Navigator.of(context, rootNavigator: true)` bypasses GoRouter on regular routes**: Only valid inside `showCupertinoModalPopup` — on GoRouter page routes it resolves to the root navigator which has nothing to pop and silently does nothing; always use `context.pop()` for GoRouter navigation → `lib/features/documents/screens/document_upload_screen.dart`
- **`CupertinoPageScaffold` nav bar overlaps its child at y=0**: The `child` starts at the top of the screen, not below the nav bar — wrap content in `SafeArea(bottom: false)` to push it below the nav bar; without this, the first widget in a `CustomScrollView` renders behind the nav bar → `lib/features/documents/screens/document_detail_screen.dart`
- **Duplicate icon switches silently diverge from DB values**: Multiple files each owning a local icon switch with semantic keys (`'insurance'`) that don't match DB values (`'shield'`) causes silent folder-icon fallback everywhere — consolidate to one catalog (`CategoryIcons.forKey()`) and verify keys against DB before shipping
- **`if (!mounted) return` after every async gap in State**: In `ConsumerStatefulWidget` (or `StatefulWidget`) methods, always check `if (!mounted) return` after any `await` before calling `setState`, `ScaffoldMessenger`, or `context.push` — widget may have been disposed during the async gap
- **Merge conflict resolution in worktrees requires build_runner re-run**: When resolving a merge conflict that introduced new Freezed models or Riverpod providers, the generated `.freezed.dart`/`.g.dart` files are stale or missing — always run `dart run build_runner build --delete-conflicting-outputs` after finishing conflict resolution before re-running quality gate
- **DATE vs TIMESTAMP Supabase columns**: Sending a full ISO timestamp to a Postgres DATE column is silently truncated or rejected depending on the client — always check column type before inserting date values; use `split('T')[0]` for DATE, full ISO string for TIMESTAMP
- **`String? _propertyId` must be nullable in form `initState`**: Property ID is fetched async in `initState` and stored as a field — accessing it before the fetch completes returns null; always guard provider watches with `if (_propertyId != null)` or use `AsyncData([])` as the fallback → `lib/features/maintenance/screens/task_form_screen.dart`
- **Parallel worktrees touching shared files need conflict resolution + build_runner**: Both #32 and #34 modified `maintenance_task.dart`, `maintenance_tasks_provider.dart`, and `app_router.dart` — conflict resolution must be done carefully (keep all additive changes from both sides), then `build_runner` must be re-run before the quality gate passes
- **MCP-deployed work produces no local git diff**: Supabase migrations and Edge Functions deployed via MCP tools (`apply_migration`, `deploy_edge_function`) are applied directly to the cloud — the working tree stays clean; commit local SQL/TS files separately if repo tracking is needed
- **`task_difficulty` enum uses `'involved'` not `'professional'`**: The `diy_or_pro` column uses `'professional'`; the `difficulty` column uses `'involved'` for the hardest self-serviceable difficulty — two different enums; mixing them causes a silent insert error
- **Verify template count with SQL after seeding**: Always run `SELECT COUNT(*) FROM {table}` after applying a seed migration — confirms all rows landed (easy to miss truncation from multi-statement inserts)
- **Edge Function `verify_jwt: true` is a gateway-level guard**: Setting `verify_jwt: true` on deploy causes the Supabase gateway to reject requests with no/invalid JWT before function code runs — the function's own `auth.getUser()` check is defense-in-depth, not the primary gate
- **`functions.invoke()` requires explicit `Authorization` header in supabase_flutter v2**: The SDK does not reliably auto-attach the user's JWT — always pass `headers: {'Authorization': 'Bearer ${session.accessToken}'}` explicitly; guard with `final session = client.auth.currentSession; if (session == null) return;` first → `lib/features/maintenance/screens/maintenance_screen.dart`
- **Edge Function `verify_jwt: true` gateway may reject valid Flutter JWTs**: If the JWT is consistently rejected even after `refreshSession()`, the gateway JWT secret may not match the project config — bypass by implementing the same logic as a provider method using the standard DB client, which handles auth automatically; Edge Function can be re-enabled for production once the project JWT config is confirmed → `lib/features/maintenance/providers/maintenance_tasks_provider.dart`
- **`(_, __)` triggers `unnecessary_underscores` lint in Dart 3**: Multiple wildcard underscores in callbacks (`(_, __)`) are flagged by the analyzer — use `(_, _)` instead; Dart 3 allows repeated `_` wildcards for multi-arg discards
- **RPC aggregate queries must mirror Flutter client classification logic**: If Flutter classifies a task as overdue by `due_date < today`, the SQL must use the same predicate — `status = 'overdue'` alone misses tasks whose status column hasn't been flipped by the background updater yet; always cross-check SQL aggregation logic against the Flutter display code that determines what the user sees
- **`GoRouter initialLocation` must match an existing route**: Removing a route without updating `initialLocation` causes "GoException: no routes for location" on cold start — always update `initialLocation`, root redirect (`/`), auth redirect, and all `context.go()` call sites together when retiring a route
- **`StatefulShellBranch` first route = tab default**: The first `GoRoute` in a `StatefulShellBranch.routes` list is the branch's initial location — adding a placeholder as the first route means tapping the tab never shows the real screen; always put the primary screen first
- **Supabase `systems` table requires `category` enum column**: `system_type` is free text; `category` is a NOT NULL `system_category` enum — seeding without `category` fails silently on the error path; always check `is_nullable = 'NO'` columns before seeding

## Philosophy

**Ship complete** — When Keystona launches, all 5 feature pillars will be fully polished and ready for the App Store. No soft launch, no partial feature set.

**Feature-first development** — Work through the Sprint Plan phases in order. Each phase has clear acceptance criteria. Some phases can be parallelized across agents.

**Document everything** — Use `/compound` or `/quick-compound` after completing work to extract learnings, patterns, decisions, and lessons into this CLAUDE.md file.

**Agent-native architecture** — Agents are first-class citizens. Any action a user can take, an agent can take. Anything a user can see, an agent can see.
