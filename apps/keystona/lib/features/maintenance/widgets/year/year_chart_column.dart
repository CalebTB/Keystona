import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_a.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../tasks_copy.dart';

/// One month of the year chart: its task count, a bar as tall as the count
/// (relative to the busiest month) and the month's letter.
class YearChartColumn extends StatelessWidget {
  const YearChartColumn({
    super.key,
    required this.month,
    required this.count,
    required this.fraction,
    required this.selected,
    required this.onTap,
  });

  final DateTime month;
  final int count;

  /// [count] as a share of the busiest month, 0 to 1.
  final double fraction;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final barHeight = a.of(
      (AuroraTasksA.barMaxHeight * fraction).clamp(
        AuroraTasksA.barMinHeight,
        AuroraTasksA.barMaxHeight,
      ),
    );
    return AuroraPressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: TasksCopy.monthChartLabel(month, count),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: a.of(AuroraTasksA.monthColumn)),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: AuroraTasksAType.chartCount(selected: selected),
              ),
              SizedBox(height: a.of(AuroraSpacing.space1)),
              Container(
                width: a.of(AuroraTasksA.barWidth),
                height: barHeight,
                decoration: BoxDecoration(
                  color: selected ? AuroraColors.ink : null,
                  borderRadius: BorderRadius.circular(
                    a.of(AuroraTasksA.barRadius),
                  ),
                  border: selected
                      ? null
                      : Border.all(
                          color: AuroraColors.inkCheckBorder,
                          width: AuroraBorders.emphasis,
                        ),
                ),
              ),
              SizedBox(height: a.of(AuroraSpacing.space1)),
              Text(
                TasksCopy.monthLetter(month),
                style: AuroraTasksAType.chartLabel(selected: selected),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
