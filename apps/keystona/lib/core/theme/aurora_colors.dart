import 'package:flutter/material.dart';

/// Aurora design kit (`design/`) — canonical color palette.
///
/// The kit is the source of truth. White paper is the canvas. Ink is text.
/// Coral means "act now" (one coral surface per screen). Cobalt is action and
/// save. Lime/olive is the win. Amber is "soon". No tinted fills.
///
/// Tokens marked LEGACY predate the kit and are kept only so unmigrated screens
/// compile. Do not use them in new code; each is deleted when its last caller
/// is rebuilt.
abstract final class AuroraColors {
  // ─── Surfaces ───────────────────────────────────────────────────────────────

  /// Primary canvas — 70% of pixels. Always the outermost background.
  static const Color paper = Color(0xFFFFFFFF);

  /// LEGACY — not in the kit. Replace with [paper] plus a border.
  static const Color butter = Color(0xFFF5F1E8);

  // ─── Brand ──────────────────────────────────────────────────────────────────

  /// Hero, overdue, primary CTA. One coral surface per screen.
  static const Color coral = Color(0xFFFF3B62);

  /// Action, info, scheduled. Save buttons.
  static const Color cobalt = Color(0xFF2540D8);

  /// Positive feedback — streaks, completion, done tiles.
  static const Color lime = Color(0xFFECF87F);

  /// Highlight accent — sun spot on coral hero, premium badges.
  static const Color yellow = Color(0xFFFFD947);

  /// All primary text and max-contrast surface.
  static const Color ink = Color(0xFF071238);

  // ─── Text opacity variants ───────────────────────────────────────────────────

  /// Secondary text — mono labels, eyebrows, captions. (0.55 opacity)
  static const Color inkSecondary = Color(0x8C071238);

  /// Placeholders, inactive tab, disabled labels. (0.35 opacity) Kit name: [inkPlaceholder].
  static const Color inkTertiary = Color(0x59071238);

  // ─── Borders ────────────────────────────────────────────────────────────────

  /// Default hairline borders on paper. (0.12 opacity)
  static const Color inkBorder = Color(0x1F071238);

  /// Hover/focus borders, secondary button borders. (0.20 opacity)
  static const Color inkBorderStrong = Color(0x33071238);

  // ─── LEGACY dim tints — the kit forbids tinted fills ────────────────────────

  /// Coral tint — overdue chips, soft accent surfaces. (0.10 opacity)
  static const Color coralDim = Color(0x1AFF3B62);

  /// Cobalt tint — info chips, HVAC icon bg, link hover. (0.10 opacity)
  static const Color cobaltDim = Color(0x1A2540D8);

  /// Lime tint — task row background, success toasts. (0.40 opacity)
  static const Color limeDim = Color(0x66ECF87F);

  /// Yellow tint — due-soon task bg. (0.30 opacity)
  static const Color yellowDim = Color(0x4DFFD947);

  // ─── Status deep variants (text on status surface) ───────────────────────────

  static const Color coralDeep = Color(0xFFB12347);
  static const Color cobaltDeep = Color(0xFF1A2EA3);
  static const Color yellowDeep = Color(0xFF6B4F00);
  static const Color limeDeep = Color(0xFF4A6604);

  // ─── Kit additions ──────────────────────────────────────────────────────────

  /// Done text and stroke (olive). Pairs with [lime] fill.
  static const Color olive = limeDeep;

  /// Dark olive text on a lime fill.
  static const Color oliveDeep = Color(0xFF2E4003);

  /// "Soon" / getting close stroke.
  static const Color amber = Color(0xFFB08A00);

  /// "Soon" dot.
  static const Color amberDot = Color(0xFFE0A800);

  /// "Soon" text — same as [yellowDeep].
  static const Color amberDeep = yellowDeep;

  /// Body text on paper. (0.70 opacity)
  static const Color inkBody = Color(0xB3071238);

  /// Placeholder / inactive tab. (0.35 opacity)
  static const Color inkPlaceholder = inkTertiary;

  /// Helper text under inputs. (0.45 opacity)
  static const Color inkHelper = Color(0x73071238);

  /// Icon tile border. (0.14 opacity)
  static const Color inkTileBorder = Color(0x24071238);

  /// Input, chip and select borders on paper. (0.18 opacity)
  static const Color inkInputBorder = Color(0x2E071238);

  /// Cancel / quiet action text. (0.60 opacity)
  static const Color inkSubtle = Color(0x99071238);

  /// Empty check-circle outline on task rows. (0.30 opacity)
  static const Color inkCheckBorder = Color(0x4D071238);

  /// Switch-off track. (0.16 opacity)
  static const Color inkTrackOff = Color(0x29071238);

  /// Disabled fill (disabled Save). (0.08 opacity)
  static const Color inkDisabledFill = Color(0x14071238);

  /// Scrim behind sheets. (0.45 opacity)
  static const Color scrim = Color(0x73071238);

  /// Ring tracks and secondary marks on the coral hero. (white 0.20)
  static const Color onCoralTrack = Color(0x33FFFFFF);

  /// Sun spot on the coral hero. (yellow 0.32)
  static const Color heroSun = Color(0x52FFD947);

  /// Health-score rings on coral: outer 100%, middle 75%, inner 50% white.
  static const Color ringOuter = Color(0xFFFFFFFF);
  static const Color ringMiddle = Color(0xBFFFFFFF);
  static const Color ringInner = Color(0x80FFFFFF);

  /// Cobalt selected-row tint border. (0.25 opacity)
  static const Color cobaltBorder = Color(0x402540D8);

  // ─── Focus rings (non-const — use withValues) ───────────────────────────────

  static Color get focusCoral => coral.withValues(alpha: 0.12);
  static Color get focusCobalt => cobalt.withValues(alpha: 0.12);
}

/// Text on an ink surface (snackbar).
abstract final class AuroraOnInk {
  /// Secondary line on ink. (white 0.70)
  static const Color secondary = Color(0xB3FFFFFF);
}

/// Non-brand structural colors.
abstract final class AuroraStructure {
  /// Fully transparent (host surfaces that paint their own decoration).
  static const Color transparent = Color(0x00FFFFFF);
}
