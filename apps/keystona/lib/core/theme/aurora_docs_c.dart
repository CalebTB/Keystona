import 'package:flutter/material.dart';

import 'aurora_colors.dart';

/// Docs track C tokens (document detail, search, expiring), taken from the
/// kit sources `DocDetail`, `Search`, `SearchResults` and `DocsExpiring`.
///
/// Values are logical px at the 390 pt reference width. Widgets read sizes
/// through `context.aurora` and use them as minimums, never fixed heights.
abstract final class AuroraDocsCColors {
  /// Graph-paper grid lines behind the document preview. (cobalt 11%)
  static const Color previewGrid = Color(0x1C2540D8);

  /// Left rule beside the notes paragraph. (cobalt 35%)
  static const Color noteRule = Color(0x592540D8);
}

abstract final class AuroraDocsCSizes {
  // ─── Document detail ──────────────────────────────────────────────────────

  /// Preview card proportion (358 x 300 at the reference width).
  static const double previewAspect = 1.2;

  /// Graph-paper grid cell edge.
  static const double previewGridCell = 22;

  /// Paper sheet drawn on the preview: inset from the top.
  static const double previewPaperTop = 22;

  /// Paper sheet width as a fraction of the preview width.
  static const double previewPaperWidthFactor = 0.586;

  /// Paper sheet inner padding.
  static const double previewPaperPadH = 18;
  static const double previewPaperPadV = 20;

  /// Placeholder text lines on the paper sheet.
  static const double previewTitleLine = 9;
  static const double previewTextLine = 5;
  static const double previewLineGap = 8;
  static const double previewLineSpacing = 6;

  /// "Open" pill and "PAGE 1 OF 3" tag inset from the preview corner.
  static const double previewCornerInset = 10;
  static const double openPillHeight = 34;
  static const double openPillPadH = 14;

  /// Coverage progress bar.
  static const double coverageBarHeight = 8;

  /// Claim card icon circle.
  static const double claimIconCircle = 36;

  /// Minimum heights of the claim and linked rows.
  static const double claimMinHeight = 60;
  static const double linkedRowMinHeight = 64;

  /// Width of the rule beside the notes paragraph.
  static const double noteRuleWidth = 2;

  /// Gap between the main sections of the detail screen.
  static const double sectionGap = 24;

  /// Skeleton block heights: a short card, a tall card, an expiring card.
  static const double skeletonCard = 100;
  static const double skeletonCardTall = 150;
  static const double skeletonExpiringCard = 88;

  // ─── Search ───────────────────────────────────────────────────────────────

  /// Search field height and the pieces inside it.
  static const double searchFieldHeight = 44;
  static const double searchTokenHeight = 28;
  static const double searchTokenClose = 22;
  static const double searchClearButton = 28;

  /// Suggestion row ("Search in") minimum height.
  static const double suggestionRowMinHeight = 52;

  /// Result row thumbnail and minimum height.
  static const double resultThumbWidth = 32;
  static const double resultThumbHeight = 40;
  static const double resultRowMinHeight = 64;

  /// Premium gate card minimum height.
  static const double gateMinHeight = 60;

  /// Gap between the blocks of the search body.
  static const double searchSectionGap = 22;

  /// Dashed border segment lengths for the Premium gate card.
  static const double dashLength = 6;
  static const double dashGap = 4;

  // ─── Expiring ─────────────────────────────────────────────────────────────

  /// Range tab height.
  static const double rangeTabHeight = 38;

  /// Already-ended row minimum height.
  static const double endedRowMinHeight = 56;

  /// Padding inside the segmented range control.
  static const double rangeTabsPad = 3;
}

abstract final class AuroraDocsCType {
  /// 28px 800 -0.9 — detail and expiring screen title.
  static TextStyle get screenTitle => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.9,
        color: AuroraColors.ink,
      );

  /// 20px 700 -0.4 — coverage headline.
  static TextStyle get coverageTitle => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.4,
        color: AuroraColors.ink,
      );

  /// 15px 400 — search field text.
  static TextStyle get searchInput => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.3,
        color: AuroraColors.ink,
      );

  /// 17px 600 — "No documents match" title.
  static TextStyle get noResultsTitle => TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AuroraColors.ink,
      );

  /// 15px 400 — notes paragraph.
  static TextStyle get notes => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AuroraColors.ink,
      );
}
