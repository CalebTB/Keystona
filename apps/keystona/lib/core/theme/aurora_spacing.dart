import 'package:flutter/material.dart';

/// Aurora Design System v2.0 — spacing constants (4px grid).
abstract final class AuroraSpacing {
  /// 4px — icon-to-text gaps inside chips.
  static const double space1 = 4;

  /// 6px — tight inline gaps, chip-to-chip.
  static const double space2 = 6;

  /// 8px — standard inline gaps.
  static const double space3 = 8;

  /// 10px — card padding (compact).
  static const double space4 = 10;

  /// 12px — section gaps, card padding (standard).
  static const double space5 = 12;

  /// 14px — card padding (comfortable).
  static const double space6 = 14;

  /// 16px — section bottom margins, screen horizontal padding.
  static const double space7 = 16;

  /// 20px — large section gaps.
  static const double space8 = 20;

  /// 24px — hero-to-content gaps, screen bottom padding.
  static const double space9 = 24;

  /// 32px — screen-level breathing room.
  static const double space10 = 32;

  /// 16px — screen horizontal edge padding.
  static const double screenPadH = 16;

  /// 12px — screen top padding.
  static const double screenPadTop = 12;

  /// 24px — screen bottom padding (above tab bar).
  static const double screenPadBottom = 24;
}

/// Pre-built EdgeInsets helpers referencing [AuroraSpacing].
abstract final class AuroraPadding {
  /// Horizontal screen edge padding (16px left/right).
  static const EdgeInsets screenH = EdgeInsets.symmetric(
    horizontal: AuroraSpacing.screenPadH,
  );

  /// Standard card internal padding (14px all sides).
  static const EdgeInsets card = EdgeInsets.all(AuroraSpacing.space6);

  /// Compact card padding (10px all sides).
  static const EdgeInsets cardCompact = EdgeInsets.all(AuroraSpacing.space4);

  /// Primary button padding.
  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 12,
  );

  /// Secondary button padding (1px reduced for border).
  static const EdgeInsets buttonSecondary = EdgeInsets.symmetric(
    horizontal: 17,
    vertical: 11.5,
  );
}
