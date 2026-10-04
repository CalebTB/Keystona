import 'package:flutter/material.dart';

/// Aurora Design System v2.0 — canonical color palette.
///
/// White paper is the canvas. Butter is the warm secondary.
/// Coral is the brand. Cobalt is action. Lime is the win.
abstract final class AuroraColors {
  // ─── Surfaces ───────────────────────────────────────────────────────────────

  /// Primary canvas — 70% of pixels. Always the outermost background.
  static const Color paper = Color(0xFFFFFFFF);

  /// Warm secondary — inset cards, modal sheets, tile backgrounds.
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

  /// Tertiary text — placeholders, disabled labels. (0.35 opacity)
  static const Color inkTertiary = Color(0x59071238);

  // ─── Borders ────────────────────────────────────────────────────────────────

  /// Default hairline borders on paper. (0.12 opacity)
  static const Color inkBorder = Color(0x1F071238);

  /// Hover/focus borders, secondary button borders. (0.20 opacity)
  static const Color inkBorderStrong = Color(0x33071238);

  // ─── Dim tints (color on white) ─────────────────────────────────────────────

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

  // ─── Hover variants (web/desktop) ───────────────────────────────────────────

  static const Color coralHover = Color(0xFFE63056);
  static const Color cobaltHover = Color(0xFF1F35B8);

  // ─── Score pillar colors (only used in health score viz) ─────────────────────

  /// Maintenance pillar — outer ring.
  static const Color scoreGreen = Color(0xFF6BCB8B);

  /// Documents pillar — middle ring.
  static const Color scoreGold = Color(0xFFC9A84C);

  /// Emergency pillar — inner ring.
  static const Color scoreBlue = Color(0xFF6FA4D6);

  // ─── Focus rings (non-const — use withValues) ───────────────────────────────

  static Color get focusCoral => coral.withValues(alpha: 0.12);
  static Color get focusCobalt => cobalt.withValues(alpha: 0.12);
}
