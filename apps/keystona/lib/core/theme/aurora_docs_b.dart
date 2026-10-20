import 'package:flutter/painting.dart';

/// Tokens for the document add flow (Sprint 1.2 / 1.7): the add-from sheet,
/// the camera scan, the category picker, the new-document form and the
/// "reading your document" state. Kit px values are logical px at the 390 pt
/// reference width; widgets read sizes through `context.aurora`.
abstract final class AuroraCameraColors {
  /// Camera surface behind the viewfinder (kit `#05091C`).
  static const Color surface = Color(0xFF05091C);

  /// Centre of the viewfinder glow (kit `#3A3F55`).
  static const Color glowCenter = Color(0xFF3A3F55);

  /// Outer edge of the viewfinder glow (kit `#10142A`).
  static const Color glowEdge = Color(0xFF10142A);

  /// Round control fill on the camera (white 12%).
  static const Color controlFill = Color(0x1FFFFFFF);

  /// Mode toggle track and flash-off fill (white 10%).
  static const Color toggleTrack = Color(0x1AFFFFFF);

  /// Inactive toggle label (white 75%).
  static const Color toggleInactive = Color(0xBFFFFFFF);

  /// Frame corners before edges are found (white 70%).
  static const Color cornerIdle = Color(0xB3FFFFFF);

  /// Hint pill fill before edges are found (white 14%).
  static const Color hintIdleFill = Color(0x24FFFFFF);

  /// Dim layer behind the reading card (surface 55%).
  static const Color readingScrim = Color(0x8C05091C);

  /// Captured page thumbnail while its image decodes (kit `#F4F1E8`).
  static const Color pageThumb = Color(0xFFF4F1E8);

  /// Deep shadow under the reading card (black 40%).
  static const Color cardShadow = Color(0x66000000);
}

abstract final class AuroraCameraSizes {
  /// Viewfinder frame width as a fraction of the screen width (286 / 390).
  static const double frameWidthFraction = 0.73;

  /// Viewfinder frame width / height (286 x 364).
  static const double frameAspect = 0.786;

  /// Corner guide arm length, stroke and radius.
  static const double cornerArm = 34;
  static const double cornerStroke = 4;
  static const double cornerRadius = 10;

  /// Round top-bar controls (close, flash).
  static const double control = 44;

  /// Close / flash glyphs.
  static const double controlGlyph = 20;

  /// Mode toggle height and inner padding.
  static const double toggleHeight = 34;
  static const double togglePad = 3;

  /// Shutter outer diameter, ring stroke, inner disc.
  static const double shutter = 78;
  static const double shutterRing = 4;
  static const double shutterDisc = 62;

  /// Captured-page thumbnail and its count badge.
  static const double thumb = 56;
  static const double thumbRadius = 10;
  static const double thumbBorder = 2;
  static const double badge = 22;
  static const double badgeOffset = 8;

  /// Tilt of the stacked thumbnail behind the top one (radians, about -6 deg).
  static const double thumbTilt = -0.105;

  /// Minimum width of the Done pill.
  static const double doneMinWidth = 72;

  /// Blur of the reading card shadow and its vertical offset.
  static const double cardShadowBlur = 60;
  static const double cardShadowDy = 24;
}

abstract final class AuroraCameraShadows {
  static const List<BoxShadow> readingCard = [
    BoxShadow(
      color: AuroraCameraColors.cardShadow,
      blurRadius: AuroraCameraSizes.cardShadowBlur,
      offset: Offset(0, AuroraCameraSizes.cardShadowDy),
    ),
  ];
}

abstract final class AuroraUploadSizes {
  /// File card thumbnail.
  static const double fileThumbWidth = 60;
  static const double fileThumbHeight = 78;
  static const double fileThumbRadius = 6;

  /// Scan-sourced field marker: a cobalt rule on the left edge.
  static const double scanRule = 3;

  /// Add-file tiles (Scan / Photos / Files) minimum height and icon.
  static const double sourceTileHeight = 92;

  /// Tag chip minimum height.
  static const double tagHeight = 32;

  /// Minimum width of the tag text input.
  static const double tagInputMinWidth = 90;

  /// Icon tile in the add-from sheet and category rows.
  static const double sourceIconTile = 44;
  static const double categoryIconTile = 34;

  /// Category check circle.
  static const double categoryCheck = 24;

  /// Linked-item icon tile.
  static const double linkIconTile = 32;

  /// Upload progress bar height.
  static const double progressHeight = 3;

  /// Reading card progress bar and step dot.
  static const double readingBar = 6;
  static const double stepDot = 22;
  static const double stepSpinnerStroke = 2.5;
  static const double stepCheck = 11;

  /// Dashed outline: dash length and gap of the forward-email card.
  static const double dashLength = 5;
  static const double dashGap = 4;
}

/// Limits and rules that are product decisions, not layout.
abstract final class AuroraUploadRules {
  /// Largest file accepted ("UP TO 25 MB").
  static const int maxFileBytes = 25 * 1024 * 1024;

  /// Tags per document ("UP TO 8").
  static const int maxTags = 8;

  /// Longest single tag.
  static const int maxTagLength = 30;

  /// Longest document name and notes.
  static const int maxNameLength = 120;
  static const int maxNotesLength = 500;

  /// How far ahead an expiry date can be picked.
  static const int expiryYearsAhead = 50;

  /// "WE'LL REMIND YOU 30 DAYS BEFORE".
  static const int reminderLeadDays = 30;

  /// Extensions the file picker offers.
  static const List<String> fileExtensions = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'heic',
  ];

  /// Category names whose documents usually expire: "It expires" defaults on.
  static const Set<String> expiringCategories = {
    'insurance',
    'warranty',
    'permit',
    'contract',
    'inspection',
    'inspection report',
  };

  /// Head start on the percentage while a stage is still running.
  static const int readingInFlightPercent = 12;
}

abstract final class AuroraCameraDurations {
  /// Corner colour change when edges are found.
  static const Duration cornerFade = Duration(milliseconds: 200);
}
