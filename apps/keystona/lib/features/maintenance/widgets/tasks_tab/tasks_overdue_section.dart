import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../models/maintenance_task.dart';
import '../../models/task_schedule.dart';
import '../../providers/maintenance_tasks_provider.dart';
import '../../providers/tasks_today_provider.dart';
import '../../tasks_copy.dart';
import '../actions/task_actions.dart';
import '../actions/task_menu.dart';
import '../actions/task_quick_done.dart';
import '../actions/task_skip_sheet.dart';
import 'task_overdue_card.dart';
import 'task_row_tile.dart';
import 'tasks_group_section.dart';

/// Everything overdue: the most overdue task large with its actions, then any
/// others in a coral-outlined list.
class TasksOverdueSection extends ConsumerWidget {
  const TasksOverdueSection({
    super.key,
    required this.hero,
    required this.others,
  });

  final MaintenanceTask hero;
  final List<MaintenanceTask> others;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aurora;
    final today = ref.watch(tasksTodayProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TaskOverdueCard(
          name: hero.name,
          description: hero.description,
          daysLate: TaskSchedule.daysLate(hero, today),
          meta: TasksCopy.meta(hero, withWho: true),
          onMarkDone: () => TaskQuickDone.run(context, ref, hero),
          onSnooze: () => TaskSkipSheet.show(context, ref, hero),
          onLongPress: () => TaskMenu.show(context, ref, hero),
          onDoesntApply: () => TaskActions.stop(
            Navigator.of(context, rootNavigator: true).context,
            ref.read(maintenanceTasksProvider.notifier),
            hero,
            reason: TasksCopy.reasonNotApplicable,
          ),
        ),
        if (others.isNotEmpty) ...[
          SizedBox(height: a.of(AuroraSpacing.space8)),
          TasksGroupSection(
            overdue: true,
            title: TasksCopy.overdueCount(others.length),
            rows: [
              for (final task in others)
                TaskRowTile(key: ValueKey(task.id), task: task),
            ],
          ),
        ],
      ],
    );
  }
}
