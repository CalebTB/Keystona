import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_button.dart';
import '../../../../core/widgets/aurora/aurora_task_row.dart';
import '../../../maintenance/models/maintenance_task.dart';
import '../../../maintenance/models/task_schedule.dart';
import '../../../maintenance/tasks_copy.dart';
import '../../../maintenance/widgets/actions/task_menu.dart';
import '../../../maintenance/widgets/actions/task_quick_done.dart';
import '../../appliance_copy.dart';

/// The appliance's next tasks as check-circle rows, then the "All 4 appliance
/// tasks" pill. A tap opens the task, the circle marks it done, a long press
/// opens the task menu.
class ApplianceNextUp extends ConsumerWidget {
  const ApplianceNextUp({
    super.key,
    required this.shown,
    required this.total,
    required this.today,
    required this.onAll,
    required this.onAdd,
  });

  /// The tasks to draw, soonest first.
  final List<MaintenanceTask> shown;

  /// How many open tasks there are in all.
  final int total;
  final DateTime today;
  final VoidCallback onAll;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final task in shown) ...[
          AuroraTaskRow(
            key: ValueKey(task.id),
            name: task.name,
            dueLabel: TasksCopy.dateLabel(task.dueDate),
            metaLine: TasksCopy.meta(task, withWho: true),
            dueToday: TaskSchedule.isSoon(task, today),
            overdue: TaskSchedule.isOverdue(task, today),
            onTap: () => context.push(
              AppRoutes.maintenanceTaskDetail.replaceFirst(':taskId', task.id),
            ),
            onToggle: () => TaskQuickDone.run(context, ref, task),
            onLongPress: () => TaskMenu.show(context, ref, task),
          ),
          SizedBox(height: a.of(AuroraSpacing.space3)),
        ],
        if (total > 0)
          SecondaryButton(
            label: ApplianceCopy.allTasks(total),
            onPressed: onAll,
            expand: true,
          )
        else
          SecondaryButton(
            label: ApplianceCopy.addTask,
            onPressed: onAdd,
            expand: true,
          ),
      ],
    );
  }
}
