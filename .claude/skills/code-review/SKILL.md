---
name: code-review
description: Use this skill whenever reviewing Flutter/Dart code, Supabase queries, Edge Functions, or any code submitted by an agent for the HomeTrack (Keystona) app. Trigger when the user says 'review this code', 'check this feature', 'is this ready to merge', 'audit this PR', 'review agent output', 'code review', or when evaluating any code against project standards. Also trigger when looking at existing code to assess quality, find bugs, or suggest improvements. This skill provides a comprehensive checklist covering performance, platform compliance, security, error handling, and code conventions.
---

# Code Review Skill — HomeTrack (Keystona)

## Review Process

When reviewing code, run through these checklists in order. Flag issues as:
- 🔴 **Blocker** — Must fix before merge. App will break, be rejected, or have security issues.
- 🟡 **Warning** — Should fix. Performance impact, UX issue, or convention violation.
- 🟢 **Suggestion** — Nice to have. Cleaner code, better pattern, minor improvement.

## Checklist 1: Platform Compliance (App Store Rejection Risk)

| Check | What to Look For | Severity |
|-------|-----------------|----------|
| Date pickers | `CupertinoDatePicker` on iOS, never `showDatePicker` on iOS | 🔴 Blocker |
| Alert dialogs | `CupertinoAlertDialog` on iOS, never `AlertDialog` on iOS | 🔴 Blocker |
| Action sheets | `CupertinoActionSheet` on iOS, never bare `ModalBottomSheet` for pickers | 🔴 Blocker |
| Spinners | `.adaptive()` constructor used | 🟡 Warning |
| Switches | `Switch.adaptive()` used | 🟡 Warning |
| FAB on iOS | No `FloatingActionButton` on iOS — use nav bar button | 🔴 Blocker |
| Back gesture | `CupertinoPageRoute` on iOS (not `MaterialPageRoute`) | 🔴 Blocker |
| Large titles | List screens use `CupertinoSliverNavigationBar` on iOS | 🟡 Warning |
| Touch feedback | `GestureDetector` on iOS (no ripple), `InkWell` on Android | 🟡 Warning |
| Safe area | All screens wrapped in `SafeArea` or `AppScaffold` | 🔴 Blocker |
| Pull-to-refresh | `CupertinoSliverRefreshControl` on iOS | 🟡 Warning |

**Quick test:** Search for `Platform.isIOS` — if there are direct platform checks in feature code (not in adaptive helpers), flag them. Agents should use pre-built adaptive widgets.

## Checklist 2: Performance

| Check | What to Look For | Severity |
|-------|-----------------|----------|
| `Image.network` | Any usage → must be `CachedNetworkImage` | 🔴 Blocker |
| Image dimensions | All images have explicit width/height (no layout shift) | 🔴 Blocker |
| `select('*')` on lists | List queries must specify exact columns | 🟡 Warning |
| N+1 queries | Multiple sequential Supabase calls for related data → use nested select | 🔴 Blocker |
| Missing pagination | List queries without `.range()` or `.limit()` | 🟡 Warning |
| `const` constructors | `StatelessWidget` without `const` constructor | 🟡 Warning |
| `const` literals | `EdgeInsets`, `BorderRadius`, `TextStyle`, `SizedBox` without `const` | 🟡 Warning |
| `.builder()` lists | `ListView` or `GridView` without `.builder()` for dynamic lists | 🔴 Blocker |
| Debounced search | Search text field without debounce (300ms minimum) | 🔴 Blocker |
| `RepaintBoundary` | Complex `CustomPainter` widgets without `RepaintBoundary` | 🟡 Warning |
| `ref.watch` in handlers | `ref.watch` inside `onTap` or `onPressed` (should be `ref.read`) | 🔴 Blocker |
| Provider scope | Watching an entire provider when only one field is needed (use `.select()`) | 🟡 Warning |

## Checklist 3: Error Handling & UX

| Check | What to Look For | Severity |
|-------|-----------------|----------|
| Missing skeleton | Screen has no loading state or uses `CircularProgressIndicator` alone | 🔴 Blocker |
| Missing empty state | List screen with no empty state widget | 🔴 Blocker |
| Missing error state | `asyncValue.when()` without error handler, or error handler that just shows text | 🟡 Warning |
| Snackbar for errors | Errors shown via `AlertDialog` instead of snackbar | 🟡 Warning |
| Undo on delete | Soft delete without undo snackbar | 🟡 Warning |
| Form validation | No `validator` on required `TextFormField` inputs | 🔴 Blocker |
| Validation timing | Validation only on submit (should also be on blur for required fields) | 🟡 Warning |
| Save button spinner | Save button doesn't show loading state while saving | 🟡 Warning |
| Free tier check | Create action without checking tier limits first | 🔴 Blocker |
| Offline handling | No connectivity check before network calls (non-Emergency features) | 🟡 Warning |

## Checklist 4: Security & Data

| Check | What to Look For | Severity |
|-------|-----------------|----------|
| Missing `property_id` filter | Query doesn't filter by `property_id` | 🔴 Blocker |
| Missing `deleted_at` filter | Query on soft-delete table without `.is_('deleted_at', null)` | 🔴 Blocker |
| Hardcoded user ID | User ID hardcoded or passed from client for auth (should use `auth.uid()` in RLS) | 🔴 Blocker |
| Sensitive data in logs | `print()` or `debugPrint()` with user data left in code | 🟡 Warning |
| Missing error catch | Supabase calls without try/catch | 🟡 Warning |
| Storage path structure | File uploads not following `{userId}/{propertyId}/filename` pattern | 🔴 Blocker |
| Signed URL caching | Signed URLs cached beyond 1 hour (they expire) | 🟡 Warning |

## Checklist 5: Code Quality

| Check | What to Look For | Severity |
|-------|-----------------|----------|
| File location | Code in wrong directory (e.g., feature code in `lib/core/`) | 🟡 Warning |
| Widget extraction | Build methods returning widgets instead of extracted widget classes | 🟡 Warning |
| Magic numbers | Hardcoded dimensions, durations, or limits without constants | 🟡 Warning |
| Missing `key` | Widgets in lists without proper `key` parameter | 🟡 Warning |
| Dead code | Commented-out code or unused imports | 🟡 Warning |
| Naming conventions | Files not in `snake_case`, classes not in `PascalCase` | 🟡 Warning |
| `mounted` check | `setState` or `context` usage after async gap without `mounted` check | 🔴 Blocker |
| Disposed controller | `TextEditingController` or `ScrollController` not disposed | 🟡 Warning |

## Checklist 6: Completeness

| Check | What to Look For | Severity |
|-------|-----------------|----------|
| Acceptance criteria | All boxes from Sprint Plan chunk checked | 🔴 Blocker |
| Edge cases | All edge cases from Error Handling Guide Section 14.X handled | 🟡 Warning |
| Routes provided | Agent delivered list of routes to add to router | 🟡 Warning |
| Shared code flagged | Agent documented any shared code they needed or created | 🟡 Warning |
| Widget tests | At minimum: list screen, detail screen, create form | 🟡 Warning |
| `flutter analyze` | Zero warnings | 🔴 Blocker |
| `flutter test` | All tests pass | 🔴 Blocker |

## Review Output Format

After reviewing, provide a summary:

```
## Code Review: {Feature Name}

### Summary
{1-2 sentence overview}

### 🔴 Blockers ({count})
1. {file}:{line} — {description} — {fix}
2. ...

### 🟡 Warnings ({count})
1. {file}:{line} — {description} — {fix}
2. ...

### 🟢 Suggestions ({count})
1. {file}:{line} — {description}
2. ...

### Verdict
- [ ] ✅ Ready to merge
- [ ] 🔄 Needs fixes (blockers must be resolved)
- [ ] ❌ Needs significant rework
```

## Common Patterns to Watch For

### The "It Works But..." Pattern
Code that functions but violates project conventions. Example: Material date picker on iOS that works fine but will get rejected by Apple.

### The "Forgot the Edge Case" Pattern
Happy path works, but what happens when: the list is empty, the network is down, the user is on free tier, the file is too large, the data was deleted by another device?

### The "Premature Optimization" Pattern
Complex caching or state management when a simple query would be under budget. Don't over-engineer — but don't under-engineer either.

### The "Copy-Paste Drift" Pattern
Code copied from another feature that still references the wrong table, wrong route, or wrong model. Search for the original feature name in the new code.