import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_a.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../models/tasks_year_data.dart';
import '../../tasks_copy.dart';
import '../tasks_tab/task_list_card.dart';
import '../tasks_tab/task_row_tile.dart';

/// One month's heading ("October 2026", "6 TASKS · 2 NEED A PRO") and its
/// rows. A month with nothing due says so.
class YearMonthSection extends StatelessWidget {
  const YearMonthSection({super.key, required this.month});

  final TaskMonth month;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                TasksCopy.monthTitle(month.month),
                style: AuroraTasksAType.monthTitle,
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space3)),
            Flexible(
              child: Text(
                TasksCopy.monthMeta(month.count, month.pros),
                textAlign: TextAlign.end,
                style: AuroraType.meta,
              ),
            ),
          ],
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        if (month.occurrences.isEmpty)
          Container(
            padding: a.all(AuroraSpacing.space7),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: AuroraRadius.xl,
              border: Border.all(
                color: AuroraColors.inkBorder,
                width: AuroraBorders.regular,
              ),
            ),
            child: Text(
              TasksCopy.monthEmpty,
              style: AuroraType.body.copyWith(color: AuroraColors.inkSubtle),
            ),
          )
        else
          TaskListCard(
            children: [
              for (final o in month.occurrences)
                TaskRowTile(
                  key: ValueKey('${o.task.id}-${o.date.toIso8601String()}'),
                  task: o.task,
                  date: o.date,
                  projected: o.projected,
                ),
            ],
          ),
      ],
    );
  }
}
