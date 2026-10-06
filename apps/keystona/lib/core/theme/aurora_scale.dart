import 'package:flutter/widgets.dart';

import 'aurora_breakpoints.dart';
import 'aurora_sizes.dart';

/// Responsive layer for Aurora tokens.
///
/// Kit values are logical px at a 390 pt reference width. Widgets never use a
/// token directly for a size; they read it through `context.aurora`, which
/// shrinks it on compact screens and leaves it unchanged on regular screens.
/// On tablets the content is capped at [AuroraSizes.contentMaxWidth] instead of
/// scaling up.
class AuroraScale {
  const AuroraScale._(this.width, this.deviceClass, this.textScale);

  /// Reference width the kit was drawn at.
  static const double referenceWidth = 390;

  /// Smallest factor applied on compact screens (keeps 320 pt readable).
  static const double minFactor = 0.88;

  final double width;
  final AuroraDeviceClass deviceClass;
  final double textScale;

  factory AuroraScale.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AuroraScale._(
      size.width,
      AuroraBreakpoints.forWidth(size.width),
      MediaQuery.textScalerOf(context).scale(1),
    );
  }

  /// 1.0 on regular and tablet widths; between [minFactor] and 1.0 on compact.
  double get factor {
    if (deviceClass != AuroraDeviceClass.compact) return 1;
    return (width / referenceWidth).clamp(minFactor, 1.0);
  }

  /// Scales a spacing/radius/icon token.
  double of(double token) => token * factor;

  /// Minimum size for a control: scaled, never below the touch target, and
  /// grown with the text scale so large text never clips.
  double minControl(double token) {
    final scaled = token * factor * (textScale > 1 ? textScale : 1);
    return scaled < AuroraSizes.minTouch ? AuroraSizes.minTouch : scaled;
  }

  EdgeInsets all(double token) => EdgeInsets.all(of(token));

  EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) =>
      EdgeInsets.symmetric(horizontal: of(horizontal), vertical: of(vertical));

  /// Max width for page content (centered on wide screens).
  double get contentMaxWidth => AuroraSizes.contentMaxWidth;

  bool get isTablet => deviceClass == AuroraDeviceClass.tablet;
}

extension AuroraScaleContext on BuildContext {
  AuroraScale get aurora => AuroraScale.fromContext(this);
}
