/// Aurora design kit — fixed component sizes, in logical px at the 390 pt
/// reference width. Widgets must read these through the responsive layer
/// (`AuroraScale`) and use them as minimums, never as fixed heights.
abstract final class AuroraSizes {
  /// Minimum touch target (iOS 44 pt).
  static const double minTouch = 44;

  /// Primary pill button height.
  static const double buttonHeight = 46;

  /// Large primary button (paywall, upgrade).
  static const double buttonHeightLg = 54;

  /// Compact pill (sheet Save).
  static const double buttonHeightSm = 36;

  /// Text input height.
  static const double inputHeight = 50;

  /// Tab bar content height including bottom inset padding.
  static const double tabBarHeight = 84;

  /// Switch track and knob.
  static const double switchWidth = 51;
  static const double switchHeight = 31;
  static const double switchKnob = 27;

  /// Bottom sheet grabber.
  static const double grabberWidth = 36;
  static const double grabberHeight = 4;

  /// Icon tile (rounded square behind a category icon).
  static const double iconTile = 30;

  /// Quick-action circle on Home.
  static const double quickAction = 56;

  /// Health-score ring diameter on the hero.
  static const double scoreRing = 72;

  /// Max content width on tablets and landscape.
  static const double contentMaxWidth = 560;
}

/// Icon sizes (Tabler-style outline, stroke 1.8).
abstract final class AuroraIconSizes {
  static const double xs = 14;
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 22;

  /// Outline stroke width (2 on plus signs and chevrons).
  static const double stroke = 1.8;
  static const double strokeBold = 2;
}

/// Border widths.
abstract final class AuroraBorders {
  static const double hairline = 0.5;
  static const double regular = 1;
  static const double emphasis = 1.5;
}
