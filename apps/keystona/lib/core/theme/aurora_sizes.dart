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

  /// Chip height (filter and quick-pick pills).
  static const double chipHeight = 36;

  /// Floating action button diameter.
  static const double fab = 56;

  /// Bottom-sheet action row minimum height.
  static const double actionRow = 56;

  /// Section header dot.
  static const double sectionDot = 6;

  /// Task-row check circle.
  static const double checkCircle = 24;

  /// Inset between switch track edge and knob.
  static const double switchInset = 2;

  /// Inline spinner inside buttons.
  static const double spinner = 18;

  /// Max width of the centered title in a sheet header, as a fraction of the
  /// header width.
  static const double sheetTitleFraction = 0.4;

  /// Sun spot diameter on the coral hero and its offset past the corner.
  static const double heroSun = 180;
  static const double heroSunOffset = 50;

  /// Max content width on tablets and landscape.
  static const double contentMaxWidth = 560;
}

/// Icon sizes (Tabler-style outline, stroke 1.8).
abstract final class AuroraIconSizes {
  static const double xs = 14;
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 22;
  static const double xl = 24;

  /// Outline stroke width (2 on plus signs and chevrons).
  static const double stroke = 1.8;
  static const double strokeBold = 2;
}

/// Border widths.
abstract final class AuroraBorders {
  static const double hairline = 0.5;
  static const double regular = 1;
  static const double emphasis = 1.5;

  /// Colored left rule on urgent cards and rows.
  static const double accentRule = 4;

  /// Tab indicator underline.
  static const double indicator = 2;

  /// Spinner stroke inside buttons.
  static const double spinnerStroke = 2;
}

/// Sizes for the shared core widgets (tab bar, snackbar, modal, empty/error
/// states, pills). Same rules as [AuroraSizes]: logical px at the 390 pt
/// reference width, read through `AuroraScale`, used as minimums.
abstract final class AuroraSharedSizes {
  /// Tab bar active indicator (coral bar on top of the active tab).
  static const double tabIndicatorWidth = 20;
  static const double tabIndicatorHeight = 3;

  /// Tab bar padding: top, and minimum bottom (home-indicator area).
  static const double tabPadTop = 8;
  static const double tabPadBottomMin = 22;

  /// Gap between tab icon and label.
  static const double tabIconLabelGap = 4;

  /// Outlined circle behind the icon on an empty state.
  static const double emptyIconCircle = 64;

  /// Outlined circle behind the icon on the error view.
  static const double errorIconCircle = 78;

  /// Outlined circle behind the icon on the confirm modal.
  static const double confirmIconCircle = 48;

  /// Glyph inside the confirm-modal circle.
  static const double confirmIconGlyph = 22;

  /// Glyph inside the empty-state circle.
  static const double emptyIconGlyph = 30;

  /// Glyph inside the error circle.
  static const double errorIconGlyph = 34;

  /// Max width of centred body copy on empty and error states.
  static const double bodyMaxWidth = 300;

  /// Minimum width of the snackbar Undo target.
  static const double snackbarActionMinWidth = 64;

  /// Check mark inside a status pill.
  static const double pillCheck = 10;

  /// Check stroke inside a status pill.
  static const double pillCheckStroke = 3.2;

  /// Height of the 1 px-ring icon tile used in cards (empty-state CTA card).
  static const double iconTile = 40;

  /// Amber rule under the offline banner.
  static const double offlineRule = 2;
}
