---
name: flutter-agent
description: Use this skill whenever writing Flutter/Dart code for the HomeTrack (Keystona) app. This includes building screens, widgets, forms, navigation, state management, or any UI component. Trigger this skill for ANY Flutter code — even small fixes, new widgets, or refactors. It encodes the project's iOS-first adaptive widget strategy, Keystona design system, Riverpod patterns, performance requirements, and Error Handling patterns. Also trigger when the user mentions 'build a screen', 'create a widget', 'Flutter code', 'Dart code', 'UI component', 'adaptive widget', or anything related to the mobile app frontend.
---

# Flutter Agent Skill — HomeTrack (Keystona)

## Core Identity

HomeTrack is a Flutter mobile app (iOS + Android) for home management. Brand name: **Keystona**. Every piece of Flutter code must follow these conventions.

## Critical Rules (Never Violate)

1. **iOS-first adaptive widgets.** Use Cupertino on iOS, Material on Android for ALL platform components. See Platform UI Guide for the complete component matrix.
2. **Performance: under 1 second.** Every interaction. No exceptions. See Performance Guide for budgets.
3. **`const` everywhere.** Every `StatelessWidget` gets a `const` constructor. Every literal `EdgeInsets`, `BorderRadius`, `TextStyle`, `SizedBox` is `const`.
4. **`CachedNetworkImage` only.** Never use `Image.network`. Always provide explicit dimensions.
5. **Skeleton loading on every screen.** Show skeleton immediately on frame 1. Never show blank screens.
6. **Snackbar for errors.** 4-second auto-dismiss, optional action button. See Error Handling Guide.

## Design System — Keystona Premium Home Theme

```dart
// Colors
Deep Navy:      #1A2B4A  (primary, headers, text)
Gold Accent:    #C9A84C  (CTAs, active tab, highlights)
Warm Off-White: #FAF8F5  (backgrounds)
Error Red:      #D32F2F
Success Green:  #2E7D32
Warning Amber:  #F57C00
Skeleton Gray:  #E0E0E0

// Typography
Headlines: Outfit (Bold) — via google_fonts
Body text: Plus Jakarta Sans (Regular) — via google_fonts
iOS override: SF Pro Display (headings), SF Pro Text (body)

// Spacing
Base unit: 4px
Standard padding: 16px
Card padding: 16px
Section spacing: 24px
Screen horizontal padding: 16px
Border radius (cards): 12px
Border radius (buttons): 8px
Border radius (badges): 4px
```

## File Structure

Every feature lives in its own directory:

```
lib/features/{feature_name}/
├── screens/          — Full page screens
├── widgets/          — Feature-specific widgets
├── providers/        — Riverpod providers for this feature
├── models/           — Data models/DTOs
└── services/         — Feature-specific business logic (if needed)
```

Shared code lives in:
```
lib/core/widgets/     — Shared UI components
lib/core/utils/       — Formatters, validators, helpers
lib/services/         — Supabase, auth, storage, connectivity
lib/core/theme/       — AppColors, AppTextStyles, AppTheme
```

**Rule:** Agents work only in their feature directory. Modifications to `lib/core/`, `lib/services/`, or `lib/router/` require integrator approval.

## Riverpod Patterns

```dart
// ✅ Use code generation style
@riverpod
Future<List<Document>> documents(DocumentsRef ref) async {
  final propertyId = ref.watch(currentPropertyProvider);
  return ref.watch(supabaseProvider)
    .from('documents')
    .select('id, name, category_id, thumbnail_path, created_at')
    .eq('property_id', propertyId)
    .is_('deleted_at', null)
    .order('created_at', ascending: false);
}

// ✅ Use .select() to minimize rebuilds
final count = ref.watch(tasksProvider.select((t) => t.length));

// ✅ Use ref.read in event handlers (not ref.watch)
onTap: () => ref.read(tasksProvider.notifier).complete(id);

// ✅ Use autoDispose for screen-specific providers
```

## Adaptive Widget Usage

Always use pre-built adaptive helpers from `lib/core/widgets/adaptive/`:

```dart
// Date picker
final date = await showAdaptiveDatePicker(context);

// Alert dialog
final confirmed = await showAdaptiveAlert(
  context: context,
  title: 'Delete document?',
  message: 'This can\'t be undone.',
  confirmText: 'Delete',
  cancelText: 'Cancel',
);

// Action sheet
final choice = await showAdaptiveActionSheet(
  context: context,
  title: 'Upload from',
  options: [camera, photoLibrary, files],
);
```

**Never write platform checks directly.** Use the adaptive helpers.

**iOS-specific patterns:**
- Large collapsing titles on list screens (`CupertinoSliverNavigationBar`)
- Nav bar "+" button instead of FAB
- `CupertinoPageRoute` for page transitions
- `GestureDetector` instead of `InkWell` (no ripple on iOS)
- `CupertinoSliverRefreshControl` for pull-to-refresh

## Screen Template

Every screen follows this structure:

```dart
class DocumentListScreen extends ConsumerWidget {
  const DocumentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDocs = ref.watch(documentsProvider);

    return AppScaffold(
      title: 'Documents',
      trailing: AddButton(onTap: () => context.push('/documents/upload')),
      body: asyncDocs.when(
        loading: () => const DocumentListSkeleton(),
        error: (e, s) => ErrorView(
          message: 'Couldn\'t load documents.',
          onRetry: () => ref.invalidate(documentsProvider),
        ),
        data: (docs) => docs.isEmpty
          ? const DocumentsEmptyState()
          : DocumentListView(documents: docs),
      ),
    );
  }
}
```

**Every screen MUST have:**
- Skeleton loading state (matching content layout)
- Error state with retry
- Empty state matching the **Empty States Catalog** exactly (pattern, copy, icon, CTA). Do not improvise empty state copy.
- Pull-to-refresh (if scrollable list)

## Performance Checklist

Before submitting any code:
- [ ] All widgets that can be `const` ARE `const`
- [ ] No `Image.network` — all use `CachedNetworkImage` with explicit dimensions
- [ ] Lists use `.builder()` constructors
- [ ] Database queries select only needed columns
- [ ] No N+1 queries
- [ ] Search is debounced (300ms)
- [ ] `RepaintBoundary` on complex paint widgets
- [ ] Scrolling is 60fps in profile mode

## Key Project References

For detailed specifications, consult these project documents:
- **Platform UI Compliance Guide** — Complete component matrix, Apple HIG rules, 5-tab navigation
- **Performance & Optimization Guide** — Time budgets, caching, widget optimization
- **Error Handling Guide** — Error display patterns, loading states, empty states, form validation
- **Sprint Plan** — Feature acceptance criteria, deliverables, and cross-reference table to spec docs
- **SRS** — Design system specifications, accessibility requirements
- **Dashboard Spec** — Home tab section layout, hero card, quick actions, insights, urgent banner, onboarding setup checklist, task relevance model
- **Health Score Algorithm** — Three-pillar scoring formula (maintenance 50%, documents 30%, emergency 20%), overdue penalties, trend calculation, expanded `get_home_health_score` RPC contract
- **Empty States Catalog** — Exact empty state pattern, copy, icons, and CTA for every screen (25 total). Reference this before building ANY screen's empty state.
- **Dashboard State Variations** — 8 dashboard states with section visibility matrix. Reference when building the Home tab.
- **Notification Priority** — P1/P2/P3 tier system, daily digest, back-off rules, per-task muting, quiet hours. Reference when building Phase 7.
- **Security Guide** — Auth flow rules, input validation, PII handling, Sentry configuration, pre-deployment security checklist. Reference before writing ANY code that touches auth, data, or network.