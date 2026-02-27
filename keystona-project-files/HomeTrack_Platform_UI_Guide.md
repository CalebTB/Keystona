# HomeTrack Platform UI Compliance Guide
## iOS-First Component Strategy for Flutter

**Version 1.0 | February 2026**
**Status:** Active — Every agent consults this before building any interactive component

---

## Table of Contents

1. [Philosophy](#1-philosophy)
2. [Apple HIG Requirements (Non-Negotiable)](#2-apple-hig-requirements)
3. [Component Decision Matrix](#3-component-decision-matrix)
4. [Navigation Patterns](#4-navigation-patterns)
5. [Input Components](#5-input-components)
6. [Feedback & Dialogs](#6-feedback--dialogs)
7. [Lists & Scrolling](#7-lists--scrolling)
8. [Custom Components (Safe on Both)](#8-custom-components)
9. [Platform Detection & Adaptive Widgets](#9-platform-detection--adaptive-widgets)
10. [App Store Rejection Risks](#10-app-store-rejection-risks)
11. [Android-Specific Considerations](#11-android-specific-considerations)
12. [Quick Reference Cheat Sheet](#12-quick-reference-cheat-sheet)

---

## 1. Philosophy

**iOS first.** Apple has strict Human Interface Guidelines (HIG) and actively rejects apps that violate them. Android's Material Design guidelines are recommendations, not enforcement criteria. Build to Apple's rules and Android follows naturally.

**The rule:** If Apple has a native component for it, use it on iOS. If it's a custom UI element unique to HomeTrack (cards, empty states, badges), build it once in Flutter and use it everywhere.

**Flutter makes this easy.** Many Flutter widgets have `.adaptive()` constructors that automatically render Cupertino (iOS-style) on iOS and Material on Android. Use these whenever available.

### Decision Framework

```
Is there an Apple HIG requirement for this component?
  → YES: Use CupertinoWidget on iOS, MaterialWidget on Android
  → NO: Continue ↓

Is there a Flutter .adaptive() constructor?
  → YES: Use it — automatic platform rendering
  → NO: Continue ↓

Is this a standard input/feedback component?
  → YES: Use Cupertino on iOS, Material on Android (manual platform check)
  → NO: Continue ↓

Is this a custom HomeTrack component (cards, badges, empty states)?
  → YES: Build once in Flutter, use on both platforms
```

---

## 2. Apple HIG Requirements (Non-Negotiable)

These are components where Apple **will reject your app** if you use non-native implementations.

### 2.1 Date & Time Pickers

**Apple requires:** Cupertino-style spinning wheel date/time picker. Using a Material calendar picker on iOS **will cause rejection**.

```dart
// ✅ CORRECT — iOS gets Cupertino, Android gets Material
import 'dart:io' show Platform;

Future<DateTime?> showAdaptiveDatePicker(BuildContext context) async {
  if (Platform.isIOS) {
    // Cupertino spinning wheel in a bottom sheet
    return showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            // Done/Cancel bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(child: Text('Cancel'), onPressed: () => Navigator.pop(context)),
                CupertinoButton(child: Text('Done'), onPressed: () => Navigator.pop(context, selectedDate)),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                onDateTimeChanged: (date) => selectedDate = date,
              ),
            ),
          ],
        ),
      ),
    );
  } else {
    // Material calendar picker for Android
    return showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
  }
}
```

**Used in HomeTrack:**
- Document expiration date
- System/appliance installation date, warranty expiry
- Maintenance task due date
- Project planned start/end dates
- Budget item paid date
- Insurance policy effective/expiration dates

### 2.2 Time Pickers

Same rule — Cupertino spinning wheel on iOS.

```dart
// ✅ CORRECT
if (Platform.isIOS) {
  CupertinoTimerPicker(...)  // or CupertinoDatePicker with time mode
} else {
  showTimePicker(...)         // Material time picker
}
```

**Used in HomeTrack:**
- Notification quiet hours start/end
- Preferred maintenance reminder time

### 2.3 Alert Dialogs

**Apple requires:** `CupertinoAlertDialog` on iOS. Material `AlertDialog` on iOS looks wrong and can trigger review issues.

```dart
// ✅ CORRECT — Adaptive alert dialog
Future<bool?> showAdaptiveAlert({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'OK',
  String? cancelText,
}) {
  if (Platform.isIOS) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (cancelText != null)
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text(cancelText),
              onPressed: () => Navigator.pop(context, false),
            ),
          CupertinoDialogAction(
            isDestructiveAction: confirmText == 'Delete',
            child: Text(confirmText),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  } else {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (cancelText != null)
            TextButton(child: Text(cancelText), onPressed: () => Navigator.pop(context, false)),
          TextButton(child: Text(confirmText), onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
  }
}
```

**Used in HomeTrack:**
- Delete confirmations (document, system, project)
- Discard unsaved changes confirmation
- Sign out confirmation
- Account deletion confirmation

### 2.4 Action Sheets

**Apple requires:** `CupertinoActionSheet` for multi-option choices presented from the bottom. Android uses Material bottom sheets.

```dart
// ✅ CORRECT — Adaptive action sheet
Future<String?> showAdaptiveActionSheet({
  required BuildContext context,
  required String title,
  required List<ActionSheetOption> options,
}) {
  if (Platform.isIOS) {
    return showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(title),
        actions: options.map((opt) => CupertinoActionSheetAction(
          isDestructiveAction: opt.isDestructive,
          child: Text(opt.label),
          onPressed: () => Navigator.pop(context, opt.value),
        )).toList(),
        cancelButton: CupertinoActionSheetAction(
          child: Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  } else {
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) => ListTile(
          title: Text(opt.label),
          onTap: () => Navigator.pop(context, opt.value),
        )).toList(),
      ),
    );
  }
}
```

**Used in HomeTrack:**
- Upload source picker (Camera, Photo Library, File Picker)
- Document actions (Share, Download, Edit, Delete)
- Photo type selection (Before, After, Progress)
- Sort options

### 2.5 Activity Indicator (Spinner)

```dart
// ✅ Use Flutter's adaptive constructor
CircularProgressIndicator.adaptive()
// Renders CupertinoActivityIndicator on iOS, CircularProgressIndicator on Android
```

### 2.6 Switches / Toggles

```dart
// ✅ Use Flutter's adaptive constructor
Switch.adaptive(
  value: isEnabled,
  onChanged: (value) => setState(() => isEnabled = value),
)
// Renders CupertinoSwitch on iOS, Material Switch on Android
```

**Used in HomeTrack:**
- Notification toggles (push, email)
- Is 24/7 available (emergency contacts)
- Is favorite toggle
- Is paid toggle (budget items)

### 2.7 Sliders

```dart
// ✅ Use adaptive
Slider.adaptive(
  value: rating,
  min: 1,
  max: 5,
  divisions: 4,
  onChanged: (value) => setState(() => rating = value),
)
```

### 2.8 Scrollbar

iOS uses a thin scrollbar that fades out. Android uses Material scrollbar. Flutter handles this automatically with `Scrollbar` widget, but explicit usage ensures correct behavior:

```dart
// ✅ Use CupertinoScrollbar on iOS
Platform.isIOS
  ? CupertinoScrollbar(child: listView)
  : Scrollbar(child: listView)
```

---

## 3. Component Decision Matrix

Complete reference for every UI component in HomeTrack.

### Must Be Platform-Native

| Component | iOS (Cupertino) | Android (Material) | Where Used |
|-----------|----------------|-------------------|------------|
| Date picker | `CupertinoDatePicker` | `showDatePicker` | Expiration, install, due dates |
| Time picker | `CupertinoDatePicker` (time mode) | `showTimePicker` | Quiet hours, reminder time |
| Alert dialog | `CupertinoAlertDialog` | `AlertDialog` | Delete, discard, sign out |
| Action sheet | `CupertinoActionSheet` | `ModalBottomSheet` | Upload source, sort, actions |
| Context menu | `CupertinoContextMenu` | Long-press menu | Document/task long-press |
| Activity indicator | `CupertinoActivityIndicator` | `CircularProgressIndicator` | Button loading states |
| Switch/toggle | `CupertinoSwitch` | `Switch` | All boolean settings |
| Slider | `CupertinoSlider` | `Slider` | Rating, any range input |
| Search bar | `CupertinoSearchTextField` | `SearchBar` | Document search, contact search |
| Navigation bar | `CupertinoNavigationBar` | `AppBar` | All screen headers |
| Tab bar | `CupertinoTabBar` | `NavigationBar` | Bottom navigation |
| Pull-to-refresh | `CustomScrollView` + `CupertinoSliverRefreshControl` | `RefreshIndicator` | All list screens |

### Use Flutter `.adaptive()` (Automatic)

These have built-in adaptive constructors — use them and Flutter picks the right platform widget:

| Widget | Adaptive Constructor | Notes |
|--------|---------------------|-------|
| `Switch` | `Switch.adaptive()` | ✅ Always use |
| `Slider` | `Slider.adaptive()` | ✅ Always use |
| `CircularProgressIndicator` | `CircularProgressIndicator.adaptive()` | ✅ Always use |
| `Checkbox` | `Checkbox.adaptive()` | ✅ Use if checkboxes needed |
| `Radio` | `Radio.adaptive()` | ✅ Use if radio buttons needed |
| `Icon` | `Icon.adaptive()` | Not commonly used but available |

### Custom HomeTrack Components (Same on Both Platforms)

These are our brand components — no platform equivalent, safe to build once:

| Component | Implementation | Notes |
|-----------|---------------|-------|
| Document card | Custom `Card` widget | Thumbnail + metadata layout |
| Task card | Custom `Card` widget | Status badge + due date |
| Project card | Custom `Card` widget | Budget bar + cover photo |
| System/appliance card | Custom `Card` widget | Category icon + lifespan bar |
| Contact card | Custom `ListTile` variant | Avatar + phone + category |
| Status badges | Custom `Container` widget | Colored pills (overdue, expired, etc.) |
| Empty states | Custom composite widget | Illustration + text + CTA |
| Skeleton loaders | Custom `Shimmer` widget | Gray shapes with pulse animation |
| Snackbar | Custom `SnackBar` | Brand colors per Error Handling Guide |
| Upgrade sheet | Custom `BottomSheet` | Premium upsell per Error Handling Guide |
| Offline banner | Custom `Container` | Amber warning per Error Handling Guide |
| Health score gauge | Custom `CustomPainter` | Circular progress gauge |
| Lifespan bar | Custom `LinearProgressIndicator` | Green→amber→red gradient |
| Before/after slider | Custom `GestureDetector` + `ClipRect` | Photo comparison |
| Budget category chart | Custom or `fl_chart` | Category breakdown visual |
| Phase timeline | Custom vertical stepper | Project phase visualization |

---

## 4. Navigation Patterns

### 4.1 Bottom Tab Bar

```dart
// iOS-first approach: CupertinoTabBar-style behavior
// Uses GoRouter with StatefulShellRoute for tab persistence

// Visual behavior:
// iOS: Translucent bar, thin top border, SF Symbols-style icons
// Android: Material NavigationBar with filled icons
```

**Rules:**
- 5 permanent tabs: Home · Docs · Tasks · Projects · Settings
- All 5 tabs are always visible — Projects shows an empty state (Showcase pattern with ghosted example cards) when no projects exist. See Empty States Catalog §2.4.
- Emergency Hub is accessed via a quick-action button on the Home tab, not a dedicated tab
- Tab state preserved when switching (don't rebuild screens)
- Active tab: Gold Accent (`#C9A84C`) icon + label
- Inactive tab: Gray icon + label

### 4.2 Screen Navigation

**iOS patterns (non-negotiable on iOS):**
- Back swipe gesture (right edge → left) for going back — Flutter provides this by default with `CupertinoPageRoute`
- Large title style for primary screens (collapsing on scroll)
- No back button label on nav bar — just the chevron
- Modals slide up from bottom (not from right)

```dart
// ✅ Use CupertinoPageRoute on iOS for correct back gesture
if (Platform.isIOS) {
  Navigator.push(context, CupertinoPageRoute(builder: (_) => DetailScreen()));
} else {
  Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen()));
}

// Or configure GoRouter to use CupertinoPage on iOS:
GoRoute(
  path: '/documents/:id',
  pageBuilder: (context, state) {
    if (Platform.isIOS) {
      return CupertinoPage(child: DocumentDetailScreen(id: state.pathParameters['id']!));
    } else {
      return MaterialPage(child: DocumentDetailScreen(id: state.pathParameters['id']!));
    }
  },
)
```

### 4.3 Large Title Headers (iOS)

iOS apps use large titles that collapse on scroll. This is a strong HIG signal that says "this is a native app."

```dart
// ✅ iOS large title style
if (Platform.isIOS) {
  CupertinoSliverNavigationBar(
    largeTitle: Text('Documents'),
    trailing: CupertinoButton(
      padding: EdgeInsets.zero,
      child: Icon(CupertinoIcons.add),
      onPressed: onAdd,
    ),
  )
} else {
  SliverAppBar(
    title: Text('Documents'),
    floating: true,
    actions: [IconButton(icon: Icon(Icons.add), onPressed: onAdd)],
  )
}
```

**Screens that get large titles:**
- Document Vault list
- Maintenance Calendar list
- Home Profile overview
- Emergency Hub
- Projects list
- Settings

**Screens that get regular (small) titles:**
- Detail screens (document detail, task detail, system detail, project detail)
- Form screens (add/edit anything)
- Search screens

### 4.4 Modals vs Push

| Action | iOS | Android |
|--------|-----|---------|
| Navigate to detail screen | Push right (with back swipe) | Push right |
| Open create/edit form | Slide up as modal with "Done"/"Cancel" | Push right or bottom sheet |
| Action sheet (share, delete) | `CupertinoActionSheet` from bottom | `ModalBottomSheet` |
| Filter/sort options | `CupertinoActionSheet` | `ModalBottomSheet` |
| Upload source selection | `CupertinoActionSheet` | `ModalBottomSheet` |

---

## 5. Input Components

### 5.1 Text Fields

```dart
// ✅ Adaptive text field
Platform.isIOS
  ? CupertinoTextField(
      placeholder: 'Document name',
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: CupertinoColors.systemGrey4),
        borderRadius: BorderRadius.circular(8),
      ),
    )
  : TextField(
      decoration: InputDecoration(
        labelText: 'Document name',
        border: OutlineInputBorder(),
      ),
    )
```

**HomeTrack approach:** Use a custom `AppTextField` widget that renders the correct platform variant internally. Agents just call `AppTextField(label: 'Name', controller: ctrl)`.

### 5.2 Text Areas (Multi-line)

Same adaptive approach but with `maxLines` set. iOS uses `CupertinoTextField` with `maxLines`, Android uses `TextField` with `maxLines`.

### 5.3 Dropdown / Picker

**iOS:** Use `CupertinoPicker` in a bottom sheet (spinning wheel). Never use Material `DropdownButton` on iOS.
**Android:** `DropdownButton` or `DropdownMenu` is fine.

```dart
// ✅ iOS picker in bottom sheet
if (Platform.isIOS) {
  showCupertinoModalPopup(
    context: context,
    builder: (_) => Container(
      height: 250,
      child: CupertinoPicker(
        itemExtent: 36,
        onSelectedItemChanged: (index) => selectedCategory = categories[index],
        children: categories.map((c) => Center(child: Text(c.name))).toList(),
      ),
    ),
  );
} else {
  // Material dropdown
  DropdownButton<String>(
    value: selectedCategory,
    items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
    onChanged: (val) => setState(() => selectedCategory = val),
  );
}
```

**Used in HomeTrack:**
- Category selection (documents, systems, appliances)
- Status selection (project status, task status)
- Recurrence type picker
- Utility type picker
- Budget category picker
- Contact category picker

### 5.4 Segmented Control

**iOS:** `CupertinoSlidingSegmentedControl` — Apple's native segmented picker
**Android:** `SegmentedButton` (Material 3)

```dart
// ✅ Adaptive segmented control
if (Platform.isIOS) {
  CupertinoSlidingSegmentedControl<String>(
    groupValue: selectedFilter,
    children: {
      'all': Text('All'),
      'overdue': Text('Overdue'),
      'upcoming': Text('Upcoming'),
    },
    onValueChanged: (value) => setState(() => selectedFilter = value!),
  );
} else {
  SegmentedButton<String>(
    segments: [
      ButtonSegment(value: 'all', label: Text('All')),
      ButtonSegment(value: 'overdue', label: Text('Overdue')),
      ButtonSegment(value: 'upcoming', label: Text('Upcoming')),
    ],
    selected: {selectedFilter},
    onSelectionChanged: (set) => setState(() => selectedFilter = set.first),
  );
}
```

**Used in HomeTrack:**
- Task list filters (all/overdue/upcoming)
- Document view mode (list/grid) if implemented
- DIY vs contractor vs mixed selection

### 5.5 Form Buttons

| Button Type | iOS | Android |
|-------------|-----|---------|
| Primary action (Save, Create) | `CupertinoButton.filled` or custom with Gold Accent | `ElevatedButton` with Gold Accent |
| Secondary action (Cancel, Back) | `CupertinoButton` (text style) | `TextButton` or `OutlinedButton` |
| Destructive (Delete) | `CupertinoButton` with red text | `TextButton` with red text |
| Icon button (Add, Edit) | `CupertinoButton` with icon | `IconButton` |
| FAB (Floating Action Button) | **Not standard on iOS** — use nav bar button instead | `FloatingActionButton` |

**Critical FAB Decision:**

FABs are a Material Design concept. On iOS, the equivalent is a button in the navigation bar (usually "+" in the top right). HomeTrack approach:

```dart
// ✅ iOS: add button in nav bar. Android: FAB.
if (Platform.isIOS) {
  // "+" button in CupertinoNavigationBar trailing position
  CupertinoNavigationBar(
    trailing: CupertinoButton(
      padding: EdgeInsets.zero,
      child: Icon(CupertinoIcons.add),
      onPressed: onAdd,
    ),
  )
} else {
  // FAB at bottom right
  Scaffold(
    floatingActionButton: FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: onAdd,
    ),
  )
}
```

---

## 6. Feedback & Dialogs

### 6.1 Snackbar / Toast

**iOS:** iOS doesn't have a native snackbar. Use a custom toast-style overlay at the bottom or a temporary banner. Apple won't reject a bottom snackbar, but it should feel iOS-native (rounded corners, subtle shadow, no Material ripple).

**Android:** Standard Material `SnackBar`.

**HomeTrack approach:** Custom `AppSnackbar` widget that renders a rounded, brand-colored bar at the bottom on both platforms. This is a custom component (Section 8) so platform variance is minimal — just ensure it respects safe areas on both platforms.

### 6.2 Bottom Sheets

**iOS:** Use `showCupertinoModalPopup` or `CupertinoActionSheet`. Sheets should have rounded top corners and a drag handle.

**Android:** Use `showModalBottomSheet` with Material styling.

**HomeTrack approach:** Upgrade sheets, action sheets, and filter sheets use a custom `AppBottomSheet` that renders correctly on both platforms. Always include a drag handle and rounded corners.

### 6.3 Haptic Feedback

Both platforms support haptics. Use them judiciously:

```dart
import 'package:flutter/services.dart';

// Light impact: toggle switch, tab change
HapticFeedback.lightImpact();

// Medium impact: task completed, document uploaded
HapticFeedback.mediumImpact();

// Selection: picker scroll, drag reorder
HapticFeedback.selectionClick();

// Error: validation failure, upload error
HapticFeedback.heavyImpact();
```

**Where to use in HomeTrack:**
- Task completed → medium impact
- Document uploaded → medium impact
- Switch toggle → light impact
- Delete confirmed → medium impact
- Error/validation → heavy impact (brief)
- Pull-to-refresh threshold → selection click
- Phase reorder drag → selection click

---

## 7. Lists & Scrolling

### 7.1 List Separators

**iOS:** Thin separator lines between list items (inset from left). This is expected iOS behavior.
**Android:** Can use separators or card elevation for separation.

```dart
// ✅ iOS-style list with separators
if (Platform.isIOS) {
  ListView.separated(
    separatorBuilder: (_, __) => Divider(indent: 16, height: 1),
    itemBuilder: (context, index) => contactTile(contacts[index]),
    itemCount: contacts.length,
  );
} else {
  ListView.builder(
    itemBuilder: (context, index) => Card(
      child: contactTile(contacts[index]),
    ),
    itemCount: contacts.length,
  );
}
```

**HomeTrack application:**
- Simple lists (contacts, insurance) → separators on iOS, cards on Android
- Rich cards (documents, tasks, projects) → cards on both platforms (brand component)

### 7.2 Swipe Actions

**iOS:** Swipe-to-delete and swipe-to-action are core iOS patterns. Users expect them.
**Android:** Also supported but less critical.

```dart
// ✅ Swipe actions on list items
Dismissible(
  key: Key(item.id),
  direction: DismissDirection.endToStart,  // Swipe left
  background: Container(
    color: Colors.red,
    alignment: Alignment.centerRight,
    padding: EdgeInsets.only(right: 16),
    child: Icon(Icons.delete, color: Colors.white),
  ),
  confirmDismiss: (_) => showAdaptiveAlert(
    context: context,
    title: 'Delete?',
    message: 'This can\'t be undone.',
    confirmText: 'Delete',
    cancelText: 'Cancel',
  ),
  onDismissed: (_) => deleteItem(item.id),
  child: itemWidget,
)
```

**HomeTrack swipe actions:**
- Documents: swipe left to delete
- Tasks: swipe right to complete, swipe left to skip
- Contacts: swipe left to delete
- Budget items: swipe left to delete

### 7.3 Pull-to-Refresh

**iOS:** `CupertinoSliverRefreshControl` (native iOS feel)
**Android:** `RefreshIndicator` (Material)

```dart
// ✅ Adaptive pull-to-refresh
if (Platform.isIOS) {
  CustomScrollView(
    slivers: [
      CupertinoSliverRefreshControl(
        onRefresh: () => ref.read(documentsProvider.notifier).refresh(),
      ),
      SliverList(delegate: SliverChildBuilderDelegate(...)),
    ],
  )
} else {
  RefreshIndicator(
    color: AppColors.goldAccent,
    onRefresh: () => ref.read(documentsProvider.notifier).refresh(),
    child: ListView.builder(...),
  )
}
```

---

## 8. Custom Components (Safe on Both Platforms)

These components have no platform-native equivalent. Build them once, use everywhere. Apple won't reject these because they're app-specific UI, not system-level components.

| Component | Build Approach | Platform Notes |
|-----------|---------------|----------------|
| Document card | Custom `Card` with `InkWell`/`GestureDetector` | Use `GestureDetector` on iOS (no ripple), `InkWell` on Android |
| Task card | Custom `Card` | Same as above |
| Status badge | `Container` with `BorderRadius` | Identical both platforms |
| Empty states | Column + Image + Text + Button | Identical both platforms |
| Skeleton loaders | `Shimmer` package | Identical both platforms |
| Snackbar | Custom overlay widget | Respect safe area insets on both |
| Upgrade bottom sheet | Custom `BottomSheet` | Drag handle + rounded corners on both |
| Offline banner | `Container` at top of screen | Below status bar safe area |
| Health score gauge | `CustomPainter` | Identical both platforms |
| Lifespan bar | `LinearProgressIndicator` with gradient | Identical both platforms |
| Before/after slider | `GestureDetector` + `ClipRect` | Identical both platforms |
| Budget chart | `fl_chart` package | Identical both platforms |
| Photo grid | `GridView` with `CachedNetworkImage` | Identical both platforms |
| Journal feed | `ListView` with card items | Identical both platforms |

### Touch Feedback Difference

The one subtle difference for custom components:

```dart
// ✅ iOS: subtle highlight, no ripple. Android: ripple effect.
if (Platform.isIOS) {
  GestureDetector(
    onTap: onTap,
    child: Container(
      // Use ColorFiltered or opacity change for feedback
      child: cardContent,
    ),
  )
} else {
  InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: cardContent,
  )
}
```

---

## 9. Platform Detection & Adaptive Widgets

### 9.1 Platform Service

Create a centralized platform service agents can use:

```dart
// lib/core/utils/platform_utils.dart

import 'dart:io' show Platform;

class PlatformUtils {
  static bool get isIOS => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;
}
```

### 9.2 Adaptive Widget Helper

Create a base helper for building adaptive widgets:

```dart
// lib/core/widgets/adaptive_widget.dart

import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Returns the iOS widget on iOS, Material widget on Android
Widget adaptiveWidget({
  required Widget ios,
  required Widget android,
}) {
  return Platform.isIOS ? ios : android;
}
```

### 9.3 Pre-Built Adaptive Components for HomeTrack

Build these in Phase 0 (Foundation) so agents can use them:

```dart
// lib/core/widgets/adaptive/
adaptive_alert_dialog.dart     → showAdaptiveAlert()
adaptive_action_sheet.dart     → showAdaptiveActionSheet()
adaptive_date_picker.dart      → showAdaptiveDatePicker()
adaptive_time_picker.dart      → showAdaptiveTimePicker()
adaptive_text_field.dart       → AppTextField()
adaptive_picker.dart           → showAdaptivePicker() (dropdown/wheel)
adaptive_page_route.dart       → adaptivePageRoute() (push vs Cupertino)
adaptive_scaffold.dart         → AppScaffold() (nav bar + FAB/nav button)
adaptive_search_bar.dart       → AppSearchBar()
adaptive_refresh.dart          → AppRefreshableList()
```

Agents call these — they never write platform checks themselves. This ensures consistency and prevents iOS compliance issues.

---

## 10. App Store Rejection Risks

Common Flutter app rejections and how to avoid them.

### 10.1 High-Risk (Apple Will Reject)

| Risk | What Triggers It | How to Avoid |
|------|-----------------|--------------|
| Material date picker on iOS | Using `showDatePicker` on iOS | Always use `CupertinoDatePicker` on iOS |
| Material alert dialog on iOS | Using `AlertDialog` on iOS | Always use `CupertinoAlertDialog` on iOS |
| Missing back swipe gesture | Custom navigation that breaks iOS back swipe | Use `CupertinoPageRoute` on iOS |
| Non-native spinner | Material `CircularProgressIndicator` on iOS without adaptive | Use `.adaptive()` constructor |
| FAB as only add mechanism on iOS | FAB is not an iOS pattern | Use nav bar "+" button on iOS |
| Missing Safe Area handling | Content under notch or home indicator | Always wrap in `SafeArea` |
| Permission requests without explanation | Requesting camera/photos without telling user why | Always show pre-permission explanation sheet |
| Using Android-specific UI metaphors | Hamburger menu, drawer navigation on iOS | Use tab bar navigation |

### 10.2 Medium-Risk (May Trigger Review Questions)

| Risk | What Triggers It | How to Avoid |
|------|-----------------|--------------|
| Android ripple on iOS | InkWell on iOS | Use GestureDetector on iOS, InkWell on Android |
| Material bottom sheet on iOS | `showModalBottomSheet` on iOS | Use `showCupertinoModalPopup` for pickers/action sheets |
| Missing haptic feedback | Key actions without haptics | Add appropriate haptics per Section 6.3 |
| Non-standard tab bar | Custom bottom bar that doesn't behave like iOS tab bar | Use `CupertinoTabBar` patterns |

### 10.3 Safe (Won't Cause Rejection)

| Practice | Why It's Safe |
|----------|--------------|
| Custom card designs | App-specific UI, not system components |
| Brand colors and typography | Expected — apps should have their own brand |
| Custom empty states | No platform equivalent |
| Custom charts and gauges | Data visualization is app-specific |
| Custom bottom sheets for brand content | Upgrade sheets, feature info — not system-level |
| Material icons on iOS | Acceptable if consistent — but prefer SF Symbols where possible |

---

## 11. Android-Specific Considerations

While iOS is the primary compliance target, Android has expectations too.

### 11.1 Material 3 Baseline

Use Material 3 (Material You) as the Android design baseline:
- Dynamic color support (optional but nice to have)
- Rounded corners on cards and buttons
- Elevation-based hierarchy

### 11.2 System Back Button

Android has a system back button (or gesture). Flutter handles this automatically with `WillPopScope` (now `PopScope`), but verify:
- Back button dismisses modals and bottom sheets
- Back button navigates up in screen stack
- Back button on root screen shows "Press again to exit" or just minimizes app

### 11.3 Android-Specific Widgets

| Component | Android Implementation |
|-----------|----------------------|
| Navigation | `NavigationBar` (Material 3) |
| App bar | `AppBar` with `SliverAppBar` |
| FAB | `FloatingActionButton` (bottom right) |
| Snackbar | `ScaffoldMessenger.showSnackBar` |
| Drawer | Not used — tab navigation |
| Chips | `FilterChip`, `ChoiceChip` for filters |

---

## 12. Quick Reference Cheat Sheet

Print this and pin it next to your monitor.

### Before Building Any Component, Ask:

```
1. Does Apple have a native version? → Use Cupertino on iOS
2. Does Flutter have .adaptive()? → Use it
3. Is it a HomeTrack brand component? → Build custom, same on both
4. Is it a form input? → Use AppTextField / AppPicker (adaptive)
5. Is it a dialog? → Use showAdaptiveAlert / showAdaptiveActionSheet
6. Is it navigation? → Use CupertinoPageRoute on iOS
```

### Platform Widget Quick Map

| Need | iOS | Android |
|------|-----|---------|
| Date picker | `CupertinoDatePicker` | `showDatePicker` |
| Time picker | `CupertinoDatePicker` (time) | `showTimePicker` |
| Alert | `CupertinoAlertDialog` | `AlertDialog` |
| Action sheet | `CupertinoActionSheet` | `ModalBottomSheet` |
| Spinner | `CupertinoActivityIndicator` | `CircularProgressIndicator` |
| Switch | `CupertinoSwitch` | `Switch` |
| Slider | `CupertinoSlider` | `Slider` |
| Text field | `CupertinoTextField` | `TextField` |
| Search bar | `CupertinoSearchTextField` | `SearchBar` |
| Dropdown | `CupertinoPicker` in bottom sheet | `DropdownButton` |
| Segmented | `CupertinoSlidingSegmentedControl` | `SegmentedButton` |
| Nav bar | `CupertinoNavigationBar` | `AppBar` |
| Tab bar | `CupertinoTabBar` | `NavigationBar` |
| Back gesture | Automatic with `CupertinoPageRoute` | System back button |
| Add button | Nav bar trailing "+" | `FloatingActionButton` |
| Pull refresh | `CupertinoSliverRefreshControl` | `RefreshIndicator` |
| Haptics | `HapticFeedback.*` | `HapticFeedback.*` |

---

**Cross-references:**
- For performance implications of adaptive widgets, see **HomeTrack Performance Guide, Section 4 (Widget Build Optimization)**.
- For Home tab dashboard layout, hero card, and section specifications, see **HomeTrack Dashboard Spec**.
- For dashboard behavior across user states (onboarding, healthy, at risk, offline), see **HomeTrack Dashboard State Variations**.
- For empty state visual patterns per screen, see **HomeTrack Empty States Catalog**.
- For health score ring widget specifications, see **HomeTrack Health Score Algorithm**.

---

*End of Platform UI Compliance Guide*
*HomeTrack — Version 1.1 — February 2026*
