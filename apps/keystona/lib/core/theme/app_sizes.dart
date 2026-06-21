import 'package:flutter/material.dart';

import 'aurora_radius.dart';
import 'aurora_spacing.dart';

/// Spacing, sizing, and layout constants — bridge to Aurora v2.0.
///
/// Updated to Aurora radii (larger) and screen padding (16px, down from 22px).
/// Callers switch to AuroraSpacing/AuroraRadius during screen migration;
/// this file is deleted once all feature screens are updated.
abstract final class AppSizes {
  // ─── Spacing ────────────────────────────────────────────────────────────────

  /// 4px
  static const double xs = AuroraSpacing.space1;

  /// 8px
  static const double sm = AuroraSpacing.space3;

  /// 16px
  static const double md = AuroraSpacing.space7;

  /// 24px
  static const double lg = AuroraSpacing.space9;

  /// 32px
  static const double xl = AuroraSpacing.space10;

  /// 48px
  static const double xxl = 48;

  // ─── Border Radii ───────────────────────────────────────────────────────────

  /// 4px — status chips, micro-tags.
  static const double radiusXs = 4;

  /// 8px — icon tiles, input fields.
  static const double radiusSm = 8;

  /// 12px — buttons, small surfaces.
  static const double radiusMd = 12;

  /// 14px — tiles, task rows, list cards.
  static const double radiusCard = 14;

  /// 16px — standard cards.
  static const double radiusLg = 16;

  /// 22px — hero cards, premium surfaces.
  static const double radiusXl = 22;

  /// 999px — pills, FABs, avatars.
  static const double radiusFull = 999;

  // ─── Standard Paddings ──────────────────────────────────────────────────────

  /// Horizontal screen edge padding — 16px.
  static const double screenPadding = AuroraSpacing.screenPadH;

  /// Internal card content padding — 14px.
  static const double cardPadding = AuroraSpacing.space6;

  /// Vertical space between major page sections — 20px.
  static const double sectionSpacing = AuroraSpacing.space8;

  /// Gap between cards in a list — 6px.
  static const double cardGap = AuroraSpacing.space2;

  // ─── Icon Sizes ─────────────────────────────────────────────────────────────

  static const double iconSm = 16;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double iconXl = 48;

  // ─── Component Heights ──────────────────────────────────────────────────────

  static const double buttonHeight = 48;
  static const double inputHeight = 50;
  static const double bottomNavHeight = 64;
  static const double appBarHeight = 56;
  static const double cardMinHeight = 72;
}

/// Pre-built [BorderRadius] helpers — all const via [AuroraRadius].
abstract final class AppRadius {
  /// 8px — icon tiles, input fields.
  static const BorderRadius sm = AuroraRadius.sm;

  /// 12px — buttons, inputs.
  static const BorderRadius md = AuroraRadius.md;

  /// 14px — tiles, task rows (primary card radius).
  static const BorderRadius card = AuroraRadius.lg;

  /// 16px — standard cards.
  static const BorderRadius lg = AuroraRadius.xl;

  /// 22px — hero cards, bottom sheet corners.
  static const BorderRadius xl = AuroraRadius.xxl;
}

/// Pre-built [EdgeInsets] helpers.
abstract final class AppPadding {
  /// All-sides screen padding (16px).
  static const EdgeInsets screen = EdgeInsets.all(AuroraSpacing.screenPadH);

  /// Horizontal-only screen padding (16px left/right).
  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(
    horizontal: AuroraSpacing.screenPadH,
  );

  /// All-sides card internal padding (14px).
  static const EdgeInsets card = EdgeInsets.all(AuroraSpacing.space6);

  /// Button content padding.
  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 12,
  );
}
