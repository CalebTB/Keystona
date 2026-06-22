# Keystona — Aurora Design System

**Version 2.0 · June 2026 · Active**
**Status:** Canonical · supersedes `Keystona_Design_System.md` v1.x in full.
**Consumes:** `HomeTrack_Database_Schema.md` · `HomeTrack_API_Contract.md` · `HomeTrack_Dashboard_Spec.md`
**Owners:** Flutter agent (theme + components) · Integration agent (cross-screen audit) · Subscription/QA agent (Premium surface treatments)
**Replaces:** All prior color tokens, font references, and component styling rules. If a doc elsewhere in the suite references Fraunces, IBM Plex Mono, terracotta `#B85638`, olive `#5A7050`, slate `#506A80`, sand `#B8A060`, plum `#7B5E7B`, teal `#4A8078`, the warm parchment `#F3F0EB`, or any legacy "warm editorial" token — that doc is stale and must be updated to match this one.

---

## 1. The Aurora System in One Sentence

**White paper is the canvas. Butter is the warm secondary. Coral is the brand. Cobalt is action. Lime is the win.** Everything else exists to support those five surfaces.

The system pivots on one decision: **coral carries the brand**, and the rest of the palette is calibrated so coral never has to fight for attention.

---

## 2. Color Tokens

### 2.1 Canonical palette

| Token | Hex | Role | Notes |
|---|---|---|---|
| `paper` | `#FFFFFF` | Primary canvas | 70% of pixels by surface area. Always the outermost background. |
| `butter` | `#F5F1E8` | Warm secondary surface | Inset cards, modal sheets, tile backgrounds. The only warm-cream in the system. |
| `coral` | `#FF3B62` | Brand · hero · overdue | One coral surface per screen. Never two stacked. |
| `coral-dim` | `rgba(255, 59, 98, 0.10)` | Coral tint on white | Overdue chip backgrounds, soft accent surfaces. |
| `cobalt` | `#2540D8` | Action · info · scheduled | Save buttons, scheduled state, info tiles. |
| `cobalt-dim` | `rgba(37, 64, 216, 0.10)` | Cobalt tint on white | Info chips, HVAC icon backgrounds, link hover states. |
| `lime` | `#ECF87F` | Positive feedback | Streaks, completion celebrations, "done" tiles. Never carries text-only content. |
| `lime-dim` | `rgba(236, 248, 127, 0.40)` | Lime tint on white | Lime task row background, success toasts. |
| `yellow` | `#FFD947` | Highlight accent | Sun spot on coral hero, premium badges. Always paired with ink for legibility. |
| `ink` | `#071238` | All primary text · max contrast | Midnight navy, NOT pure black. Carries all body text and is the highest-contrast surface. |
| `ink-secondary` | `rgba(7, 18, 56, 0.55)` | Secondary text · labels | Mono labels, eyebrows, captions. |
| `ink-tertiary` | `rgba(7, 18, 56, 0.35)` | Tertiary text · placeholders | Input placeholders, disabled labels. |
| `ink-border` | `rgba(7, 18, 56, 0.12)` | Default border | All hairline borders on paper. |
| `ink-border-strong` | `rgba(7, 18, 56, 0.20)` | Border emphasis | Hover/focus borders, secondary button borders. |

### 2.2 Status colors (semantic)

Status colors share the brand palette deliberately — homeowners shouldn't have to learn a new color language for state.

| Status | Surface fill | Text on surface | Stroke (when used) |
|---|---|---|---|
| Overdue | `coral-dim` `rgba(255, 59, 98, 0.10)` | `#B12347` (coral-deep) | `coral` |
| Due soon | `rgba(255, 217, 71, 0.30)` (yellow tint) | `#6B4F00` (yellow-deep) | `yellow` |
| Scheduled | `cobalt-dim` `rgba(37, 64, 216, 0.10)` | `#1A2EA3` (cobalt-deep) | `cobalt` |
| Done | `lime` `#ECF87F` | `#4A6604` (lime-deep) | `lime` |
| Healthy | `lime-dim` `rgba(236, 248, 127, 0.40)` | `ink` `#071238` | none |
| Premium | `coral` `#FF3B62` | white `#FFFFFF` | none |

**Critical rule for status:** the *text color on a status surface* must be the deep variant of the same family — never plain ink. `#B12347` text on coral-dim, `#6B4F00` on yellow tint, `#1A2EA3` on cobalt-dim, `#4A6604` on lime. This is non-negotiable for accessibility.

### 2.3 Score pillar colors

The Home Health Score has three pillars per the existing spec. Aurora keeps the pillar identity colors distinct from the brand palette so the hero's data viz reads independently of the surface chrome.

| Pillar | Color | Where used |
|---|---|---|
| Maintenance | `#6BCB8B` (score-green) | Outer ring, pillar dot |
| Documents | `#C9A84C` (score-gold) | Middle ring, pillar dot |
| Emergency | `#6FA4D6` (score-blue) | Inner ring, pillar dot |

Pillar colors only appear on the score hero, the Home Profile health rings, and pillar tiles inside the dashboard hero. Nowhere else. They are *not* part of the general palette and should never be reached for as fill colors elsewhere.

### 2.4 Color usage matrix (where each color is allowed)

| Surface | paper | butter | coral | cobalt | lime | yellow | ink |
|---|---|---|---|---|---|---|---|
| Screen background | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Section inset | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Dashboard hero | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Tile / mini-card | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ | ❌ |
| Primary CTA | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Secondary CTA | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ (text) |
| Save / confirm CTA | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Task row (default) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Task row (due today) | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |
| Premium badge | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Streak badge | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |
| Body text | n/a | n/a | n/a | n/a | n/a | n/a | ✅ |
| Mono label | n/a | n/a | n/a | n/a | n/a | n/a | ✅ (at 55% opacity) |

---

## 3. Typography

### 3.1 Type stack

| Token | Family | Purpose | Weights | Source |
|---|---|---|---|---|
| `sans` | **Inter** | Everything | 400, 500, 600, 700, 800 | OFL via Google Fonts |
| `mono` | **JetBrains Mono** | Labels, dates, numbers, code | 400, 500, 600, 700 | OFL via Google Fonts |

**Decision:** No serif. No display font. The decision is to let color carry personality and keep type neutral. Inter is the only sans-serif family. JetBrains Mono is preferred over IBM Plex Mono and SF Mono because (a) it's OFL-licensed (matches your existing open-source stack), (b) the lowercase `g` and slashed zero read better at 10px label sizes, and (c) it has visible character at small sizes where SF Mono goes flat.

### 3.2 Type scale

| Token | Size | Weight | Line height | Letter spacing | Where used |
|---|---|---|---|---|---|
| `display-xl` | 46px | 800 | 0.9 | -1.8px | Score hero number (dashboard) |
| `display-lg` | 36px | 800 | 1.0 | -1.2px | Item count headers, big score callouts |
| `h1` | 22px | 700 | 1.0 | -0.7px | Screen greeting, screen title |
| `h2` | 18px | 600 | 1.1 | -0.4px | Section headings within a screen |
| `h3` | 15px | 700 | 1.15 | -0.3px | Card titles, list-item primary names |
| `body-lg` | 14px | 400 | 1.5 | 0 | Body copy emphasis |
| `body` | 13px | 400 | 1.5 | 0 | Default body copy |
| `body-sm` | 12px | 400 | 1.45 | 0 | Captions, secondary descriptions |
| `label` | 10px | 500 | 1.2 | 1.2px | Mono labels, eyebrows (always uppercase) |
| `label-sm` | 9px | 600 | 1.2 | 0.8px | Mono micro-labels (status chips) |
| `number` | 13px | 600 | 1.3 | 0 | All in-line numbers (dates, counts, prices) |

### 3.3 Type rules

1. **All labels are mono uppercase.** Eyebrows, status chips, section labels, button captions. JetBrains Mono in `label` size with `text-transform: uppercase` and 1.2px letter-spacing.
2. **All numbers are mono.** Dates, counts, prices, percentages, task durations. This is a Keystona principle (carried from v1) and Aurora preserves it.
3. **No font-weight below 400.** No "light" or "thin" weights. The system reads as confident, not delicate.
4. **No font-weight above 800.** Inter at 800 is the heaviest weight Aurora uses, reserved for the display-xl score hero.
5. **Heading hierarchy uses size + weight, never color.** Don't make an H2 a "lighter shade" of ink — make it smaller and reduce weight. Color stays consistent across hierarchy.

### 3.4 Sentence case everywhere

No Title Case. No ALL CAPS in body text. The only place ALL CAPS appears is in mono labels (which are uppercase by definition). Section titles, button labels, screen titles — all sentence case.

---

## 4. Radius, Spacing, Borders, Shadows

### 4.1 Radius scale

| Token | Value | Where used |
|---|---|---|
| `radius-xs` | 4px | Status chips, micro-tags |
| `radius-sm` | 8px | Task category icon tiles, input fields |
| `radius-md` | 12px | Buttons, small surfaces |
| `radius-lg` | 14px | Tiles, task rows, list cards |
| `radius-xl` | 16px | Standard cards |
| `radius-2xl` | 22px | Hero cards, premium surfaces |
| `radius-full` | 999px | Pills, filter chips, FABs, avatars |

**Critical:** Aurora uses larger radii than v1. The minimum card radius is 14px (was 12px in v1). The hero radius is 22px (was 18px). This is intentional — bigger radii read more modern and pair better with the saturated color palette. Don't reach for v1's 10–12px radii on new components.

### 4.2 Spacing scale (4px grid)

| Token | Value | Use |
|---|---|---|
| `space-1` | 4px | Icon-to-text gaps inside chips |
| `space-2` | 6px | Tight inline gaps, chip-to-chip |
| `space-3` | 8px | Standard inline gaps |
| `space-4` | 10px | Card padding (compact) |
| `space-5` | 12px | Section gaps, card padding (standard) |
| `space-6` | 14px | Card padding (comfortable) |
| `space-7` | 16px | Section bottom margins |
| `space-8` | 20px | Large section gaps |
| `space-9` | 24px | Hero-to-content gaps |
| `space-10` | 32px | Screen-level breathing room |

**Default screen padding:** 16px horizontal, 12px top, 24px bottom (above tab bar).

### 4.3 Borders

| Token | Value | Use |
|---|---|---|
| `border-hairline` | `0.5px solid ink-border` | Internal dividers (lists, table rows) |
| `border-default` | `1px solid ink-border` | Default card and tile borders |
| `border-emphasis` | `1.5px solid ink-border-strong` | Focus rings, hover states, secondary buttons |
| `border-focus` | `2px solid coral` | Active input field, focused button |

**No 1.5px outlined surfaces by default.** Aurora is not Citrine. Borders are subtle — `0.5px` and `1px` carry the work. The `1.5px` weight is reserved for focused/emphasized states only.

### 4.4 Shadows

| Token | Value | Use |
|---|---|---|
| `shadow-none` | none | Most surfaces (Aurora is a flat system) |
| `shadow-card` | `0 1px 2px rgba(7, 18, 56, 0.04)` | Optional lift on tile cards |
| `shadow-hero` | `0 4px 20px rgba(255, 59, 98, 0.15)` | Coral hero lift (rarely — Aurora is flat) |
| `shadow-fab` | `0 4px 12px rgba(255, 59, 98, 0.35)` | Floating action button |
| `shadow-focus-coral` | `0 0 0 4px rgba(255, 59, 98, 0.12)` | Coral focus ring |
| `shadow-focus-cobalt` | `0 0 0 4px rgba(37, 64, 216, 0.12)` | Cobalt focus ring |

**Aurora is a flat system.** Default to `shadow-none` unless lift adds genuine information. `shadow-card` is opt-in, not the default.

---

## 5. Iconography

### 5.1 Icon library

Use **Tabler Icons (outline)** — `tabler_icons_flutter` package or SVG assets.

- **Outline only.** Never filled icons.
- **Stroke width 1.8px.** This matches Inter's letter stroke and reads consistently against text.
- **Inherits color from parent.** Don't hardcode icon colors.
- **Size scale:** 14px (inline with body), 16px (default), 18px (label-adjacent), 20px (button), 22px (tab bar), 24px (hero/feature). Never below 14, never above 24.

### 5.2 Icon-color pairing rules

Icons take their color from the surface they sit on, not from a separate icon-color token.

| Surface | Icon color |
|---|---|
| White card, paper background | `ink` `#071238` |
| Coral hero | white `#FFFFFF` |
| Cobalt tile | white `#FFFFFF` |
| Lime tile | `ink` `#071238` |
| Butter tile | `ink` `#071238` |
| Cobalt-dim category icon tile | `cobalt` `#2540D8` |
| Coral-dim category icon tile | `coral` `#FF3B62` |

### 5.3 Category icons (canonical)

Each category in the database has a canonical Tabler icon. This list is authoritative — don't pick alternates.

| Category | Icon | Tile background | Icon color |
|---|---|---|---|
| HVAC | `ti-wind` | `cobalt-dim` | `cobalt` |
| Plumbing | `ti-droplet` | `cobalt-dim` | `cobalt` |
| Electrical | `ti-bolt` | `yellow` tint | `#6B4F00` |
| Exterior | `ti-home` | butter | ink |
| Interior | `ti-armchair` | butter | ink |
| Roofing | `ti-triangle` | butter | ink |
| Kitchen | `ti-tools-kitchen-2` | `coral-dim` | `coral` |
| Laundry | `ti-shirt` | `coral-dim` | `coral` |
| Climate | `ti-temperature` | `cobalt-dim` | `cobalt` |
| Safety | `ti-shield` | `coral-dim` | `coral` |
| Documents | `ti-file` | butter | ink |
| Tasks | `ti-checks` | butter | ink |
| Emergency | `ti-alert-triangle` | `coral` | white |
| Scan | `ti-scan` | `cobalt` | white |
| Add task | `ti-plus` | `ink` | `lime` |

---

## 6. Component Library

### 6.1 Buttons

#### Primary CTA (`PrimaryButton`)
- **Background:** `coral` `#FF3B62`
- **Text:** white `#FFFFFF`, Inter 600, 14px
- **Padding:** 12px vertical, 18px horizontal
- **Radius:** `radius-full` (pill) for compact actions; `radius-md` (12px) for form-level CTAs
- **Focus ring:** `shadow-focus-coral`
- **Hover (web only):** background darkens to `#E63056`
- **Disabled:** background `coral-dim`, text `coral`, no shadow

#### Secondary CTA (`SecondaryButton`)
- **Background:** white `#FFFFFF`
- **Border:** `1.5px solid ink-border-strong`
- **Text:** `ink` `#071238`, Inter 600, 14px
- **Padding:** 11.5px vertical, 17px horizontal (1px reduced to account for border)
- **Radius:** same as primary
- **Focus ring:** `shadow-focus-cobalt`

#### Save / confirm CTA (`SaveButton`)
- **Background:** `cobalt` `#2540D8`
- **Text:** white, Inter 600, 14px
- Other props identical to primary, but with `shadow-focus-cobalt`.

#### Ghost button (`GhostButton`)
- **Background:** transparent
- **Text:** `coral` `#FF3B62`, Inter 600, 13px
- **Padding:** 8px vertical, 12px horizontal
- For inline secondary actions: "View all", "Edit", "Cancel"

### 6.2 Cards

#### Standard card (`AuroraCard`)
- **Background:** white `#FFFFFF`
- **Border:** `border-default` (`1px solid ink-border`)
- **Radius:** `radius-xl` (16px)
- **Padding:** 14px
- **Shadow:** none by default
- Used for content containers throughout the app.

#### Tile (`AuroraTile`)
- **Background:** `butter`, `cobalt`, or `lime` per the color matrix
- **Border:** none
- **Radius:** `radius-lg` (14px)
- **Padding:** 10px 12px
- Used for stat tiles, quick actions, mini-callouts. Always inside a card or grid, never freestanding.

#### Hero card (`AuroraHero`)
- **Background:** `coral` `#FF3B62`
- **Text color:** white
- **Border:** none
- **Radius:** `radius-2xl` (22px)
- **Padding:** 16px
- **Decorative element:** absolutely-positioned yellow blob (180×180, `rgba(255, 217, 71, 0.32)`, border-radius 50%, positioned top: -50px right: -50px). This is the Aurora signature.
- Used for the score hero, premium upgrade prompts, achievement moments. **One per screen, never two stacked.**

### 6.3 Status chips

```
┌─────────────┐
│  OVERDUE    │  ← mono uppercase, label-sm size
└─────────────┘
```

- **Padding:** 3px 7px
- **Radius:** `radius-xs` (4px)
- **Font:** JetBrains Mono, 9px, 600 weight, 0.5px tracking, uppercase
- **Surface + text per status:** see §2.2 status colors

### 6.4 Filter pills

```
┌───────────┐  ┌─────────────┐  ┌────────┐
│ All 12    │  │ Overdue 3   │  │ Done   │
└───────────┘  └─────────────┘  └────────┘
```

- **Default:** white background, `1px solid ink-border`, ink text
- **Active:** `ink` background, white text, no border
- **Padding:** 5px 11px
- **Radius:** `radius-full`
- **Font:** Inter 500, 11px
- **Count number:** mono, 9px, 700 weight, same color as text

### 6.5 Task row (`AuroraTaskRow`)

```
┌─────────────────────────────────────────────────┐
│  [icon]  Clean fridge door seals      JUN 30    │
│  30px    13px / 600                   mono 10   │
│          DUE IN 8 DAYS · 10 MIN                 │
│          mono 10 / secondary                    │
└─────────────────────────────────────────────────┘
```

- **Background:** white (default), `lime` (due today), `coral-dim` (overdue)
- **Border:** `1px solid ink-border` (default), no border on colored states
- **Radius:** `radius-lg` (14px)
- **Padding:** 11px 12px
- **Icon tile:** 30×30, `radius-sm` (8px), category-specific background per §5.3
- **Name:** Inter 600, 12.5px, ink
- **Meta line:** JetBrains Mono, 10px, ink-secondary, uppercase
- **Date:** JetBrains Mono, 10px, 600, ink-secondary

### 6.6 Hero (dashboard)

The dashboard hero is the most opinionated component in the system. It uses the coral background, the yellow blob decoration, the score number in `display-xl`, the mono trend label in `lime`, and a three-pillar grid below the divider.

```
┌────────────────────────────────────────────────┐
│  HOME HEALTH                                  ★│  ← mono label / yellow blob
│  100                                           │  ← display-xl, white
│  ↗ STABLE THIS MONTH                          │  ← mono / lime
│  ─────────────────────────                    │
│  MAINT.    DOCS    EMERG.                     │  ← mono / 65% white
│  100       100     100                        │  ← h3 / white
└────────────────────────────────────────────────┘
```

Layout details:
- The yellow decorative blob is a `Positioned` widget with negative top/right offsets and `opacity: 0.32`.
- The divider between the score and the pillars is `0.5px solid rgba(255, 255, 255, 0.20)`.
- The trend indicator text is `lime` `#ECF87F`, not white, to provide a positive accent against the coral.

### 6.7 Quick action button (`QuickActionButton`)

```
┌────────────┐
│   [icn]    │  ← 28×28 tile
│   Scan     │  ← Inter 600 10.5px
└────────────┘
```

- **Container:** butter background, `radius-lg` (14px), 10px 8px padding, center-aligned
- **Icon tile:** 28×28, `radius-sm` (8px), color per the matrix:
  - Scan: cobalt fill, white icon
  - SOS: coral fill, white icon
  - Add task: ink fill, lime icon
- **Label:** Inter 600, 10.5px, ink

### 6.8 Input fields (`AuroraTextField`)

- **Background:** white
- **Border:** `1.5px solid ink-border`
- **Border (focus):** `2px solid coral`, plus `shadow-focus-coral`
- **Border (error):** `1.5px solid coral`
- **Radius:** `radius-md` (12px)
- **Padding:** 12px 14px
- **Font:** Inter 500, 14px
- **Placeholder:** Inter 400, 14px, ink-tertiary
- **Label (above field):** mono, 10px, 500 weight, ink-secondary, uppercase, 1.2px tracking, 6px margin below

### 6.9 Tab bar (`AuroraTabBar`)

- **Background:** white, with `0.5px` border on the top edge in `ink-border`
- **Height:** 64px (plus safe-area bottom padding)
- **Icon size:** 22px Tabler outline
- **Label:** Inter 600, 10px
- **Active state:** icon and label both `coral` `#FF3B62`
- **Inactive state:** icon and label both `ink-tertiary` `rgba(7, 18, 56, 0.35)`
- **Active indicator:** 3px tall pill (`radius-full`) positioned 4px above the active tab, in `coral`, 20px wide

### 6.10 Floating action button (`AuroraFAB`)

- **Background:** `coral` `#FF3B62`
- **Icon:** white, 24px Tabler outline
- **Size:** 56×56
- **Radius:** `radius-full`
- **Shadow:** `shadow-fab`
- **Position:** bottom-right, 24px from edges, 90px above tab bar

---

## 7. Flutter Implementation

### 7.1 pubspec dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.2.1
  tabler_icons_flutter: ^1.0.0
  flutter_svg: ^2.0.10+1
```

### 7.2 Theme file structure

```
lib/
  theme/
    aurora_colors.dart       ← Token constants (this doc §2)
    aurora_typography.dart   ← TextStyle constants (this doc §3)
    aurora_radius.dart       ← BorderRadius constants (this doc §4.1)
    aurora_spacing.dart      ← Padding/margin constants (this doc §4.2)
    aurora_shadows.dart      ← BoxShadow constants (this doc §4.4)
    aurora_theme.dart        ← Main ThemeData export, composes the above
  widgets/
    aurora/
      aurora_button.dart     ← PrimaryButton, SecondaryButton, SaveButton, GhostButton
      aurora_card.dart       ← AuroraCard, AuroraTile, AuroraHero
      aurora_chip.dart       ← StatusChip, FilterPill
      aurora_task_row.dart   ← Task list item
      aurora_quick_action.dart
      aurora_input.dart      ← AuroraTextField
      aurora_tab_bar.dart    ← Bottom tab bar
      aurora_fab.dart        ← Floating action button
```

### 7.3 `aurora_colors.dart` (canonical Dart constants)

```dart
import 'package:flutter/material.dart';

class AuroraColors {
  // Surfaces
  static const paper = Color(0xFFFFFFFF);
  static const butter = Color(0xFFF5F1E8);

  // Brand
  static const coral = Color(0xFFFF3B62);
  static const cobalt = Color(0xFF2540D8);
  static const lime = Color(0xFFECF87F);
  static const yellow = Color(0xFFFFD947);
  static const ink = Color(0xFF071238);

  // Text on paper
  static const inkSecondary = Color(0x8C071238); // 0.55 opacity
  static const inkTertiary = Color(0x59071238);  // 0.35 opacity

  // Borders
  static const inkBorder = Color(0x1F071238);          // 0.12 opacity
  static const inkBorderStrong = Color(0x33071238);    // 0.20 opacity

  // Dim variants (color tint on white)
  static const coralDim = Color(0x1AFF3B62);   // 0.10 opacity
  static const cobaltDim = Color(0x1A2540D8);  // 0.10 opacity
  static const limeDim = Color(0x66ECF87F);    // 0.40 opacity
  static const yellowDim = Color(0x4DFFD947);  // 0.30 opacity

  // Status deep variants (text on status surface)
  static const coralDeep = Color(0xFFB12347);
  static const cobaltDeep = Color(0xFF1A2EA3);
  static const yellowDeep = Color(0xFF6B4F00);
  static const limeDeep = Color(0xFF4A6604);

  // Hover variants (web/desktop)
  static const coralHover = Color(0xFFE63056);
  static const cobaltHover = Color(0xFF1F35B8);

  // Score pillar colors
  static const scoreGreen = Color(0xFF6BCB8B);
  static const scoreGold = Color(0xFFC9A84C);
  static const scoreBlue = Color(0xFF6FA4D6);

  // Focus rings
  static Color get focusCoral => coral.withOpacity(0.12);
  static Color get focusCobalt => cobalt.withOpacity(0.12);
}
```

### 7.4 `aurora_typography.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'aurora_colors.dart';

class AuroraType {
  // Inter — body, headings, buttons, everything except labels and numbers
  static TextStyle get displayXl => GoogleFonts.inter(
    fontSize: 46, fontWeight: FontWeight.w800,
    height: 0.9, letterSpacing: -1.8, color: AuroraColors.ink,
  );

  static TextStyle get displayLg => GoogleFonts.inter(
    fontSize: 36, fontWeight: FontWeight.w800,
    height: 1.0, letterSpacing: -1.2, color: AuroraColors.ink,
  );

  static TextStyle get h1 => GoogleFonts.inter(
    fontSize: 22, fontWeight: FontWeight.w700,
    height: 1.0, letterSpacing: -0.7, color: AuroraColors.ink,
  );

  static TextStyle get h2 => GoogleFonts.inter(
    fontSize: 18, fontWeight: FontWeight.w600,
    height: 1.1, letterSpacing: -0.4, color: AuroraColors.ink,
  );

  static TextStyle get h3 => GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w700,
    height: 1.15, letterSpacing: -0.3, color: AuroraColors.ink,
  );

  static TextStyle get bodyLg => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w400,
    height: 1.5, color: AuroraColors.ink,
  );

  static TextStyle get body => GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w400,
    height: 1.5, color: AuroraColors.ink,
  );

  static TextStyle get bodySm => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w400,
    height: 1.45, color: AuroraColors.ink,
  );

  // JetBrains Mono — labels, eyebrows, numbers, dates
  static TextStyle get label => GoogleFonts.jetBrainsMono(
    fontSize: 10, fontWeight: FontWeight.w500,
    height: 1.2, letterSpacing: 1.2, color: AuroraColors.inkSecondary,
  );

  static TextStyle get labelSm => GoogleFonts.jetBrainsMono(
    fontSize: 9, fontWeight: FontWeight.w600,
    height: 1.2, letterSpacing: 0.8, color: AuroraColors.inkSecondary,
  );

  static TextStyle get number => GoogleFonts.jetBrainsMono(
    fontSize: 13, fontWeight: FontWeight.w600,
    height: 1.3, color: AuroraColors.ink,
  );

  // Helper: uppercase variants (for labels)
  static TextStyle get labelUppercase => label;  // Already uppercase via style guide
}
```

**Implementation note for the Flutter agent:** when rendering `AuroraType.label` or `AuroraType.labelSm`, always wrap the text content with `text.toUpperCase()` at the call site. Don't rely on a `textTransform` property — Flutter doesn't have one natively, and applying it through `TextStyle` isn't reliable across platforms.

### 7.5 `aurora_radius.dart`

```dart
import 'package:flutter/material.dart';

class AuroraRadius {
  static const xs = BorderRadius.all(Radius.circular(4));
  static const sm = BorderRadius.all(Radius.circular(8));
  static const md = BorderRadius.all(Radius.circular(12));
  static const lg = BorderRadius.all(Radius.circular(14));
  static const xl = BorderRadius.all(Radius.circular(16));
  static const xxl = BorderRadius.all(Radius.circular(22));
  static const full = BorderRadius.all(Radius.circular(999));
}
```

### 7.6 `aurora_spacing.dart`

```dart
class AuroraSpacing {
  static const space1 = 4.0;
  static const space2 = 6.0;
  static const space3 = 8.0;
  static const space4 = 10.0;
  static const space5 = 12.0;
  static const space6 = 14.0;
  static const space7 = 16.0;
  static const space8 = 20.0;
  static const space9 = 24.0;
  static const space10 = 32.0;

  static const screenPadH = 16.0;
  static const screenPadTop = 12.0;
  static const screenPadBottom = 24.0;
}
```

### 7.7 `aurora_shadows.dart`

```dart
import 'package:flutter/material.dart';
import 'aurora_colors.dart';

class AuroraShadows {
  static const none = <BoxShadow>[];

  static const card = <BoxShadow>[
    BoxShadow(
      color: Color(0x0A071238), // 0.04 opacity
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static const fab = <BoxShadow>[
    BoxShadow(
      color: Color(0x59FF3B62), // 0.35 opacity coral
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  static const hero = <BoxShadow>[
    BoxShadow(
      color: Color(0x26FF3B62), // 0.15 opacity coral
      offset: Offset(0, 4),
      blurRadius: 20,
    ),
  ];
}
```

### 7.8 `aurora_theme.dart` (composed ThemeData)

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'aurora_colors.dart';
import 'aurora_typography.dart';
import 'aurora_radius.dart';

class AuroraTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    scaffoldBackgroundColor: AuroraColors.paper,
    canvasColor: AuroraColors.paper,

    colorScheme: const ColorScheme.light(
      primary: AuroraColors.coral,
      onPrimary: Colors.white,
      secondary: AuroraColors.cobalt,
      onSecondary: Colors.white,
      tertiary: AuroraColors.lime,
      onTertiary: AuroraColors.ink,
      surface: AuroraColors.paper,
      onSurface: AuroraColors.ink,
      error: AuroraColors.coral,
      onError: Colors.white,
      surfaceContainerHighest: AuroraColors.butter,
      outline: AuroraColors.inkBorder,
      outlineVariant: AuroraColors.inkBorderStrong,
    ),

    textTheme: TextTheme(
      displayLarge: AuroraType.displayXl,
      displayMedium: AuroraType.displayLg,
      headlineLarge: AuroraType.h1,
      headlineMedium: AuroraType.h2,
      titleMedium: AuroraType.h3,
      bodyLarge: AuroraType.bodyLg,
      bodyMedium: AuroraType.body,
      bodySmall: AuroraType.bodySm,
      labelLarge: AuroraType.label,
      labelSmall: AuroraType.labelSm,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AuroraColors.coral,
        foregroundColor: Colors.white,
        elevation: 0,
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: const RoundedRectangleBorder(borderRadius: AuroraRadius.full),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AuroraColors.ink,
        side: const BorderSide(color: AuroraColors.inkBorderStrong, width: 1.5),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11.5),
        shape: const RoundedRectangleBorder(borderRadius: AuroraRadius.full),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AuroraColors.coral,
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: const RoundedRectangleBorder(borderRadius: AuroraRadius.md),
      ),
    ),

    cardTheme: CardThemeData(
      color: AuroraColors.paper,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AuroraRadius.xl,
        side: const BorderSide(color: AuroraColors.inkBorder, width: 1),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AuroraColors.paper,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      labelStyle: AuroraType.label,
      hintStyle: AuroraType.body.copyWith(color: AuroraColors.inkTertiary),
      border: const OutlineInputBorder(
        borderRadius: AuroraRadius.md,
        borderSide: BorderSide(color: AuroraColors.inkBorder, width: 1.5),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: AuroraRadius.md,
        borderSide: BorderSide(color: AuroraColors.inkBorder, width: 1.5),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AuroraRadius.md,
        borderSide: BorderSide(color: AuroraColors.coral, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: AuroraRadius.md,
        borderSide: BorderSide(color: AuroraColors.coral, width: 1.5),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AuroraColors.paper,
      labelStyle: AuroraType.body.copyWith(fontWeight: FontWeight.w500),
      side: const BorderSide(color: AuroraColors.inkBorder, width: 1),
      shape: const RoundedRectangleBorder(borderRadius: AuroraRadius.full),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AuroraColors.paper,
      selectedItemColor: AuroraColors.coral,
      unselectedItemColor: AuroraColors.inkTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AuroraColors.coral,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: CircleBorder(),
    ),

    dividerTheme: const DividerThemeData(
      color: AuroraColors.inkBorder,
      thickness: 0.5,
      space: 0,
    ),
  );
}
```

### 7.9 App entry point

```dart
import 'package:flutter/material.dart';
import 'theme/aurora_theme.dart';

class KeystonaApp extends StatelessWidget {
  const KeystonaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keystona',
      theme: AuroraTheme.light,
      home: const HomeScaffold(),
      debugShowCheckedModeBanner: false,
    );
  }
}
```

### 7.10 Example custom widget: `AuroraHero`

```dart
import 'package:flutter/material.dart';
import '../../theme/aurora_colors.dart';
import '../../theme/aurora_radius.dart';
import '../../theme/aurora_typography.dart';

class AuroraHero extends StatelessWidget {
  final int score;
  final String trend;          // e.g. "↗ Stable this month"
  final int maintScore;
  final int docsScore;
  final int emergScore;

  const AuroraHero({
    super.key,
    required this.score,
    required this.trend,
    required this.maintScore,
    required this.docsScore,
    required this.emergScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AuroraColors.coral,
        borderRadius: AuroraRadius.xxl,
      ),
      child: ClipRRect(
        borderRadius: AuroraRadius.xxl,
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AuroraColors.yellow.withOpacity(0.32),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'HOME HEALTH',
                    style: AuroraType.label.copyWith(
                      color: Colors.white.withOpacity(0.78),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    score.toString(),
                    style: AuroraType.displayXl.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    trend.toUpperCase(),
                    style: AuroraType.label.copyWith(
                      color: AuroraColors.lime,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 0.5,
                    color: Colors.white.withOpacity(0.20),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _Pillar(label: 'MAINT.', value: maintScore)),
                      Expanded(child: _Pillar(label: 'DOCS', value: docsScore)),
                      Expanded(child: _Pillar(label: 'EMERG.', value: emergScore)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pillar extends StatelessWidget {
  final String label;
  final int value;
  const _Pillar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AuroraType.labelSm.copyWith(color: Colors.white.withOpacity(0.65)),
        ),
        const SizedBox(height: 3),
        Text(
          value.toString(),
          style: AuroraType.h3.copyWith(color: Colors.white),
        ),
      ],
    );
  }
}
```

---

## 8. Migration from v1 (the warm editorial system)

For every file in the codebase that references the v1 tokens, here's the mapping:

| v1 token | v1 hex | v2 (Aurora) token | v2 hex |
|---|---|---|---|
| `background` | `#F3F0EB` | `paper` | `#FFFFFF` |
| `cardBackground` | `#FFFFFF` | `paper` | `#FFFFFF` |
| `warmFill` | `#E9E4DC` | `butter` | `#F5F1E8` |
| `warmInset` | `#E2DDD4` | `butter` | `#F5F1E8` |
| `textPrimary` | `#2A2420` | `ink` | `#071238` |
| `textSecondary` | `#6B6058` | `inkSecondary` | `rgba(7,18,56,0.55)` |
| `textTertiary` | `#9E9488` | `inkTertiary` | `rgba(7,18,56,0.35)` |
| `accent` (terracotta) | `#B85638` | `coral` | `#FF3B62` |
| `olive` | `#5A7050` | `lime` (with translation) | `#ECF87F` |
| `slate` | `#506A80` | `cobalt` | `#2540D8` |
| `sand` / `sand-amber` | `#B8A060` / `#9B7E3E` | `yellow` (with translation) | `#FFD947` |
| `plum` | `#7B5E7B` | — (deprecated) | — |
| `teal` | `#4A8078` | — (deprecated) | — |
| `amber` | `#B8923D` | `yellow` | `#FFD947` |
| `border` | `#DDD7CE` | `inkBorder` | `rgba(7,18,56,0.12)` |
| `border-strong` | `#CBC4B8` | `inkBorderStrong` | `rgba(7,18,56,0.20)` |
| Fraunces (display) | — | Inter | — |
| IBM Plex Mono | — | JetBrains Mono | — |

**Deprecated colors:** `plum` and `teal` from v1 do not map to anything in Aurora. Wherever they're used (link_type colors per v1 §5.3 — `warranty` was plum, `receipt` was teal), reassign:
- `link_type=receipt` → `cobalt` (was teal)
- `link_type=permit` → `coral` (was accent)
- `link_type=contract` → `cobalt` (was slate)
- `link_type=invoice` → `yellow-deep` `#6B4F00` (was sand)
- `link_type=warranty` → `coral` (was plum)
- `link_type=general` → `inkSecondary` (was tertiary)

**The collapse is intentional** — Aurora deliberately uses fewer category colors to keep the system tight. Five accents (coral, cobalt, lime, yellow, ink) cover what v1 needed nine for.

---

## 9. Audit Checklist (for the Integration Agent)

When the Flutter agent finishes the theme swap, the Integration agent must verify:

- [ ] All references to `Fraunces` have been removed from the codebase.
- [ ] All references to `IBM Plex Mono` have been removed; replaced with `JetBrains Mono`.
- [ ] All references to `#B85638`, `#5A7050`, `#506A80`, `#B8A060`, `#9B7E3E`, `#7B5E7B`, `#4A8078`, `#B8923D`, `#F3F0EB`, `#E9E4DC`, `#E2DDD4`, `#2A2420`, `#6B6058`, `#9E9488`, `#DDD7CE`, `#CBC4B8` have been removed.
- [ ] Every screen background is `paper` (`#FFFFFF`), not warm parchment.
- [ ] The dashboard hero is `coral`, not the previous dark `textPrimary` background.
- [ ] No card uses a border below 1px or above 1.5px (except focused states, which use 2px).
- [ ] No two coral surfaces appear on the same screen simultaneously.
- [ ] All mono labels are uppercase.
- [ ] All numbers (dates, counts, prices) render in JetBrains Mono.
- [ ] Tab bar uses `coral` for active state, `inkTertiary` for inactive.
- [ ] FAB is `coral` with `shadow-fab`.
- [ ] Stale documentation (`Keystona_Agent_Definitions.md`, `Keystona_Onboarding_Spec.md`, `HomeTrack_Empty_States_Catalog.md`, `HomeTrack_Dashboard_Spec.md`, `HomeTrack_Web_Dashboard_Spec.md`, `SKILL.md`) is updated to reference Aurora tokens.

---

## 10. Surfaces NOT Covered by This Spec (and where they live)

This doc covers the design system. The following remain the responsibility of their own specs:

- **Health Score Algorithm** — formulas unchanged; only the pillar ring colors are now sourced from §2.3.
- **Dashboard sections and 8 states** — `HomeTrack_Dashboard_Spec.md` and `HomeTrack_Dashboard_States.md` remain canonical for behavior; their visual specs should be updated to reference Aurora components in §6.
- **Notification priority** — `HomeTrack_Notification_Priority.md` is unaffected.
- **Empty states catalog** — copy and structure unchanged; CTAs now use `PrimaryButton` from §6.1.
- **Sub-page wrapper pattern** — three-file pattern (Overview wrapper + active default + retrospective default) is unaffected; the *visual* components inside each spec must update to Aurora.

---

*End of Aurora Design System spec.*
