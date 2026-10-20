import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_motion.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_a.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../models/tasks_year_data.dart';
import '../../tasks_copy.dart';
import '../tasks_tab/task_row_tile.dart';
import '../tasks_tab/tasks_group_section.dart';
import '../tasks_tab/tasks_search_field.dart';
import 'year_back_header.dart';
import 'year_chart.dart';
import 'year_month_section.dart';

/// All tasks: overdue first, the year at a glance, then one month at a time.
/// Swipe left or right (or tap a bar) to change month.
class TasksYearContent extends StatelessWidget {
  const TasksYearContent({
    super.key,
    required this.data,
    required this.selected,
    required this.onSelect,
    required this.onQuery,
  });

  final TasksYearData data;
  final int selected;
  final ValueChanged<int> onSelect;
  final ValueChanged<String> onQuery;

  void _swipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -AuroraTasksA.swipeVelocity &&
        selected < data.months.length - 1) {
      onSelect(selected + 1);
    } else if (velocity > AuroraTasksA.swipeVelocity && selected > 0) {
      onSelect(selected - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.space8));
    final previous = selected > 0 ? data.months[selected - 1].month : null;
    final next = selected < data.months.length - 1
        ? data.months[selected + 1].month
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        YearBackHeader(eyebrow: TasksCopy.yearEyebrow(data.openCount)),
        gap,
        TasksSearchField(onChanged: onQuery),
        if (data.overdue.isNotEmpty) ...[
          gap,
          TasksGroupSection(
            overdue: true,
            title: TasksCopy.overdueCount(data.overdue.length),
            rows: [
              for (final task in data.overdue)
                TaskRowTile(key: ValueKey(task.id), task: task),
            ],
          ),
        ],
        gap,
        YearChart(data: data, selected: selected, onSelect: onSelect),
        gap,
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: _swipe,
          child: AnimatedSwitcher(
            duration: AuroraDurations.fast,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, ?current],
            ),
            child: YearMonthSection(
              key: ValueKey(data.months[selected].month),
              month: data.months[selected],
            ),
          ),
        ),
        SizedBox(height: a.of(AuroraSpacing.space4)),
        Text(
          TasksCopy.swipeHint(previous, next),
          textAlign: TextAlign.center,
          style: AuroraType.meta.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
