import 'package:flutter/material.dart';

import 'aurora_colors.dart';

/// Aurora design kit — typography.
///
/// Platform system font only (SF Pro on iOS, Roboto on Android). Never bundle
/// or load a font. Labels and numbers use the same family with tabular figures.
/// The health score uses the rounded system face where the platform has one.
///
/// All label/labelSm callers MUST call `.toUpperCase()` on their text content —
/// Flutter has no native textTransform, so uppercase is applied at the call site.
abstract final class AuroraType {
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// Rounded system face for the health-score number.
  static const List<String> _roundedFallback = ['SF Pro Rounded', 'Roboto'];

  // ─── System font — body, headings, buttons ────────────────────────────────────────

  /// 46px 800 −1.8px — score hero number.
  static TextStyle get displayXl => TextStyle(
        fontSize: 46,
        fontWeight: FontWeight.w800,
        height: 0.9,
        letterSpacing: -1.8,
        color: AuroraColors.ink,
      );

  /// 36px 800 −1.2px — item count headers, big callouts.
  static TextStyle get displayLg => TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        height: 1.0,
        letterSpacing: -1.2,
        color: AuroraColors.ink,
      );

  /// 22px 700 −0.7px — screen greeting, screen title.
  static TextStyle get h1 => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.0,
        letterSpacing: -0.7,
        color: AuroraColors.ink,
      );

  /// 18px 600 −0.4px — section headings within a screen.
  static TextStyle get h2 => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.1,
        letterSpacing: -0.4,
        color: AuroraColors.ink,
      );

  /// 15px 700 −0.3px — card titles, list-item primary names.
  static TextStyle get h3 => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.3,
        color: AuroraColors.ink,
      );

  /// 14px 400 — body copy emphasis.
  static TextStyle get bodyLg => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AuroraColors.ink,
      );

  /// 13px 400 — default body copy.
  static TextStyle get body => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AuroraColors.ink,
      );

  /// 12px 400 — captions, secondary descriptions.
  static TextStyle get bodySm => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AuroraColors.ink,
      );

  // ─── System font, tabular figures — labels, eyebrows, numbers ─────────────────────────────

  /// 10px 500 +1.2px — mono eyebrow/label. ALWAYS render uppercase at call site.
  static TextStyle get label => TextStyle(
        fontFeatures: _tabular,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 1.2,
        letterSpacing: 1.2,
        color: AuroraColors.inkSecondary,
      );

  /// 9px 600 +0.8px — micro-labels (status chips). ALWAYS uppercase at call site.
  static TextStyle get labelSm => TextStyle(
        fontFeatures: _tabular,
        fontSize: 9,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.8,
        color: AuroraColors.inkSecondary,
      );

  /// 13px 600 — all inline numbers (dates, counts, prices).
  static TextStyle get number => TextStyle(
        fontFeatures: _tabular,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AuroraColors.ink,
      );

  /// 16px 700 — sheet and top-bar titles.
  static TextStyle get sheetTitle => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AuroraColors.ink,
      );

  /// 40px 800 rounded — Home health score number.
  static TextStyle get scoreNumber => TextStyle(
        fontFamilyFallback: _roundedFallback,
        fontFeatures: _tabular,
        fontSize: 40,
        fontWeight: FontWeight.w800,
        height: 1.0,
        letterSpacing: -1.6,
        color: AuroraColors.paper,
      );

  /// 10px 600 — tab bar label (700 when active via `copyWith`).
  static TextStyle get tabLabel => TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AuroraColors.inkPlaceholder,
      );
}
