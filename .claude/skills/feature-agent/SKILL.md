---
name: feature-agent
description: Use this skill whenever building a complete feature or feature chunk for the HomeTrack (Keystona) app. This is the master orchestration skill that tells an agent everything it needs to know to build a feature from start to finish — file structure, what to deliver, how to handle errors, how to test, and how to hand off. Trigger whenever the user says 'build the Document Vault', 'implement maintenance calendar', 'create the projects feature', 'work on emergency hub', 'build home profile', or any instruction to implement a feature or feature chunk from the Sprint Plan. Also trigger for 'implement feature X', 'start building X', or 'agent assignment for X'.
---

# Feature Agent Skill — HomeTrack (Keystona)

## Your Role

You are an agent building one feature of the HomeTrack app. You receive a feature assignment, build it in your feature directory, and deliver a complete, tested, polished feature that meets the acceptance criteria.

**You are NOT building the whole app.** Other agents are building other features in parallel. Stay in your lane.

## Before You Write Any Code

1. **Read the Sprint Plan** — Find your feature's phase. Read every chunk's acceptance criteria.
2. **Read the API Contract** — Find your feature's section. These are the exact queries you'll write.
3. **Read the Error Handling Guide** — Find your feature's edge cases (Section 14). Follow all UI patterns.
4. **Read the Platform UI Guide** — Know which components must be adaptive (iOS/Android).
5. **Read the Performance Guide** — Know the time budgets and optimization rules.

## Feature Directory Structure

```
lib/features/{your_feature}/
├── screens/
│   ├── {feature}_list_screen.dart
│   ├── {feature}_detail_screen.dart
│   ├── {feature}_create_screen.dart
│   └── {feature}_edit_screen.dart
├── widgets/
│   ├── {feature}_card.dart
│   ├── {feature}_list_skeleton.dart
│   ├── {feature}_empty_state.dart
│   └── ... (feature-specific widgets)
├── providers/
│   ├── {feature}_provider.dart
│   ├── {feature}_detail_provider.dart
│   └── ... (Riverpod providers)
├── models/
│   ├── {feature}_model.dart
│   └── ... (data classes / DTOs)
└── services/
    └── {feature}_service.dart  (if needed — business logic)
```

## Every Screen Must Have

This is non-negotiable. A screen without these is not complete.

### 1. Skeleton Loading State
Gray placeholder shapes matching the content layout. Pulse animation. Shows immediately on frame 1.

```dart
asyncData.when(
  loading: () => const FeatureListSkeleton(),  // ← required
  error: (e, s) => ErrorView(onRetry: () => ref.invalidate(provider)),
  data: (items) => items.isEmpty
    ? const FeatureEmptyState()
    : FeatureListView(items: items),
);
```

### 2. Error State with Retry
Full-screen error with icon, message, and retry button.

### 3. Empty State
- **Motivational** for primary screens (Document Vault, Maintenance, Emergency Hub, Projects): illustration + headline + subtitle + CTA button
- **Instructional** for sub-screens (search results, completion history, budget items): simple icon + message

### 4. Pull-to-Refresh (if scrollable list)
Uses adaptive refresh control (Cupertino on iOS, Material on Android).

### 5. Adaptive Navigation
- iOS: Large collapsing title, nav bar buttons, `CupertinoPageRoute`
- Android: `SliverAppBar`, FAB, `MaterialPageRoute`

## The Standard Screen Build Order

For each screen in your feature, build in this order:

```
1. Model/DTO           → Data class matching the database table columns you need
2. Provider            → Riverpod provider that fetches/manages the data
3. Skeleton widget     → Loading state matching the screen layout
4. Empty state widget  → Motivational or instructional variant
5. List/detail widget  → The actual content display
6. Screen widget       → Combines provider + skeleton + empty + content with .when()
7. Form widgets        → Create/edit forms with validation
8. Error handling      → Snackbar errors, form validation, edge cases
```

## Data Flow Pattern

```
Screen (ConsumerWidget)
  → watches Provider (Riverpod)
    → calls Service or Supabase directly
      → returns Model
        → Screen renders with .when(loading/error/data)
```

## Form Patterns

### Validation Rules (from Error Handling Guide)

- **On blur:** Required fields, email format, phone format
- **On change:** Character counters, slider values
- **On submit:** All fields validated together
- **Show errors inline** below the field, red text, with specific message

### Save Pattern

```dart
Future<void> onSave() async {
  if (!formKey.currentState!.validate()) return;

  setState(() => isSaving = true);  // Button shows spinner

  try {
    await ref.read(featureProvider.notifier).create(formData);
    if (mounted) {
      context.pop();  // Return to list
      showSuccessSnackbar('Document saved');
    }
  } catch (e) {
    showErrorSnackbar('Couldn\'t save. Please try again.');
  } finally {
    if (mounted) setState(() => isSaving = false);
  }
}
```

## Free Tier Gating

Check limits BEFORE showing the create form, not after the user fills it out.

```dart
// ✅ Check before navigating to create screen
void onAddTapped() async {
  final count = await ref.read(featureCountProvider.future);
  final tier = ref.read(subscriptionTierProvider);

  if (tier == 'free' && count >= freeLimit) {
    showUpgradeSheet(context, feature: 'documents');
    return;
  }

  context.push('/documents/upload');
}
```

| Feature | Free Limit | Premium |
|---------|-----------|---------|
| Documents | 25 | Unlimited |
| Projects | 2 | Unlimited |
| OCR Search | Name/category only | Full-text |
| Household Members | 1 (self) | Up to 6 |

## Destructive Actions

Always use a confirmation dialog, then undo snackbar.

```dart
// 1. Confirm with adaptive alert dialog
final confirmed = await showAdaptiveAlert(
  context: context,
  title: 'Delete "$name"?',
  message: 'This can be undone for 5 seconds.',
  confirmText: 'Delete',
  cancelText: 'Cancel',
);

if (confirmed != true) return;

// 2. Optimistic delete with undo
ref.read(featureProvider.notifier).softDelete(id);
showUndoSnackbar(
  message: '"$name" deleted',
  onUndo: () => ref.read(featureProvider.notifier).restore(id),
);
```

## What to Deliver

When your feature is complete, deliver:

### Code
- [ ] All screens in `lib/features/{feature}/screens/`
- [ ] All widgets in `lib/features/{feature}/widgets/`
- [ ] All providers in `lib/features/{feature}/providers/`
- [ ] All models in `lib/features/{feature}/models/`

### Tests
- [ ] Widget tests for list screen (skeleton, empty, data states)
- [ ] Widget tests for detail screen
- [ ] Widget tests for create/edit form (validation)
- [ ] Provider tests (data loading, error handling)

### Documentation
- [ ] List of routes that need to be added to the router
- [ ] List of any shared code you created or needed from `lib/core/`
- [ ] List of any Edge Functions or RPCs your feature depends on
- [ ] Any deviations from the Sprint Plan with justification

## What NOT to Touch

These require integrator approval first:
- `lib/core/` — Flag what's missing, propose the change
- `lib/services/` — Flag what method is needed
- `lib/router/` — Provide routes, integrator adds them
- `supabase/migrations/` — Describe the change needed
- Any other agent's feature directory

## Quality Bar

Your feature is NOT complete until:
- [ ] Every screen has skeleton + error + empty states
- [ ] All acceptance criteria from Sprint Plan are met
- [ ] All edge cases from Error Handling Guide are handled
- [ ] Platform-native components used per Platform UI Guide
- [ ] Performance checklist from Performance Guide passes
- [ ] `flutter analyze` shows no warnings
- [ ] `flutter test` passes all tests

## Feature-Specific References

| Feature | Sprint Plan | API Contract | Error Handling | Key Tables |
|---------|------------|-------------|----------------|------------|
| Document Vault | Phase 1 (1.1–1.7) | Section 6 | Section 14.1 | documents, doc_categories, doc_types |
| Maintenance | Phase 2 (2.1–2.6) | Section 9 | Section 14.2 | maintenance_tasks, task_completions, task_templates |
| Home Profile | Phase 3 (3.1–3.4) | Sections 7–8 | Section 14.3 | home_systems, home_appliances |
| Emergency Hub | Phase 4 (4.1–4.5) | Section 10 | Section 14.4 | utility_shutoffs, emergency_contacts, insurance_info |
| Projects | Phase 5 (5.1–5.8) | Section 14 | Section 14.5 | projects, project_phases, project_budget_items, project_photos, project_notes, project_contractors, project_documents |