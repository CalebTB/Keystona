// Home profile Sprint 3, Track B tokens: Systems list, Scan, Add system,
// System detail and the "Log a repair or service" sheet. Kit px values are
// logical px at the 390 pt reference width and are read through
// `context.aurora` by the widgets.
import 'package:flutter/painting.dart';

abstract final class AuroraHomeBColors {
  /// The camera backdrop: a dark radial gradient, centre to edge.
  static const Color cameraCentre = Color(0xFF3A3F4A);
  static const Color cameraEdge = Color(0xFF15181F);

  /// Dim chips drawn over the camera (back button, segmented control, hint).
  static const Color cameraChip = Color(0x59000000);

  /// The faint outline of the label guide inside the frame. (white 0.18)
  static const Color cameraGuide = Color(0x2EFFFFFF);

  /// Secondary text on the camera. (white 0.8)
  static const Color cameraTextSoft = Color(0xCCFFFFFF);
}

abstract final class AuroraHomeBSizes {
  /// Lifespan slider track thickness and thumb radius.
  static const double sliderTrack = 6;
  static const double sliderThumbRadius = 11;

  /// Smallest and largest expected lifespan on the slider, in years. The kit
  /// stops at 40 but its own plumbing and foundation defaults are 50.
  static const double sliderMin = 1;
  static const double sliderMax = 60;

  /// Photo slots drawn in a row on the form.
  static const int photoColumns = 4;

  /// Scan banner check disc and its glyph.
  static const double bannerCheck = 26;
  static const double bannerCheckGlyph = 14;

  /// Warranty card shield disc and glyph.
  static const double warrantyDisc = 40;
  static const double warrantyGlyph = 20;

  /// Scan choose-card icon tile and glyph.
  static const double chooseTile = 48;
  static const double chooseTileGlyph = 24;

  /// Viewfinder frame: width as a fraction of the screen, width / height.
  static const double frameWidthFraction = 0.82;
  static const double frameAspect = 1.5;

  /// Viewfinder corner bracket arm length, stroke and corner radius.
  static const double bracketArm = 30;
  static const double bracketStroke = 4;
  static const double bracketRadius = 14;

  /// Least height of the stage the frame sits in, so it never collapses.
  static const double frameMinStage = 220;

  /// Corner radius of the faint guide inside the frame.
  static const double guideRadius = 6;

  /// Shutter ring diameter and the inner disc.
  static const double shutterOuter = 72;
  static const double shutterInner = 56;
  static const double shutterRing = 3;

  /// Photo thumbnail corner radius uses the md radius; the add slot glyph:
  static const double photoAddGlyph = 20;

  /// Tallest the camera hint text may grow before it wraps, in lines.
  static const int hintMaxLines = 2;

  /// Suggestion chips shown under the systems list.
  static const int maxSuggestions = 6;

  /// Tasks shown under "Next up" on the detail screen.
  static const int nextUpShown = 2;

  /// Earliest year offered for an install date.
  static const int firstInstallYear = 1950;

  /// A warranty ending within this many days shows the "add a check" card.
  static const int warrantyCheckWindowDays = 90;

  /// A warranty ending within this many days shows "WARRANTY ENDS" on a list
  /// row (when there is no lifespan status to show).
  static const int warrantyNoteWindowDays = 180;

  /// The warranty check task is due this many days before the warranty ends.
  static const int warrantyCheckLeadDays = 14;

  /// [warrantyCheckLeadDays] as a duration.
  static const Duration warrantyCheckLead = Duration(days: warrantyCheckLeadDays);

  /// Years before replacement that the detail screen starts planning.
  static const int planAheadYears = 3;

  /// Skeleton block heights (kit px): the filter row, one list row, the detail
  /// hero, a card, a form field.
  static const double skeletonFilter = 36;
  static const double skeletonRow = 92;
  static const double skeletonHero = 220;
  static const double skeletonCard = 140;
  static const double skeletonField = 50;
  static const int skeletonRows = 4;

  /// Cap on free-text lengths (validation, client side).
  static const int nameMaxLength = 80;
  static const int noteMaxLength = 500;
  static const int fieldMaxLength = 120;
}
