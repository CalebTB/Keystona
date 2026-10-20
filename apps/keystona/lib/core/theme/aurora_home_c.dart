import 'package:flutter/material.dart';

import 'aurora_colors.dart';

/// Home profile track C tokens: Appliances, Add / Edit an appliance, the
/// appliance detail and the shared item screens (tasks, photos, reminders).
/// Kit px values are logical px at the 390 pt reference width and are read
/// through `context.aurora`; widgets use them as minimums, never fixed sizes.
abstract final class AuroraHomeCColors {
  /// Border of the scan banner and the "label read" circle.
  static const Color bannerBorder = AuroraColors.limeDeep;

  /// Outline of the EVERY / DIY pills on a task card. (ink 16%)
  static const Color pillBorder = Color(0x29071238);
}

abstract final class AuroraHomeCSizes {
  /// Outlined / filled pill in an item screen's top bar.
  static const double pillHeight = 36;

  // ─── ItemTasks ────────────────────────────────────────────────────────────

  /// Gap between the segmented tabs' track and its chosen tab.
  static const double tabsInset = 3;

  /// Olive check on a finished task.
  static const double doneCheck = 24;

  // ─── ItemPhotos ───────────────────────────────────────────────────────────

  /// The big photo: width / height.
  static const double viewerAspect = 4 / 3;

  /// Expand button on the big photo.
  static const double expandButton = 40;

  /// Thumbnails per row.
  static const int photoColumns = 4;

  /// "Add" pill on the limit card.
  static const double addPillHeight = 40;

  /// Check circle on a "good photo" line.
  static const double tipCheck = 24;

  /// Swipe speed (logical px per second) that changes photo.
  static const double swipeVelocity = 200;

  // ─── Add / Edit appliance ─────────────────────────────────────────────────

  /// Lime check circle on the scan banner.
  static const double bannerCheck = 32;

  /// At this text scale two side-by-side fields stack.
  static const double stackTextScale = 1.5;

  // ─── Appliance detail ─────────────────────────────────────────────────────

  /// Shield circle on the warranty callout.
  static const double calloutIcon = 36;

  // ─── Skeletons ────────────────────────────────────────────────────────────
  static const double skeletonRow = 88;
  static const double skeletonCard = 68;
  static const double skeletonHero = 200;
  static const double skeletonBlock = 120;
  static const double skeletonTab = 44;
}

abstract final class AuroraHomeCType {
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// 9 / 600 +0.6 - the EVERY / DIY pills on a task card.
  static TextStyle get pill => TextStyle(
    fontFeatures: _tabular,
    fontSize: 9,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.6,
    color: AuroraColors.inkSubtle,
  );

  /// 24 / 800 - the amount on the Done tab's summary.
  static TextStyle get doneTotal => TextStyle(
    fontFeatures: _tabular,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.6,
    color: AuroraColors.ink,
  );
}
