import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../../../core/theme/aurora_typography.dart';

/// One tile: a big value over an uppercase caption.
class TaskStat {
  const TaskStat({
    required this.value,
    required this.caption,
    this.color = AuroraColors.ink,
  });

  final String value;
  final String caption;
  final Color color;
}

/// The row of totals at the top of History. Tiles share the row equally and
/// drop to two per row at large text sizes.
class TaskHistoryStats extends StatelessWidget {
  const TaskHistoryStats({super.key, required this.stats});

  final List<TaskStat> stats;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = a.of(AuroraSpacing.space3);
    final columns = a.textScale >= AuroraTasksB.stackTextScale
        ? 2
        : AuroraTasksB.statColumns;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final s in stats)
              SizedBox(
                width: width,
                child: _Tile(stat: s),
              ),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.stat});

  final TaskStat stat;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: a.all(AuroraSpacing.space5),
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
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AuroraTasksBType.statValue.copyWith(color: stat.color),
          ),
          SizedBox(height: a.of(AuroraSpacing.space1)),
          Text(stat.caption.toUpperCase(), style: AuroraType.meta),
        ],
      ),
    );
  }
}
