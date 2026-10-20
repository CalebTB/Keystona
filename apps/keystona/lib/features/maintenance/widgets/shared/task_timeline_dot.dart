import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_sizes.dart';

/// Filled or ringed circle on a timeline. Fills the size its parent gives it.
class TaskTimelineDot extends StatelessWidget {
  const TaskTimelineDot({
    super.key,
    this.fill = AuroraColors.paper,
    this.ring,
    this.ringWidth = AuroraBorders.emphasis,
  });

  final Color fill;

  /// Ring color; null draws no ring.
  final Color? ring;
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: ring == null
            ? null
            : Border.all(color: ring!, width: ringWidth),
      ),
    );
  }
}
