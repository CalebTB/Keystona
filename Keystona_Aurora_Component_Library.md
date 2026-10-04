# Keystona — Aurora Component Library

**Version 1.0 · June 2026 · Active**
**Status:** Canonical. Required reading for any agent building UI surfaces outside the canonical screens and forms.
**Consumes:** `Keystona_Aurora_Design_System.md` (tokens) · `Keystona_Aurora_Form_Schemas.md` (form widgets)
**Owners:** Flutter agent (renders components) · Integration agent (cross-screen patterns) · Subscription/QA agent (Premium gates and tier-limit modals)

---

## 1. Why this doc exists

The Aurora Design System doc establishes tokens (colors, typography, radii, spacing). The Form Schemas doc establishes the canonical form widget kit. This doc covers **everything in between** — every reusable UI primitive that appears across multiple screens but isn't a form field or a full screen layout.

If the Flutter agent is building anything that's not a tokenized style or a form, they look here. Specifically:

- **Modals** — confirmation dialogs, alerts, upgrade prompts
- **Bottom sheets** — pickers, action sheets, sub-forms, share sheets
- **Toasts & snackbars** — transient feedback
- **Banners** — persistent inline notices
- **Viewers** — photo and PDF full-screen viewers
- **Empty states** — five canonical patterns
- **Loading & skeleton states**
- **Tab bar** (the global bottom nav, already specced in `Keystona_Aurora_Design_System.md` §6.9 — referenced here for completeness)
- **Section headers and dividers**
- **Badges & chips** (status, tier, count)
- **Avatars**
- **Pull-to-refresh**
- **Empty navigation states** (offline banner)
- **The Aurora-style action sheet** (iOS-native pattern adapted)

What this doc does NOT cover:

- Buttons (in Design System §6.1)
- Cards (in Design System §6.2)
- Status chips (in Design System §6.3) and Filter pills (§6.4)
- Task rows (§6.5)
- Hero cards (§6.6)
- Quick action buttons (§6.7)
- Form fields (in Form Schemas)
- Screen-level layouts (in individual screen specs)

---

## 2. Modal dialogs

### 2.1 When to use a modal

A modal is for **acknowledgment** or **confirmation** — content the user must address before continuing. If the user can dismiss the content without consequence and continue working, it's a toast, banner, or sheet — not a modal.

The five modal use cases in Keystona:

| Use case | Pattern | Example |
|---|---|---|
| Confirm destructive action | Confirmation modal | "Delete this system?" |
| Confirm tier-gated action | Upgrade modal | "You've reached the 50-document limit" |
| Acknowledge irreversible result | Result modal | "Account deleted" |
| Resolve conflict | Choice modal | "This task has 3 future occurrences. Update all?" |
| Force critical info | Alert modal | "Your trial ends tomorrow" |

### 2.2 Modal anatomy

```
       ┌──────────────────────────────────────┐
       │           [optional icon]            │  ← 56×56, only on alert/upgrade modals
       │                                      │
       │           Modal title.               │  ← h2 weight 600, ink, sentence case
       │                                      │
       │    Supporting copy explaining        │  ← body 13/400, ink-secondary
       │    what's happening or why this      │     line-height 1.5, max 3 lines
       │    confirmation matters.             │
       │                                      │
       │  ┌────────────┐  ┌────────────┐      │  ← buttons stacked vertically on mobile
       │  │   Cancel   │  │  Confirm   │      │     side-by-side only on tablet+
       │  └────────────┘  └────────────┘      │
       └──────────────────────────────────────┘
```

- **Container:** 320–340px wide, white `paper` background, `radius-2xl` (22px), `border: none`, `box-shadow: 0 8px 32px rgba(7, 18, 56, 0.18)`.
- **Backdrop:** `rgba(7, 18, 56, 0.55)` overlay, full-screen, blocks all interaction outside the modal.
- **Padding:** 24px on all sides, 20px between content blocks.
- **Title:** Inter 600, 18px, `-0.4px tracking`, `ink` color, sentence case with a period.
- **Body:** Inter 400, 13px, `1.5 line-height`, `ink-secondary` color, max 3 lines (if longer, use a sheet not a modal).
- **Icon (when present):** 56×56, centered above title, 16px below the icon to title. Icon color depends on modal type (see §2.4).
- **Button row:** full-width row at the bottom, 8px gap between buttons. Buttons inherit from Design System §6.1 (Primary, Secondary, Save).

### 2.3 Button arrangement

- **One action:** single full-width button.
- **Two actions:** Cancel (left, secondary white-with-border) + Confirm (right, primary). On mobile screens narrower than 375px, stack vertically: Confirm on top, Cancel below.
- **Three actions:** stack all three vertically. Most-recommended at top in primary color, alternative middle in secondary white, destructive/cancel at bottom in ghost coral-text style.

### 2.4 Modal type variants

#### Confirmation modal (default)
- **Container:** white paper
- **Icon:** none
- **Title:** "Delete this system?" / "Discard changes?"
- **Confirm button:** **coral primary** for destructive, **cobalt primary** for non-destructive (save, accept)
- **Cancel button:** white secondary with `1.5px ink-border-strong`

```dart
AuroraModal.confirm(
  context,
  title: 'Delete this system?',
  body: 'Removes the system and unlinks 4 tasks. 30-day undo in Settings.',
  confirmLabel: 'Delete',
  destructive: true,
  onConfirm: () { ... },
)
```

#### Upgrade modal (Premium gate)
- **Container:** white paper
- **Icon:** 56×56 coral hero circle with the yellow blob decoration miniaturized, with a star or lock glyph in white
- **Title:** "You've reached the 50-document limit." / "Smart scan is a Premium feature."
- **Body:** Brief value statement of what Premium unlocks
- **Confirm button:** coral primary, label "See Premium" or "Start free trial"
- **Cancel button:** ghost button (coral text only), label "Maybe later"
- After Confirm, opens the full Premium upgrade screen (#82 in inventory), not a stacked sheet.

#### Result modal (success or info)
- **Container:** white paper
- **Icon:** 56×56 lime circle with a white checkmark for success; cobalt circle with white info-icon for neutral info
- **Title:** "Account deleted." / "Your trial starts now."
- **Body:** What happens next or what to expect
- **Confirm button:** single full-width cobalt primary, label "OK" or "Got it"
- **No Cancel option** — result modals are acknowledgment-only

#### Choice modal (conflict resolution)
- **Container:** white paper
- **Icon:** 56×56 yellow circle with `ti-alert-triangle` icon in `yellow-deep` color
- **Title:** "Update all future occurrences?"
- **Body:** Explanation of the conflict and what each choice does
- **Three buttons stacked:**
  - Top: cobalt primary — most-recommended action ("Update all 3")
  - Middle: white secondary — single-record action ("Update only this one")
  - Bottom: ghost coral text — cancel ("Cancel")

#### Alert modal (urgent info)
- **Container:** white paper
- **Icon:** 56×56 coral hero circle with `ti-alert-triangle` icon in white
- **Title:** "Your trial ends tomorrow."
- **Body:** What happens if no action is taken
- **Buttons:** coral primary "Continue trial" + ghost coral "Remind me later"
- **Dismissal:** alert modals CAN be dismissed by tapping the backdrop, unlike confirmation modals which must be explicitly resolved

### 2.5 Modal behavior

- **Backdrop tap:** dismissable for Alert and Upgrade modals only. Confirmation, Result, and Choice modals require explicit button press.
- **Animation:** scale-up from 0.95 to 1.0 + opacity fade, 220ms ease-out. Backdrop opacity fades in over 180ms.
- **Stacking:** modals do NOT stack. If a modal is open and another modal is triggered, the first dismisses before the second opens (with 120ms gap).
- **Keyboard handling:** if a modal contains a text field (rare — usually a sheet would be used instead), the modal lifts above the keyboard. If the modal would clip, switch to a sheet.

### 2.6 Flutter widget contract

```dart
class AuroraModal {
  static Future<bool?> confirm(BuildContext context, {
    required String title,
    required String body,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
    IconData? icon,
    Color? iconColor,
  });

  static Future<void> result(BuildContext context, {
    required String title,
    required String body,
    String dismissLabel = 'OK',
    AuroraResultType type = AuroraResultType.success, // success | info
  });

  static Future<int?> choice(BuildContext context, {
    required String title,
    required String body,
    required List<AuroraModalAction> actions, // top = primary, bottom = cancel
  });

  static Future<void> upgrade(BuildContext context, {
    required String title,
    required String body,
    String confirmLabel = 'See Premium',
  });

  static Future<bool?> alert(BuildContext context, {
    required String title,
    required String body,
    String confirmLabel = 'Got it',
    String? cancelLabel,
  });
}
```

---

## 3. Bottom sheets

### 3.1 When to use a sheet

A sheet is for **selection** or **secondary editing** — content the user interacts with, then dismisses to return to their main task. Sheets are NOT for confirmation (use a modal) and NOT for transient feedback (use a toast).

Sheet use cases in Keystona:

| Use case | Height | Example |
|---|---|---|
| Sub-form | 50–85% | All five sub-forms in `Keystona_Aurora_Form_Schemas.md` §13 |
| Link picker | 80% | "Pick a system to link this task to" |
| Action sheet | auto (compact) | iOS-style action list with 2–5 options |
| Share sheet | 50% | Share, export, link copy |
| Date picker | 45% | Inline date selection (alternative to native picker) |
| Source picker | 35% | "Take photo" / "Pick from library" / "Pick from files" |

### 3.2 Sheet anatomy

```
┌────────────────────────────────────────────────┐
│                   ━━━━━━                       │  ← drag handle, 4×36, ink-border-strong
│                                                │     centered, 8px from top
│   Cancel        Title.            Save xxx     │  ← title row, 12px below handle
│  ───────────────────────────────────────────   │  ← 0.5px ink-border divider
│                                                │
│  Sheet content (scrolls if needed)             │
│                                                │
│                                                │
└────────────────────────────────────────────────┘
```

- **Container:** white `paper` background, top corners `radius-2xl` (22px), no bottom corners (flush with screen edge), no shadow, no border.
- **Backdrop:** `rgba(7, 18, 56, 0.45)` overlay (lighter than modals — sheets are less interruptive).
- **Drag handle:** 4px tall × 36px wide, `ink-border-strong` fill, `radius-full`, centered horizontally, 8px from top of sheet.
- **Title row:** 12px below the handle, 16px horizontal padding, contains Cancel (left), title (center, h3 weight 700), and Save/primary action (right, cobalt pill).
- **Divider:** 0.5px solid `ink-border`, full width.
- **Body padding:** 16px horizontal, 16px top, 24px bottom (extra bottom space for safe-area).

### 3.3 Sheet height behavior

Sheets specify a target height as a percentage of screen height. The system auto-snaps to common heights.

| Height token | Pct | Use |
|---|---|---|
| `sheet-compact` | 35% | Action sheets, source pickers |
| `sheet-medium` | 50% | Date pickers, share sheets |
| `sheet-tall` | 70% | Sub-forms (most) |
| `sheet-extra` | 85% | Sub-forms with photo grids (shutoff setup) |
| `sheet-full` | 95% | Long content (rare — usually push a full screen instead) |

If content exceeds the target height, the sheet scrolls internally; the header (handle + title row + divider) stays pinned.

### 3.4 Sheet dismissal

- **Drag down:** dismissable from any point on the sheet body, not just the handle. Threshold: 80px drag distance OR 600px/s velocity downward.
- **Backdrop tap:** dismissable by default. Sub-forms with dirty fields show the iOS-style action sheet first (per Form Schemas §11.2).
- **Cancel button:** explicit dismiss, same dirty-state behavior.
- **Save button:** validates, saves, then dismisses on success.

### 3.5 Stacked sheets

- A sheet can open another sheet (max stack depth 2, per Form Schemas §14.3).
- When stacking, the lower sheet stays in place; its backdrop darkens from `rgba(7, 18, 56, 0.45)` to `rgba(7, 18, 56, 0.55)` (modal-strength) to indicate it's no longer the top sheet.
- Dismissing the top sheet returns control to the lower; the backdrop lightens back.
- A third sheet is NOT allowed. If the architecture requires it, dismiss the entire stack and push a full screen instead.

### 3.6 Action sheet variant (iOS-style)

The Action Sheet is a compact sheet variant with a stack of options as full-width rows. It's used for short, focused decision lists.

```
┌────────────────────────────────────────────────┐
│                   ━━━━━━                       │
│                                                │
│              Move document to                  │  ← h3 centered (no Cancel/Save row)
│                                                │
│  ───────────────────────────────────────────   │
│                                                │
│   Receipts                                    →│  ← row 56px tall, ink text, chev right
│   Maintenance                                 →│
│   Permits                                     →│
│   Warranties                                  →│
│                                                │
│  ───────────────────────────────────────────   │
│                                                │
│                  Cancel                        │  ← ghost coral text, centered
│                                                │
└────────────────────────────────────────────────┘
```

- **Title row:** no Cancel/Save — just a centered title and the divider.
- **Action rows:** 56px tall, 16px horizontal padding, Inter 500 14px ink text, optional leading icon (24px), optional trailing chevron or check.
- **Destructive rows:** text in `coral`, e.g. "Delete document"
- **Cancel row:** at the bottom, separated by a `0.5px ink-border` divider, ghost button styling (coral text, no fill).
- **Auto-height:** sheet height matches content; usually `sheet-compact` (35%) or less.

### 3.7 Flutter widget contract

```dart
class AuroraSheet {
  static Future<T?> show<T>(BuildContext context, {
    required Widget child,
    String? title,
    String? confirmLabel,
    VoidCallback? onConfirm,
    AuroraSheetHeight height = AuroraSheetHeight.tall,
    bool dismissOnBackdropTap = true,
  });

  static Future<int?> actionSheet(BuildContext context, {
    required String title,
    required List<AuroraSheetAction> actions, // each: label, icon?, destructive?
    String cancelLabel = 'Cancel',
  });

  static Future<T?> picker<T>(BuildContext context, {
    required String title,
    required List<T> items,
    required Widget Function(T) itemBuilder,
    String? searchPlaceholder,
    List<AuroraFilterChip>? filters,
  });
}

enum AuroraSheetHeight { compact, medium, tall, extra, full }
```

---

## 4. Toasts and snackbars

### 4.1 When to use a toast

A toast is for **transient feedback** — confirming an action succeeded or a background event happened. The user doesn't need to act on a toast; it auto-dismisses.

Rule: if you want the user to read the message but not necessarily act, it's a toast. If you want them to act, it's a banner or modal.

Toast use cases in Keystona:

| Use case | Variant | Example |
|---|---|---|
| Action confirmed | Success | "Task marked done. +3 health points." |
| Background event | Info | "Synced 3 documents." |
| Soft error | Warning | "Couldn't reach server. Will retry." |
| Hard error | Error | "Save failed. Tap to retry." |

### 4.2 Toast anatomy

```
┌─────────────────────────────────────────────┐
│ [icon]  Toast message goes here.       [×]  │
└─────────────────────────────────────────────┘
```

- **Position:** floats above the tab bar, 16px from bottom edge (above the 88px tab bar = 104px total from screen bottom). Horizontal: 16px from screen edges.
- **Container:** rounded card, `radius-lg` (14px), 12px padding all sides, full-width minus 32px (16px on each side).
- **Background:** `ink` `#071238` (always — toasts are top-of-stack and need max contrast against any screen).
- **Shadow:** `0 4px 16px rgba(7, 18, 56, 0.20)`.
- **Icon (left):** 18px, color per variant (see §4.3). 8px gap to message.
- **Message:** Inter 500, 13px, white, 1.4 line-height. Max 2 lines — if longer, use a banner.
- **Dismiss (right):** small `×` icon, 16px, `rgba(255,255,255,0.55)`. Optional — present only on toasts that linger (warning/error). Success and info toasts auto-dismiss without a dismiss control.
- **Action (right):** optional inline action button in `lime` text, e.g. "Tap to retry" or "Undo". Replaces the dismiss `×` when present.

### 4.3 Toast variants

| Variant | Icon | Icon color | Behavior |
|---|---|---|---|
| Success | `ti-check` | `lime` | Auto-dismiss after 2.5s |
| Info | `ti-info-circle` | `cobalt` (lightened to `#6FA4D6` for contrast on ink) | Auto-dismiss after 3.5s |
| Warning | `ti-alert-triangle` | `yellow` | Auto-dismiss after 4.5s, dismiss icon visible |
| Error | `ti-x-circle` | `coral` | Persists until dismissed, dismiss icon AND action button |

### 4.4 Toast behavior

- **Animation:** slides up from below tab bar with opacity fade, 220ms ease-out. Slides back down with fade on dismiss, 180ms ease-in.
- **Stacking:** toasts stack vertically with 8px gap between. Max 3 visible at once — a 4th toast pushes the oldest off the top with a fade-out.
- **Persistent toasts:** error toasts persist until dismissed or until a navigation event clears them.
- **Action tap:** triggers the callback and dismisses the toast. The action is the only tappable surface on the toast body — tapping the toast body itself does nothing.
- **Swipe to dismiss:** any toast can be swiped horizontally to dismiss, regardless of variant.

### 4.5 Snackbar variant

A snackbar is the same as a toast but **anchored to the top** of the screen (just below the status bar), used for cross-screen events that don't relate to the current screen's content.

Use snackbars for:
- Sync events ("3 documents synced.")
- Connectivity changes ("Back online.")
- App-wide events ("Account upgraded to Premium.")

Use toasts for:
- Actions the user just took on the current screen ("Document saved.")
- Errors related to the user's current action ("Save failed.")

### 4.6 Flutter widget contract

```dart
class AuroraToast {
  static void show(BuildContext context, {
    required String message,
    AuroraToastVariant variant = AuroraToastVariant.success,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration, // override default per variant
  });

  static void snackbar(BuildContext context, {
    required String message,
    AuroraToastVariant variant = AuroraToastVariant.info,
    String? actionLabel,
    VoidCallback? onAction,
  });

  static void dismissAll();
}

enum AuroraToastVariant { success, info, warning, error }
```

---

## 5. Banners

### 5.1 When to use a banner

A banner is for **persistent inline notice** — content that needs to stay visible until the user resolves it or it becomes irrelevant. Banners live inside screen content (not floating like toasts) and don't auto-dismiss.

Banner use cases in Keystona:

| Use case | Variant | Example | Where |
|---|---|---|---|
| Approaching limit | Warning | "You're using 45 of 50 free documents." | Top of Documents screen |
| Limit reached | Coral | "Free tier limit reached. Delete or upgrade to add more." | Top of Documents screen |
| Offline status | Neutral | "Working offline. Changes sync when you reconnect." | Top of all screens |
| Trial expiring | Warning | "Your trial ends in 2 days. Add payment to continue." | Top of Home / Settings |
| Important action needed | Coral | "Renew your homeowners insurance — expires in 7 days." | Top of Dashboard |
| Onboarding nudge | Info | "Add a system to start tracking maintenance." | Top of Dashboard until dismissed |

### 5.2 Banner anatomy

```
┌─────────────────────────────────────────────────────┐
│ [icon]   Banner title.                          [×] │
│          Supporting text on a second line if        │
│          needed. Keep this brief.              [→]  │
└─────────────────────────────────────────────────────┘
```

- **Container:** full-width (matches screen padding), `radius-lg` (14px), padding 12px 14px, 14px bottom margin.
- **Position:** below the screen header (greeting/title block), above the main content.
- **Background:** color per variant (see §5.3).
- **Icon (left):** 20px, top-aligned, 12px gap to text.
- **Title:** Inter 600, 13.5px, ink (on light banner backgrounds) or `[variant]-deep` color (matching the background family).
- **Body:** Inter 400, 12px, secondary color, 1.45 line-height, 2 lines max.
- **Dismiss (top-right):** small `×` icon, 16px, secondary color. Only on dismissable banners.
- **Action (bottom-right or inline):** small chevron or text link in `[variant]-deep` color, e.g. "Upgrade →" or "Tap to sync".

### 5.3 Banner variants

| Variant | Background | Border | Icon color | Title color | Body color | Use |
|---|---|---|---|---|---|---|
| Info | white | `1.5px solid ink-border` | `cobalt` | `ink` | `ink-secondary` | Onboarding nudges, neutral status |
| Success | `lime-dim` | none | `lime-deep` | `lime-deep` | `ink-secondary` | Positive status (rare — usually a toast suffices) |
| Warning | `yellow-dim` | none | `yellow-deep` | `yellow-deep` | `ink-secondary` | Approaching limits, expiring soon |
| Coral / Action needed | `coral-dim` | none | `coral` | `coral-deep` | `ink-secondary` | Limit reached, overdue items, action required |
| Offline | `butter` | none | `ink-secondary` | `ink` | `ink-secondary` | Connectivity status |

### 5.4 Banner behavior

- **Persistence:** banners stay until dismissed or the underlying condition resolves. They do not auto-hide.
- **Dismissable banners:** show the `×` icon. Tapping dismisses the banner for that session only — on next app open, the banner returns if the condition still applies. Exception: onboarding nudges, which are dismissable for the lifetime of the user.
- **Non-dismissable banners:** offline status, hard-limit banners (e.g. trial expired). These have no `×` and must be resolved by the underlying condition changing.
- **Tap behavior:** if the banner has a clear action, the whole banner is tappable. If it's purely informational, only the action link is tappable.

### 5.5 Banner stacking

- Multiple banners on the same screen stack with 8px gap.
- Maximum 2 banners visible at once. If a third is triggered, the lowest-priority is hidden.
- Priority order: Coral > Warning > Offline > Info > Success. (Coral always shows first; success banners rarely appear in stacks.)

### 5.6 Flutter widget contract

```dart
class AuroraBanner extends StatelessWidget {
  final AuroraBannerVariant variant;
  final String title;
  final String? body;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool dismissible;
  final VoidCallback? onDismiss;

  const AuroraBanner({ ... });
}

enum AuroraBannerVariant { info, success, warning, coral, offline }
```

---

## 6. Photo viewer

### 6.1 Use case

Full-screen photo viewing for:
- System / appliance photos (Schema 1 §9, Schema 2 §12)
- Project before/after pairs (lives inside the Photo Gallery, not the viewer)
- Document image previews (JPG/PNG/HEIC files in the vault)
- Shutoff setup photos (location + valve close-up)

### 6.2 Photo viewer anatomy

```
┌────────────────────────────────────────────────┐
│  ←                                       ⋯     │  ← top toolbar (transparent)
│                                                │
│                                                │
│                                                │
│            [photo, fit to screen]              │
│                                                │
│                                                │
│                                                │
│                                                │
│  ┌────────────────────────────────────────┐   │
│  │  Caption text · Mono date stamp        │   │  ← optional caption strip
│  └────────────────────────────────────────┘   │
└────────────────────────────────────────────────┘
```

- **Background:** `ink` `#071238` (always — black-on-photo doesn't read; midnight navy does and matches the system).
- **Top toolbar:** 56px tall, transparent (sits over the photo), contains a back chevron (left) and a kebab menu `⋯` (right). Toolbar fades out after 3s of no interaction; tapping the photo anywhere brings it back.
- **Photo:** centered, fit-to-screen with letterboxing where aspect ratios don't match. Pinch-to-zoom up to 4x, double-tap to zoom to fit-width.
- **Caption strip (optional):** 60px tall, `radius-lg` top corners only, background `rgba(7,18,56,0.85)` with backdrop blur, contains caption text (Inter 500 13px white) and a mono date (right-aligned, `rgba(255,255,255,0.55)`). Caption strip fades with the toolbar.

### 6.3 Photo viewer menu (`⋯`)

The kebab menu opens an action sheet (per §3.6) with context-dependent options:

- **For item photos:** Set as cover, Replace, Remove
- **For project photos:** Set as cover, Pair with another photo, Add to phase, Remove
- **For document previews:** Save to Photos app, Share, Replace, Delete document

### 6.4 Multi-photo gallery (swipe)

When the viewer is opened from a context with multiple photos (system gallery, before/after pairs, document with multiple pages), the viewer supports horizontal swipe between photos. A subtle pagination dot indicator appears at the bottom (above the safe area) — 6px dots, white at 40% opacity for inactive, lime at 100% for active.

### 6.5 Flutter widget contract

```dart
class AuroraPhotoViewer extends StatelessWidget {
  final List<String> photoUrls;
  final int initialIndex;
  final List<String?>? captions;
  final List<DateTime?>? dates;
  final List<AuroraPhotoMenuAction>? menuActions;
  // Constructor and methods...
}
```

---

## 7. PDF viewer

### 7.1 Use case

PDF viewing for documents in the vault. Most Keystona documents are PDFs (warranties, insurance policies, permits, contracts). The viewer must support multi-page navigation, zoom, and a "linked from" badge showing what system/appliance/project the doc is tied to.

### 7.2 PDF viewer anatomy

```
┌────────────────────────────────────────────────┐
│  ← Document name             1 / 4    ⋯       │  ← top toolbar (white opaque)
│  ──────────────────────────────────────────    │
│                                                │
│           [page rendered, fit to width]        │
│                                                │
│                                                │
│                                                │
│  ──────────────────────────────────────────    │
│   < Prev page    [Linked from: HVAC]    Next > │  ← bottom toolbar (white opaque)
└────────────────────────────────────────────────┘
```

- **Background:** `butter` `#F5F1E8` (warm — gives the PDF a paper-like context, easier on the eyes than white-on-white).
- **Top toolbar:** 56px, white opaque, `0.5px ink-border` bottom border. Contains back chevron, document name (h3 truncated), page count (mono `1 / N`), kebab menu.
- **Bottom toolbar:** 56px, white opaque, `0.5px ink-border` top border. Contains Prev page chevron (left), centered "Linked from: [entity]" chip (only when document is linked), Next page chevron (right).
- **PDF page:** centered, fit-to-width, with smooth horizontal swipe to next/prev page. Pinch-to-zoom up to 4x.
- **Linked-from chip:** small pill, `radius-full`, padding 4px 10px, background `cobalt-dim`, text `cobalt-deep` Inter 500 11px. Tapping navigates to the linked entity.

### 7.3 PDF viewer menu (`⋯`)

Action sheet with: Share, Save to Files, Replace, Edit metadata, Delete.

### 7.4 Flutter widget contract

```dart
class AuroraPdfViewer extends StatelessWidget {
  final String pdfUrl;
  final String documentName;
  final String? linkedEntityName;
  final String? linkedEntityRoute;
  final List<AuroraPdfMenuAction> menuActions;
  // Constructor and methods...
}
```

---

## 8. Empty states

### 8.1 Five canonical patterns

Per `HomeTrack_Empty_States_Catalog.md` (which must be updated to reference Aurora tokens — see §15 below), there are five empty-state patterns. Aurora preserves all five but updates the visual treatment.

| Pattern | When to use | Aurora treatment |
|---|---|---|
| **A. Motivational** | First-run state of a feature with no user data yet (Dashboard day-one, Documents empty, Tasks empty) | Coral hero with yellow blob, large icon (96px), title (h1), body (body), primary CTA |
| **B. Showcase** | First-run with ghosted example cards (Projects empty) | Two ghosted example cards at 30% opacity, centered title (h2), CTA below |
| **C. Instructional** | Filtered view with no results (Documents filtered by category with 0 results) | 64px icon (`ink-tertiary`), title (h3), body (body, secondary color), no CTA |
| **D. Celebration** | Positive empty state (Tasks all caught up) | 64px lime check icon, title (h3), supportive body, no CTA |
| **E. Inline CTA card** | Sub-section of a screen has no data (Project budget tab with 0 items) | Compact card, butter background, 48px icon, title (h3), CTA button |

### 8.2 Empty state anatomy — Pattern A (Motivational)

```
                  ┌────────────┐
                  │            │
                  │   [icon]   │   ← 96px icon, inside coral circle 120px
                  │            │      circle has yellow blob decoration
                  └────────────┘

              Your home, organized.              ← h1, centered, ink

       Add your first system to start              ← body, centered, ink-secondary
       tracking maintenance, warranties,            max 60 chars per line, 3 lines max
       and replacement timelines.

       ┌────────────────────────────┐
       │      + Add a system        │             ← coral primary, full-width pill
       └────────────────────────────┘

       Or scan a document to begin               ← ghost coral text, tap = alt path
```

- **Layout:** vertically centered in available space (above the tab bar), 24px horizontal padding.
- **Icon container:** 120×120, `radius-full`, `coral` background with the yellow blob decoration (same pattern as the Aurora hero — top-right positioning of the blob inside the circle).
- **Icon itself:** 56px Tabler outline, white color.
- **Title:** Inter 700, 22px, `-0.7px tracking`, ink color, sentence case with period, max 2 lines.
- **Body:** Inter 400, 13px, ink-secondary, 1.5 line-height, max 3 lines, max 320px width.
- **Primary CTA:** full-width pill button, coral primary style. Always present in Pattern A.
- **Alternate path (optional):** ghost coral text below the CTA, single tap target. Used when there's a secondary entry point (e.g. "Or scan a document" on Documents empty state).

### 8.3 Empty state anatomy — Pattern C (Instructional)

```
              [64px icon, ink-tertiary]

         No documents in this category.         ← h3, centered, ink

      Try a different category or upload a       ← body-sm, centered, ink-secondary
      new document to this one.
```

- **No CTA.** Filtered empty states are instructional, not action-oriented — the user already navigated to a filter, so the answer is to change the filter or use the FAB.
- **Icon:** 64px Tabler outline in `ink-tertiary` (rgba(7, 18, 56, 0.35)), monochrome.
- **Title:** Inter 700, 15px, ink color.
- **Body:** Inter 400, 12px, ink-secondary, 1.45 line-height, max 2 lines.

### 8.4 Empty state anatomy — Pattern D (Celebration)

```
              [64px lime circle with check]

           You're all caught up.                ← h3, centered, ink

       Nothing due this week. We'll let         ← body-sm, centered, ink-secondary
       you know when something's coming up.
```

- **Icon:** 64×64 `lime` `radius-full` background with white checkmark in the center (28px stroke 2.5).
- **Title:** Inter 700, 15px.
- **No CTA** — Pattern D is for moments of rest, not action.

### 8.5 Empty state anatomy — Pattern E (Inline CTA card)

```
┌─────────────────────────────────────────────┐
│                                              │
│  [48px icon, butter circle]                  │
│                                              │
│  Track this project's budget.                │  ← h3, ink
│  Add line items to monitor spending          │  ← body-sm, ink-secondary
│  against your estimate.                      │
│                                              │
│  ┌─────────────────────────────┐            │
│  │  + Start tracking            │            │  ← coral pill primary
│  └─────────────────────────────┘            │
│                                              │
└─────────────────────────────────────────────┘
```

- **Container:** card, `butter` background, `radius-xl` (16px), padding 16px.
- **Used inside a section** of a larger screen, not as a screen-level empty state.
- **Icon container:** 48×48 `radius-full`, butter-dim or coral-dim depending on context.
- **CTA:** half-width or auto-width pill, never full-width.

### 8.6 Flutter widget contract

```dart
class AuroraEmptyState extends StatelessWidget {
  final AuroraEmptyPattern pattern; // motivational | showcase | instructional | celebration | inline
  final IconData icon;
  final String title;
  final String? body;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final String? alternateLabel;
  final VoidCallback? onAlternate;
  final List<Widget>? showcaseCards; // for pattern B only
}

enum AuroraEmptyPattern { motivational, showcase, instructional, celebration, inline }
```

---

## 9. Loading and skeleton states

### 9.1 When to use each

| Pattern | Use |
|---|---|
| **Spinner** | Inline, short loads (< 500ms expected), inside buttons during async actions |
| **Skeleton** | Initial screen load, list refresh, anywhere structured content is loading and we know the shape |
| **Progress bar** | Multi-step or long-running operations (file upload, OCR processing, sync) |
| **Pulse dot** | Background activity, "live" indicators (real-time sync status) |

### 9.2 Spinner

- **Inline spinner:** 16–24px circular spinner, 2px stroke, `coral` color on white surfaces, white on coral surfaces.
- **In-button spinner:** replaces the button label with a 16px spinner centered. Button stays clickable disabled (visually) for the duration.
- **Full-screen spinner:** centered 32px coral spinner on a translucent backdrop. Used only when the entire screen is blocked by a load and no skeleton is appropriate.

### 9.3 Skeleton

Skeleton placeholders mimic the shape of incoming content:

- **Background:** `butter` `#F5F1E8` for the skeleton element (one shade darker than paper to read as a placeholder).
- **Shimmer:** light-to-dark linear gradient sweeps left-to-right across the skeleton element every 1.2s. Gradient is `rgba(255,255,255,0)` → `rgba(255,255,255,0.4)` → `rgba(255,255,255,0)` over 30% of the element width.
- **Corner radius:** matches the real component's radius (`radius-lg` for task rows, `radius-2xl` for hero cards, etc.).
- **Text placeholder:** rectangles at the height of the real text (e.g. 14px tall for body text), 60–85% width (vary per line to feel natural — never identical widths stacked).
- **Image placeholder:** square or rectangle at the photo's dimensions, no shimmer (would feel like a real image is loading).

### 9.4 Progress bar

```
┌─────────────────────────────────────────────┐
│  Uploading 3 of 12 documents...     25%     │  ← label + percentage
│  ████████░░░░░░░░░░░░░░░░░░░░░░░░░          │  ← 4px tall fill
└─────────────────────────────────────────────┘
```

- **Track:** 4px tall, `ink-border` color, `radius-full`.
- **Fill:** 4px tall, `cobalt` color (for sync), `lime` (for OCR processing — Premium feature), `coral` (rare — only for "running out of free quota" style progress).
- **Label:** Inter 500, 12px, ink, above the bar with 6px gap.
- **Percentage:** mono 12px, 600 weight, ink, right-aligned same line as label.

### 9.5 Pulse dot

A 7×7 lime circle that softly pulses (scale 1.0 → 1.3 → 1.0 over 1.4s) to indicate background activity. Used in:

- The Emergency Hub "last synced" line (small dot next to the timestamp when actively syncing)
- The Smart Scan status pill (the dot inside "Reading · 8 fields found")
- Premium "AI processing" indicators

---

## 10. Section headers and dividers

### 10.1 Section header (mono eyebrow)

The canonical section header throughout the app:

```
●  COMING UP                                  View all →
↑   ↑                                              ↑
dot eyebrow text (mono uppercase)                  optional action
```

- **Dot:** 7×7, color matches the section type (coral for tasks/alerts, cobalt for actions/info, lime for completed, yellow for warnings).
- **Eyebrow text:** JetBrains Mono, 10px, 500 weight, `1.2px tracking`, uppercase, `ink-secondary` color.
- **Gap between dot and text:** 6px.
- **Action link (right-aligned, optional):** Inter 700, 10px, `coral` color, uppercase, 0.5px tracking, with trailing arrow.
- **Margin:** 16px top, 8px bottom.

### 10.2 Dividers

Three weights:

| Weight | Use |
|---|---|
| 0.5px `ink-border` | List item separators inside a card, table rows |
| 1px `ink-border` | Section breaks within a screen (rarely needed — usually whitespace suffices) |
| 1.5px `ink-border-strong` | Hard section breaks (rare — never on a single screen, used between major regions) |

### 10.3 Dashed dividers

For form helper text or "or" separators between options, use a dashed divider:

- `0.5px dashed` border with `rgba(7, 18, 56, 0.15)` color
- Used in: form field helper-text underlines (when present), between OR options in choice cards

---

## 11. Badges and chips

### 11.1 Status chips

Covered in `Keystona_Aurora_Design_System.md` §6.3. Referenced here for completeness:

- 9px JetBrains Mono, 600 weight, uppercase
- Padding 3px 7px
- Radius `radius-xs` (4px)
- Surface + text colors per status (see Design System §2.2)

### 11.2 Tier badges (Free / Premium / Family)

Used to mark gated features or current tier status:

| Tier | Background | Text color | Label | Where |
|---|---|---|---|---|
| Free | `butter` | `ink-secondary` | "FREE" | Settings → Subscription |
| Premium | `coral` | white | "★ PREMIUM" | Feature unlocks, badges next to gated features |
| Family | `cobalt` | white | "★ FAMILY" | Multi-property switcher, household sharing |

- Style: JetBrains Mono, 9px, 700 weight, uppercase, 0.8px tracking, padding 3px 8px, `radius-xs` (4px).
- The star prefix `★` is part of the label for Premium and Family — not a separate icon.

### 11.3 Count badges

Used on tabs and icons to indicate unread notifications or pending counts:

- 16×16 minimum, 18×18 typical, 22×22 for two-digit counts
- Background: `coral` (for urgent counts) or `cobalt` (for info counts)
- Text: white, JetBrains Mono 9px 700, centered
- Shape: `radius-full` for single-digit, `radius-md` (12px) pill shape for double-digit
- Position: top-right of the icon, offset -4px right and -2px up (overlapping the icon)
- Max display: "99+" for counts over 99

### 11.4 Filter pills

Covered in `Keystona_Aurora_Design_System.md` §6.4. Referenced here for completeness.

---

## 12. Avatars

### 12.1 Avatar sizes and surfaces

| Size | Use |
|---|---|
| 24px | Inline in row metadata |
| 32px | Comment rows, contact list |
| 36px | Emergency contact rows |
| 48px | Settings account card |
| 64px | Profile screen header |
| 96px | (not used at v1) |

### 12.2 Avatar variants

- **Photo avatar:** circular crop of user-supplied image, no border. If image fails to load, falls back to initials.
- **Initials avatar:** background per category color, text in matching deep color. For favorites: `coral` background with white text. For non-favorite contacts: `butter` background with ink text.
- **Icon avatar:** for system entities (not people), use a category icon centered in the appropriate dim-tile background.

### 12.3 Flutter widget contract

```dart
class AuroraAvatar extends StatelessWidget {
  final double size;
  final String? imageUrl;
  final String? initials;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
}
```

---

## 13. Pull-to-refresh

### 13.1 Pattern

When a user pulls down on a scrollable list, a refresh indicator appears at the top.

- **Indicator:** 24px coral spinner, centered horizontally, appearing 12px below the screen top edge as the user pulls.
- **Pull threshold:** 80px before refresh triggers.
- **Pull behavior:** the indicator fades in from 0% to 100% opacity as the user pulls past 40px, then scales from 0.6 to 1.0 between 60px and 80px.
- **Refresh duration:** maintained until the data fetch resolves, with a 400ms minimum to prevent flicker.
- **Completion:** spinner fades out over 200ms; if new content arrived, it animates in with a slide-down + fade (200ms staggered per item, max 5 items animated).

### 13.2 Where it's used

- Documents list
- Tasks list
- Projects list
- Notifications inbox
- Emergency Hub (forces a sync attempt)

Never on:
- Settings (no live data)
- Form screens (would conflict with keyboard / scroll behavior)
- Modal sheets (sheet would dismiss instead)

### 13.3 Flutter widget contract

Use Flutter's `RefreshIndicator` wrapped with Aurora styling:

```dart
class AuroraRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
}
```

---

## 14. Offline banner (system-wide)

### 14.1 Pattern

When connectivity is lost, a butter-colored banner appears at the very top of the screen (above any screen header), persistent until connectivity returns.

```
┌─────────────────────────────────────────────────┐
│  ⊘  Working offline · Emergency Hub available  │  ← butter banner, ink text
└─────────────────────────────────────────────────┘
```

- **Container:** full-width, `butter` background, no border, padding 8px 16px.
- **Position:** below the system status bar, above the screen header. Pushes screen content down by its height (~36px).
- **Icon:** `ti-cloud-off` or similar, 16px, ink color.
- **Text:** Inter 500, 12px, ink color. Includes a reassuring secondary phrase: "Emergency Hub available" reminds the user that critical info is still reachable.
- **No dismiss action.** Resolves when connectivity returns; on resolve, banner slides up and out over 220ms.

### 14.2 Special cases

- **Inside Emergency Hub:** the offline banner is REPLACED by the Emergency Hub's own "Works offline · last synced N min ago" surface (per Emergency Hub screen spec). Avoid double-banner visual.
- **During an action requiring connectivity:** show a toast (not a banner) — "Couldn't sync. Will retry when online." — and disable the action's commit button.

---

## 15. Updating the Empty States Catalog

`HomeTrack_Empty_States_Catalog.md` is the existing canonical doc for empty state copy. It must be updated to reference Aurora tokens. The mapping:

| v1 reference | Aurora replacement |
|---|---|
| "Deep Navy" icon color | `ink` `#071238` |
| "Gold Accent" CTA background | `coral` `#FF3B62` |
| "Success Green" check icons | `lime` for cards, `lime-deep` for icon-only |
| "120px icon" (Pattern A) | unchanged size; icon now sits inside a 120px coral circle with yellow blob (per §8.2) |
| "64px gray icon" (Pattern C) | 64px `ink-tertiary` |
| "Pattern A — Motivational" CTA copy | unchanged |
| "Pattern B — Showcase" ghosted card opacity | 30% (was 50% in v1) — slightly less ghosted to read better against white canvas |
| "Pattern C — Instructional" gray icon color | `ink-tertiary` `rgba(7, 18, 56, 0.35)` |
| "Pattern D — Celebration" green check | `lime-deep` `#4A6604` icon inside `lime` `radius-full` circle |
| "Pattern E — Single CTA card" — Gold Accent icon | `coral` icon (when in coral-dim circle) or `ink` (when in butter circle) |

All copy from the existing Empty States Catalog is preserved verbatim. Only the visual treatment changes.

---

## 16. Component build order recommendation

For the Flutter agent, after the `AuroraForm*` widget kit lands (per Form Schemas §12), build components in this order:

1. **§10 Section headers and dividers** — used on every screen, low complexity.
2. **§11 Badges and chips** — used in lists and headers, low complexity.
3. **§12 Avatars** — used in contacts list, settings, dashboard greeting.
4. **§4 Toasts and snackbars** — needed by every save action.
5. **§5 Banners** — needed by tier limits, offline state, expiring renewals.
6. **§2 Modals** — needed by delete confirmations, upgrade prompts.
7. **§3 Bottom sheets** — needed by sub-forms (already specced) and link pickers.
8. **§8 Empty states** — needed for every list screen's empty render.
9. **§9 Loading and skeleton states** — polish layer, build after primary functionality works.
10. **§13 Pull-to-refresh** — polish layer.
11. **§14 Offline banner** — last, after offline sync logic is built.
12. **§6 Photo viewer** — needed when first photos ship (Home Profile photos, Project photos).
13. **§7 PDF viewer** — needed when Document Vault ships.

---

## 17. What's NOT in this doc

These surfaces have their own canonical specs and are not duplicated here:

- **Onboarding flow** — see forthcoming `Keystona_Aurora_Onboarding_Spec.md`
- **Dashboard 8-state variations** — see `HomeTrack_Dashboard_States.md` (must be updated to Aurora)
- **Health Score algorithm and visualizations** — see `HomeTrack_Health_Score_Algorithm.md`
- **Notification priority and copy** — see `HomeTrack_Notification_Priority.md`
- **Emergency Hub offline architecture** — see `HomeTrack_SRS.md` §3.4.4
- **Subscription tier definitions** — see `HomeTrack_SRS.md` §5 (canonical pricing: $9.99/mo or $79.99/yr, 50-doc free cap, 30-day trial)

---

*End of Aurora component library.*
