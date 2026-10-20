import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../models/tasks_tab_data.dart';
import '../../tasks_copy.dart';
import 'task_row_tile.dart';
import 'tasks_done_this_week_row.dart';
import 'tasks_group_section.dart';
import 'tasks_see_all_button.dart';

/// The grouped list under the overdue card: this month's tasks by date (or by
/// area), "See all N tasks", and the quiet "done this week" row.
class TasksUpcomingSection extends StatelessWidget {
  const TasksUpcomingSection({
    super.key,
    required this.data,
    required this.grouping,
    required this.onGrouping,
    required this.onSeeAll,
  });

  final TasksTabData data;
  final TaskGrouping grouping;
  final VoidCallback onGrouping;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final byDate = grouping == TaskGrouping.date;
    final gap = SizedBox(height: a.of(AuroraSpacing.space7));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < data.groups.length; i++) ...[
          if (i > 0) gap,
          TasksGroupSection(
            title: data.groups[i].title,
            groupingLabel: byDate ? TasksCopy.byDate : TasksCopy.byArea,
            onGrouping: i == 0 ? onGrouping : null,
            rows: [
              for (final task in data.groups[i].tasks)
                TaskRowTile(
                  key: ValueKey(task.id),
                  task: task,
                  showToday: !byDate,
                ),
            ],
          ),
        ],
        if (data.groups.isNotEmpty) gap,
        TasksSeeAllButton(
          label: TasksCopy.seeAll(data.openCount),
          onTap: onSeeAll,
        ),
        if (data.weekDone > 0) ...[
          SizedBox(height: a.of(AuroraSpacing.space5)),
          TasksDoneThisWeekRow(
            label: TasksCopy.doneThisWeek(data.weekDone),
            onTap: onSeeAll,
          ),
        ],
      ],
    );
  }
}
