// The toast context is the root navigator's, captured before any await: it
// outlives the row that started the action, and every use checks `mounted`.
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/aurora/aurora_sheet.dart';
import '../../models/maintenance_task.dart';
import '../../models/quick_completion.dart';
import '../../models/skip_plan.dart';
import '../../providers/maintenance_tasks_provider.dart';
import '../../providers/tasks_today_provider.dart';
import '../../tasks_copy.dart';
import 'skip/skip_sheet_body.dart';
import 'task_actions.dart';

/// The kit's "Not now?" sheet (TaskSkip): push it back, log that someone else
/// did it, stop the reminder, or just skip this one. Each ends with an Undo
/// snackbar.
abstract final class TaskSkipSheet {
  /// Shows the sheet for [task] and carries out the user's choice through
  /// `maintenanceTasksProvider`. Returns true if the task was acted on, false
  /// when the sheet was cancelled.
  static Future<bool> show(
    BuildContext context,
    WidgetRef ref,
    MaintenanceTask task,
  ) async {
    final notifier = ref.read(maintenanceTasksProvider.notifier);
    final today = ref.read(tasksTodayProvider);
    // The row that opened the sheet may leave the list; toasts need a context
    // that stays.
    final toast = Navigator.of(context, rootNavigator: true).context;

    final plan = await AuroraSheet.show<SkipPlan>(
      context,
      title: TasksCopy.skipTitle,
      height: AuroraSheetHeight.extra,
      child: SkipSheetBody(task: task, today: today),
    );
    if (plan == null) return false;
    await _perform(toast, notifier, task, plan, today);
    return true;
  }

  static Future<void> _perform(
    BuildContext toast,
    MaintenanceTasksNotifier notifier,
    MaintenanceTask task,
    SkipPlan plan,
    DateTime today,
  ) async {
    switch (plan.reason) {
      case SkipReason.later:
        await TaskActions.pushBack(
          toast,
          notifier,
          task,
          plan.pushedTo(task, today),
        );
      case SkipReason.other:
        final previous = notifier.markDoneLocally(task.id, on: today);
        if (previous == null) return;
        await TaskActions.commitDone(
          toast,
          notifier,
          previous,
          QuickCompletion(completedOn: today, byPro: plan.byPro),
        );
      case SkipReason.notApplicable:
        await TaskActions.stop(
          toast,
          notifier,
          task,
          reason: TasksCopy.reasonNotApplicable,
        );
      case SkipReason.skip:
        await TaskActions.skip(
          toast,
          notifier,
          task,
          reason: TasksCopy.reasonSkip,
        );
    }
  }
}
