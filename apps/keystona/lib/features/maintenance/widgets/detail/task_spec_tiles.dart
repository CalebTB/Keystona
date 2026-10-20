import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../../../core/theme/aurora_tasks_wire.dart';
import '../../../../core/theme/aurora_typography.dart';

/// One tile: an uppercase label over a value.
class TaskSpec {
  const TaskSpec(this.label, this.value);

  final String label;
  final String value;
}

/// A row of small facts (Time, Level, Who, Cost). Tiles share the row equally
/// and drop to two per row at large text sizes instead of squeezing.
class TaskSpecTiles extends StatelessWidget {
  const TaskSpecTiles({super.key, required this.specs});

  final List<TaskSpec> specs;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = a.of(AuroraSpacing.space2);
    final perRow = a.textScale >= AuroraTasksB.stackTextScale
        ? 2
        : AuroraTasksWire.specColumns;
    // Fewer tiles than columns (no estimate yet) still fill the row.
    final columns = specs.length < perRow ? specs.length : perRow;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final s in specs)
              SizedBox(
                width: width,
                child: _Tile(spec: s),
              ),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.spec});

  final TaskSpec spec;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: a.symmetric(
        horizontal: AuroraSpacing.space4,
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
            spec.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AuroraType.label,
          ),
          SizedBox(height: a.of(AuroraSpacing.space1)),
          Text(
            spec.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AuroraTasksBType.tileValue,
          ),
        ],
      ),
    );
  }
}
