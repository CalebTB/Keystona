import 'package:flutter/material.dart';

import 'aurora_colors.dart';

/// Sprint 1 · Docs (track A) tokens: the Docs tab (DocsSearchLed, DocsEmpty)
/// and Your categories (DocCategories).
///
/// Values are logical px at the 390 pt reference width. Widgets read them
/// through `context.aurora` (`a.of(token)`), never directly as a size.
abstract final class AuroraDocsA {
  // ─── Page ───────────────────────────────────────────────────────────────────

  /// Top padding above the page header (kit: 28).
  static const double pageTop = 28;

  /// Text scale from which two-button rows stack instead of sitting side by
  /// side (same threshold the confirm dialog uses).
  static const double stackTextScale = 1.3;

  /// Tiny gap between a row title and its meta line, and pill padding.
  static const double hairlineGap = 2;

  // ─── Docs tab ───────────────────────────────────────────────────────────────

  /// Pulsing dot in front of "EXPIRING SOON".
  static const double pulseDot = 7;

  /// Radius the pulse ring grows to beyond the dot.
  static const double pulseRing = 6;

  /// Opacity of the pulse ring when it starts; it fades to nothing.
  static const double pulseStartOpacity = 0.5;

  /// Document row thumbnail (a file glyph in an outlined tile).
  static const double docThumbWidth = 32;
  static const double docThumbHeight = 40;

  /// Document row minimum height.
  static const double rowMinHeight = 64;

  /// Small file-type glyph inside the thumbnail.
  static const double docThumbGlyph = 16;

  /// Magnifier in the search field.
  static const double searchGlyph = 18;

  /// Outlined "+" circle on a suggestion row.
  static const double plusCircle = 32;

  /// Left inset of the hairline between suggestion rows (rows are indented
  /// past their icon).
  static const double suggestionInset = 46;

  /// Dashed border: dash and gap length.
  static const double dashLength = 6;
  static const double dashGap = 4;

  // ─── Categories ─────────────────────────────────────────────────────────────

  /// Drag handle column.
  static const double dragHandleWidth = 28;

  /// Icon tile on a category row.
  static const double categoryTile = 36;

  /// Glyph inside a category tile.
  static const double categoryGlyph = 18;

  /// Category row minimum height.
  static const double categoryRowMinHeight = 60;

  /// Grip glyph on the drag handle.
  static const double dragGlyph = 18;

  /// Icon picker square (kit: 44, also the touch target).
  static const double iconPick = 44;

  /// Collapsed height of the "standard categories" disclosure.
  static const double disclosureMinHeight = 52;

  // ─── Skeleton ───────────────────────────────────────────────────────────────

  static const double skelEyebrow = 10;
  static const double skelTitle = 22;
  static const double skelSubtitle = 12;
  static const double skelEyebrowWidthFactor = 0.4;
  static const double skelTitleWidthFactor = 0.5;
  static const double skelSubtitleWidthFactor = 0.3;
  static const double skelHero = 250;
  static const double skelRow = 64;
  static const double skelCategoryRow = 60;
  static const int skelRowCount = 5;
  static const int skelCategoryCount = 3;
}

/// Type styles the kit uses on the Docs screens that the shared scale lacks.
abstract final class AuroraDocsAType {
  /// "Documents" subtitle under the title ("1 expiring soon").
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

  /// Title of the expiring-soon card and of the empty hero.
  static TextStyle get heroTitle => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.5,
    color: AuroraColors.ink,
  );

  /// Description under the hero title.
  static TextStyle get heroBody => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AuroraColors.inkSubtle,
  );

  /// Empty-hero description.
  static TextStyle get emptyBody => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AuroraColors.inkSubtle,
  );

  /// Inline link ("See all 12", "All expiring dates").
  static TextStyle get link => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AuroraColors.ink,
  );

  /// Category row name.
  static TextStyle get rowName => TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AuroraColors.ink,
  );

  /// "Your categories" page title.
  static TextStyle get pageTitle => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.9,
    color: AuroraColors.ink,
  );

  /// Page intro paragraph.
  static TextStyle get intro => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AuroraColors.inkBody,
  );

  /// Back link ("‹ Documents").
  static TextStyle get back => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: AuroraColors.ink,
  );

  /// Delete-confirmation heading.
  static TextStyle get confirmTitle => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AuroraColors.ink,
  );

  /// Delete-confirmation body.
  static TextStyle get confirmBody => TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AuroraColors.inkBody,
  );
}
