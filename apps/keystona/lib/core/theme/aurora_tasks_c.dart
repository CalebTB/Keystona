import 'package:flutter/material.dart';

import 'aurora_colors.dart';

/// Tasks track C tokens (add a task, review your reminders, around the house,
/// turned-off reminders), taken from the kit sources `AddTask`, `TaskReview`,
/// `HomeReminders` and `SettingsReminders`.
///
/// Values are logical px at the 390 pt reference width. Widgets read sizes
/// through `context.aurora` and use them as minimums, never fixed heights.
abstract final class AuroraTasksCColors {
  /// Left rule beside the "Every N years" slider. (cobalt 35%)
  static const Color yearsRule = Color(0x592540D8);

  /// Outline of the "what saving does" summary once the form is ready, and of
  /// the hint card on Around the house. (cobalt 35%)
  static const Color readyRule = Color(0x592540D8);
}

abstract final class AuroraTasksCSizes {
  // ─── Add a task ───────────────────────────────────────────────────────────

  /// First-due chip (label over the date) minimum height.
  static const double dueChipMinHeight = 56;

  /// Segmented choice (Systems / Appliances) minimum height.
  static const double segmentMinHeight = 40;

  /// "Who does it" choice minimum height.
  static const double whoMinHeight = 46;

  /// Square icon tile on the linked item field.
  static const double linkTile = 32;

  /// Glyph inside [linkTile].
  static const double linkTileGlyph = 17;

  /// Radio circle at the end of an item row, and the check inside it.
  static const double radio = 22;
  static const double radioCheck = 12;

  /// Minimum height of an item row in the inline picker.
  static const double pickerRowMinHeight = 52;

  /// Left rule beside the "Every N years" slider.
  static const double yearsRule = 2;

  /// Glyph on a common-task chip.
  static const double suggestionPlus = 14;

  /// Glyph on the summary box.
  static const double summaryIcon = 20;

  /// Most dues columns / choices shown side by side before they wrap.
  static const int dueColumns = 4;

  /// Choice columns in the "Who does it" row.
  static const int whoColumns = 3;

  /// Width at which the first-due chips stop fitting four across.
  static const double dueChipMinWidth = 64;

  // ─── Reminder lists ───────────────────────────────────────────────────────

  /// Minimum height of a switch row (Review your reminders).
  static const double switchRowMinHeight = 60;

  /// Minimum height of a row with a "how often" pill or a reason line.
  static const double detailRowMinHeight = 64;

  /// "How often" pill on an Around the house row.
  static const double frequencyPillHeight = 26;
  static const double frequencyChevron = 10;

  /// Reason tag (FREEZE, HUMID, STORMS) padding.
  static const double tagPadH = 7;
  static const double tagPadV = 2;

  /// Progress bar under the "12 of 14 on" summary.
  static const double progressHeight = 6;

  /// Glyph on the Add a reminder row and the info cards.
  static const double actionGlyph = 18;

  /// Glyph on the delete button of one of your own reminders.
  static const double deleteGlyph = 18;

  /// Skeleton row and block heights.
  static const double skeletonRow = 60;
  static const double skeletonStat = 64;
  static const double skeletonSummary = 80;

  /// Add a task form padding above the first block and below the last.
  static const double formPadTop = 18;
  static const double formPadBottom = 30;

  /// Gap between the blocks of a reminder screen.
  static const double blockGap = 22;

  /// Dashed outline: dash and gap length.
  static const double dashLength = 6;
  static const double dashGap = 4;

  /// Section header minimum height.
  static const double sectionHeaderMinHeight = 20;
}

abstract final class AuroraTasksCType {
  /// 28px 800 -0.9 — screen title on the reminder screens.
  static TextStyle get screenTitle => const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.9,
    color: AuroraColors.ink,
  );

  /// 24px 800 -0.6 — "12" in "12 of 14 on".
  static TextStyle get summaryNumber => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.6,
    color: AuroraColors.ink,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// 22px 800 -0.5 — the three counts on Around the house.
  static TextStyle get statNumber => const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.5,
    color: AuroraColors.ink,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// 15px 600 — reminder name on a row.
  static TextStyle get rowName => const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AuroraColors.ink,
  );

  /// 12.5px 600 — value inside the "how often" pill.
  static TextStyle get frequency => const TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AuroraColors.ink,
  );

  /// 9px 700 +0.6 — reason tag. Uppercase at call site.
  static TextStyle get tag => const TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.6,
    color: AuroraColors.inkSubtle,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// 9.5px 600 +0.6 — date under a first-due chip label. Uppercase.
  static TextStyle get chipSub => const TextStyle(
    fontSize: 9.5,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.6,
    color: AuroraColors.inkSecondary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// 14px 600 — first-due chip label, segmented choice label.
  static TextStyle get choice => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AuroraColors.ink,
  );

  /// 15px 600 — "Who does it" choice label.
  static TextStyle get whoChoice => const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AuroraColors.ink,
  );

  /// 15px 700 — "3 years" beside the slider.
  static TextStyle get yearsValue => const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AuroraColors.ink,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// 14px 400 1.5 — the paragraph under a screen title.
  static TextStyle get blurb => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AuroraColors.inkBody,
  );

  /// 13px 400 1.45 — text on the info cards.
  static TextStyle get infoCard => const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AuroraColors.inkBody,
  );

  /// 14px 400 1.45 — the "what saving does" sentence.
  static TextStyle get summary => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AuroraColors.ink,
  );
}

/// Layout proportions that are ratios, not sizes.
abstract final class AuroraTasksCRatios {
  /// "Tools & supplies" is a little wider than "Estimate" (1.4 : 1).
  static const int estimateFlex = 10;
  static const int toolsFlex = 14;

  /// Width below which the two cost fields stack.
  static const double costStackWidth = 300;

  /// Text scale above which two-up field rows stack.
  static const double stackTextScale = 1.3;
}

abstract final class AuroraTasksCDurations {
  /// How long to wait for suggested reminders before carrying on without
  /// them.
  static const Duration suggestionTimeout = Duration(seconds: 12);
}
