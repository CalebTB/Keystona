import 'package:flutter/material.dart';

import 'aurora_colors.dart';

/// Sprint 2 · Tasks (track A) tokens: the Tasks tab (Tasks, TasksCaughtUp),
/// All tasks (TasksAllYear), the long-press TaskMenu, TaskSkip and
/// TaskDoneQuick.
///
/// Values are logical px at the 390 pt reference width. Widgets read them
/// through `context.aurora` (`a.of(token)`), never directly as a size.
abstract final class AuroraTasksA {
  // ─── Page ───────────────────────────────────────────────────────────────────

  /// Top padding above the Tasks tab header (kit: 28).
  static const double pageTop = 28;

  /// Top padding of pushed screens that start with a back link (kit: 12).
  static const double pushedPageTop = 12;

  /// Magnifier in the search field.
  static const double searchGlyph = 18;

  // ─── Rows ───────────────────────────────────────────────────────────────────

  /// Task row minimum height.
  static const double rowMinHeight = 64;

  /// Gap between a row's text and its chip / date.
  static const double rowGap = 10;

  /// Minimum width of the date at a row's right edge, so dates line up.
  static const double dateMinWidth = 40;

  /// Check circle inside its 44 pt target.
  static const double checkCircle = 24;

  /// Check mark inside a done circle.
  static const double checkGlyph = 12;

  /// Done circle border width.
  static const double checkBorder = 1.5;

  // ─── Overdue card ───────────────────────────────────────────────────────────

  /// Glyph inside the "N DAYS LATE" chip.
  static const double lateGlyph = 11;

  /// Gap between the late glyph and its words.
  static const double lateGlyphGap = 4;

  /// Home glyph in the hero tile.
  static const double heroGlyph = 20;

  /// Minimum height of the "Doesn't apply to my home" row.
  static const double linkRowMinHeight = 32;

  /// Lime circle in the "done — nothing overdue" row.
  static const double doneBadge = 26;

  /// Done row minimum height.
  static const double doneRowMinHeight = 56;

  // ─── Caught up ──────────────────────────────────────────────────────────────

  /// Lime celebration circle and its check.
  static const double celebrate = 64;
  static const double celebrateGlyph = 30;

  /// Max width of the caught-up body copy.
  static const double celebrateBodyMaxWidth = 290;

  // ─── Year chart ─────────────────────────────────────────────────────────────

  /// Height of one month column (count, bar, letter).
  static const double monthColumn = 112;

  /// Tallest a bar can be.
  static const double barMaxHeight = 64;

  /// Shortest a bar can be (a month with one task still shows).
  static const double barMinHeight = 6;

  /// Bar width.
  static const double barWidth = 16;

  /// Bar corner radius.
  static const double barRadius = 5;

  /// Months drawn in the year chart and swiped through.
  static const int monthsShown = 12;

  /// Months in one season caption.
  static const int monthsPerSeason = 3;

  /// Swipe speed (px/s) above which a month change counts.
  static const double swipeVelocity = 200;

  // ─── Menu (TaskMenu) ────────────────────────────────────────────────────────

  /// Menu row minimum heights (two-line rows, one-line row).
  static const double menuRowMinHeight = 62;
  static const double menuRowShortMinHeight = 52;

  /// Glyph on a menu row.
  static const double menuGlyph = 22;

  /// Left inset of the frequency chips (lines up with the row text).
  static const double menuChipInset = 51;

  /// Frequency chip height.
  static const double frequencyChipHeight = 38;

  /// Thickness of the bar that sets "Stop reminding me" apart.
  static const double menuSetApart = 6;

  /// The pressed row lifts by this scale.
  static const double liftScale = 1.02;

  /// Blur behind the menu.
  static const double blurSigma = 6;

  /// Menu card and preview corner radius.
  static const double menuRadius = 18;

  // ─── Sheets (TaskSkip, TaskDoneQuick) ───────────────────────────────────────

  /// Radio circle and its inner dot.
  static const double radio = 22;
  static const double radioDot = 10;
  static const double radioBorderOn = 2;

  /// Done badge at the top of the quick-done sheet and its check.
  static const double doneSheetBadge = 52;
  static const double doneSheetGlyph = 24;

  /// Camera glyph on the "Add photos" row.
  static const double addMoreGlyph = 22;

  /// Share of the width the cost field takes next to the note field.
  static const int costFlex = 10;
  static const int noteFlex = 14;

  /// Text scale from which two side-by-side controls stack.
  static const double stackTextScale = 1.3;

  // ─── Skeleton ───────────────────────────────────────────────────────────────

  static const double skelEyebrow = 10;
  static const double skelTitle = 22;
  static const double skelSubtitle = 12;
  static const double skelEyebrowWidthFactor = 0.4;
  static const double skelTitleWidthFactor = 0.3;
  static const double skelSubtitleWidthFactor = 0.35;
  static const double skelHero = 250;
  static const double skelRow = 64;
  static const int skelRowCount = 3;

  // ─── Colors ─────────────────────────────────────────────────────────────────

  /// Scrim behind the long-press menu (ink at 32%; the screen is blurred too).
  static const Color menuScrim = Color(0x52071238);

  /// Bar that sets the destructive menu row apart (ink at 6%).
  static const Color setApartBar = Color(0x0F071238);
}

/// Type styles the kit uses on the Tasks screens that the shared scale lacks.
abstract final class AuroraTasksAType {
  /// Subtitle under "Tasks" ("1 overdue · 1 due today").
  static TextStyle get subtitle => TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AuroraColors.inkSecondary,
  );

  /// Search field placeholder.
  static TextStyle get searchHint => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: AuroraColors.inkPlaceholder,
  );

  /// Search field text.
  static TextStyle get searchInput => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: AuroraColors.ink,
  );

  /// Title of the overdue card.
  static TextStyle get heroTitle => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.5,
    color: AuroraColors.ink,
  );

  /// Description under the overdue card title.
  static TextStyle get heroBody => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AuroraColors.inkSubtle,
  );

  /// "Doesn't apply to my home" and other quiet links.
  static TextStyle get quietLink => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AuroraColors.inkSubtle,
  );

  /// "See all upcoming" (coral) and the done-this-week row.
  static TextStyle get link => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AuroraColors.ink,
  );

  /// Coral link ("See all upcoming", "Undo" on the done row).
  static TextStyle get coralLink => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AuroraColors.coral,
  );

  /// Month heading in the year view.
  static TextStyle get monthTitle => TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
    color: AuroraColors.ink,
  );

  /// Back link ("‹ Tasks").
  static TextStyle get back => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: AuroraColors.ink,
  );

  /// Count above a year-chart bar; [selected] is bold and ink.
  static TextStyle chartCount({required bool selected}) => TextStyle(
    fontFeatures: const [FontFeature.tabularFigures()],
    fontSize: 10,
    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
    height: 1.2,
    color: selected ? AuroraColors.ink : AuroraColors.inkHelper,
  );

  /// Month letter under a year-chart bar.
  static TextStyle chartLabel({required bool selected}) => TextStyle(
    fontFeatures: const [FontFeature.tabularFigures()],
    fontSize: 10,
    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
    height: 1.2,
    color: selected ? AuroraColors.ink : AuroraColors.inkSecondary,
  );

  /// Season caption under the year chart.
  static TextStyle get season => TextStyle(
    fontFeatures: const [FontFeature.tabularFigures()],
    fontSize: 9,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.8,
    color: AuroraColors.inkHelper,
  );

  /// Heading of the celebration ("You're all caught up").
  static TextStyle get celebrateTitle => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
    color: AuroraColors.ink,
  );

  /// Body of the celebration.
  static TextStyle get celebrateBody => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AuroraColors.inkSubtle,
  );

  /// Menu row title.
  static TextStyle get menuTitle => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AuroraColors.ink,
  );

  /// Menu row second line.
  static TextStyle get menuSub => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: AuroraColors.inkSubtle,
  );

  /// Title of the lifted preview card.
  static TextStyle get previewTitle => TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.6,
    color: AuroraColors.ink,
  );

  /// Description of the lifted preview card.
  static TextStyle get previewBody => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AuroraColors.inkBody,
  );

  /// "TAP ANYWHERE TO CLOSE".
  static TextStyle get closeHint => TextStyle(
    fontFeatures: const [FontFeature.tabularFigures()],
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.8,
    color: AuroraOnInk.secondary,
  );

  /// Frequency chip label.
  static TextStyle get frequencyChip => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AuroraColors.ink,
  );

  /// Task name at the top of the skip and quick-done sheets.
  static TextStyle get sheetHeading => TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.4,
    color: AuroraColors.ink,
  );

  /// Reason title in the skip sheet.
  static TextStyle get reasonTitle => TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AuroraColors.ink,
  );

  /// Reason description in the skip sheet.
  static TextStyle get reasonSub => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AuroraColors.inkSubtle,
  );

  /// What will happen, in the result box of the skip sheet.
  static TextStyle get result => TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AuroraColors.inkBody,
  );

  /// "DONE · NEXT ONE JAN 4, 2027" under the quick-done heading.
  static TextStyle get doneMeta => TextStyle(
    fontFeatures: const [FontFeature.tabularFigures()],
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0.6,
    color: AuroraColors.olive,
  );
}
