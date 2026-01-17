# Feature Implementation Checklist

Use this checklist for every new feature to ensure nothing is missed.

## Phase 1: Planning ✓
- [ ] Read feature specification
- [ ] Identify dependencies (existing features, APIs, etc.)
- [ ] Review database schema requirements
- [ ] Plan navigation integration points
- [ ] Create implementation plan

## Phase 2: Data Layer ✓
- [ ] Apply database migrations via Supabase MCP
- [ ] Create data models with proper serialization
- [ ] Implement service layer with error handling
- [ ] Create Riverpod providers
- [ ] Add shared error classes if needed

## Phase 3: UI Layer ✓
- [ ] Create screen widgets
- [ ] Create reusable widgets/components
- [ ] Implement forms with validation
- [ ] Add loading and error states
- [ ] Follow design system (colors, spacing, typography)

## Phase 4: Navigation Integration ⭐ CRITICAL
- [ ] **Identify entry point(s)** - Where should users access this feature?
- [ ] **Add import statements** in parent screens
- [ ] **Add navigation UI elements** (buttons, cards, list tiles)
- [ ] **Pass required parameters** (IDs, objects, etc.)
- [ ] **Test navigation flow** from entry point to all screens
- [ ] **Verify back button** behavior
- [ ] **Document navigation path** in PR description

## Phase 5: Testing ✓
- [ ] Run `flutter analyze` - fix all issues
- [ ] Manual testing:
  - [ ] Can access feature from main UI flow (not just code)
  - [ ] All CRUD operations work
  - [ ] Error messages display correctly
  - [ ] Loading states show appropriately
  - [ ] Back navigation preserves state
- [ ] Test on different screen sizes (if applicable)
- [ ] Test offline behavior (if applicable)

## Phase 6: Documentation ✓
- [ ] Update CLAUDE.md if new patterns introduced
- [ ] Add navigation path to PR description
- [ ] Document any configuration needed (.env, etc.)
- [ ] Add screenshots to PR (before/after if applicable)

## Phase 7: PR Submission ✓
- [ ] Commit with descriptive message
- [ ] Push to feature branch
- [ ] Create PR with:
  - [ ] Summary of changes
  - [ ] Navigation path explanation
  - [ ] Testing checklist
  - [ ] Screenshots
- [ ] Request review

---

## Common Pitfalls to Avoid

❌ **Building screens without navigation** - Always add navigation in Phase 4
❌ **Skipping flutter analyze** - Catches type errors and deprecations
❌ **Not testing the full user journey** - Always navigate from entry point
❌ **Forgetting to pass parameters** - Test with real data, not hardcoded values
❌ **Not documenting navigation** - Future developers need to know how to access features

## Navigation Integration Patterns

### Property-Related Features
**Entry Point:** `PropertyDetailScreen`
```dart
Card(
  child: ListTile(
    leading: const Icon(Icons.feature_icon),
    title: const Text('Feature Name'),
    subtitle: const Text('Brief description'),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FeatureScreen(propertyId: propertyId),
      ),
    ),
  ),
)
```

### User-Level Features
**Entry Point:** Main navigation drawer
```dart
ListTile(
  leading: const Icon(Icons.feature_icon),
  title: const Text('Feature Name'),
  onTap: () => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => FeatureScreen()),
  ),
)
```

### List Screen with Add Button
**Entry Point:** Parent screen + FAB
```dart
floatingActionButton: FloatingActionButton.extended(
  onPressed: () => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CreateScreen(parentId: parentId),
    ),
  ),
  icon: const Icon(Icons.add),
  label: const Text('Add Item'),
),
```

---

## Quick Verification

Before submitting PR, answer these questions:

1. ✅ Can a user access this feature without modifying code?
2. ✅ Does the navigation make logical sense in the app structure?
3. ✅ Are all required parameters passed correctly?
4. ✅ Does the back button work as expected?
5. ✅ Is the navigation path documented in the PR?

If you answered "No" to any question, fix it before submitting!

---

**Remember:** Navigation integration is not optional - it's a core requirement for every UI feature.
