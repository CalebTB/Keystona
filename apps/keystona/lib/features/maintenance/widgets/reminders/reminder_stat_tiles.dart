import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_c.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../reminders_copy.dart';

/// The three counts at the top of Around the house: on, turned off, yours.
class ReminderStatTiles extends StatelessWidget {
  const ReminderStatTiles({
    super.key,
    required this.on,
    required this.off,
    required this.yours,
  });

  final int on;
  final int off;
  final int yours;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(width: a.of(AuroraSpacing.space3));
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Tile(count: on, label: RemindersCopy.statOn),
          ),
          gap,
          Expanded(
            child: _Tile(count: off, label: RemindersCopy.statOff, dim: true),
          ),
          gap,
          Expanded(
            child: _Tile(count: yours, label: RemindersCopy.statYours),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.count, required this.label, this.dim = false});

  final int count;
  final String label;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: a.symmetric(
        horizontal: AuroraSpacing.space6,
        vertical: AuroraSpacing.space5,
      ),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.lg,
        border: Border.all(
          color: AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: AuroraTasksCType.statNumber.copyWith(
              color: dim ? AuroraColors.inkHelper : AuroraColors.ink,
            ),
          ),
          SizedBox(height: a.of(AuroraSpacing.space1)),
          Text(label.toUpperCase(), style: AuroraType.meta),
        ],
      ),
    );
  }
}
