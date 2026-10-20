import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../models/maintenance_task.dart';
import '../../models/task_schedule.dart';
import '../../providers/tasks_today_provider.dart';
import '../../tasks_copy.dart';
import '../actions/task_menu.dart';
import '../actions/task_quick_done.dart';
import 'task_row_item.dart';

/// A [MaintenanceTask] as a row, wired the way every task row behaves: tap
/// opens the task, the circle marks it done, long-press opens the menu.
///
/// A [projected] occurrence is a future repeat that is not scheduled yet; its
/// circle opens the task instead of marking anything done.
class TaskRowTile extends ConsumerWidget {
  const TaskRowTile({
    super.key,
    required this.task,
    this.date,
    this.showToday = true,
    this.projected = false,
  });

  final MaintenanceTask task;

  /// The date to show; defaults to the task's due date.
  final DateTime? date;

  /// Whether a task due today says "TODAY" (the Tasks tab groups them under a
  /// TODAY heading instead).
  final bool showToday;

  final bool projected;

  void _open(BuildContext context) => context.push(
    AppRoutes.maintenanceTaskDetail.replaceFirst(':taskId', task.id),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(tasksTodayProvider);
    final late = TaskSchedule.isOverdue(task, today);
    final shown = TaskSchedule.dayOf(date ?? task.dueDate);
    final isToday = shown == today;
    return TaskRowItem(
      name: task.name,
      meta: TasksCopy.meta(task),
      late: late,
      chip: late
          ? TasksCopy.daysLate(TaskSchedule.daysLate(task, today))
          : task.diyOrPro == DiyOrPro.professional
          ? TasksCopy.pro
          : null,
      date: late
          ? null
          : isToday && !showToday
          ? null
          : isToday
          ? TasksCopy.todayLabel
          : TasksCopy.dateLabel(shown),
      checkLabel: TasksCopy.markDoneSemantics(task.name),
      onToggle: projected
          ? () => _open(context)
          : () => TaskQuickDone.run(context, ref, task),
      onTap: () => _open(context),
      onLongPress: () => TaskMenu.show(context, ref, task),
    );
  }
}
