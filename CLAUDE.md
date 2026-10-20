# CLAUDE.md

Guidance for Claude Code in this repository. The previous, much longer version is in `CLAUDE_ARCHIVE.md` (not loaded; many of its entries describe the retired Navy/Gold design system).

## Project

**Keystona**: a Flutter mobile app for home management. It helps homeowners organize documents, track maintenance, manage emergencies and monitor home health through a composite score.

**Stack:** Flutter · Supabase (backend) · RevenueCat + Stripe · Firebase (FCM) · Sentry · PostHog

**Layout:** app in `apps/keystona/` · SQL in `supabase/` (migrations, tests, Edge Functions) · specs in `keystona-project-files/` · design kit in `design/` · agents in `.claude/agents/` · open items in `FOLLOW_UPS.md`.

**Navigation:** 5 tabs: Home · Docs · Tasks · Projects · Settings. Emergency Hub is a quick action on Home (not a tab).

## Design source of truth

The Aurora kit in `design/` is the source of truth for every screen. It wins over `Keystona_Aurora_Design_System.md`, `Keystona_Aurora_Component_Library.md` and anything older.

- `design/screens/` (PNG, 390 pt wide), `design/source/*.dc.html` (exact copy, sizes, states, links), `design/BUILD_ORDER.md` (sprints and commits), `design/Keystona_Implementation_Notes.md` (behaviour: long-press, Undo, offline, reminders).
- The HTML is a spec, never transpile it. px values are logical pixels at the 390 pt reference width.
- **Where a PNG and a written rule conflict, follow the PNG.** Copy text exactly. Words always accompany status color.
- Tokens: `apps/keystona/lib/core/theme/aurora_*.dart` (`AuroraColors/Type/Spacing/Radius/Shadows/Sizes/...`), scaled by `context.aurora` (`AuroraScale`). Platform system font, never bundled. Legacy tokens (`butter`, `*Dim`, `inkTertiary`) stay only until their last caller is rebuilt.
- **No hard-coded values in feature code** (colors, sizes, radii, durations, opacities, fixed widths/heights). Check: `apps/keystona/tool/check_hardcoded.sh <paths>`.
- Aurora rules: one coral surface per screen; coral = act now; cobalt = actions and save; lime = wins; amber = soon; no tinted fills; 44 pt touch targets; no ⋯ buttons on task rows (long-press instead).
- New shared widgets in `lib/core/widgets`, router changes and migrations need Caleb's OK first.
- UI work is done by the `storyboard-to-flutter` agent, which replaces screens in place and deletes the superseded UI. Its file holds the working rules (layout, navigation, tests, parallel-track etiquette).

## Commands

```bash
cd apps/keystona
flutter analyze
flutter test                                   # curated responsive matrix (fast)
flutter test --dart-define=FULL_MATRIX=true    # full 5 viewports x 3 text scales; run before a release
dart run build_runner build --delete-conflicting-outputs   # after touching @riverpod / @freezed files
tool/check_hardcoded.sh lib/features/<feature>             # hard-coded value guard
tool/check_state_leaks.sh                                   # state that could outlive a screen
```

SQL tests (safe: BEGIN ... ROLLBACK, run against any database): `supabase/tests/*.sql`. Via the Supabase MCP `execute_sql`, only the LAST statement's result comes back, so end a script with `rollback;` then a `select 'PASS'`, or raise an exception to carry a message.

## Agents and skills

| Agent | Use for |
|---|---|
| `storyboard-to-flutter` | Rebuilding screens from the Aurora kit (all kit UI work) |
| `flutter-keystona-dev` | Non-visual Flutter work: providers, services, performance |
| `supabase-backend-specialist` | Queries, RLS, Edge Functions, storage, RPCs |
| `integration-wiring` | Cross-feature routing and shared state |
| `keystona-qa-specialist` | Tests and security-boundary checks |
| `dashboard-home-builder` | Home tab (8 states, 7 sections) |

Skills: `plan-and-build`, `feature-agent`, `flutter-agent`, `supabase-agent`, `migration-writer`, `code-review`, `compound`, `quick-compound` (see `.claude/skills/`).

## Sprint workflow

1. **Pre-flight (before any agent):** read the sprint in `design/BUILD_ORDER.md`; list the legacy files it replaces (`wc -l`); check the live schema for every column the screens need (information_schema) and list gaps; ask for decisions that block a screen. This avoids a rework wave at the end.
2. **Split by disjoint file sets** (one agent per track; each owns its legacy files exclusively; shared contracts fixed by path and signature in the briefs; each track adds tokens only in its own NEW `aurora_*.dart` file). Briefs list screens, files, contracts and gaps only: the standing rules live in the agent file.
3. **Verify the combined tree yourself:** analyze, full test, hard-coded guard, state-leak guard (`tool/check_state_leaks.sh`), duplicate router paths (`grep -o "path: AppRoutes\.[A-Za-z]*" ... | sort | uniq -d`), file sizes. Run the app's checks against the live DB where an agent could not.
4. Record leftovers in `FOLLOW_UPS.md`; commit in logical commits when asked.

## Architecture

```
lib/features/<feature>/{models,providers,repositories,screens,widgets,services}/
```
- **Riverpod:** `@riverpod` codegen only (never hand-written `AsyncNotifierProvider`); `ref.watch` in `build`, `ref.read` in handlers; `autoDispose` for screen providers; `.select()` for fields; `ref.keepAlive()` on lists watched across tabs; `.value` (not `.valueOrNull`; Riverpod 3); `StateProvider` only from `flutter_riverpod/legacy.dart`, prefer `NotifierProvider`. Feature methods must not be named `update()` (shadows `AsyncNotifier.update`). Failed providers are not retried automatically (`noAutomaticRetry` in `main.dart`).
- **Mutations:** optimistic UI (never set `AsyncLoading` before a write; update local data, write after, roll back on failure). After a write invalidate the sibling providers too. Capture `ref.read(x.notifier)` before an async gap; `if (!mounted) return` after every await. `ref.invalidate` is safe on a disposed provider; calling a notifier method on one is not.
- **State belongs to the screen.** A form, draft or scan must not outlive its flow or reappear on another screen. Prefer `autoDispose`. If state must exist before the screen does (a file picked in a sheet) or after it closes (a scan still reading), keep it alive deliberately: reset it on EVERY exit (pop, save) and on every entry (first step of the flow) through one helper (`DocumentFlow.reset`), list it in `tool/keepalive_allowlist.txt` with the test that proves it, and scope per-user data to the signed-in user. **Never write into a provider from `build()` or from a post-frame callback that `build()` schedules** (it re-applies on every rebuild, including the rebuild a reset causes): apply input once from `initState` (`ref.listenManual` + one post-frame read). This is the bug where closing a renewal reopened it as the next "new document".
- **Data access behind a repository interface**, exposed through a provider so tests override it with a fake. Widgets take narrow inputs (values or callbacks), not whole models or `WidgetRef`.
- **Models:** `@freezed abstract class` (Freezed v3). Supabase is snake_case (`build.yaml` `field_rename: snake`; `@JsonKey(name:)` for names like `is_24x7` or a clash with a Freezed member). JSON numbers: `(x as num?)?.toInt()`. DATE columns are `YYYY-MM-DD` (`toIso8601String().split('T')[0]`). `'key': ?value` omits null map entries. Re-run build_runner after merges.
- **Services:** pure logic as `abstract final class` with static methods; services throw, the UI catches and shows a snackbar. Stub unbuilt backends with `throw UnimplementedError('x() implemented by issue #N')` and list them in `FOLLOW_UPS.md`. Use `// note:` for deferred work (a `TODO(...)` trips the lint). Every model field used only by a future issue gets a `/// [#N] used for ...` comment.
- **Every screen:** skeleton that mirrors the layout, error with retry, empty state per the Empty States Catalog or the kit, pull-to-refresh on scrollable lists.
- **Performance:** every interaction under 1 s; `const` where possible; `CachedNetworkImage` only (never `Image.network`); `.builder()` lists; search debounced 300 ms.

## Router (`lib/core/router/app_router.dart`)

- All paths are `AppRoutes` constants. Static segments before param routes (`/documents/upload` before `/documents/:documentId`).
- `routerProvider` watches auth; after sign-in/up never call `context.go()`, let the redirect fire. Auth and onboarding routes stay in the public list.
- `StatefulShellRoute.indexedStack`: the first route of a branch is the tab default; `goBranch(i, initialLocation: i == current)`; `context.go` to switch tabs, `context.push` for sub-screens of the current branch.
- `initialLocation` must exist; after any router merge grep for duplicate `path:` (the first match silently shadows the rest). A pushed (non-tab) screen needs a reachable entry point.

## Navigation, sheets and layout pitfalls

- **Dismiss a sheet or dialog with its own context.** `AuroraSheet` and `showModalBottomSheet` live on the nearest navigator; `Navigator.of(context, rootNavigator: true).pop()` on them pops the router's last page and crashes ("popped the last page"). `showCupertinoModalPopup` and `showDialog` use the root navigator. Use the builder's context, not the opener's.
- Show a post-save sheet before `context.pop()` (popping first locks the navigator). Wrap `TextField`s inside Cupertino popups in `Material(type: transparency)`. Pass `context.pop(value)` back to callers with `context.push<T>()`.
- **Never put an `Expanded` next to a loose `Flexible` in a `Row`**: they split the free space evenly and the `Flexible`'s unused share stays empty, so trailing widgets float mid-row. Use `Flexible` + `Flexible` with `mainAxisAlignment: spaceBetween`, or `Expanded` + a plain trailing child. Label/value rows: label natural width, value `Expanded`.
- Size from content with `minHeight` constraints, not fixed heights (`Border.all` draws inward). Non-scrolling `ListView` inside a `CustomScrollView` needs `padding: EdgeInsets.zero`. `ListView`/`LayoutBuilder` crash inside `SliverFillRemaining(hasScrollBody: false)`. Bare `FractionallySizedBox` in a `Row` crashes (wrap in `Expanded`). Own `TextEditingController`s in `State`, never in `build()`. Skeleton animations start in `addPostFrameCallback`. Use `(_, _)` for discarded callback params.

## Supabase

- RLS is the auth layer on every user-data table (`auth.uid()`; never trust a client `user_id`). Filter by `property_id` first and `deleted_at IS NULL`; never `SELECT *` on lists; nested selects over N+1; signed URLs for private buckets.
- **Verify before writing a query or insert:** every selected column exists (`information_schema.columns`), NOT NULL columns without a default (e.g. `user_id`) are in the insert, nested-select FKs/RLS exist, enum values match (`enum_range`). A bad column is a 400 that leaves the screen on its skeleton. Use `.maybeSingle()` when 0 rows is valid.
- **Soft delete and restore go through `SECURITY DEFINER` RPCs** (`soft_delete_*`, `restore_*`): a plain `UPDATE ... SET deleted_at` fails with 42501 because the SELECT policy hides the written row, and a plain restore matches 0 rows. Each RPC checks ownership with `auth.uid()`. Join tables with no history hard-delete.
- **New public functions get an explicit `anon` grant** on Supabase; `REVOKE ... FROM PUBLIC` alone does not remove it. Always `REVOKE ... FROM PUBLIC, anon`, then grant to `authenticated`/`service_role`. Prefer `SECURITY INVOKER` unless RLS must be bypassed.
- Migrations are additive, sequential, applied in dependency order, with a rollback block and an SQL test in `supabase/tests/`. After applying, run the advisors. Create storage buckets before writing upload code.
- RPC aggregates must mirror the client's logic (`due_date < today AND status NOT IN (completed, skipped)`, not `status = 'overdue'`).
- Edge Functions: verify the token first (`auth.getUser`); `functions.invoke` needs an explicit `Authorization` header; wrap secondary calls in `try/catch` so the primary write never blocks. Claude Vision responses: parse numbers with `num`.
- Seed a property before testing document/task flows; there is a single remote project (`hmvsiiicjwygayekwaor`).

## Security

Never log PII (names, emails, OCR text, addresses). Auth: email + Apple + Google, 7-day sessions, biometric unlock. Validate input on the client AND the server. See `HomeTrack_Security_Guide.md` §8 before every PR.

## Testing

- Responsive tests use `testResponsive` / `activeViewports` / `scalesFor` from `test/support/responsive_harness.dart`: a curated 5 cases per screen by default, the full 5x3 matrix with `--dart-define=FULL_MATRIX=true`. Override providers with fakes; never hit Supabase.
- **Test position, not only overflow:** assert where key elements land (actions at the right edge, labels at the left, primary buttons, stacked menu items). Overflow-only tests missed real layout bugs.
- A regression test for a bug must fail without the fix (revert the fix to check).
- Golden tests against the kit PNGs do not exist yet.

## Documentation index (`keystona-project-files/`)

| Document | Covers |
|---|---|
| HomeTrack_SRS.md | Requirements, non-functional requirements |
| HomeTrack_Database_Schema.md | Migrations, RLS policies, storage buckets |
| HomeTrack_API_Contract.md | Endpoints, Edge Functions, rate limits |
| HomeTrack_Sprint_Plan.md | Phases 0 to 9, acceptance criteria |
| HomeTrack_Performance_Guide.md | Time budgets, caching |
| HomeTrack_Error_Handling.md | Loading, errors, offline, forms, empty states |
| HomeTrack_Empty_States_Catalog.md | 25 empty states (the kit wins where it draws one) |
| HomeTrack_Dashboard_Spec.md / _States.md | Home tab layout and 8 states |
| HomeTrack_Health_Score_Algorithm.md | Three-pillar scoring |
| HomeTrack_Notification_Priority.md | P1/P2/P3 tiers, digest, quiet hours |
| HomeTrack_Security_Guide.md | Auth, validation, PII, Sentry, checklist |

## Philosophy

**Ship complete:** all 5 pillars polished before launch, no soft launch. **Feature-first:** work through the sprints in `design/BUILD_ORDER.md`. **Agent-native:** anything a user can do or see, an agent can. **Document as you go:** record leftovers in `FOLLOW_UPS.md`, learnings here (keep this file short; move retired material to the archive).
