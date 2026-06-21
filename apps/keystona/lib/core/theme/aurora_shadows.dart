import 'package:flutter/material.dart';

/// Aurora Design System v2.0 — shadow tokens.
///
/// Aurora is a flat system. Default to [none] unless lift adds information.
/// [card] is opt-in. [fab] and [hero] are specific to their components.
abstract final class AuroraShadows {
  /// No shadow — default for all surfaces.
  static const List<BoxShadow> none = <BoxShadow>[];

  /// Subtle card lift — opt-in only.
  static const List<BoxShadow> card = <BoxShadow>[
    BoxShadow(
      color: Color(0x0A071238), // ink at 4%
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  /// Coral hero lift — rarely used.
  static const List<BoxShadow> hero = <BoxShadow>[
    BoxShadow(
      color: Color(0x26FF3B62), // coral at 15%
      offset: Offset(0, 4),
      blurRadius: 20,
    ),
  ];

  /// FAB elevation — coral glow.
  static const List<BoxShadow> fab = <BoxShadow>[
    BoxShadow(
      color: Color(0x59FF3B62), // coral at 35%
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];
}
