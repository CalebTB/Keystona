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
- **Static Service Pattern**: Pure logic classes use `abstract final class` with static methods — no instantiation, no state (SnackbarService, PhotoPicker, AppDateUtils, CurrencyFormatter, Validators)
- **Services throw, UI catches**: AuthService/StorageService throw on failure with no UI concerns — callers catch and route to SnackbarService
- **Riverpod providers co-located**: All service providers in `lib/services/providers/service_providers.dart`, not scattered across features
- **AppRoutes constants class**: All route strings as `static const` in `abstract final class AppRoutes` — never hardcode path strings in features → `lib/core/router/app_router.dart`
- **Static routes before param routes**: `/documents/upload` declared before `/documents/:documentId` — prevents static segments being swallowed by param matcher
- **routerProvider watches auth**: `Provider<GoRouter>` watches `isAuthenticatedProvider` — router rebuilds automatically on sign-in/out, redirect fires on every navigation
- **PlaceholderScreen pattern**: Single reusable widget for all unbuilt routes keeps route tree complete without stub files per feature → `lib/core/widgets/placeholder_screen.dart`
- **goBranch with initialLocation**: `goBranch(index, initialLocation: index == currentIndex)` — active tab tap pops to root, other tabs preserve state
- **ConsumerStatefulWidget for forms**: Forms need both Riverpod ref (services) and local state (loading, controllers) → `ConsumerStatefulWidget` is the correct base
- **Loading state on submit button**: Disable button + swap label for `CircularProgressIndicator` during async call — prevents double-submit
- **AsyncNotifier for DB writes**: Feature data mutations use `AsyncNotifier` + `AsyncValue.guard` — caller inspects state after notifier call completes
- **Router-driven auth navigation**: After sign-in/sign-up never call `context.go()` — let `routerProvider` redirect automatically when `isAuthenticatedProvider` updates → `lib/core/router/app_router.dart`
- **Onboarding routes in publicRoutes**: Onboarding screens must be in `_publicRoutes` so the auth guard doesn't intercept during the auth-stream update window → `lib/core/router/app_router.dart`
- **Freezed v3 `abstract class` pattern**: Must use `@freezed abstract class Foo with _$Foo` — Freezed v3 generates abstract getters in the mixin so `class` (non-abstract) fails to compile → `lib/features/documents/models/document.dart`
- **`@riverpod` codegen for all feature providers**: Use `@riverpod` annotation + `class FooNotifier extends _$FooNotifier` — codegen generates `fooProvider` and `fooProvider.notifier`; never write manual `AsyncNotifierProvider` → `lib/features/documents/providers/documents_provider.dart`
- **Downstream-annotated model fields**: Every model field used only by a future issue gets a `/// [#N] used for {purpose}` doc comment — guides agents building dependent issues without reading multiple files → `lib/features/documents/models/document.dart`
- **UnimplementedError stubs for downstream provider methods**: `throw UnimplementedError('method() implemented by issue #N')` in provider stubs — agents know exactly which method to fill in and why → `lib/features/documents/providers/documents_provider.dart`
- **Shimmer skeleton matches card layout exactly**: Skeleton mirrors card height and internal layout — seamless loading→content transition with no layout jump → `lib/features/documents/widgets/document_list_skeleton.dart`
- **`.maybeSingle()` for optional single-row queries**: Returns `null` on 0 rows instead of throwing `PGRST116` — always use for queries where 0 rows is valid (e.g. user has no property yet); guard with `if (row == null) return []`
- **Capture notifier before async gap**: Store `ref.read(provider.notifier)` in a local variable before any `await` — the widget may unmount during the gap, invalidating `ref` → `lib/features/documents/widgets/upload_source_sheet.dart`
- **Completer to outlast modal dismissal**: `showCupertinoModalPopup` resolves on sheet dismiss, before async picker completes — use a `Completer<void>` inside `show()` so the method awaits actual picker completion → `lib/features/documents/widgets/upload_source_sheet.dart`
- **`build.yaml` for Supabase snake_case**: `json_serializable` defaults to camelCase but Supabase returns snake_case — add `build.yaml` with `field_rename: snake` so generated `fromJson` matches Supabase keys → `apps/keystona/build.yaml`
- **Wizard state as ephemeral Freezed model**: Multi-step wizard state uses `@freezed abstract class` without `fromJson`/`toJson` — only needs `.freezed.dart`, no `.g.dart` → `lib/features/documents/models/document_upload_state.dart`
- **Re-run build_runner after cross-worktree merge**: Merging a branch with new `@riverpod`/`@freezed` files means `.g.dart` files won't exist in the target worktree — always run `dart run build_runner build --delete-conflicting-outputs` after merging main into a feature branch
- **`_save()` no-param method uses `this.context`**: Avoids `use_build_context_synchronously` warning after `await` — linter recognizes `this.context` as guarded by `mounted` → `lib/features/maintenance/screens/task_completion_form_screen.dart`
- **`context.pop(value)` to return typed result to caller**: Form screens pop with the created record's ID — caller uses `context.push<String>(route)`; no shared state or callback needed → `lib/features/maintenance/screens/task_completion_form_screen.dart`
- **`Image.file(File(photo.path))` for local picker thumbnails**: Use `dart:io` `File(xFile.path)` + `Image.file()` for locally-picked photos — `Image.network()` and `Image.memory()` don't apply to local file paths → `lib/features/maintenance/screens/task_completion_form_screen.dart`
- **Conditional spread in form data map**: `if (condition) ...{'key': value}` in a `Map<String, dynamic>` literal — cleaner than `addAll` for optional fields → `lib/features/maintenance/screens/task_completion_form_screen.dart`
- **`static show()` with `WidgetRef ref` parameter**: When a picker sheet needs to watch a Riverpod provider internally, pass `WidgetRef ref` as a named param to `static show()` → `lib/features/maintenance/screens/task_completion_form_screen.dart`
- **`CustomPaint` arc gauge with score-based color**: `_ArcPainter` uses `startAngle = 135°`, `sweepTotal = 270°`; active sweep = `total * (score / 100)`; color from `AppColors.healthGood/Fair/Poor` → `lib/features/maintenance/widgets/health_score_widget.dart`
- **`fromRpc()` factory on plain model**: RPC responses use a named `fromRpc(Map<String, dynamic>)` factory — avoids `build.yaml` `field_rename` ambiguity; model stays free of `.g.dart` → `lib/features/maintenance/models/home_health_score.dart`
- **`empty()` factory as RPC null guard**: When RPC returns null, `Model.empty()` returns safe defaults — prevents null propagation into UI → `lib/features/maintenance/models/home_health_score.dart`
- **Keyed family provider for detail screens**: `@riverpod class FooDetailNotifier extends _$FooDetailNotifier` with `build(String id)` — generates `fooDetailProvider(id)` keyed by ID, auto-disposed on pop → `lib/features/documents/providers/document_detail_provider.dart`
- **`static show()` on bottom sheets**: Edit/confirm sheets expose `static Future<T?> show(BuildContext context, ...)` — callers never instantiate the widget directly → `lib/features/documents/widgets/edit_metadata_sheet.dart`
- **`Theme.of(context).platform` for adaptive check**: `Theme.of(context).platform == TargetPlatform.iOS` — avoids importing `dart:io` just for `Platform.isIOS` → `lib/features/documents/screens/document_detail_screen.dart`
- **`ref.invalidateSelf()` + `await future` for post-mutation refresh**: After a write, call `ref.invalidateSelf()` then `await future` — blocks until re-fetched, detail screen shows persisted data not stale state → `lib/features/documents/providers/document_detail_provider.dart`
- **Debounced search bar as isolated ConsumerStatefulWidget**: Search bar owns its own `Timer` debounce + `TextEditingController` — parent passes `onChanged(String?)`; 300ms debounce → `lib/features/documents/widgets/document_search_bar.dart`
- **Adaptive search split into private platform widgets**: `_IOSSearchBar` / `_AndroidSearchBar` are private `StatelessWidget` classes in the same file — isolates platform logic from public API → `lib/features/documents/widgets/document_search_bar.dart`
- **Freemium gate at widget level with PRO badge**: Show gold PRO badge inline on gated features — gates awareness at point of use, not at navigation → `lib/features/documents/widgets/document_search_bar.dart`
- **`isPremiumProvider` stub in service_providers.dart**: `Provider<bool>((ref) => false)` — replace with RevenueCat stream in Phase 8; all widgets already gate on it → `lib/services/providers/service_providers.dart`
- **Icon catalog as `abstract final class` with string keys**: Store icon name strings in DB, map to `IconData` in a const Map — add new icons in one place, fallback via `forKey(key)` → `lib/features/documents/widgets/category_form_sheet.dart`
- **Color catalog as `const List<String>` of hex strings**: Preset color options stored as hex strings, parsed to `Color` at render time — hex stored in DB, `Color` never persisted → `lib/features/documents/widgets/category_form_sheet.dart`
- **Top-level `showCategoryFormSheet()` function**: Use a top-level function (not `static show()`) when the presenter needs to branch between `showCupertinoModalPopup` and `showModalBottomSheet` → `lib/features/documents/widgets/category_form_sheet.dart`
- **`TaskDetail` composite model for detail screens**: Separate `@freezed abstract class` combining primary model + related list — no `fromJson` since never persisted; omit `.g.dart` part declaration → `lib/features/maintenance/models/task_detail.dart`
- **Undo snackbar with returned record ID**: Write methods return the new row's ID (`Future<String>`) — caller captures it before the snackbar, passes to undo handler; no state needed → `lib/features/maintenance/screens/task_detail_screen.dart`
- **`ref.invalidate(sibling) + ref.invalidateSelf()` for cross-provider sync**: After a write in a detail provider, invalidate BOTH detail + sibling list so list screen reflects the change without pull-to-refresh → `lib/features/maintenance/providers/task_detail_provider.dart`
- **DATE column serialized as split ISO string**: Supabase DATE columns require `"YYYY-MM-DD"` — use `DateTime.now().toIso8601String().split('T')[0]`; full timestamp is rejected → `lib/features/maintenance/providers/task_detail_provider.dart`
- **`typedef PickerOption = ({String id, String name})`**: Dart 3 record typedef for id+name picker pairs — no model class needed when data never leaves the form → `lib/features/maintenance/providers/task_form_providers.dart`
- **Newline-delimited textarea for `List<String>` fields**: JSONB array edited as multiline `TextFormField` — join with `'\n'` in `initState`, split + trim + filter blanks on save → `lib/features/maintenance/screens/task_form_screen.dart`
- **Generic `_pickEnumIOS<T>()` for all adaptive enum pickers**: Single generic method wraps `CupertinoActionSheet` with `options`, `labelOf`, `onSelected` — one implementation handles all enum pickers → `lib/features/maintenance/screens/task_form_screen.dart`
- **iOS FAB via `Stack` + `Positioned` on `CupertinoPageScaffold`**: `CupertinoPageScaffold` has no `floatingActionButton` slot — `Stack + Positioned(bottom: 16, right: 16)` for iOS; `Scaffold.floatingActionButton` for Android → `lib/features/maintenance/screens/maintenance_screen.dart`
- **`bool get _isEditing => widget.existingTask != null`**: Simple getter in `ConsumerState` to branch create vs edit mode — drives title, save method, and controller pre-population in `initState` → `lib/features/maintenance/screens/task_form_screen.dart`
- **Property ID fetched once in `initState`, stored as nullable field**: Async property lookup stored as `String? _propertyId` — pickers use `AsyncData([])` when null and switch to real data once resolved; never blocks the first frame → `lib/features/maintenance/screens/task_form_screen.dart`
- **`NoPropertyException` sentinel via typedef**: Private exception exported via `typedef` — screen catches the public alias without coupling to the private symbol → `lib/features/home_profile/providers/home_profile_provider.dart`
- **Parallel Supabase queries with `Future.wait`**: Independent data fetches run concurrently — single await for all results; total latency = slowest query, not sum → `lib/features/home_profile/providers/home_profile_provider.dart`
- **Nearing-EOL count in Dart over RPC**: Classify lightweight rows in Dart using `(ageYears / avgLifespan) >= 0.75` — avoids extra RPC, uses same formula as lifespan screen → `lib/features/home_profile/providers/home_profile_provider.dart`
- **`FractionallySizedBox` for proportional skeleton bars**: Use inside `Expanded` for percentage-width shimmer bars — `LayoutBuilder` crashes inside `SliverFillRemaining(hasScrollBody: false)` → `lib/features/home_profile/widgets/home_profile_skeleton.dart`
- **Extension methods on `String` for enum display labels**: `extension FooLabel on String` — label lookup works on any raw DB value without a Dart enum or widget-local switch → `lib/features/emergency/models/utility_shutoff.dart`
- **Plain class for composite overview models**: Non-persisted multi-source models use a plain Dart `class const` constructor — never Freezed; assembled in-memory from parallel queries → `lib/features/emergency/models/emergency_hub_overview.dart`
- **Quick-action button for non-tab pushed screens**: Non-tab screens need an explicit entry point on an existing tab — always verify a new pushed-route screen has a reachable button before closing the issue → `lib/features/home_profile/screens/home_profile_screen.dart`
- **`showDocumentLinkPicker()` returning typed record**: Cross-feature picker as a top-level function returning `({String id, String name})?` — caller gets both ID and display name without a secondary lookup → `lib/features/emergency/widgets/document_link_picker.dart`
- **`Flexible(child: ListView.separated(shrinkWrap: true))` inside modal Column**: Lets a list in a constrained modal take remaining space and scroll — `Flexible` shrinks with few items, `shrinkWrap: true` prevents unconstrained height → `lib/features/emergency/widgets/document_link_picker.dart`
- **Computed display getters on plain RPC model**: RPC result models carry UI logic as instance getters (`healthColor`, `healthLabel`, `barFraction`) — single source of truth for data + display → `lib/features/home_profile/models/system_lifespan_entry.dart`
- **Fixed-width `Container`s for bare skeleton bars in `Row`**: Use `Container(width: N)` for shimmer bars not inside `Expanded` — `FractionallySizedBox` requires finite parent width and crashes in unconstrained `Row` → `lib/features/home_profile/widgets/lifespan_skeleton.dart`
- **Pattern B Showcase empty state with ghosted example cards**: Two example cards at `Opacity(opacity: 0.5)` — non-interactive; CTA below; use when examples are more compelling than a plain illustration → `lib/features/projects/widgets/project_empty_state.dart`
- **`String? _activeFilter` with toggle-to-clear filter chips**: `null` = show all; tapping active chip calls `onFilterChanged(null)`, inactive calls `onFilterChanged(s.value)` — driven from `ConsumerStatefulWidget` state → `lib/features/projects/screens/projects_screen.dart`
- **Budget progress bar with overflow color**: `value: (spent / estimated).clamp(0.0, 1.0)`; color switches to `AppColors.error` at `pct >= 1.0` on both bar and label — over-budget alert without separate state → `lib/features/projects/widgets/project_card.dart`
- **`ProjectStatusTransitions` allowlist class**: `static const Map<String, List<String>> allowed` maps current status → permitted next statuses; UI only offers valid transitions; `nextFor()` method handles unknown current status gracefully → `lib/features/projects/models/project.dart`
- **Cover photo upload after create (two-step)**: In create mode, insert row first to get project ID, then upload photo using ID as path segment; update row with `cover_photo_path`; avoids needing a pre-generated ID and keeps photo path scoped to the project → `lib/features/projects/screens/project_form_screen.dart`
- **`null`-aware map entry operator `?`**: Dart 3 syntax `'key': ?value` omits the map entry when value is null — replaces `if (value != null) 'key': value` in map literals; cleaner for optional Supabase insert/update fields
- **Join table model with denormalized display fields**: Carry display fields from the related entity (`contactName`, `contactPhone`) alongside join-table fields in one Freezed model — avoids a secondary lookup at display time; populated via nested select in the provider → `lib/features/projects/models/project_contractor.dart`
- **`_fromRow()` private factory on the notifier**: When a nested select returns JSON that doesn't map directly to Freezed `fromJson`, add a private `_fromRow(Map<String, dynamic> row)` method on the notifier to manually extract and flatten fields — cleaner than patching `fromJson` → `lib/features/projects/providers/project_contractors_provider.dart`
- **`createAndLink()` two-step insert for join tables**: Insert primary entity first to get its ID, then insert the join row with both IDs — sequential awaits give clear error propagation and the call site sees a single atomic method → `lib/features/projects/providers/project_contractors_provider.dart`
- **`abstract final class` catalog with color records for type badges**: Store per-type badge colors as `({Color background, Color foreground})` records returned from a `switch` in the catalog — single source of truth for label + color; call `PhotoTypes.colorFor(type)` in any widget → `lib/features/projects/models/project_photo.dart`
- **`ClipRect + Align(widthFactor:)` for draggable before/after divider**: Layer the after photo as a base, then `ClipRect(child: Align(widthFactor: _divider, child: SizedBox(width: fullWidth, child: beforePhoto)))` reveals before proportionally — no custom painter needed; `GestureDetector` on a `Positioned` 40px hit area updates `_divider` via `onHorizontalDragUpdate` → `lib/features/projects/screens/photo_comparison_screen.dart`
- **Signed-URL list fetched in one `Future.wait` parallel batch**: After fetching rows, call `Future.wait(rows.map(r => storage.getSignedUrl(...)))` — one `await` for all N URLs; total latency = slowest single call → `lib/features/projects/providers/project_photos_provider.dart`
- **`uploadPhoto` returns new photo ID for immediate auto-pairing**: Provider method returns `Future<String>` (the inserted row's ID) — caller captures it and immediately calls `pairPhotos(beforeId, newId)` without any secondary query → `lib/features/projects/providers/project_photos_provider.dart`
- **Mode-toggle chip pair for link-existing vs create-new in a form sheet**: `_ModeChip` widgets switch `_isCreatingNew` bool — "Link existing" shows an inline scrollable contact list loaded in `initState`; "Create new" shows name/phone fields; shared join-table fields (`_buildJoinFields()`) render in both paths → `lib/features/projects/widgets/contractor_form_sheet.dart`
- **Inline contact picker via `getContactsForPicker()` on a cross-feature notifier**: Form sheet calls `ref.read(emergencyHubProvider.notifier).getContactsForPicker()` in `initState` — re-uses existing auth + property resolution, no duplicate query, already stubbed by the Emergency Hub issue for downstream use → `lib/features/projects/widgets/contractor_form_sheet.dart`

## Decisions

<!-- Format:
- **[Decision]**: Chose [X] over [Y] because [reason]
-->
- **`abstract final class` for design tokens**: Chose over plain `class` — prevents instantiation, signals pure namespace intent
- **`get` over `const` for TextStyles**: `GoogleFonts.*` returns runtime instances — TextStyle constants must be getters, not `const` fields
- **`context.go()` for auth transitions**: Auth nav uses `go()` not `push()` — replaces stack so no back button returns to auth after sign-in
- **`ref.read()` for one-shot service calls**: Fire-and-forget service calls don't need a notifier — call `ref.read(service).method()` directly
- **`StatefulShellRoute.indexedStack` over `ShellRoute`**: Preserves scroll/state per tab — `ShellRoute` rebuilds on every tab switch
- **`BottomNavigationBar` over `NavigationBar`**: Material 2 bar matches iOS feel better for MVP — upgrade to `NavigationBar` in polish phase
- **Auth providers separate from router**: Router watches auth providers, doesn't own auth logic — cleaner separation of concerns
- **`StateProvider` from legacy import**: Riverpod v3 moved `StateProvider` to `legacy.dart` — use `NotifierProvider` for all new state going forward
- **`initialValue` over `value` on dropdowns**: `DropdownButtonFormField.value` deprecated in Flutter 3.33+ — always use `initialValue`
- **`String.fromEnvironment` needs `defaultValue` for dev**: No default = empty string at runtime when `--dart-define-from-file` is omitted → always add `defaultValue` for dev credentials
- **Supabase `external_email_enabled` off by default**: New projects ship with email/password auth disabled — enable via Dashboard → Auth → Providers
- **`updateDocument()` not `update()` for provider methods**: `AsyncNotifier` has a built-in `update()` — feature methods named `update()` silently shadow it; use descriptive names like `updateDocument()`, `updateTask()`
- **Two-client Edge Function pattern**: One admin client (`SUPABASE_SERVICE_ROLE_KEY`) for DB ops; verify identity via `supabase.auth.getUser(token)` — never trust client-supplied `user_id`
- **`SliverToBoxAdapter` over `SliverPersistentHeader` inside `CupertinoPageScaffold`**: Pinned headers conflict with `CupertinoSliverNavigationBar` geometry — use `SliverToBoxAdapter`; sticky via `NestedScrollView` later
- **`@riverpod` codegen naming convention**: Codegen generates `fooProvider` and `fooProvider.notifier` — match these exactly; never write manual `AsyncNotifierProvider`
- **Shared `_FormBody` between iOS and Android sheet variants**: Platform wrappers render the same `_FormBody` — differences (header style, save button) isolated to wrappers → `lib/features/documents/widgets/category_form_sheet.dart`
- **Single icon catalog via `CategoryIcons.forKey()`**: All icon-string → `IconData` lookups through one map — add new keys to `CategoryIcons.all`, call `forKey()` everywhere
- **`quickCompleteTask()` returns ID over void**: `Future<String>` lets callers pass the ID to the undo handler without extra state — enables robust undo in the same interaction
- **Composite detail model over fat primary model**: Separate `TaskDetail(task, completions)` keeps the list model lean — assembled only when the detail screen opens
- **`PickerOption` record typedef over a model class**: `typedef PickerOption = ({String id, String name})` — zero overhead, no file needed; sufficient when data never leaves the form
- **Newline textarea over chip-add-remove for list fields**: Multiline textarea for `List<String>` fields — simpler; join with `'\n'` on init, split + trim + filter on save
- **`context.push<String>()` typed return over callback/shared state**: Typed push/pop relays form result back to caller — cleaner than a provider field or callback closure
- **`SECURITY DEFINER` RPC with immediate ownership check**: RPC verifies `properties.user_id = auth.uid()` before any data read — client-supplied `p_property_id` validated against session, not trusted
- **`due_date < CURRENT_DATE AND NOT IN (completed, skipped)` over `status = 'overdue'` in RPCs**: Status column lags reality — date-based predicates always accurate; cross-check SQL against Flutter display code
- **`FractionallySizedBox` over `LayoutBuilder` for skeleton width fractions**: `LayoutBuilder` cannot respond to intrinsic dimension queries from `SliverFillRemaining(hasScrollBody: false)` — same result, no crash
- **`Future.wait([q1, q2, q3, q4])` for hub overview fetch**: Parallel fetches reduce total latency to slowest single query instead of sum of all
- **`typedef NoEmergencyPropertyException = _NoPropertyException`**: Private exception exported via `typedef` — sentinel type; downstream screens catch the public alias without coupling to private symbol
- **Top-level `show*Picker()` for cross-feature pickers**: When a picker needs platform-branching AND returns cross-feature data, a top-level function is cleaner than `static show()` → `lib/features/emergency/widgets/document_link_picker.dart`
- **`CupertinoDatePicker` in fixed-height `Container` inside `showCupertinoModalPopup`**: 300px `Container` with header Row (Cancel/Done) + `Expanded(CupertinoDatePicker)`; `Material(type: transparency)` ancestor prevents assertion errors → `lib/features/emergency/screens/insurance_form_screen.dart`
- **`@JsonKey(name:)` to avoid Freezed mixin naming conflict**: When a DB column name conflicts with a Freezed-generated mixin property (e.g. `model`), give Dart field a different name + `@JsonKey(name: 'db_column')` → `lib/features/home_profile/models/system.dart`
- **`@JsonEnum(valueField:)` with `get label` on Dart enums**: Map Postgres enum strings with `@JsonEnum(valueField: 'value')` + explicit `final String value` + `String get label` — cleaner than String extensions when you own the enum → `lib/features/home_profile/models/system.dart`
- **Non-fatal Edge Function call after insert**: Wrap secondary Edge Function calls in `try {} catch (_) {}` — primary DB write must never block on downstream function failures
- **`BoxConstraints(minHeight:)` for bordered cards**: `Border.all(width: 1)` draws inward consuming 2px — use `minHeight` constraint instead of fixed `height` so the card expands rather than clips
- **`abstract final class` picker catalog with `(value:, label:)` records**: `static const all = [(value: 'x', label: 'X'), ...]` drives pickers from one list; `labelFor(value)` for display — documents all DB enum values in one place → `lib/features/emergency/models/emergency_contact.dart`
- **Status picker gated to `ProjectStatusTransitions.nextFor()`**: Edit form only shows valid next statuses; if transitions list is empty (e.g. completed), `onTap` returns early without showing a picker → `lib/features/projects/screens/project_form_screen.dart`
- **`work_type` as TEXT + CHECK constraint over Postgres enum**: Avoids `ALTER TYPE` for future value additions — use TEXT CHECK for small, stable sets that may grow; Postgres enum preferred only when DB-level type guarantees are required
- **Hard delete over soft delete for join table rows**: Join table rows (e.g. `project_contractors`) use `.delete()` not soft-delete — no history requirement; hard delete keeps table clean and eliminates `isFilter('deleted_at', null)` on every query
- **`reorderPhases()` with sequential batch updates**: Iterates `orderedIds` and `update({'sort_order': i})` per phase; no bulk-update API needed; always invalidate sibling `projectDetailProvider` after reorder so `phase_count` stays current → `lib/features/projects/providers/project_phases_provider.dart`
- **`loadTemplatesAndCreate()` batch insert from template table**: Fetch templates filtered by `project_type`, map to insert rows with `project_id`/`user_id` injected, single `insert(rows)` call — one round-trip for N phases → `lib/features/projects/providers/project_phases_provider.dart`
- **Dark summary header + `LinearProgressIndicator` for budget overview**: `deepNavy` container at top of `CustomScrollView` via `SliverToBoxAdapter`; bar uses `goldAccent` normally, switches to `AppColors.error` when `isOverBudget`; over-budget warning row below the bar → `lib/features/projects/screens/project_budget_screen.dart`
- **Dual provider for budget screen (items + summary)**: `projectBudgetProvider` for line items, `projectBudgetSummaryProvider` for aggregated totals — watch both independently; `RefreshIndicator` invalidates both on pull-to-refresh → `lib/features/projects/screens/project_budget_screen.dart`
- **Three-mode contractor form sheet (link / create / edit)**: `bool _isCreatingNew` toggle + `_isEditing` getter drives UI branching; `_buildJoinFields()` shared across all three modes; `_loadContacts()` called in `initState` only for non-edit mode → `lib/features/projects/widgets/contractor_form_sheet.dart`
- **`ConsumerStatefulWidget` for modal sheets that `ref.watch` providers**: Plain `StatefulWidget` with an external `WidgetRef` causes provider updates to rebuild the *parent*, not the sheet — spinner never clears; always make picker/form sheets `ConsumerStatefulWidget` so they own their ref → `lib/features/projects/widgets/document_link_picker_sheet.dart`
- **Journal notes ordered by `note_date` then `created_at`**: Two-column order `order('note_date').order('created_at')` — user-specified date primary, creation time tiebreaker within same day → `lib/features/projects/providers/project_journal_provider.dart`
- **`propertyDocumentPickerList` as a standalone top-level provider**: Document picker list is a separate `@riverpod Future<List<...>>` (not a family) — fetches all documents for the authenticated user's property; reusable across any feature needing a document picker → `lib/features/projects/providers/project_documents_provider.dart`
- **"Add after" opens ImagePicker directly rather than picking from existing photos**: Chose direct ImagePicker flow over showing a picker of existing unpaired after photos — simpler UX (one tap to shoot/pick), immediately uploads as 'after' type, then auto-pairs; eliminates the need to scroll through a secondary list and removes a class of edge cases where an "after" photo is already paired → `lib/features/projects/screens/project_photos_screen.dart`
- **`uploadPhoto` returns `Future<String>` (photo ID) over `Future<void>`**: Chose returning the new row ID so the auto-pair call (`pairPhotos(beforeId, newId)`) can happen in the same interaction without any extra state or secondary query; non-fire-and-forget but enables atomic upload+pair flow
- **`MaterialPageRoute` with `fullscreenDialog: true` for single-photo viewer**: Chose over GoRouter push for inline detail views inside a feature screen — no named route needed; `fullscreenDialog` gives a bottom-up iOS sheet transition appropriate for a media viewer → `lib/features/projects/screens/project_photos_screen.dart`
- **`pairId` UUID shared across exactly two photos over a separate join table**: Chose a shared UUID column on both photo rows over a `photo_pairs` join table — simpler schema, lookup is `where(p.pairId == photo.pairId && p.id != photo.id)`, no extra query or join needed

## Lessons

<!-- Format:
- **[Issue]**: [What happened] → [How to prevent]
-->
- **`TODO(...)` triggers dart lint**: The `todo` lint rule flags `TODO(name):` comments → Use plain `// note:` style for deferred work
- **Riverpod 3.x removed `.valueOrNull`**: Use `.value` directly on `AsyncValue` — `.valueOrNull` no longer exists
- **`StateProvider` requires legacy import in Riverpod v3**: `package:flutter_riverpod/legacy.dart` needed — prefer `NotifierProvider` to avoid this
- **`DropdownButtonFormField.value` deprecated**: Flutter 3.33+ → always use `initialValue`; add `ValueKey` if value is set programmatically
- **`FileOptions` needs explicit import**: Requires `import 'package:supabase_flutter/supabase_flutter.dart'` — not resolved through transitive imports
- **Email regex in single-quoted strings**: Regex containing `'` inside a single-quoted Dart string causes parse errors → Use double-quoted or raw strings (`r"..."`)
- **Router race condition on auth navigation**: `context.go('/dashboard')` fires before `isAuthenticatedProvider` updates — router redirects back to login → remove manual `context.go` after auth calls, let router self-redirect
- **`SliverPersistentHeader(pinned: true)` crashes inside `CupertinoPageScaffold`**: `layoutExtent > paintExtent` geometry error from `CupertinoSliverNavigationBar` — replace with `SliverToBoxAdapter`
- **Supabase `.single()` throws `PGRST116` on 0 rows**: Use `.maybeSingle()` and guard with `if (row == null) return []` for any query where the user may not have data yet
- **`showCupertinoModalPopup` requires `rootNavigator: true` to dismiss**: Always dismiss with `Navigator.of(context, rootNavigator: true).pop()` — inner navigator pop empties GoRouter stack and crashes
- **Freezed v3 requires `abstract class`**: `@freezed class Foo with _$Foo` fails — always use `@freezed abstract class Foo with _$Foo`
- **`WidgetRef` invalid after modal dismissal + async**: Capture `ref.read(provider.notifier)` before the `.pop()` call — widget unmounts during async picker, `ref` throws "Used Ref after disposed"
- **`showCupertinoModalPopup` resolves on dismiss, not picker completion**: Wrap the full picker flow in a `Completer` and await it — `show()` returns before picker completes otherwise
- **`json_serializable` camelCase vs Supabase snake_case**: Without `build.yaml`, `fromJson` has camelCase keys — silently returns nulls for multi-word fields → always add `build.yaml` with `field_rename: snake`
- **Dev testing requires seeded property**: Upload and document queries resolve `property_id` first — if no property row exists, throws "No property found" → seed via `INSERT INTO properties (...)` in Supabase dashboard
- **Nested select must include all required model fields**: Missing fields cause `TypeError: null is not X` in `fromJson` — always check every `required` model field against the nested select column list
- **`TextField` inside `showCupertinoModalPopup` crashes with "No Material widget found"**: Wrap sheet root in `Material(type: MaterialType.transparency)` to provide the ancestor without visual change
- **Missing Supabase migration = provider stuck in loading**: PostgREST returns an error that AsyncNotifier never surfaces clearly — screen stays on skeleton; always apply migrations and verify with `execute_sql SELECT table_name FROM information_schema.tables`
- **Apply migrations in dependency order**: Foreign key tables must exist before referencing tables — apply migrations sequentially (005 → 006 → 007...)
- **`showCupertinoModalPopup` content overflows without height constraint**: Wrap content in `ConstrainedBox(maxHeight: MediaQuery.of(context).size.height * 0.85)` + `SingleChildScrollView`
- **Expand arrow on custom categories implies subcategories**: Gate `keyboard_arrow_down` and expansion on `category.isSystem` — custom categories should tap-to-select immediately
- **`Navigator.of(context, rootNavigator: true)` bypasses GoRouter on regular routes**: Only valid inside `showCupertinoModalPopup` — always use `context.pop()` for GoRouter navigation
- **`CupertinoPageScaffold` nav bar overlaps child at y=0**: Wrap content in `SafeArea(bottom: false)` — without this, first widget in `CustomScrollView` renders behind the nav bar
- **Duplicate icon switches silently diverge from DB values**: Consolidate to `CategoryIcons.forKey()` and verify keys against DB before shipping
- **`if (!mounted) return` after every async gap in State**: Always check `if (!mounted) return` after any `await` before calling `setState`, `ScaffoldMessenger`, or `context.push`
- **Worktree merge with new `@riverpod`/`@freezed` files requires `build_runner` re-run**: Any merge that introduces new annotated files (main → feature, conflict resolution, or fresh merge) will have stale/missing `.g.dart`/`.freezed.dart` — always run `dart run build_runner build --delete-conflicting-outputs` before quality gate
- **DATE vs TIMESTAMP Supabase columns**: Sending a full ISO timestamp to a Postgres DATE column is silently truncated/rejected — always check column type; use `split('T')[0]` for DATE columns
- **`String? _propertyId` must be nullable in form `initState`**: Property ID is fetched async — guard provider watches with `if (_propertyId != null)` or use `AsyncData([])` as fallback
- **Edge Function `verify_jwt: true` is a gateway-level guard**: Gateway rejects requests before function code runs — function's `auth.getUser()` is defense-in-depth, not the primary gate
- **`functions.invoke()` requires explicit `Authorization` header in supabase_flutter v2**: Always pass `headers: {'Authorization': 'Bearer ${session.accessToken}'}` explicitly; guard with `if (session == null) return;` first
- **Edge Function `verify_jwt: true` gateway may reject valid Flutter JWTs**: Bypass by implementing the same logic as a provider method using the standard DB client — re-enable once project JWT config is confirmed
- **`(_, __)` triggers `unnecessary_underscores` lint in Dart 3**: Use `(_, _)` instead — Dart 3 allows repeated `_` wildcards for multi-arg discards
- **RPC aggregate queries must mirror Flutter client classification logic**: If Flutter classifies by `due_date < today`, SQL must use the same predicate — `status = 'overdue'` alone misses tasks whose status hasn't been flipped yet
- **`GoRouter initialLocation` must match an existing route**: Removing a route without updating `initialLocation` causes "GoException: no routes for location" on cold start — update `initialLocation`, root redirect, auth redirect, and all `context.go()` call sites together
- **`StatefulShellBranch` first route = tab default**: Always put the primary screen first — a placeholder as the first route means tapping the tab never shows the real screen
- **Skeleton `AnimationController` must use `addPostFrameCallback`**: Calling `.repeat()` directly in `initState` crashes with `debugFrameWasSentToEngine` on pushed routes and some startup paths — always use `WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _ctrl.repeat(reverse: true); })`; also: `LayoutBuilder` and `ListView` both crash inside `SliverFillRemaining(hasScrollBody: false)` — use `FractionallySizedBox` (inside `Expanded`) and `Column` respectively
- **Non-tab pushed-route screens must have a reachable entry point**: Always verify a new pushed-route screen has a visible button on an existing tab screen before closing the issue
- **Controllers in data model for inline editable rows**: Own `TextEditingController`s in the row's data class with a `dispose()` method — parent state disposes on removal, controllers survive parent rebuilds → `lib/features/emergency/widgets/circuit_directory_editor.dart`
- **`Border.all()` draws inward, stealing 2px of content height**: Use `constraints: BoxConstraints(minHeight:)` so the card expands rather than clips
- **`ListView` inside `SliverFillRemaining(hasScrollBody: false)` crashes**: `RenderViewport` throws "does not support intrinsic dimensions" — replace skeleton's `ListView` with a `Column`
- **DB enum values don't match model enum values**: Always verify actual DB enum values with `SELECT unnest(enum_range(NULL::your_enum))` before writing model enum code
- **Same wrong column name in multiple providers**: When a column is renamed, `grep -r "old_column_name" lib/` — fixing one provider doesn't fix all others
- **NOT NULL column missing from insert payload**: Always check `SELECT column_name FROM information_schema.columns WHERE table_name = 'X' AND is_nullable = 'NO'` before writing insert code
- **`TextEditingController` created in `build()` resets cursor to 0 on every rebuild**: Own controllers in `StatefulWidget` state or data model class — `build()` creates a fresh controller each rebuild → `lib/features/emergency/widgets/circuit_directory_editor.dart`
- **`field_rename: snake` doesn't convert no-uppercase field names; use `@JsonKey` + lint suppression**: `is24x7` stays `is24x7` in JSON but DB column is `is_24x7` — fix with `@JsonKey(name: 'is_24x7')`; suppress resulting `invalid_annotation_target` lint with `// ignore_for_file: invalid_annotation_target` at top of file → `lib/features/emergency/models/emergency_contact.dart`
- **`ref.invalidateSelf(); await future` propagates refetch failures as write failures**: If the post-insert refetch queries multiple tables and any fail, the exception propagates back to the caller — verify the overview fetch succeeds independently before debugging the insert itself
- **`FractionallySizedBox` bare in a `Row` crashes with infinite width**: `Row` gives unconstrained width to direct children — wrap in `Expanded` (proportional sizing) or use `Container(width: N)` (fixed skeleton bars)
- **iOS `Stack + Positioned` FAB must be gated when empty state has its own CTA**: Gate with `if (contentCount > 0)` so FAB only appears with real content — prevents two competing tap targets → `lib/features/projects/screens/projects_screen.dart`
- **`AppColors.textTertiary` doesn't exist — use `AppColors.gray400`**: The color palette has no `textTertiary` alias; for subdued icon and hint colors use `AppColors.gray400` (same value as `textDisabled`) → verify against `app_colors.dart` before using any color name not seen elsewhere in the codebase
- **Nested select across feature boundaries requires FK + RLS**: `emergency_contacts(name, phone, email)` nested inside `project_contractors` query only works if the FK constraint exists and RLS allows the join — always test that the nested select actually returns data before writing display logic that depends on it
- **Hard-delete join tables must not include `deleted_at` in `_kColumns` or `.isFilter()`**: `project_contractors` uses hard-delete — selecting or filtering on `deleted_at` causes a 400 on every fetch; always check `information_schema.columns` before assuming a table uses soft-delete
- **Nested select column names must match exact DB column names**: `emergency_contacts(name, phone, email)` fails with 400 if the column is `phone_primary` — PostgREST returns an error for unknown columns in nested selects; always verify nested select column names against the actual table schema
- **`property_id` in `_kColumns` for a table that lacks the column causes 400 on every fetch**: Screen never leaves skeleton; always verify every column in `_kColumns` against `information_schema.columns` before writing the provider
- **`user_id` NOT NULL with no DB default must be explicitly included in insert payload**: Omitting it causes a DB constraint violation and silent upload failure; always check `is_nullable = 'NO'` + `column_default IS NULL` before writing insert code
- **Duplicate `path:` in router from merge conflict silently shadows real screen**: After resolving any router conflict, `grep` for duplicate path strings — GoRouter matches the first declaration; the real screen is unreachable without any error
- **`StatefulWidget` with external `WidgetRef` never rebuilds when provider resolves**: Provider updates trigger a rebuild on the widget that owns the ref, not the modal sheet — convert modal picker/form sheets to `ConsumerStatefulWidget` so they own their ref and rebuild on provider state changes
- **`property_id` in `_kColumns` for a table that has no such column causes 400 on every fetch**: `project_photos` has no `property_id` column (it's on `projects`) — including it in the select list causes a PostgREST 400 on the first load; screen never leaves skeleton state; always verify column list against `SELECT column_name FROM information_schema.columns WHERE table_name = 'X'` before writing `_kColumns`
- **`user_id` NOT NULL with no DB default must be in insert payload**: `project_photos.user_id` is `NOT NULL` with no server default — omitting it from the `insert({})` map causes a constraint violation and silent upload failure; always check `is_nullable = 'NO'` and `column_default IS NULL` columns before writing insert code
- **Auto-pair "Add after →" flow: upload first, pair second**: Upload returns the new photo's ID; immediately call `pairPhotos(beforeId, newId)` — both mutations invalidate and re-fetch once via `ref.invalidateSelf(); await future`; the grid reflects the paired state in the same refresh cycle without a second screen reload

## Philosophy

**Ship complete** — When Keystona launches, all 5 feature pillars will be fully polished and ready for the App Store. No soft launch, no partial feature set.

**Feature-first development** — Work through the Sprint Plan phases in order. Each phase has clear acceptance criteria. Some phases can be parallelized across agents.

**Document everything** — Use `/compound` or `/quick-compound` after completing work to extract learnings, patterns, decisions, and lessons into this CLAUDE.md file.

**Agent-native architecture** — Agents are first-class citizens. Any action a user can take, an agent can take. Anything a user can see, an agent can see.
