// The toast context is the root navigator's, captured before any await: it
// outlives the row that started the action, and every use checks `mounted`.
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../models/maintenance_task.dart';
import '../../models/quick_completion.dart';
import '../../models/quick_done_result.dart';
import '../../models/task_schedule.dart';
import '../../providers/just_done_provider.dart';
import '../../providers/maintenance_tasks_provider.dart';
import '../../providers/tasks_today_provider.dart';
import 'done/quick_done_sheet.dart';
import 'task_actions.dart';

/// Quick mark-done (TaskDoneQuick).
///
/// The task is marked done in the list at once, then the "Nice — it's done"
/// sheet opens so the user can say when, who and how much. Nothing is written
/// until the sheet closes: Undo cancels with no write at all, Save or
/// dismissing records the completion and schedules the next occurrence, and a
/// 5 second Undo snackbar can still take it back.
abstract final class TaskQuickDone {
  /// Marks [task] done and shows the sheet.
  static Future<void> run(
    BuildContext context,
    WidgetRef ref,
    MaintenanceTask task,
  ) async {
    // Everything needed after the awaits is captured here: the row that was
    // tapped usually leaves the list as soon as the task is done.
    final notifier = ref.read(maintenanceTasksProvider.notifier);
    final justDone = ref.read(justDoneProvider.notifier);
    final today = ref.read(tasksTodayProvider);
    final router = GoRouter.maybeOf(context);
    final toast = Navigator.of(context, rootNavigator: true).context;
    final wasOverdue = TaskSchedule.isOverdue(task, today);

    final previous = notifier.markDoneLocally(task.id, on: today);
    if (previous == null) return;

    final result = await QuickDoneSheet.show(
      context,
      task: previous,
      today: today,
    );

    switch (result?.outcome) {
      case QuickDoneOutcome.undo:
        notifier.revertLocally(previous);
      case QuickDoneOutcome.addMore:
        notifier.revertLocally(previous);
        router?.push(
          AppRoutes.maintenanceCompleteTask.replaceFirst(':taskId', task.id),
        );
      case QuickDoneOutcome.save || null:
        final undo = await TaskActions.commitDone(
          toast,
          notifier,
          previous,
          result?.completion ?? QuickCompletion(completedOn: today),
        );
        if (undo != null && wasOverdue) justDone.set(undo);
    }
  }
}
