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

  /// 15px 600 — pill button label.
  static TextStyle get button => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AuroraColors.ink,
      );

  /// 14px 600 — compact pill and inline text-button label.
  static TextStyle get buttonSm => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AuroraColors.ink,
      );

  /// 15px 500 — sheet Cancel.
  static TextStyle get cancel => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: AuroraColors.inkSubtle,
      );

  /// 16px 400 — text and select field value.
  static TextStyle get input => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AuroraColors.ink,
      );

  /// 13.5px 600 — chip label.
  static TextStyle get chip => TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AuroraColors.ink,
      );

  /// 10px 500 +0.3px — helper text under fields. ALWAYS uppercase at call site.
  static TextStyle get helper => TextStyle(
        fontFeatures: _tabular,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 1.35,
        letterSpacing: 0.3,
        color: AuroraColors.inkHelper,
      );

  /// 10px 500 +0.3px — row meta line (ink 55%). Uppercase at call site.
  static TextStyle get meta => TextStyle(
        fontFeatures: _tabular,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0.3,
        color: AuroraColors.inkSecondary,
      );

  /// 10px 600 — row trailing date / count.
  static TextStyle get rowDate => TextStyle(
        fontFeatures: _tabular,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AuroraColors.inkSecondary,
      );

  /// 10px 600 +1.2px ink — form section title. Uppercase at call site.
  static TextStyle get sectionTitle => TextStyle(
        fontFeatures: _tabular,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 1.2,
        color: AuroraColors.ink,
      );

  /// 14px 600 — task row title.
  static TextStyle get rowTitle => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AuroraColors.ink,
      );

  /// 10px 600 — tab bar label (700 when active via `copyWith`).
  static TextStyle get tabLabel => TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AuroraColors.inkPlaceholder,
      );
}

/// Type styles specific to the shared core widgets.
abstract final class AuroraSharedType {
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// 22px 800 −0.5 — empty/error/confirm title.
  static TextStyle get stateTitle => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.5,
        color: AuroraColors.ink,
      );

  /// 15px 400 on the empty/error body (ink 65%).
  static TextStyle get stateBody => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AuroraColors.inkBody,
      );

  /// 14.5px 400 modal body copy.
  static TextStyle get modalBody => TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AuroraColors.inkBody,
      );

  /// 15px 600 inline link rows ("Need Emergency?").
  static TextStyle get linkRow => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AuroraColors.ink,
      );

  /// 14.5px 700 snackbar message.
  static TextStyle get snackbarTitle => TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AuroraColors.paper,
      );

  /// 12.5px 400 snackbar second line.
  static TextStyle get snackbarSub => TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        height: 1.3,
        color: AuroraOnInk.secondary,
      );

  /// 15px 700 snackbar action (lime).
  static TextStyle get snackbarAction => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AuroraColors.lime,
      );

  /// 9px 600 +0.8 — status pill label (700 on done/behind via copyWith).
  static TextStyle get pill => TextStyle(
        fontFeatures: _tabular,
        fontSize: 9,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.8,
        color: AuroraColors.inkSecondary,
      );

  /// 13.5px 700 offline banner title.
  static TextStyle get offlineTitle => TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AuroraColors.amberDeep,
      );

  /// 9.5px 600 +0.4 offline banner second line.
  static TextStyle get offlineSub => TextStyle(
        fontFeatures: _tabular,
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.4,
        color: AuroraColors.amberDeep,
      );
}
