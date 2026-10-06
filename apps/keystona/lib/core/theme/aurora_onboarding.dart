import 'package:flutter/material.dart';

import 'aurora_colors.dart';

/// Aurora kit tokens for the onboarding screens (persona, your home, climate,
/// free month, do these first). Sizes are logical px at the 390 pt reference
/// width and are read through `context.aurora`.

/// Colors that only onboarding uses.
abstract final class AuroraOnbColors {
  /// Grid lines on the paper backdrop. (coral 0.12)
  static const Color grid = Color(0x1FFF3B62);

  /// Lift under the address suggestion list. (ink 0.16)
  static const Color suggestionShadow = Color(0x29071238);
}

/// Sizes that only onboarding uses.
abstract final class AuroraOnbSizes {
  /// Distance between grid lines and their thickness.
  static const double gridCell = 22;
  static const double gridLine = 1;

  /// Height of the grid backdrop that fades out below the top bar.
  static const double gridHeight = 300;

  /// Fraction of the backdrop that stays fully opaque before the fade.
  static const double gridSolidStop = 0.4;

  /// Border width of a selected choice card.
  static const double selectedBorder = 2;

  /// Progress segment height.
  static const double stepBarHeight = 4;

  /// Minimum width of the "1 OF 3" counter.
  static const double stepCounterMinWidth = 44;

  /// Back chevron glyph.
  static const double backGlyph = 22;

  /// Persona card icon tile, glyph and radio.
  static const double optionTile = 48;
  static const double optionGlyph = 24;
  static const double radioOuter = 24;
  static const double radioDot = 12;

  /// Kind-of-home tile minimum height.
  static const double typeTileHeight = 46;

  /// Trial benefit icon tile and glyph.
  static const double benefitTile = 36;
  static const double benefitGlyph = 18;

  /// Checklist hero check circle and glyph.
  static const double heroCheck = 56;
  static const double heroCheckGlyph = 28;

  /// Checklist home tile and glyph.
  static const double homeTile = 44;
  static const double homeTileGlyph = 20;

  /// Checklist step number circle.
  static const double stepNumber = 28;

  /// Checklist step row minimum height.
  static const double stepRowMinHeight = 72;

  /// Climate scale segment height and reminder row minimum height.
  static const double climateBar = 10;
  static const double climateRowMinHeight = 56;

  /// Reminder row leading glyph.
  static const double climateGlyph = 18;

  /// Share of the sheet content width the skeleton title bar takes.
  static const double skeletonTitleFraction = 0.8;
  static const double skeletonLineFraction = 0.6;
  static const double skeletonLineHeight = 14;
  static const double skeletonTitleHeight = 28;
  static const double skeletonCardHeight = 120;
  static const double skeletonRowHeight = 72;
}

/// Durations that only onboarding uses.
abstract final class AuroraOnbDurations {
  /// Free trial length.
  static const Duration trial = Duration(days: 30);
}

/// Shadows that only onboarding uses.
abstract final class AuroraOnbShadows {
  /// Address suggestion list lift.
  static const List<BoxShadow> suggestions = <BoxShadow>[
    BoxShadow(
      color: AuroraOnbColors.suggestionShadow,
      offset: Offset(0, 10),
      blurRadius: 30,
    ),
  ];
}

/// Type styles that only onboarding uses. System font; labels use tabular
/// figures. Uppercase labels must be uppercased at the call site.
abstract final class AuroraOnbType {
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// 30/800 -1 — screen title.
  static TextStyle get title => TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -1,
        color: AuroraColors.ink,
      );

  /// 26/800 -0.8 — climate sheet title.
  static TextStyle get sheetTitle => TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.8,
        color: AuroraColors.ink,
      );

  /// 15/400 — screen subtitle.
  static TextStyle get subtitle => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AuroraColors.inkBody,
      );

  /// 10/700 +1.2 coralDeep — eyebrow. Uppercase at call site.
  static TextStyle get eyebrow => TextStyle(
        fontFeatures: _tabular,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: 1.2,
        color: AuroraColors.coralDeep,
      );

  /// 10/700 +1 — "1 OF 3". Uppercase at call site.
  static TextStyle get stepCounter => TextStyle(
        fontFeatures: _tabular,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: 1,
        color: AuroraColors.inkSecondary,
      );

  /// 18/700 -0.3 — persona card title.
  static TextStyle get optionTitle => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.3,
        color: AuroraColors.ink,
      );

  /// 14/400 — persona card body.
  static TextStyle get optionBody => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AuroraColors.inkBody,
      );

  /// 10/600 +0.4 — persona card keywords. Uppercase at call site.
  static TextStyle get optionMeta => TextStyle(
        fontFeatures: _tabular,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.4,
        color: AuroraColors.inkSecondary,
      );

  /// 15/600 — address suggestion.
  static TextStyle get suggestion => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AuroraColors.ink,
      );

  /// 14.5/600 — kind-of-home tile.
  static TextStyle get tile => TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AuroraColors.ink,
      );

  /// 15/700 — benefit, plan and step title.
  static TextStyle get itemTitle => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: AuroraColors.ink,
      );

  /// 13.5/400 — benefit body.
  static TextStyle get itemBody => TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AuroraColors.inkBody,
      );

  /// 13/400 — checklist step subtitle.
  static TextStyle get stepBody => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.3,
        color: AuroraColors.inkSubtle,
      );

  /// 20/800 -0.5 — plan price.
  static TextStyle get planPrice => TextStyle(
        fontFeatures: _tabular,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.5,
        color: AuroraColors.ink,
      );

  /// 12.5/400 — fine print under the trial button.
  static TextStyle get finePrint => TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AuroraColors.inkSecondary,
      );

  /// 15/600 — quiet text link under the main button.
  static TextStyle get link => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AuroraColors.inkBody,
      );

  /// 14.5/400 — climate sheet description.
  static TextStyle get climateBody => TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AuroraColors.inkBody,
      );

  /// 14.5/600 — climate reminder title.
  static TextStyle get climateRow => TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AuroraColors.ink,
      );

  /// 9.5/700 +0.5 — climate scale number.
  static TextStyle get scaleNumber => TextStyle(
        fontFeatures: _tabular,
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: 0.5,
        color: AuroraColors.inkPlaceholder,
      );

  /// 16/700 — checklist home name.
  static TextStyle get homeName => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: AuroraColors.ink,
      );

  /// 12/800 — checklist step number.
  static TextStyle get stepNumber => TextStyle(
        fontFeatures: _tabular,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        height: 1.2,
        color: AuroraColors.ink,
      );
}
