---
name: plan-and-build
description: Use this skill before building any feature issue for Keystona. Combines planning (with look-ahead at dependent issues) and building into one workflow. Trigger whenever the user says 'plan and build issue X', 'start issue X', 'build issue #N', or before implementing any chunk from the Sprint Plan. Produces a written plan approved by the user BEFORE writing any code, with architecture decisions that account for all issues that depend on this one.
---

# Plan-and-Build Skill — Keystona

## Your Role

You plan before you build. You look ahead before you plan.

The output of this skill is:
1. A written implementation plan, approved by the user
2. A complete feature implementation that accounts for all dependent issues

## Step 1 — Issue Intake

Read the target issue from GitHub:

```bash
gh issue view {issue_number} --repo CalebTB/Keystona
```

Extract:
- Acceptance criteria
- Spec sections referenced (Key references)
- Which issues this depends on (Depends on)

## Step 2 — Look-Ahead Analysis

Find every issue that depends on the current one. These are "downstream issues."

**For the current issue**, scan all open Phase 1 issues:
```bash
gh issue list --repo CalebTB/Keystona --label phase-1 --state open
```

Read each dependent issue:
```bash
gh issue view {downstream_issue_number} --repo CalebTB/Keystona
```

For each downstream issue, extract:
- What **model fields** it will need (look at its acceptance criteria and spec references)
- What **provider methods** it will call (create, read, update, delete, search, etc.)
- What **routes** it will add under the current feature
- What **shared widgets** it will reuse

**Produce a look-ahead summary:**
```
Downstream issues analysis:
- #21 (Upload): needs Document.categoryId, Document.thumbnailPath, provider.add()
- #22 (Detail): needs Document.expirationDate, provider.getById(), provider.softDelete(), provider.update()
- #23 (Search): needs provider.search(query), debounce pattern
- #25 (Categories): needs DocumentCategory model, category provider
```

## Step 3 — Spec Research

Read all spec sections referenced across the current issue AND downstream issues.

Minimum reads:
- `keystona-project-files/HomeTrack_API_Contract.md` — your feature's section
- `keystona-project-files/HomeTrack_Database_Schema.md` — the tables you'll query
- `keystona-project-files/HomeTrack_Error_Handling.md` — your feature's edge cases (Section 14)
- `keystona-project-files/HomeTrack_Empty_States_Catalog.md` — exact empty state copy
- `keystona-project-files/HomeTrack_Platform_UI_Guide.md` — adaptive components

Also explore existing code for patterns:
```
lib/features/auth/         — screen structure, ConsumerStatefulWidget, form patterns
lib/core/theme/            — design tokens
lib/core/widgets/          — shared widgets available
lib/core/router/app_router.dart — how routes are wired
```

## Step 4 — Write the Plan

Write a complete implementation plan. Structure it as:

```markdown
# Plan: [Issue Title]

## Architecture Decisions
Decisions made now to support downstream issues, with rationale:
- **Decision**: [What] → because [downstream issue #X] will need [Y]

## Model Design
Complete model with ALL fields needed by current + downstream issues.
Fields marked: [current] or [for #21] etc.

## Provider Interface
All methods the current AND downstream issues will call, defined as stubs now.
Current issue implements them; downstream issues fill in the stubs.

## File Structure
Exact files to create in lib/features/documents/:
- models/document.dart
- models/document_category.dart
- providers/documents_provider.dart
- providers/document_categories_provider.dart
- screens/documents_screen.dart
- widgets/document_card.dart
- widgets/document_list_skeleton.dart
- widgets/document_empty_state.dart

## Screen Build Order
Step-by-step order to build each piece.

## Acceptance Criteria Checklist
Every checkbox from the GitHub issue.

## Extension Points for Downstream
Explicit notes for agents building dependent issues:
- "Agent building #21: call `documentsProvider.notifier.add(doc)` — method stub is ready"
- "Agent building #22: `Document.thumbnailPath` field already defined — just display it"
```

**Show the plan to the user and wait for approval before writing any code.**

Ask:
> "Here's the plan for #[N]. Does this look right before I start building?"

## Step 5 — Build

Only after plan approval, execute the plan from feature-agent guidelines:

### Build order (never skip steps)
1. **Models** — Dart data classes with all fields (current + downstream)
2. **Providers** — AsyncNotifier with all methods (current implemented, downstream stubbed)
3. **Skeleton widget** — loading state matching real card layout
4. **Empty state widget** — exact copy from Empty States Catalog
5. **List/detail widgets** — content display
6. **Screen widget** — `.when(loading/error/data)` combining all above
7. **Form widgets** — create/edit with validation

### Non-negotiable screen requirements
Every screen must have before it is considered done:
- Skeleton loading (pulse animation, layout matching)
- Error state with retry button
- Empty state (motivational for primary, instructional for sub-screens)
- Pull-to-refresh on scrollable lists
- `const` on every widget that can be const

### After building
Run:
```bash
flutter analyze
```
Zero warnings = required. Fix any issues before reporting done.

## Step 6 — Hand-off Notes

After building, produce a hand-off comment for the PR:

```markdown
## Built: [Issue Title]

### Extension points for dependent issues
- **#21 (Upload)**: `DocumentsProvider.add(doc)` method is stubbed at line X — implement the Supabase insert
- **#22 (Detail)**: `Document` model has all fields needed — `thumbnailPath`, `expirationDate`, `linkedSystemId`
- **#23 (Search)**: `DocumentsProvider` accepts optional `searchQuery` param — hook up Supabase ilike query
- **#25 (Categories)**: `DocumentCategory` model and `documentCategoriesProvider` already exist

### Routes to wire (for integrator)
Add to app_router.dart under the documents branch:
- `/documents/upload` → DocumentUploadScreen
- `/documents/:documentId` → DocumentDetailScreen

### Deferred to downstream issues
- OCR text display (#26)
- Full-text search (#23)
- Category management UI (#25)
```

## Quality Bar

Do not report complete until:
- [ ] All acceptance criteria from the GitHub issue are met
- [ ] Every screen has skeleton + error + empty states
- [ ] `flutter analyze` is clean
- [ ] Model includes fields needed by all downstream issues
- [ ] Provider includes stub methods for all downstream issues
- [ ] Hand-off notes written

## Feature Reference Table

| Issue | Phase | API Contract | DB Tables | Error Handling |
|-------|-------|-------------|-----------|----------------|
| #20 Doc List | 1.1 | §6.1 | documents, document_categories | §§3–4, 14.1 |
| #21 Doc Upload | 1.2 | §6.4 | documents, document_categories | §§10–11 |
| #22 Doc Detail | 1.3 | §§6.2, 6.5–6.7 | documents | §§3, 7 |
| #23 Search | 1.4 | §6.3 | documents | §10 |
| #24 Expiration | 1.5 | §6.8 | documents | §§3–4 |
| #25 Categories | 1.6 | §§6.9–6.11 | document_categories | §14.1 |
| #26 OCR | 1.7 | §14.2 | documents | §14.1 |
