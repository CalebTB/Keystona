import 'package:flutter/material.dart';

import 'aurora_colors.dart';

/// Home profile (Sprint 3) shared tokens: item rows, lifespan bars, detail
/// cards, history timeline, photo tiles, dashed controls and the "from scan"
/// field edge. Kit px values are logical px at the 390 pt reference width and
/// are read through `context.aurora` by the widgets.
abstract final class AuroraHomeColors {
  /// Blueprint grid lines on photo placeholders. (cobalt 0.11)
  static const Color gridLine = Color(0x1C2540D8);

  /// Dashed outline of add buttons and suggestion chips. (ink 0.22)
  static const Color dashed = Color(0x38071238);

  /// The 75% tick inside a lifespan bar. (ink 0.25)
  static const Color barTick = Color(0x40071238);

  /// Outline chip border (PRO / tag chips). (ink 0.16)
  static const Color chipBorder = Color(0x29071238);
}

abstract final class AuroraHomeSizes {
  /// Lifespan bar thickness in list rows and in the detail lifespan card.
  static const double barHeight = 6;
  static const double barHeightLg = 8;

  /// Where the "aging" tick sits on a bar, as a fraction of its width.
  static const double barTickAt = 0.75;

  /// Short bar on compact (HomeProfile) rows.
  static const double compactBarWidth = 64;

  /// Icon tile on list rows and its glyph.
  static const double itemTile = 40;
  static const double itemTileGlyph = 19;

  /// Bare glyph on compact rows.
  static const double compactGlyph = 20;

  /// Document row tile and glyph.
  static const double docTile = 36;
  static const double docTileGlyph = 18;

  /// Hero photo placeholder: width / height (16:10).
  static const double heroAspect = 1.6;

  /// Photo tile in a grid: width / height.
  static const double tileAspect = 1;

  /// Blueprint grid cell and line width.
  static const double gridCell = 22;
  static const double gridLineWidth = 1;

  /// Photo count badge height.
  static const double badgeHeight = 28;

  /// Timeline dot and rail.
  static const double timelineDot = 12;
  static const double timelineRail = 1;

  /// Inset "from scan" edge.
  static const double scanEdge = 3;

  /// Dashed outline pattern.
  static const double dashLength = 6;
  static const double dashGap = 4;
  static const double dashedStroke = 1.5;

  /// Minimum height of the dashed add / log buttons.
  static const double dashedButtonMin = 48;

  /// Minimum height of a key/value row, a document row and a next-up row.
  static const double rowMin = 44;
  static const double docRowMin = 60;

  /// Minimum height of a section label row.
  static const double sectionLabelMin = 20;

  /// Chip height on the filter bar sort toggle.
  static const double sortHeight = 30;
}

abstract final class AuroraHomeType {
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// 28 / 800 -0.9 - the item name on a detail screen.
  static TextStyle get itemTitle => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.9,
    color: AuroraColors.ink,
  );

  /// 14 / 700 tabular - age on list rows.
  static TextStyle get itemAge => TextStyle(
    fontFeatures: _tabular,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AuroraColors.ink,
  );

  /// 12 / 500 - "of ~12 yrs".
  static TextStyle get itemOf => TextStyle(
    fontFeatures: _tabular,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: AuroraColors.inkSecondary,
  );

  /// 9.5 / 700 +0.6 - status line on rows. Uppercase at call site.
  static TextStyle get status => TextStyle(
    fontFeatures: _tabular,
    fontSize: 9.5,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0.6,
    color: AuroraColors.inkSecondary,
  );

  /// 30 / 800 - "5½ yrs" on the lifespan card.
  static TextStyle get lifespanBig => TextStyle(
    fontFeatures: _tabular,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -1,
    color: AuroraColors.ink,
  );

  /// 15 / 600 - "old".
  static TextStyle get lifespanOld => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AuroraColors.inkSubtle,
  );

  /// 14 / 600 - value on a key/value row.
  static TextStyle get keyValue => TextStyle(
    fontFeatures: _tabular,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AuroraColors.ink,
  );

  /// 15 / 600 - titles on history and document rows.
  static TextStyle get entryTitle => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AuroraColors.ink,
  );

  /// 9 / 700 +0.8 - tags, PRO chips, COPIED. Uppercase at call site.
  static TextStyle get tag => TextStyle(
    fontFeatures: _tabular,
    fontSize: 9,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.8,
    color: AuroraColors.inkSubtle,
  );

  /// 12.5 / 600 - sort toggle.
  static TextStyle get sort => TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AuroraColors.ink,
  );

  /// 14 / 400 - copy under the lifespan bar.
  static TextStyle get lifespanBody => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AuroraColors.inkBody,
  );
}

abstract final class AuroraHomeDurations {
  /// How long a copy icon shows "COPIED" before flipping back.
  static const Duration copied = Duration(milliseconds: 1400);
}
