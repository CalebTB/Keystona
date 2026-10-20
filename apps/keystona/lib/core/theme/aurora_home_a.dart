import 'package:flutter/material.dart';

import 'aurora_colors.dart';

/// Home profile, track A (HomeProfile, HomeEdit, HomeLifespan) tokens. Kit px
/// values are logical px at the 390 pt reference width and are read through
/// `context.aurora` by the widgets.
abstract final class AuroraHomeASizes {
  /// Cover photo on HomeProfile: width / height (16:9).
  static const double coverAspect = 16 / 9;

  /// Cover photo tile on HomeEdit: width / height (4:3).
  static const double editCoverAspect = 4 / 3;

  /// Cover tile and "ADD" tile share the row 2 : 1.
  static const int editCoverFlex = 2;
  static const int editAddFlex = 1;

  /// Icon tile on the lifespan callout and its glyph.
  static const double calloutTile = 36;
  static const double calloutGlyph = 18;

  /// Minimum height of a callout, a link row and the "Around the house" row.
  static const double linkRowMin = 56;

  /// Health ring: diameter and stroke.
  static const double ring = 52;
  static const double ringStroke = 6;

  /// Height of the bar area in the "next 5 years" chart.
  static const double chartBars = 64;

  /// Shortest bar (the empty-year stub).
  static const double chartStub = 4;

  /// Timeline row: drawing height, track and fill thickness, today tick.
  static const double timelineHeight = 16;
  static const double timelineBar = 6;
  static const double timelineTick = 1.5;

  /// Over-run hatch: stripe and gap.
  static const double hatchStripe = 3;
  static const double hatchGap = 2;

  /// Timeline axis: years shown before and after the current year.
  static const int axisYearsBefore = 19;
  static const int axisYearsAfter = 15;

  /// Decade ticks closer than this many years to today are left out so the
  /// TODAY tag stays readable.
  static const int tickClearYears = 4;

  /// Years in the "set aside" forecast and months it is spread over.
  static const int forecastYears = 5;
  static const int monthsPerYear = 12;

  /// Height of the tick row above the timeline.
  static const double tickRow = 18;

  /// Legend swatch.
  static const double swatchWidth = 10;
  static const double swatchHeight = 6;

  /// Set-aside table: year column width and amount column minimum.
  static const double yearColumn = 40;
  static const double amountMin = 60;

  /// Inline bar of the set-aside table.
  static const double inlineBar = 8;

  /// Tabs on HomeLifespan.
  static const double tabHeight = 38;

  /// "Kind of home" choice minimum height.
  static const double choiceMin = 46;

  /// Stepper row minimum height and the value column.
  static const double stepperRowMin = 56;
  static const double stepperValueMin = 36;

  /// Height of the climate card glyph.
  static const double climateGlyph = 18;
  static const double climateLock = 15;

  /// Item height of the month / year wheels.
  static const double wheelItem = 40;
  static const double wheelHeight = 180;

  /// Width each field of a side by side form row needs, per unit of text
  /// scale; below it the fields stack.
  static const double sideBySidePerField = 110;

  /// Premium chip glyph.
  static const double premiumGlyph = 11;

  /// Skeleton block heights (HomeProfile, HomeLifespan, HomeEdit).
  static const double skelLine = 14;
  static const double skelTitle = 32;
  static const double skelCallout = 62;
  static const double skelRows = 220;
  static const double skelCard = 160;
  static const double skelTabs = 44;
  static const double skelTimelineRow = 70;
  static const double skelField = 50;
}

abstract final class AuroraHomeAColors {
  /// Locked card on HomeEdit (the climate zone). (ink 0.04)
  static const Color lockedFill = Color(0x0A071238);

  /// Unfilled part of a health ring.
  static const Color ringTrack = AuroraColors.inkBorder;

  /// Hatched stripes of a bar that ran past its life.
  static const Color hatch = AuroraColors.coral;
}

abstract final class AuroraHomeAType {
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// 26 / 800 -0.8 - the big total.
  static TextStyle get bigTotal => TextStyle(
    fontFeatures: _tabular,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.8,
    color: AuroraColors.ink,
  );

  /// 14 / 600 - "to replace 3 things".
  static TextStyle get bigTotalSub => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AuroraColors.inkSubtle,
  );

  /// 13.5 / 400 - copy under the big total.
  static TextStyle get summaryBody => TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AuroraColors.inkBody,
  );

  /// 15 / 800 - score inside a ring.
  static TextStyle get ringScore => TextStyle(
    fontFeatures: _tabular,
    fontSize: 15,
    fontWeight: FontWeight.w800,
    height: 1.1,
    color: AuroraColors.ink,
  );

  /// 9.5 / 700 +0.8 - ring caption and chart value.
  static TextStyle get caption => TextStyle(
    fontFeatures: _tabular,
    fontSize: 9.5,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.8,
    color: AuroraColors.ink,
  );

  /// 9.5 / 600 - chart year and timeline ticks.
  static TextStyle get tick => TextStyle(
    fontFeatures: _tabular,
    fontSize: 9.5,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AuroraColors.inkSecondary,
  );

  /// 9.5 / 700 +0.6 - legend words.
  static TextStyle get legend => TextStyle(
    fontFeatures: _tabular,
    fontSize: 9.5,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.6,
    color: AuroraColors.ink,
  );

  /// 8.5 / 700 +0.6 - the TODAY tag.
  static TextStyle get todayTag => TextStyle(
    fontFeatures: _tabular,
    fontSize: 8.5,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.6,
    color: AuroraColors.paper,
  );

  /// 14.5 / 700 - item name on the timeline.
  static TextStyle get timelineName => TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AuroraColors.ink,
  );

  /// 10 / 700 +0.4 - "REPLACE ~2038".
  static TextStyle get timelineEnd => TextStyle(
    fontFeatures: _tabular,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0.4,
    color: AuroraColors.inkSecondary,
  );

  /// 10 / 600 - cost on the timeline.
  static TextStyle get timelineCost => TextStyle(
    fontFeatures: _tabular,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AuroraColors.inkBody,
  );

  /// 12 / 700 - year in the set-aside table.
  static TextStyle get setAsideYear => TextStyle(
    fontFeatures: _tabular,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AuroraColors.ink,
  );

  /// 14 / 700 - amount in the set-aside table.
  static TextStyle get setAsideAmount => TextStyle(
    fontFeatures: _tabular,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AuroraColors.ink,
  );

  /// 14 / 600 - tab label.
  static TextStyle get tab => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AuroraColors.inkBody,
  );

  /// 14.5 / 600 - "kind of home" choice.
  static TextStyle get choice => TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AuroraColors.ink,
  );

  /// 17 / 700 - stepper value.
  static TextStyle get stepperValue => TextStyle(
    fontFeatures: _tabular,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AuroraColors.ink,
  );

  /// 15 / 600 - climate card title.
  static TextStyle get climateTitle => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AuroraColors.ink,
  );

  /// 13 / 600 cobalt - "How long things last", "Edit".
  static TextStyle get link => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AuroraColors.cobalt,
  );
}
