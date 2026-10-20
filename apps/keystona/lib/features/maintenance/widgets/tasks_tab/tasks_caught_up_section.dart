import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../models/tasks_tab_data.dart';
import '../../tasks_copy.dart';
import 'task_list_card.dart';
import 'task_row_tile.dart';
import 'tasks_caught_up_hero.dart';
import 'tasks_done_this_week_row.dart';
import 'tasks_see_upcoming_link.dart';

/// TasksCaughtUp: the celebration, the next three tasks, "See all upcoming"
/// and the done-this-week row. Used when nothing is overdue or due today.
class TasksCaughtUpSection extends StatelessWidget {
  const TasksCaughtUpSection({
    super.key,
    required this.data,
    required this.onSeeAll,
  });

  final TasksTabData data;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TasksCaughtUpHero(),
        if (data.nextUp.isNotEmpty) ...[
          SizedBox(height: a.of(AuroraSpacing.space8)),
          Text(TasksCopy.nextUp, style: AuroraType.label),
          SizedBox(height: a.of(AuroraSpacing.space3)),
          TaskListCard(
            children: [
              for (final task in data.nextUp)
                TaskRowTile(key: ValueKey(task.id), task: task),
            ],
          ),
          TasksSeeUpcomingLink(onTap: onSeeAll),
        ],
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
