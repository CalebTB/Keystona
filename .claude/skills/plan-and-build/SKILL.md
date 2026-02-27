---
name: plan-and-build
description: Use this skill before building any feature issue for Keystona. Combines planning (with look-ahead at dependent issues) and building into one workflow. Trigger whenever the user says 'plan and build issue X', 'start issue X', 'build issue #N', or before implementing any chunk from the Sprint Plan. Works for any phase (1–9). Produces a written plan approved by the user BEFORE writing any code, with architecture decisions that account for all issues that depend on this one.
---

# Plan-and-Build Skill — Keystona

## Your Role

You plan before you build. You look ahead before you plan.

The output of this skill is:
1. A written implementation plan, approved by the user
2. A complete feature implementation that accounts for all dependent issues

This skill works for any issue in any phase. Nothing is hardcoded.

## Step 1 — Issue Intake

Read the target issue from GitHub:

```bash
gh issue view {issue_number} --repo CalebTB/Keystona
```

Extract:
- Phase label (e.g. `phase-1`, `phase-2`) — you'll use this to find related issues
- Feature name (e.g. `document-vault`, `maintenance`, `projects`)
- Acceptance criteria (every checkbox)
- Spec sections referenced (Key references)
- Which issues this depends on (Depends on field)

## Step 2 — Look-Ahead Analysis

Find every open issue in the same phase that could depend on this one.

**Step 2a — List all issues in the same phase:**
```bash
gh issue list --repo CalebTB/Keystona --label {phase-label} --state open
```

**Step 2b — Find downstream issues** (issues that list this issue number in their "Depends on"):
```bash
gh issue list --repo CalebTB/Keystona --label {phase-label} --state open \
  --search "#{current_issue_number}"
```

For any ambiguous cases, read the issue body to confirm the dependency:
```bash
gh issue view {candidate_issue_number} --repo CalebTB/Keystona
```

**Step 2c — For each confirmed downstream issue, extract:**
- What **model fields** it will need (from acceptance criteria and spec references)
- What **provider methods** it will call (create, read, update, delete, search, filter, etc.)
- What **routes** it will add as children of the current feature
- What **shared widgets** it will reuse from the current issue's widgets

**Step 2d — Produce a look-ahead summary before continuing:**
```
Downstream issues:
- #{N} ({title}): needs {ModelName}.{field}, provider.{method}()
- #{N} ({title}): needs {ModelName}.{field}, provider.{method}()
...

Fields to include in model now (for downstream):
- {field}: needed by #{N}
- {field}: needed by #{N}

Provider methods to stub now (for downstream):
- {method}(): needed by #{N}
```

If no downstream issues exist, note that explicitly and skip stub methods.

## Step 3 — Spec Research (Local)

Read the spec sections referenced in the current issue AND all downstream issues.

**Always read:**
- `keystona-project-files/HomeTrack_Sprint_Plan.md` — find the current phase, read all chunk descriptions for context
- `keystona-project-files/HomeTrack_API_Contract.md` — the section(s) listed in Key references
- `keystona-project-files/HomeTrack_Database_Schema.md` — the tables you'll query
- `keystona-project-files/HomeTrack_Error_Handling.md` — Section 14 for your feature's edge cases
- `keystona-project-files/HomeTrack_Empty_States_Catalog.md` — exact empty state copy for your screens
- `keystona-project-files/HomeTrack_Platform_UI_Guide.md` — which components must be adaptive

**Read if referenced by the issue:**
- `keystona-project-files/HomeTrack_Dashboard_Spec.md` — for Home tab / dashboard work
- `keystona-project-files/HomeTrack_Health_Score_Algorithm.md` — for health score work
- `keystona-project-files/HomeTrack_Security_Guide.md` — for auth, payments, or sensitive data work

**Explore existing code for patterns:**
```bash
# Always check for prior feature implementations — learn from them
ls lib/features/
```

For each existing feature directory found, skim its structure:
- How are models defined?
- How are providers structured?
- What does the screen's `.when()` block look like?

Also always check:
```
lib/core/theme/         — design tokens (AppColors, AppSizes, AppTextStyles)
lib/core/widgets/       — shared widgets already available (don't rebuild what exists)
lib/core/router/app_router.dart — how routes and branches are wired
```

Check `pubspec.yaml` to understand which packages are already in the project —
note the exact versions before searching for documentation.

## Step 3b — Web Research (Best Practices)

Search online to validate your approach before writing the plan. This prevents
building with outdated patterns or the wrong packages.

**Step 3b-1 — Identify what needs researching.**

From your spec + codebase reading, list the specific technical questions you
need answered before you can confidently write the plan. Examples:

- "Which Flutter PDF viewer package is recommended in 2026?"
- "What is the current AsyncNotifier best practice with Riverpod 3.x?"
- "Are there known issues with CupertinoSliverRefreshControl + SliverAppBar?"
- "How does Supabase Flutter SDK handle nested selects in the current version?"
- "What is the correct way to do HEIC → JPEG conversion on iOS in Flutter?"

Only search for things that would meaningfully change your implementation
decisions. Skip if the spec already gives you the exact code and it uses
stable, well-known APIs.

**Step 3b-2 — Search in parallel where possible.**

For each question, search using terms like:
- `flutter [feature] best practices 2026`
- `riverpod [specific pattern] example`
- `supabase flutter [operation] current`
- `[package name] flutter pub.dev`
- `[package name] known issues`

**Step 3b-3 — Synthesize findings into a "Research Notes" section.**

Add to the plan:

```markdown
## Research Notes
- **[Topic]**: [What you found] → [How it affects the implementation]
- **[Package]**: v{version} — [Current recommendation, any gotchas]
- **[Pattern]**: [Current best practice] — differs from spec in that [X]
```

If a finding contradicts the spec or suggests a better approach, call it out
explicitly so the user can decide. The spec was written at a point in time —
packages change, APIs deprecate, better patterns emerge.

**What to research for common Keystona feature types:**

| Feature type | Always research |
|---|---|
| Any list screen | Current Riverpod `AsyncNotifier` pattern, `flutter_riverpod` version changelog |
| File upload | Current Supabase Storage Flutter SDK, MIME type handling, size validation |
| PDF/image viewing | Best package for PDF viewer, image zoom packages |
| Search with debounce | Current Flutter debounce patterns, Supabase `textSearch` vs `ilike` |
| Camera / photo picker | `image_picker` current version, HEIC handling, permissions |
| Adaptive UI | Flutter `Platform.isIOS` vs `defaultTargetPlatform` current recommendation |
| Any new Supabase query | Supabase Flutter SDK docs for that specific query type |

## Step 4 — Write the Plan

Write a complete implementation plan. Use this structure:

```markdown
# Plan: #{N} — {Issue Title}

## Phase & Feature
Phase {X} — {Feature Name}

## Downstream Issues Accounted For
- #{N} ({title}): {what we're pre-wiring for it}
- #{N} ({title}): {what we're pre-wiring for it}

## Architecture Decisions
Decisions made now to support downstream issues:
- **{Decision}**: {What} → because #{N} will need {Y}

## Model Design
{ModelName}:
- {field}: {type} — [current issue] used for {purpose}
- {field}: {type} — [for #{N}] used for {purpose}
- {field}: {type} — [for #{N}] used for {purpose}

## Provider Interface
{FeatureProvider} methods:
- {method}(): — implemented now (current issue)
- {method}(): — stub now, implemented by #{N}
- {method}(): — stub now, implemented by #{N}

## File Structure
lib/features/{feature}/
├── models/
│   └── {model}.dart
├── providers/
│   └── {feature}_provider.dart
├── screens/
│   └── {feature}_screen.dart
└── widgets/
    ├── {feature}_card.dart
    ├── {feature}_list_skeleton.dart
    └── {feature}_empty_state.dart

## Screen Build Order
1. {model}.dart — data class
2. {feature}_provider.dart — AsyncNotifier + stubs
3. {feature}_list_skeleton.dart — skeleton widget
4. {feature}_empty_state.dart — empty state widget
5. {feature}_card.dart — list item widget
6. {feature}_screen.dart — screen combining all above
7. {form widgets if needed}

## Acceptance Criteria Checklist
(copy every checkbox from the GitHub issue verbatim)
- [ ] ...

## Extension Points for Downstream
Notes for agents building dependent issues:
- "Agent building #{N}: {provider method} is stubbed at {file}:{line} — implement {what}"
- "Agent building #{N}: {model field} is already defined — just {display/use} it"
```

**Stop here. Show the plan to the user and wait for approval.**

Ask:
> "Here's the plan for #{N}. Does this look right before I start building?"

Do not write any code until the user approves.

## Step 5 — Build

Only after plan approval. Execute the plan following these rules:

### Build order (never skip steps)
1. **Models** — Dart data classes with all fields (current + downstream)
2. **Providers** — AsyncNotifier with all methods (current implemented, downstream as `throw UnimplementedError()` stubs)
3. **Skeleton widget** — pulse animation, layout matching real content card exactly
4. **Empty state widget** — exact copy/illustration from Empty States Catalog
5. **List/detail widgets** — content display
6. **Screen widget** — `.when(loading/error/data)` combining all above
7. **Form widgets** — create/edit with validation (if this issue includes forms)

### Non-negotiable on every screen
- Skeleton loading (pulse animation, layout matches real card)
- Error state with retry button
- Empty state (motivational for primary screens, instructional for sub-screens)
- Pull-to-refresh on all scrollable lists
- `const` on every widget that can be const

### Supabase query rules
- Always filter by `property_id` first
- Always include `deleted_at IS NULL` for soft-delete tables
- Never `SELECT *` — list only the columns the screen actually needs
- Use nested selects to avoid N+1 (e.g. fetch category name alongside document in one query)

### After building
```bash
cd apps/keystona && flutter analyze
```
Zero warnings required. Fix all issues before reporting done.

## Step 6 — Hand-off Notes

After the build passes `flutter analyze`, produce a PR description:

```markdown
## Built: #{N} — {Issue Title}

### What was built
{1–2 sentence summary}

### Extension points for downstream issues
- **#{N} ({title})**: `{ProviderName}.{method}()` stubbed at `{file}:{line}` — implement {what}
- **#{N} ({title})**: `{ModelName}.{field}` already defined — agent just needs to {display/use} it

### Routes to wire (for integrator)
Add to app_router.dart:
- `{path}` → {ScreenName}

### Deferred to downstream issues
- {Feature} (#{N})
- {Feature} (#{N})

### Acceptance criteria
- [x] {criterion}
- [x] {criterion}
```

## Quality Bar

Do not report complete until all of these pass:

- [ ] Every acceptance criteria checkbox from the GitHub issue is met
- [ ] Every screen has skeleton + error + empty states
- [ ] `flutter analyze` shows zero warnings
- [ ] Model includes all fields needed by downstream issues
- [ ] Provider stubs exist for all methods downstream issues will call
- [ ] PR hand-off notes written

## How to Find Spec References for Any Issue

The GitHub issue's **Key references** section lists exact doc + section numbers.
When in doubt, the Sprint Plan (`HomeTrack_Sprint_Plan.md`) is the source of truth —
find the chunk matching the issue title, read its "Key references" field.

All spec docs live in `keystona-project-files/`:
```
HomeTrack_SRS.md                  — requirements, design system
HomeTrack_Database_Schema.md      — all tables, RLS, storage buckets
HomeTrack_API_Contract.md         — all queries and Edge Functions
HomeTrack_Sprint_Plan.md          — phases, chunks, acceptance criteria
HomeTrack_Platform_UI_Guide.md    — adaptive widget matrix
HomeTrack_Performance_Guide.md    — time budgets, caching rules
HomeTrack_Error_Handling.md       — loading/error/empty/form/offline patterns
HomeTrack_Empty_States_Catalog.md — exact copy for all 25 empty states
HomeTrack_Security_Guide.md       — auth, PII, validation checklist
HomeTrack_Dashboard_Spec.md       — Home tab (Phase 3+)
HomeTrack_Health_Score_Algorithm.md — scoring formula (Phase 3+)
HomeTrack_Dashboard_States.md     — 8 dashboard states (Phase 3+)
HomeTrack_Notification_Priority.md — notification tiers (Phase 7)
```
