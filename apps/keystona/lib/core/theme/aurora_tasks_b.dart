import 'package:flutter/material.dart';

import 'aurora_colors.dart';

/// Sprint 2 · Tasks (track B) tokens: Task detail (4.4), Log the details (4.7)
/// and Task history (4.9).
///
/// Values are logical px at the 390 pt reference width. Widgets read them
/// through `context.aurora` (`a.of(token)`), never directly as a size.
abstract final class AuroraTasksB {
  // ─── Page ───────────────────────────────────────────────────────────────────

  /// Gap between the blocks of the detail page (kit: 24).
  static const double sectionGap = 24;

  /// Gap between the blocks of the history page (kit: 22).
  static const double historyGap = 22;

  /// Gap between the top bar and the page header (kit: 24 gap pulled up 8).
  static const double headerAfterBar = 16;

  /// Text scale from which side-by-side rows stack instead (matches the
  /// confirm dialog).
  static const double stackTextScale = 1.3;

  /// Hairline gap between a title and its meta line.
  static const double hairlineGap = 2;

  /// Minimum height of a section label row (kit: 20).
  static const double sectionLabelMinHeight = 20;

  // ─── Detail: due / done card ────────────────────────────────────────────────

  /// Calendar tile and its glyph in the due card.
  static const double dueTile = 40;
  static const double dueGlyph = 20;

  /// Lime check badge in the done card and its glyph.
  static const double doneBadge = 32;
  static const double doneGlyph = 14;

  /// Done-card vertical padding (kit: 14).
  static const double doneCardPadV = 14;

  /// Parent ("For") card minimum height and its icon tile.
  static const double parentMinHeight = 64;
  static const double parentTile = 40;

  /// Numbered step circle.
  static const double stepCircle = 26;

  /// Gap between steps (kit: 14).
  static const double stepGap = 14;

  /// Timeline dot on the detail page and on the history page.
  static const double dotDetail = 12;
  static const double dotHistory = 14;

  /// Timeline connector line width and the dot's top offset.
  static const double timelineLine = 1;
  static const double dotTopDetail = 4;
  static const double dotTopHistory = 3;

  /// Gap between a timeline dot and its content, and between entries.
  static const double timelineGap = 14;
  static const double timelineEntryGap = 18;

  // ─── History ────────────────────────────────────────────────────────────────

  /// Every-time strip: bar height, gap and legend swatch.
  static const double stripBar = 22;
  static const double stripGap = 4;
  static const double legendSwatch = 10;

  /// Most bars drawn in the every-time strip (the latest ones).
  static const int stripMax = 16;

  /// Ring width of a late bar and its legend swatch (amber, a little heavier).
  static const double lateRing = 2;

  /// Gap between a legend swatch and its label.
  static const double legendGap = 5;

  /// Photo thumbnail on a history entry.
  static const double entryThumb = 64;

  /// Stat tiles per row at regular text size.
  static const int statColumns = 3;

  // ─── Log the details ────────────────────────────────────────────────────────

  /// Task title card icon tile.
  static const double logTile = 40;

  /// Pro avatar circle (initials).
  static const double proAvatar = 36;

  /// Photo grid columns, and how many slots to show at minimum.
  static const int photoColumns = 4;
  static const int photoMinSlots = 4;

  /// Remove target on a photo tile (the glyph is small, the target is 44).
  static const double photoRemoveGlyph = 14;

  /// Plus glyph on an empty photo slot.
  static const double photoAddGlyph = 20;

  /// Dash and gap length of an empty photo slot border.
  static const double dashLength = 6;
  static const double dashGap = 4;

  /// Text field with a date mask, in characters ("MM / DD / YYYY").
  static const int dateMaskLength = 14;

  /// Notes field cap (matches the legacy form).
  static const int notesMax = 1000;

  /// Cost fields cap.
  static const int moneyMax = 10;

  // ─── Skeleton ───────────────────────────────────────────────────────────────

  static const double skelEyebrow = 12;
  static const double skelTitle = 32;
  static const double skelSubtitle = 14;
  static const double skelCard = 128;
  static const double skelRow = 64;
  static const double skelTiles = 64;
  static const double skelBlock = 160;

  /// Placeholder rows in a loading pick-one sheet.
  static const int pickSkeletonRows = 3;
  static const double skelEyebrowFactor = 0.4;
  static const double skelTitleFactor = 0.8;
  static const double skelSubtitleFactor = 0.6;
}

/// Type styles the kit uses on the task screens that the shared scale lacks.
abstract final class AuroraTasksBType {
  /// Page title (28/800).
  static TextStyle get pageTitle => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.9,
    color: AuroraColors.ink,
  );

  /// Description under the title.
  static TextStyle get subtitle => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AuroraColors.inkSubtle,
  );

  /// "Due Wednesday, Oct 7".
  static TextStyle get dueTitle => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
    color: AuroraColors.ink,
  );

  /// "Done today, 3 days early".
  static TextStyle get doneTitle => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AuroraColors.ink,
  );

  /// 13/600 link row ("Done — add cost, photos or a receipt").
  static TextStyle get linkRow => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AuroraColors.inkSubtle,
  );

  /// Parent card name, history entry title ("Done").
  static TextStyle get itemTitle => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AuroraColors.ink,
  );

  /// Spec tile value (15/700, never wraps).
  static TextStyle get tileValue => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AuroraColors.ink,
  );

  /// Step text.
  static TextStyle get step => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AuroraColors.ink,
  );

  /// Step number inside its circle.
  static TextStyle get stepNumber => TextStyle(
    fontFeatures: const [FontFeature.tabularFigures()],
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AuroraColors.ink,
  );

  /// Second line of a timeline entry ("You · 10 min").
  static TextStyle get entryMeta => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AuroraColors.inkSubtle,
  );

  /// Note text on a history entry.
  static TextStyle get entryNote => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AuroraColors.inkBody,
  );

  /// Amount at the right of a timeline entry.
  static TextStyle get amount => TextStyle(
    fontFeatures: const [FontFeature.tabularFigures()],
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AuroraColors.ink,
  );

  /// Date title on the history page.
  static TextStyle get historyDate => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AuroraColors.ink,
  );

  /// Timing word on the history page ("3 DAYS EARLY"). Uppercase at call site.
  static TextStyle get timing => TextStyle(
    fontFeatures: const [FontFeature.tabularFigures()],
    fontSize: 9,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.6,
    color: AuroraColors.ink,
  );

  /// Big number in a history stat tile.
  static TextStyle get statValue => TextStyle(
    fontFeatures: const [FontFeature.tabularFigures()],
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.5,
    color: AuroraColors.ink,
  );

  /// Legend label under the strip. Uppercase at call site.
  static TextStyle get legend => TextStyle(
    fontFeatures: const [FontFeature.tabularFigures()],
    fontSize: 9.5,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.6,
    color: AuroraColors.ink,
  );

  /// Pill word on the eyebrow row (9/700 +0.8). Uppercase at call site.
  static TextStyle get pill => TextStyle(
    fontFeatures: const [FontFeature.tabularFigures()],
    fontSize: 9,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.8,
    color: AuroraColors.ink,
  );

  /// Title on the log screen's task card.
  static TextStyle get logCardTitle => TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AuroraColors.ink,
  );

  /// Cost total at the right of the COST header.
  static TextStyle get costTotal => TextStyle(
    fontFeatures: const [FontFeature.tabularFigures()],
    fontSize: 15,
    fontWeight: FontWeight.w800,
    height: 1.2,
    color: AuroraColors.ink,
  );

  /// BEFORE / AFTER badge on a photo tile. Uppercase at call site.
  static TextStyle get photoBadge => TextStyle(
    fontFeatures: const [FontFeature.tabularFigures()],
    fontSize: 7.5,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.7,
    color: AuroraColors.ink,
  );

  /// Initials in the pro avatar.
  static TextStyle get initials => TextStyle(
    fontFeatures: const [FontFeature.tabularFigures()],
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AuroraColors.ink,
  );

  /// "Change" link on the pro card.
  static TextStyle get change => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AuroraColors.cobalt,
  );

  /// Callout body on the history page.
  static TextStyle get callout => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AuroraColors.inkBody,
  );
}
