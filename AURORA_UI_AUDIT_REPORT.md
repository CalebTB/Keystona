# Aurora UI/UX Audit Report — Keystona

**Date:** 2026-06-22
**Files Audited:** 45
**Branch:** feature/64-ui-polish-pass

---

> ## ⚠️ CORRECTION — 2026-10-04
>
> **This report's radius and spacing reference tables were wrong.** They were used to drive
> ~223 radius and ~326 spacing substitutions. Verified against `aurora_radius.dart`,
> `aurora_spacing.dart`, and `Keystona_Aurora_Design_System.md` §4.1:
>
> | Token | This report claimed | **Actual** |
> |---|---|---|
> | `AuroraRadius.xs` | 2px | **4px** |
> | `AuroraRadius.sm` | 4px | **8px** |
> | `AuroraRadius.md` | 8px | **12px** |
> | `AuroraRadius.lg` | 12px | **14px** |
> | `AuroraRadius.xl` | 16px | 16px ✓ |
> | `AuroraRadius.xxl` | 24px | **22px** |
> | `AuroraRadius.full` | 9999px | 999px |
>
> `AuroraSpacing` is **not** a 4px grid. Actual scale: `space1`=4, `space2`=6, `space3`=8,
> `space4`=10, `space5`=12, `space6`=14, `space7`=16, `space8`=20, `space9`=24, `space10`=32.
> CAT-4's claim that 6, 10, and 14 are "off-grid" is false — those are `space2`/`space4`/`space6`.
>
> CAT-13's claim that `Radius.circular(2)` → `AuroraRadius.xs` is "pixel-identical" is also
> false: that substitution changed 2px to 4px.
>
> **Authority for component radii is `Keystona_Aurora_Design_System.md` §6.x, not §4.1's
> "where used" column.** §4.1 lists input fields under `radius-sm`, but §6.8 (the canonical
> `AuroraTextField` spec) specifies `radius-md` (12px). §6.8 governs.

---

## Executive Summary

| Severity | Count |
|----------|-------|
| HIGH     | 41    |
| MEDIUM   | 63    |
| LOW      | 28    |
| **Total**| **132** |

**Top 5 Most Critical Issues:**

1. **Raw `GoogleFonts.*` calls in feature code** — 30+ violations across 6 files. Every call should be replaced with an `AuroraType.*` token. The most severe offenders are `task_detail_screen.dart` (~20 violations), `home_profile_screen.dart`, `system_detail_screen.dart`, and `appliance_detail_screen.dart`.

2. **`Colors.white` / `Colors.black` outside intentional exceptions** — 35+ violations. Appears in settings, emergency hub, paywall, appliances screen FABs, welcome screen, and documents screens. Must use `AuroraColors.textInverse` or the appropriate Aurora surface token.

3. **`BorderRadius.circular(N)` with arbitrary values** — 50+ violations across nearly every screen. Common arbitrary values: 2, 3, 4, 7, 8, 9, 10, 11, 12, 14, 16, 20, 999. Must be replaced with `AuroraRadius.*` tokens.

4. **Raw empty states** — 5 confirmed violations where a raw centered `Column` with Icon + Text is used instead of the `EmptyState` / `EmptyStateHero` / `EmptyStateCta` widget.

5. **`CircularProgressIndicator` for content loading** — 2 violations where list/content areas show a spinner instead of a skeleton shimmer. The Aurora spec mandates skeleton loading for all data-driven content areas.

---

## Issues by Category

---

### CAT-1: Raw `GoogleFonts.*` TextStyle Calls (HIGH)

Aurora rule: All typography must use `AuroraType.*` tokens. `GoogleFonts.inter()` and `GoogleFonts.jetBrainsMono()` must never appear in feature code.

#### `lib/features/maintenance/screens/task_detail_screen.dart` — ~20 violations (HIGH)

Every sub-widget in this file uses raw `GoogleFonts.*` calls:

- `_LedgerHeader`: `GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: AuroraColors.inkSecondary)` — use `AuroraType.labelSm.copyWith(...)`
- `_OverdueBadge`: `GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: ...)` — use `AuroraType.labelSm.copyWith(...)`
- `_DoneBadge`: same pattern
- `_DueBadge`: same pattern
- `_StatCell` (×3 per cell): `GoogleFonts.inter(fontSize: 11, ...)` for value; `GoogleFonts.jetBrainsMono(fontSize: 9, ...)` for label — use `AuroraType.bodySm` / `AuroraType.labelSm`
- `_InstructionsRow`: `GoogleFonts.inter(...)` for body text — use `AuroraType.body`
- `_InstructionLabel`: `GoogleFonts.inter(fontSize: 10, ...)` — use `AuroraType.labelSm`
- `_ServiceHistory` section header: `GoogleFonts.inter(...)` — use `AuroraType.label`
- `_ScheduledNextEntry`: `GoogleFonts.inter(...)` for date and label — use `AuroraType.body` / `AuroraType.label`
- `_OverdueEntry`: same
- `_CompletionEntry`: `GoogleFonts.inter(...)` and `GoogleFonts.jetBrainsMono(...)` — use Aurora tokens
- `_EmptyHistory`: `GoogleFonts.inter(...)` — use `AuroraType.body`

**File:** `/Users/calebbyers/Code/Keystona/apps/keystona/lib/features/maintenance/screens/task_detail_screen.dart`

---

#### `lib/features/home_profile/screens/home_profile_screen.dart` — 10 violations (HIGH)

- `_LegendDot`: `GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, ...)` — use `AuroraType.labelSm`
- `_SystemCard` health badge: `GoogleFonts.jetBrainsMono(...)` — use `AuroraType.label`
- `_SystemCard` spec text: `GoogleFonts.inter(...)` — use `AuroraType.bodySm`
- `_SystemCard` age text: `GoogleFonts.inter(...)` — use `AuroraType.bodySm`
- `_SystemCard` remaining text: `GoogleFonts.inter(...)` — use `AuroraType.bodySm`
- `_SystemCard` cost/warranty badge: `GoogleFonts.jetBrainsMono(...)` — use `AuroraType.labelSm`
- `_ApplianceCard` (same pattern as `_SystemCard` — 4 violations)
- `_SectionLoadingPlaceholder`: `GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600)` — use `AuroraType.h3`

**File:** `/Users/calebbyers/Code/Keystona/apps/keystona/lib/features/home_profile/screens/home_profile_screen.dart`

---

#### `lib/features/home_profile/screens/system_detail_screen.dart` — 6 violations (HIGH)

- Hero eyebrow: `GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, ...)` — use `AuroraType.label.copyWith(...)`
- Hero subtitle: `GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w400, ...)` — use `AuroraType.bodySm`
- `_StatCell2` label: `GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.w700, ...)` — use `AuroraType.labelSm`
- `_WarrantyCalloutCard2` label: `GoogleFonts.jetBrainsMono(fontSize: 9, ...)` — use `AuroraType.labelSm`
- `_QuickActionCell2` subtitle: `GoogleFonts.jetBrainsMono(fontSize: 11, ...)` — use `AuroraType.bodySm`

**File:** `/Users/calebbyers/Code/Keystona/apps/keystona/lib/features/home_profile/screens/system_detail_screen.dart`

---

#### `lib/features/home_profile/screens/appliance_detail_screen.dart` — 6 violations (HIGH)

Same pattern as `system_detail_screen.dart` — hero eyebrow, hero subtitle, `_StatCell` label, `_WarrantyCalloutCard` label, `_QuickActionCell` subtitle all use `GoogleFonts.jetBrainsMono(...)`.

**File:** `/Users/calebbyers/Code/Keystona/apps/keystona/lib/features/home_profile/screens/appliance_detail_screen.dart`

---

### CAT-2: `Colors.white` and `Colors.black` Violations (HIGH)

Aurora rule: These raw `Colors.*` values are prohibited in feature code. Intentional exceptions: `_FullscreenPreview`, `_PdfPreview`, `_ImagePreview` in `document_detail_screen.dart`, and `photo_comparison_screen.dart`.

#### `lib/features/settings/screens/settings_screen.dart` (HIGH)

- `_AccountCard`: `AuroraType.h2.copyWith(color: Colors.white)` — use `AuroraColors.paper` or `AuroraColors.textInverse`
- `_AccountCard`: `AuroraType.h3.copyWith(color: Colors.white)` — same fix
- `_AccountCard`: `AuroraType.bodySm.copyWith(color: Colors.white.withValues(alpha: 0.65))` — same fix
- `_AccountCard`: `Colors.white.withValues(alpha: 0.40)` for chevron icon — same fix
- `_ProUpgradeCard`: `AuroraType.h3.copyWith(color: Colors.white)` — same fix
- `_ProUpgradeCard`: `AuroraType.body.copyWith(color: Colors.white.withValues(alpha: 0.80))` — same fix

**File:** `/Users/calebbyers/Code/Keystona/apps/keystona/lib/features/settings/screens/settings_screen.dart`

---

#### `lib/features/emergency/screens/emergency_hub_screen.dart` (HIGH)

`_Call911Card` is a coral-background card where all text and icon colors use raw `Colors.white`:
- Icon container: `Colors.white.withValues(alpha: 0.20)` — use `AuroraColors.paper.withValues(alpha: 0.20)`
- Phone icon: `color: Colors.white` — use `AuroraColors.paper`
- 'EMERGENCY' label: `Colors.white.withValues(alpha: 0.78)` — use `AuroraColors.paper.withValues(...)`
- 'Call 911' heading: `Colors.white` — use `AuroraColors.paper`
- Body text: `Colors.white.withValues(alpha: 0.78)` — use `AuroraColors.paper.withValues(...)`
- Trailing icon: `color: Colors.white` — use `AuroraColors.paper`

**File:** `/Users/calebbyers/Code/Keystona/apps/keystona/lib/features/emergency/screens/emergency_hub_screen.dart`

---

#### `lib/features/subscription/screens/paywall_screen.dart` (HIGH)

The paywall has a dark gradient background (ink → cobalt → paper). While this is an intentional dark-on-dark design, all text/icon colors use raw `Colors.white`:
- `_HeroSection`: hero icon `color: Colors.white`; `AuroraType.h1.copyWith(color: Colors.white)`; `AuroraType.bodyLg.copyWith(color: Colors.white.withValues(alpha: 0.80))`
- `_FeatureList` container: `Colors.white.withAlpha(18)` background; `Colors.white.withAlpha(30)` border
- `_CloseButton`: close button container `Colors.white.withAlpha(30)` background; `color: Colors.white` icon

These require design decision: either add dedicated `AuroraColors.onDark*` tokens for paywall use, or mark as intentional exceptions with a code comment. Until resolved, flag as HIGH.

**File:** `/Users/calebbyers/Code/Keystona/apps/keystona/lib/features/subscription/screens/paywall_screen.dart`

---

#### `lib/features/documents/screens/documents_screen.dart` (HIGH)

- Add button (iOS and Android): `color: Colors.white` for icon and label
- `_FilterPill` selected: `Colors.white` for label; `Colors.white.withValues(alpha: 0.75)` for count badge text
- `_StorageTierCard`: multiple `Colors.white` and `Colors.white.withAlpha(...)` on dark surfaces

**File:** `/Users/calebbyers/Code/Keystona/apps/keystona/lib/features/documents/screens/documents_screen.dart`

---

#### `lib/features/documents/screens/document_detail_screen.dart` (MEDIUM)

- Undo snackbar: `Colors.white` text — should use `SnackbarService` which handles this correctly
- Preview thumbnail scrim: `Colors.black.withValues(alpha: 0.35)` and `Colors.white` — these are in the non-fullscreen thumbnail, NOT in the intentional exceptions block

**File:** `/Users/calebbyers/Code/Keystona/apps/keystona/lib/features/documents/screens/document_detail_screen.dart`

---

#### `lib/features/documents/screens/document_categories_screen.dart` (MEDIUM)

- FAB `foregroundColor: Colors.white` — use `AuroraColors.paper`
- Category icon `color: Colors.white` on coral background — use `AuroraColors.paper`

**File:** `/Users/calebbyers/Code/Keystona/apps/keystona/lib/features/documents/screens/document_categories_screen.dart`

---

#### `lib/features/home_profile/screens/home_profile_screen.dart` (HIGH)

- `_AndroidLayout` FAB: `const Icon(Icons.add, color: Colors.white)` — use `AuroraColors.paper`
- `_AddFab`: `const Icon(Icons.add, color: Colors.white)` — use `AuroraColors.paper`
- `_PropertyCard`: `const Color(0xFFFFFFFF)` — use `AuroraColors.paper`; `const Color(0x59FFFFFF)` — use `AuroraColors.paper.withValues(alpha: 0.35)`

**File:** `/Users/calebbyers/Code/Keystona/apps/keystona/lib/features/home_profile/screens/home_profile_screen.dart`

---

#### `lib/features/home_profile/screens/property_edit_screen.dart` (HIGH)

- `_PhotoSlot` overlay icon: `Colors.white` — use `AuroraColors.paper`
- `_PhotoSlot` overlay label: `Colors.white` — use `AuroraColors.paper`
- `Colors.green` for success check icon — use `AuroraColors.lime` or `AuroraColors.limeDeep`

**File:** `/Users/calebbyers/Code/Keystona/apps/keystona/lib/features/home_profile/screens/property_edit_screen.dart`

---

#### `lib/features/onboarding/screens/welcome_screen.dart` (MEDIUM)

- `_HeroCircle` icon: `const Icon(Icons.home_work_rounded, color: Colors.white, size: 52)` — use `AuroraColors.paper`. Note: `EmptyStateHero` widget in `empty_state.dart` has the same pattern (`Colors.white` icon on coral circle) so this should be normalized to `AuroraColors.paper` across the board.

**File:** `/Users/calebbyers/Code/Keystona/apps/keystona/lib/features/onboarding/screens/welcome_screen.dart`

---

#### `lib/features/home_profile/screens/appliances_screen.dart` (MEDIUM)

- iOS FAB: `foregroundColor: Colors.white` — use `AuroraColors.paper`
- Android FAB: `foregroundColor: Colors.white` — use `AuroraColors.paper`

**File:** `/Users/calebbyers/Code/Keystona/apps/keystona/lib/features/home_profile/screens/appliances_screen.dart`

---

#### `lib/features/projects/screens/projects_screen.dart` (MEDIUM)

- `_Chip` selected label: `Colors.white` — use `AuroraColors.paper`
- `_Chip` selected count badge background: `Colors.white.withValues(alpha: 0.15)` — use `AuroraColors.paper.withValues(...)`
- `_Chip` selected count badge text: `Colors.white.withValues(alpha: 0.8)` — use `AuroraColors.paper.withValues(...)`

**File:** `/Users/calebbyers/Code/Keystona/apps/keystona/lib/features/projects/screens/projects_screen.dart`

---

### CAT-3: `BorderRadius.circular(N)` with Arbitrary Values (MEDIUM/HIGH)

Aurora rule: All border radii must use `AuroraRadius.*` tokens (`xs`=2, `sm`=4, `md`=8, `lg`=12, `xl`=16, `xxl`=24, `full`=9999). Any `BorderRadius.circular(N)` with a value not mapping to these tokens is a violation.

Quick reference (CORRECTED — exact token values):
- `N=4` → `AuroraRadius.xs`
- `N=8` → `AuroraRadius.sm`
- `N=12` → `AuroraRadius.md`
- `N=14` → `AuroraRadius.lg`
- `N=16` → `AuroraRadius.xl`
- `N=22` → `AuroraRadius.xxl`
- `N=999` → `AuroraRadius.full`
- Other values (2, 3, 7, 9, 10, 11, 13, 20) — pick the nearest token, but FIRST check whether the
  value is intentional inset compensation (e.g. outer `md`=12 minus a 1.5px border = 10.5;
  outer `lg`=14 minus a 1px border = 13). Those are correct and must not be "fixed" — unless the
  content is already wrapped in a `ClipRRect` at the outer radius, in which case the clip governs
  and the compensation is unnecessary.

**`lib/features/maintenance/screens/task_detail_screen.dart`** (HIGH)
- `BorderRadius.circular(10)` — use `AuroraRadius.lg` (12) or `AuroraRadius.md` (8)
- `BorderRadius.circular(12)` — use `AuroraRadius.lg`
- `BorderRadius.circular(7)` — use `AuroraRadius.sm` or `AuroraRadius.md`
- `BorderRadius.circular(4)` — use `AuroraRadius.sm`
- `BorderRadius.circular(16)` — use `AuroraRadius.xl`
- `BorderRadius.vertical(top: Radius.circular(16))` for skip-reason sheet — use `AuroraRadius.xl` equivalent

**`lib/features/maintenance/screens/task_form_screen.dart`** (HIGH)
- `_inputDecoration`: `BorderRadius.all(Radius.circular(8))` on all 5 border variants — replace all with `AuroraRadius.md`
- `_TapRow`: `BorderRadius.all(Radius.circular(8))` — use `AuroraRadius.md`
- `_SectionHeader` dot: `BorderRadius.all(Radius.circular(2))` — use `AuroraRadius.xs`

**`lib/features/maintenance/screens/task_completion_form_screen.dart`** (MEDIUM)
- `_SectionLabel` dot: `BorderRadius.all(Radius.circular(2))` — use `AuroraRadius.xs`

**`lib/features/documents/screens/documents_screen.dart`** (MEDIUM)
- `BorderRadius.circular(999)` on filter pills — use `AuroraRadius.full`
- `BorderRadius.circular(12)` on `_DocGridTile` — use `AuroraRadius.lg`

**`lib/features/documents/screens/document_detail_screen.dart`** (MEDIUM)
- `BorderRadius.circular(16)` — use `AuroraRadius.xl`
- `BorderRadius.circular(14.5)` — use `AuroraRadius.xl` (nearest)
- `BorderRadius.circular(8)` — use `AuroraRadius.md`
- `BorderRadius.circular(4)` — use `AuroraRadius.sm`
- `BorderRadius.circular(9)` — use `AuroraRadius.md` or `AuroraRadius.lg`
- `BorderRadius.circular(13)` — use `AuroraRadius.lg`
- `BorderRadius.circular(12)` — use `AuroraRadius.lg`

**`lib/features/home_profile/screens/home_profile_screen.dart`** (HIGH)
- `_kCardDecoration`: `BorderRadius.all(Radius.circular(14))` — use `AuroraRadius.xl`
- `_PropertyCard`: `BorderRadius.all(Radius.circular(16 + 2))` (computed) — use `AuroraRadius.xl` or `AuroraRadius.xxl`
- `_SystemCard` icon container: `BorderRadius.circular(11)` — use `AuroraRadius.lg`
- `_SystemCard` health badge: `BorderRadius.circular(4)` — use `AuroraRadius.sm`
- `_SystemCard` progress bar: `BorderRadius.circular(3)` — use `AuroraRadius.xs`
- Forecast strip: `BorderRadius.all(Radius.circular(14))` — use `AuroraRadius.xl`
- Forecast strip status badge: `BorderRadius.circular(9)` — use `AuroraRadius.md`

**`lib/features/home_profile/screens/system_form_screen.dart`** (HIGH)
- `_TextField` all 5 border variants: `BorderRadius.circular(14)` — use `AuroraRadius.xl` or `AuroraRadius.lg`
- `_CategoryDropdown`, `_StatusDropdown`: same `BorderRadius.circular(14)` — same fix
- `_DatePickerField`: `BorderRadius.circular(14)` — same fix

**`lib/features/home_profile/screens/appliance_form_screen.dart`** (HIGH)
- `_TextField` all borders: `BorderRadius.circular(8)` — use `AuroraRadius.md`
- `_PickerField` (iOS and Android): `BorderRadius.circular(8)` — use `AuroraRadius.md`
- `_DateField`: `BorderRadius.circular(8)` — use `AuroraRadius.md`

**`lib/features/home_profile/screens/system_detail_screen.dart`** (HIGH)
- `_SkeletonBar`: `BorderRadius.all(Radius.circular(8))` — use `AuroraRadius.md`
- Hero card: `BorderRadius.all(Radius.circular(16))` — use `AuroraRadius.xl`
- Hero card inner: `BorderRadius.circular(16 - 1.5)` (computed) — use `AuroraRadius.xl`
- Hero card icon container: `BorderRadius.circular(12)` — use `AuroraRadius.lg`
- `_SectionLabel2` dot: `BorderRadius.all(Radius.circular(2))` — use `AuroraRadius.xs`
- Android photo source sheet: `BorderRadius.vertical(top: Radius.circular(16))` — use `BorderRadius.vertical(top: AuroraRadius.xl.topLeft)`

**`lib/features/home_profile/screens/appliance_detail_screen.dart`** (HIGH)
- Same hero card pattern as `system_detail_screen.dart` — `Radius.circular(16)`, computed `16 - 1.5`, `Radius.circular(12)`, `Radius.circular(2)` dot
- `SizedBox(width: 10)`, `SizedBox(height: 14)`, `SizedBox(height: 6)`, `SizedBox(height: 3)` — off grid (see CAT-4)

**`lib/features/home_profile/screens/property_edit_screen.dart`** (MEDIUM)
- `_kCardDecoration`: `BorderRadius.all(Radius.circular(14))` — use `AuroraRadius.xl`
- `_FieldCard` animated container: `BorderRadius.all(Radius.circular(14))` — same fix
- Zone icon container: `BorderRadius.circular(9)` — use `AuroraRadius.md`
- Photo overlay button: `BorderRadius.circular(20)` — use `AuroraRadius.xxl`
- Progress bar clip: `BorderRadius.circular(3)` — use `AuroraRadius.xs`

**`lib/features/emergency/screens/emergency_hub_screen.dart`** (MEDIUM)
- `_SectionHeader` dot: `BorderRadius.all(Radius.circular(2))` — use `AuroraRadius.xs`

**`lib/features/settings/screens/settings_screen.dart`** (MEDIUM)
- `_SectionHeader` dot: `BorderRadius.all(Radius.circular(2))` — use `AuroraRadius.xs`

**`lib/features/settings/screens/settings_profile_screen.dart`** (MEDIUM)
- `_FormSectionHeader` dot: `BorderRadius.all(Radius.circular(2))` — use `AuroraRadius.xs`

**`lib/features/projects/screens/projects_screen.dart`** (MEDIUM)
- `_Chip`: `BorderRadius.circular(999.0)` — use `AuroraRadius.full`
- `_Chip` count badge: `BorderRadius.circular(10)` — use `AuroraRadius.lg` or `AuroraRadius.md`
- `_PageDots`: `BorderRadius.circular(dotSize)` with variable `dotSize` — acceptable for pill dots but should be `AuroraRadius.full`

**`lib/features/projects/screens/project_form_screen.dart`** (HIGH)
- `_inputDecoration`: `BorderRadius.circular(8)` across all 3 border variants — use `AuroraRadius.md`
- `_SectionHeader` dot uses `BoxShape.circle` (correct for dots); acceptable here

**`lib/features/maintenance/screens/maintenance_screen.dart`** (MEDIUM)
- `BorderRadius.all(Radius.circular(14))` in skeleton — use `AuroraRadius.xl`

**`lib/core/widgets/snackbar_service.dart`** (LOW)
- `BorderRadius.all(Radius.circular(12))` on snackbar shape — use `AuroraRadius.lg`. This is a core widget; fix here propagates app-wide.

---

### CAT-4: Off-Grid Spacing Values (MEDIUM)

Aurora rule: All spacing must use `AuroraSpacing.*` tokens. **The scale is NOT a 4px grid** (the
doc comment in `aurora_spacing.dart` is misleading): `space1`=4, `space2`=6, `space3`=8, `space4`=10,
`space5`=12, `space6`=14, `space7`=16, `space8`=20, `space9`=24, `space10`=32.

Therefore 6, 10, and 14 **are** valid token values (`space2`, `space4`, `space6`) and need only be
rewritten as tokens with no pixel change. Genuinely non-token values are 2, 3, 5, 7, 9, 11, 13, 18.
The per-file notes below that call 6/10/14 "off grid" are incorrect.

**`lib/features/maintenance/screens/maintenance_screen.dart`** (MEDIUM)
- `SizedBox(height: 14)` — use `space4` (16) or `space3` (12)
- `SizedBox(height: 10)` — use `space2` (8) or `space3` (12)
- `SizedBox(height: 18)` — use `space5` (20)
- `SizedBox(height: 11)` — not on grid; use `space3` (12)
- `SizedBox(height: 6)` — use `space1` (4) or `space2` (8)
- Tab strip padding `top: 6, bottom: 11` — both off grid

**`lib/features/home/screens/home_screen.dart`** (MEDIUM)
- `SizedBox(width: 3)` — use `space1` (4)
- `SizedBox(width: 5)` — use `space1` (4) or `space2` (8)

**`lib/features/home_profile/screens/home_profile_screen.dart`** (MEDIUM)
- `SizedBox(width: 14)` — use `space4` (16) or `space3` (12)
- `SizedBox(height: 6)` — use `space1` (4) or `space2` (8)
- `SizedBox(height: 5)` — use `space1` (4)
- `SizedBox(height: 2)` — use `space1` (4)
- `SizedBox(width: 6)` in `_SectionHeader` — use `space1` (4) or `space2` (8)
- Forecast strip: `EdgeInsets.symmetric(horizontal: 14, vertical: 12)` — 14 off grid; use `space4` (16)
- `AuroraType.h3.copyWith(fontSize: 13)` — raw font size override, use `AuroraType.body` or design token

**`lib/features/home_profile/screens/system_detail_screen.dart`** (MEDIUM)
- `EdgeInsets.fromLTRB(18, 14, 18, 14)` — 18 and 14 both off grid; use `EdgeInsets.fromLTRB(AuroraSpacing.space5, AuroraSpacing.space4, AuroraSpacing.space5, AuroraSpacing.space4)` (20, 16, 20, 16)

**`lib/features/home_profile/screens/appliance_detail_screen.dart`** (MEDIUM)
- `EdgeInsets.fromLTRB(18, 14, 18, 14)` — same as above
- `SizedBox(width: 10)` — use `space2` (8)
- `SizedBox(height: 14)` — use `space4` (16) or `space3` (12)
- `SizedBox(height: 6)` — use `space2` (8)
- `SizedBox(height: 3)` — use `space1` (4)

**`lib/features/projects/screens/projects_screen.dart`** (LOW)
- `SizedBox(height: 16)` — replace with `const SizedBox(height: AuroraSpacing.space4)`
- `Padding(padding: const EdgeInsets.symmetric(vertical: 16))` for page dots — use `AuroraSpacing.space4`
- `_Header`: `EdgeInsets.fromLTRB(20, 20, 20, 4)` — 20 is `screenPadH` (correct); 4 is `space1` (acceptable); however should use tokens explicitly: `EdgeInsets.fromLTRB(AuroraSpacing.screenPadH, AuroraSpacing.screenPadH, AuroraSpacing.screenPadH, AuroraSpacing.space1)`
- `_FilterChips`: `EdgeInsets.fromLTRB(20, 12, 20, 4)` — 12 is `space3` (acceptable)
- `_Chip`: `EdgeInsets.symmetric(horizontal: 14, vertical: 8)` — 14 off grid; use `space4` (16)
- `_Chip` count badge: `EdgeInsets.symmetric(horizontal: 5, vertical: 1)` — 5 and 1 off grid
- `_Chip` count badge: `SizedBox(width: 5)` — off grid

**`lib/features/settings/screens/settings_profile_screen.dart`** (LOW)
- `_InfoRow`: `EdgeInsets.symmetric(horizontal: ..., vertical: 13)` — 13 off grid; use `space3` (12) or `space4` (16)
- `_FormSectionHeader` gap: `SizedBox(width: 6)` — use `space1` (4) or `space2` (8)

**`lib/features/emergency/screens/emergency_hub_screen.dart`** (LOW)
- `_Call911Card` inner column: `SizedBox(height: 2)` (×2) — use `space1` (4)
- `_ShutoffTile` status text: `AuroraType.bodySm.copyWith(fontSize: 10)` — raw font size override; use `AuroraType.labelSm`

---

### CAT-5: Raw `Color(0x...)` Literals (MEDIUM)

Aurora rule: No inline raw `Color(0xFF...)` or `Color(0x0A...)` literals. Use `AuroraShadows.*` tokens or existing `AuroraColors.*` tokens.

**`lib/features/maintenance/screens/maintenance_screen.dart`** (MEDIUM)
- `_CircleIconButton` boxShadow: `color: Color(0x0A071238)` — use `AuroraShadows.cardSm` or equivalent shadow token

**`lib/features/documents/screens/documents_screen.dart`** (MEDIUM)
- `_DocGridTile` boxShadow: `Color(0x0D071238)` — use shadow token
- `_FeedRow` boxShadow: `Color(0x0A071238)` — use shadow token

**`lib/features/home_profile/screens/home_profile_screen.dart`** (MEDIUM)
- `_kCardDecoration` shadow: `Color(0x0D071238)` — use shadow token
- `_PropertyCard` colors: `const Color(0xFFFFFFFF)` — use `AuroraColors.paper`; `const Color(0x59FFFFFF)` — use `AuroraColors.paper.withValues(alpha: 0.35)`

**`lib/features/home_profile/screens/system_detail_screen.dart`** (MEDIUM)
- Hero card boxShadow: `Color(0x0A071238)` — use shadow token

**`lib/features/home_profile/screens/appliance_detail_screen.dart`** (MEDIUM)
- Hero card boxShadow: `Color(0x0A071238)` — use shadow token

**`lib/features/projects/screens/project_detail_screen.dart`** (MEDIUM)
- `_statusDim` helper: `const Color(0xFFEEEDF2)` as fallback — use `AuroraColors.butter` or `AuroraColors.inkBorder`

---

### CAT-6: Raw Empty States (HIGH)

Aurora rule: All empty states must use `EmptyState`, `EmptyStateHero`, or `EmptyStateCta` widgets. Raw centered `Column(Icon, Text, ...)` patterns are prohibited.

**`lib/features/home_profile/screens/home_profile_screen.dart`** — `_EmptySectionHint` (HIGH)

The `_EmptySectionHint` widget is a custom `Container` with icon + text, used inline for empty systems/appliances sections. Replace with `EmptyStateCta` or `EmptyState` as appropriate.

**File:** `/Users/calebbyers/Code/Keystona/apps/keystona/lib/features/home_profile/screens/home_profile_screen.dart`

---

**`lib/features/documents/screens/documents_screen.dart`** — `_FilteredEmptyState` (HIGH)

Raw centered `Column` with icon, text, and clear-filter button. Replace with `EmptyState` widget.

**File:** `/Users/calebbyers/Code/Keystona/apps/keystona/lib/features/documents/screens/documents_screen.dart`

---

**`lib/features/documents/screens/document_categories_screen.dart`** — `_EmptyCustomCategories` (HIGH)

Raw centered `Column` with icon and text. Replace with `EmptyState` widget.

**File:** `/Users/calebbyers/Code/Keystona/apps/keystona/lib/features/documents/screens/document_categories_screen.dart`

---

**`lib/features/maintenance/screens/task_completion_form_screen.dart`** — receipt picker empty state (MEDIUM)

The receipt picker shows a raw centered column instead of `EmptyState` or `EmptyStateCta`.

**File:** `/Users/calebbyers/Code/Keystona/apps/keystona/lib/features/maintenance/screens/task_completion_form_screen.dart`

---

**`lib/features/projects/screens/projects_screen.dart`** — `_NoResultsState` (MEDIUM)

The filtered-no-results state is a raw `Column` with icon, text, and a `TextButton`. Replace with `EmptyState` widget (pass the clear-filter action as `onAction`).

**File:** `/Users/calebbyers/Code/Keystona/apps/keystona/lib/features/projects/screens/projects_screen.dart`

---

### CAT-7: `CircularProgressIndicator` for Content Loading (HIGH)

Aurora rule: Content areas must use skeleton shimmer on frame 1. `CircularProgressIndicator` is only acceptable for inline action feedback (e.g., save button spinner).

**`lib/features/home_profile/screens/appliance_detail_screen.dart`** — `_Body` loading state (HIGH)

```
Center(child: CircularProgressIndicator(strokeWidth: 2))
```

This is the loading state for the entire appliance detail content body. Must be replaced with a skeleton shimmer matching the hero card + stat cells + quick action cells layout.

**File:** `/Users/calebbyers/Code/Keystona/apps/keystona/lib/features/home_profile/screens/appliance_detail_screen.dart`

---

**`lib/features/maintenance/screens/task_completion_form_screen.dart`** — receipt picker loading (MEDIUM)

```
CircularProgressIndicator(strokeWidth: 2)
```

Used while the receipt image picker is loading. Replace with an inline shimmer placeholder if the duration is noticeable, or at minimum an `AuroraColors.ink`-colored `CupertinoActivityIndicator`.

**File:** `/Users/calebbyers/Code/Keystona/apps/keystona/lib/features/maintenance/screens/task_completion_form_screen.dart`

---

### CAT-8: `AuroraType.label` / `AuroraType.labelSm` Without `.toUpperCase()` (MEDIUM)

Aurora rule: `AuroraType.label` and `AuroraType.labelSm` are mono fonts at 10px/9px. The spec requires `.toUpperCase()` at the call site, not inside the token. Dynamic values (e.g., 'Tasks', 'Docs', 'Photos') must be uppercased.

**`lib/features/home_profile/screens/system_detail_screen.dart`** (MEDIUM)
- `_QuickActionCell2` label: `AuroraType.labelSm` applied to `'Tasks'`, `'Docs'`, `'Photos'` without `.toUpperCase()`.

**`lib/features/home_profile/screens/appliance_detail_screen.dart`** (MEDIUM)
- `_QuickActionCell` label: same pattern — `'Tasks'`, `'Docs'`, `'Photos'` not uppercased.

**`lib/features/home/screens/home_screen.dart`** (MEDIUM)
- Quick action labels `'Scan'`, `'Emergency'`, `'Add Task'` rendered with `AuroraType.labelSm` without `.toUpperCase()`
- Stat labels rendered with `AuroraType.labelSm` without `.toUpperCase()`
- `'View all'` text using `AuroraType.labelSm` without `.toUpperCase()`

---

### CAT-9: `CupertinoColors` Usage (MEDIUM)

Aurora rule: `CupertinoColors.*` must not be used in feature code. All surface colors must come from `AuroraColors.*`.

**`lib/features/home_profile/screens/appliance_form_screen.dart`** (MEDIUM)
- iOS date picker container: `CupertinoColors.systemBackground.resolveFrom(context)` — use `AuroraColors.paper`

**`lib/features/home_profile/screens/system_detail_screen.dart`** (MEDIUM)
- `_DeleteBar`: `CupertinoColors.systemBackground` for iOS background — use `AuroraColors.paper`

**`lib/features/home_profile/screens/property_edit_screen.dart`** (MEDIUM)
- `_DoneToolbar` background: `CupertinoColors.systemBackground` — use `AuroraColors.paper`
- iOS date picker container: `CupertinoColors.systemBackground` — use `AuroraColors.paper`

**`lib/features/maintenance/screens/task_completion_form_screen.dart`** (MEDIUM)
- iOS date picker: `CupertinoColors.systemBackground.resolveFrom(context)` — use `AuroraColors.paper`

**`lib/features/projects/screens/project_form_screen.dart`** (MEDIUM)
- iOS date picker container: `CupertinoColors.systemBackground.resolveFrom(context)` — use `AuroraColors.paper`

---

### CAT-10: Form Field / Focus Border Violations (MEDIUM)

Aurora rule: Focused form fields must use a 2px coral border with `focusCoral` glow shadow. `AuroraTextField` shows the correct implementation.

**`lib/features/maintenance/screens/task_detail_screen.dart`** — skip reason `TextField` (MEDIUM)
- `focusedBorder` uses `AuroraColors.ink` instead of `AuroraColors.coral`

**`lib/features/maintenance/screens/task_form_screen.dart`** (HIGH)
- `_inputDecoration.focusedBorder`: uses `AuroraColors.ink` instead of `AuroraColors.coral`
- All 5 `InputDecoration` border variants use `BorderRadius.all(Radius.circular(8))` — replace with `AuroraRadius.md`
- `hintStyle` uses raw `TextStyle(color: AuroraColors.inkTertiary)` — replace with `AuroraType.body.copyWith(color: AuroraColors.inkTertiary)`
- `counterStyle` uses raw `TextStyle(color: ...)` — replace with `AuroraType.labelSm.copyWith(...)`

**`lib/features/maintenance/screens/task_completion_form_screen.dart`** (MEDIUM)
- `_FormField` label uses `AuroraType.body` for the label — should use `AuroraType.label` (mono) to match form conventions

**`lib/features/projects/screens/project_form_screen.dart`** (MEDIUM)
- `_inputDecoration.focusedBorder`: uses `AuroraColors.cobalt` with `width: 1.5` — should use `AuroraColors.coral` with `width: 2.0` per Aurora focus spec
- All borders use `BorderRadius.circular(8)` — replace with `AuroraRadius.md`

---

### CAT-11: Raw `TextStyle(...)` Constructors in Feature Code (MEDIUM)

Aurora rule: No raw `TextStyle(fontSize:, fontWeight:, color:, ...)` constructors in feature code. Use `AuroraType.*` tokens with `.copyWith()` for overrides.

**`lib/features/home_profile/screens/system_form_screen.dart`** (MEDIUM)
- iOS nav bar trailing save button: `TextStyle(color: AuroraColors.cobalt, fontWeight: FontWeight.w600)` — use `AuroraType.label.copyWith(color: AuroraColors.cobalt)`

**`lib/features/home_profile/screens/appliance_form_screen.dart`** (MEDIUM)
- iOS nav bar trailing: `TextStyle(color: AuroraColors.cobalt, fontWeight: FontWeight.w600)` — same fix

**`lib/features/home_profile/screens/property_edit_screen.dart`** (MEDIUM)
- `_CompletionBar`: `TextStyle(fontSize: 11, color: ..., fontWeight: ...)` — replace with `AuroraType.labelSm.copyWith(...)`
- `_FieldCard` error text: `TextStyle(fontSize: 10, color: AuroraColors.coral, height: 1.4)` — replace with `AuroraType.labelSm.copyWith(color: AuroraColors.coral, height: 1.4)`

**`lib/features/documents/screens/document_detail_screen.dart`** (MEDIUM)
- `_FileMeta` rich text: raw `TextStyle(...)` inside `TextSpan` — use `AuroraType.*` tokens

---

### CAT-12: `ScaffoldMessenger` Called Directly (LOW)

Aurora rule: All snackbars must route through `SnackbarService` for consistent styling.

**`lib/features/documents/screens/document_categories_screen.dart`** (LOW)
- Direct `ScaffoldMessenger.of(context).showSnackBar(...)` call — replace with `SnackbarService.showSuccess(...)` / `showError(...)`

---

### CAT-13: Section Header Dot Pattern Inconsistency (LOW)

Aurora rule: Section header dots are 7×7 containers with `AuroraRadius.xs` border radius, not `Radius.circular(2)` (even though they resolve to the same value, the token must be used for consistency). The dot fill color is `AuroraColors.cobaltDim` or `AuroraColors.inkSecondary` per context.

Multiple files use `BorderRadius.all(Radius.circular(2))` for the section header dot rather than `AuroraRadius.xs`. This is a LOW finding because the pixel output is identical, but token consistency is required:

- `home_profile_screen.dart` — `_SectionHeader` dot
- `system_detail_screen.dart` — `_SectionLabel2` dot
- `appliance_detail_screen.dart` — `_SectionLabel2` dot (inherits same widget)
- `emergency_hub_screen.dart` — `_SectionHeader` dot
- `settings_screen.dart` — `_SectionHeader` dot
- `settings_profile_screen.dart` — `_FormSectionHeader` dot

Fix uniformly: `BorderRadius.all(Radius.circular(2))` → `AuroraRadius.xs` everywhere.

---

### CAT-14: Non-Aurora Button Usage (MEDIUM)

Aurora rule: All interactive buttons must use `PrimaryButton` (coral), `SaveButton` (cobalt), `SecondaryButton`, or `GhostButton`. Non-Aurora button types (`CupertinoButton.filled`, `OutlinedButton.icon`, `TextButton`) may only be used where no Aurora equivalent exists.

**`lib/features/maintenance/screens/task_detail_screen.dart`** (MEDIUM)
- Skip reason sheet: `CupertinoButton.filled` — use `PrimaryButton` or `SaveButton` inside the sheet

**`lib/features/maintenance/screens/task_completion_form_screen.dart`** (MEDIUM)
- Receipt picker: `OutlinedButton.icon` — use `SecondaryButton` with an icon or `GhostButton`

**`lib/features/projects/screens/projects_screen.dart`** (LOW)
- `_NoResultsState` clear filter: `TextButton` — use `GhostButton` for consistency

---

### CAT-15: Required Asterisk in Label String (LOW)

Aurora rule: Required field indicator must be a separate coral `*` `TextSpan`, not embedded in the label string (e.g., `'Title *'` is wrong; the `*` must be a separate `Text` with `color: AuroraColors.coral`).

**`lib/features/maintenance/screens/task_form_screen.dart`** (LOW)
- Field labels include `'Title *'`, `'Due date *'` etc. with the asterisk embedded in the string rather than as a separate coral span.

Note: `project_form_screen.dart` correctly separates the asterisk in `_FormField`.

---

### CAT-16: `AuroraType.*` Token Misuse / Raw Font Size Overrides (LOW)

**`lib/features/home_profile/screens/home_profile_screen.dart`** (LOW)
- `AuroraType.h3.copyWith(fontSize: 13)` in forecast strip — this overrides the token with an arbitrary size. Use `AuroraType.bodySm` or `AuroraType.body` directly.

**`lib/features/projects/screens/projects_screen.dart`** (LOW)
- `_Header`: `AuroraType.label.copyWith(fontSize: 10, letterSpacing: 1.4, color: ...)` — `AuroraType.label` is already 10px; the fontSize override is redundant but the letterSpacing override is arbitrary. Use token as-is with only color override.
- `AuroraType.h2.copyWith(fontSize: 26)` — arbitrary font size override. Use `AuroraType.h2` directly or add a named display token.
- `_Chip` count badge: `AuroraType.label.copyWith(fontSize: 9, ...)` — this downsizes label to 9px (which is `labelSm`). Use `AuroraType.labelSm` directly.

**`lib/features/emergency/screens/emergency_hub_screen.dart`** (LOW)
- `_ShutoffTile`: `AuroraType.bodySm.copyWith(fontSize: 10)` — `bodySm` is 12px; overriding to 10px with a raw value. Use `AuroraType.labelSm` if a 9-10px mono label is needed.

---

## Clean Files

The following files are fully Aurora-compliant and require no changes:

- `lib/features/auth/screens/login_screen.dart` — correct `AuroraRadius.md` on inputs, coral focus border, separate coral `*` for required fields, no raw TextStyles
- `lib/features/auth/screens/signup_screen.dart` — same as login
- `lib/features/emergency/screens/contacts_list_screen.dart` — uses `AuroraFAB`, `AuroraColors`, `AuroraType` tokens correctly throughout
- `lib/features/home_profile/screens/systems_screen.dart` — clean; `AuroraColors.ink` for Android RefreshIndicator is acceptable (Material widget, not brand surface)
- `lib/core/widgets/aurora/aurora_button.dart` — `Colors.white` is intentional within design system primitive
- `lib/core/widgets/aurora/aurora_card.dart` — `Colors.white` in `AuroraHeroCard` is intentional within design system primitive
- `lib/core/widgets/aurora/aurora_text_field.dart` — canonical reference implementation; correct in all respects
- `lib/core/widgets/empty_state.dart` — canonical empty state implementation; `Colors.white` icon on coral hero circle is intentional within the design primitive (normalize to `AuroraColors.paper` in a future token pass)
- `lib/features/settings/screens/settings_profile_screen.dart` — clean; `_InfoRow` vertical padding of 13px is a LOW finding but file is otherwise compliant
- `lib/features/home_profile/screens/lifespan_screen.dart` — clean; uses Aurora tokens throughout
- `lib/features/projects/screens/project_detail_screen.dart` — mostly clean; one `Color(0xFFEEEDF2)` raw literal in `_statusDim` helper
- `lib/features/onboarding/screens/property_setup_screen.dart` — clean; uses `AuroraTextField`, `AuroraRadius`, `AuroraSpacing` correctly

---

## Recommended Fix Priority

### Sprint 1 — Critical (1–2 days)

Fix items that cause visible brand inconsistency or broken design language:

1. Replace all `GoogleFonts.*` calls in feature code with `AuroraType.*` tokens (CAT-1): `task_detail_screen.dart`, `home_profile_screen.dart`, `system_detail_screen.dart`, `appliance_detail_screen.dart`
2. Replace all `Colors.white` / `Colors.black` violations with `AuroraColors.paper` (CAT-2): `settings_screen.dart`, `emergency_hub_screen.dart`, `appliances_screen.dart`, `home_profile_screen.dart`, `property_edit_screen.dart`
3. Replace `CircularProgressIndicator` content loaders with skeleton shimmer (CAT-7): `appliance_detail_screen.dart`
4. Fix all raw empty states to use `EmptyState` widget (CAT-6): 5 files

### Sprint 2 — High (2–3 days)

5. Replace all `BorderRadius.circular(N)` with `AuroraRadius.*` tokens (CAT-3): all form screens and detail screens
6. Fix focus borders from `AuroraColors.ink` to `AuroraColors.coral` (CAT-10): `task_form_screen.dart`, `task_detail_screen.dart`, `project_form_screen.dart`
7. Replace `CupertinoColors.*` with `AuroraColors.paper` (CAT-9): 5 files
8. Fix raw `TextStyle(...)` constructors (CAT-11): 3 files

### Sprint 3 — Polish (1 day)

9. Fix off-grid spacing values (CAT-4): sweep all files
10. Replace raw `Color(0x...)` shadow literals with shadow tokens (CAT-5)
11. Add `.toUpperCase()` to all `AuroraType.label`/`AuroraType.labelSm` call sites (CAT-8)
12. Fix section header dot token usage `Radius.circular(2)` → `AuroraRadius.xs` (CAT-13)
13. Replace non-Aurora buttons (CAT-14)
14. Fix required asterisk pattern (CAT-15)
15. Remove raw font size overrides (CAT-16)
16. Replace direct `ScaffoldMessenger` calls with `SnackbarService` (CAT-12)

---

## Notes on Intentional Exceptions (Do Not Change)

- `_FullscreenPreview`, `_PdfPreview`, `_ImagePreview` in `document_detail_screen.dart` — black/white correct for full-screen media backgrounds
- `photo_comparison_screen.dart` — black/white correct for photo comparison viewer
- `aurora_button.dart` / `aurora_card.dart` — `Colors.white` within design system primitives is intentional; these ARE the source of truth
- `empty_state.dart` `EmptyStateHero` — `Colors.white` icon on coral circle is a design system primitive; acceptable here but should be normalized to `AuroraColors.paper` in a future token harmonization pass
