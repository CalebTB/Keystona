import 'package:flutter/widgets.dart';

/// Aurora Design System v2.0 — responsive device classes.
///
/// The design docs specify sheet heights as a percentage of screen height
/// (`Keystona_Aurora_Component_Library.md` §3.3) but never defined device
/// classes. These are the project's breakpoints; add new responsive tokens
/// here rather than reaching for raw `MediaQuery` width checks in features.
enum AuroraDeviceClass {
  /// < 390pt — iPhone SE / 13 mini. Tighter radii, slightly taller sheets.
  compact,

  /// 390–599pt — the primary target. Spec values apply verbatim here.
  regular,

  /// >= 600pt — iPad and large foldables. Sheets are width-constrained.
  tablet,
}

abstract final class AuroraBreakpoints {
  /// Upper bound (inclusive) of [AuroraDeviceClass.compact].
  static const double compactMax = 389;

  /// Upper bound (inclusive) of [AuroraDeviceClass.regular].
  static const double regularMax = 599;

  /// Max sheet width on [AuroraDeviceClass.tablet] — sheets centre rather
  /// than stretching the full iPad width.
  static const double tabletSheetMaxWidth = 560;

  static AuroraDeviceClass of(BuildContext context) =>
      forWidth(MediaQuery.sizeOf(context).width);

  static AuroraDeviceClass forWidth(double width) {
    if (width <= compactMax) return AuroraDeviceClass.compact;
    if (width <= regularMax) return AuroraDeviceClass.regular;
    return AuroraDeviceClass.tablet;
  }

  static bool isTablet(BuildContext context) =>
      of(context) == AuroraDeviceClass.tablet;
}
