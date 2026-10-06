import 'package:flutter/material.dart';

import 'aurora_colors.dart';

/// Aurora Design System v2.0 — shadow tokens.
///
/// Aurora is a flat system. Default to [none] unless lift adds information.
/// [card] is opt-in. [fab] and [hero] are specific to their components.
abstract final class AuroraShadows {
  /// No shadow — default for all surfaces.
  static const List<BoxShadow> none = <BoxShadow>[];

  /// Subtle card lift — opt-in only.
  static List<BoxShadow> get card => <BoxShadow>[
    BoxShadow(
      color: AuroraColors.ink.withValues(alpha: 0.04),
      offset: const Offset(0, 1),
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

  /// Floating action button lift (ink, no brand glow).
  static const List<BoxShadow> fabAction = <BoxShadow>[
    BoxShadow(color: Color(0x40071238), offset: Offset(0, 4), blurRadius: 12),
  ];

  /// Switch knob.
  static const List<BoxShadow> knob = <BoxShadow>[
    BoxShadow(color: Color(0x40071238), offset: Offset(0, 2), blurRadius: 4),
  ];

  /// Snackbar lift.
  static const List<BoxShadow> snackbar = <BoxShadow>[
    BoxShadow(color: Color(0x4D071238), offset: Offset(0, 12), blurRadius: 30),
  ];

  /// Centered confirm modal lift.
  static const List<BoxShadow> modal = <BoxShadow>[
    BoxShadow(color: Color(0x59071238), offset: Offset(0, 24), blurRadius: 60),
  ];
}
