import 'package:flutter/material.dart';

/// Aurora Design System v2.0 — border radius constants.
///
/// All const — use these instead of BorderRadius.circular().
/// Min card radius: 14px. Hero: 22px. Both are intentionally larger than v1.
///
/// Component radii are specified in Keystona_Aurora_Design_System.md §6.x, which is
/// authoritative over §4.1's "where used" column. Notably input fields are `md` (12px)
/// per §6.8, even though §4.1 lists them under `sm`.
abstract final class AuroraRadius {
  /// 4px — status chips, micro-tags.
  static const BorderRadius xs = BorderRadius.all(Radius.circular(4));

  /// 8px — task category icon tiles, input fields.
  static const BorderRadius sm = BorderRadius.all(Radius.circular(8));

  /// 12px — buttons, small surfaces.
  static const BorderRadius md = BorderRadius.all(Radius.circular(12));

  /// 14px — tiles, task rows, list cards.
  static const BorderRadius lg = BorderRadius.all(Radius.circular(14));

  /// 16px — standard cards.
  static const BorderRadius xl = BorderRadius.all(Radius.circular(16));

  /// 22px — hero cards, premium surfaces.
  static const BorderRadius xxl = BorderRadius.all(Radius.circular(22));

  /// 999px — pills, filter chips, FABs, avatars.
  static const BorderRadius full = BorderRadius.all(Radius.circular(999));
}
