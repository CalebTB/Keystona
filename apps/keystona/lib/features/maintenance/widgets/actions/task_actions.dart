import 'package:flutter/widgets.dart';

import '../../../../core/widgets/snackbar_service.dart';
import '../../models/maintenance_task.dart';
import '../../models/quick_completion.dart';
import '../../models/task_schedule.dart';
import '../../models/task_undo.dart';
import '../../providers/maintenance_tasks_provider.dart';
import '../../tasks_copy.dart';

/// The one-step task actions (skip, stop reminding, change how often, push
/// back). Each changes the list at once, writes, and ends with an Undo
/// snackbar. If the write fails the task goes back and an error toast says so.
///
/// [toast] must be a context that outlives the row that started the action
/// (the root navigator's context): the row usually leaves the list when the
/// action completes.
abstract final class TaskActions {
  /// "Skip this time": a recurring task comes back at its next date.
  static Future<void> skip(
    BuildContext toast,
    MaintenanceTasksNotifier notifier,
    MaintenanceTask task, {
    String? reason,
  }) {
    return _run(
      toast,
      notifier,
      task,
      () => notifier.skipTask(task.id, reason: reason),
      (_) {
        final next = notifier.taskById(task.id);
        final recurring = next != null && TaskSchedule.isOpen(next);
        final title = recurring
            ? TasksCopy.skippedTitle(
                TasksCopy.comesBack(
                  next.dueDate,
                  TaskSchedule.dayOf(DateTime.now()),
                ),
              )
            : TasksCopy.skippedOneTime(task.name);
        return (title: title, subtitle: TasksCopy.skippedSub);
      },
    );
  }

  /// "Stop reminding me" / "Doesn't apply to my home". [reason] is kept with
  /// the turned-off reminder and shown on Turned-off reminders.
  static Future<void> stop(
    BuildContext toast,
    MaintenanceTasksNotifier notifier,
    MaintenanceTask task, {
    String? reason,
  }) {
    return _run(
      toast,
      notifier,
      task,
      () => notifier.stopReminders(task.id, reason: reason),
      (_) => (
        title: TasksCopy.stoppedTitle(task.name),
        subtitle: TasksCopy.stoppedSub,
      ),
    );
  }

  /// "Change how often".
  static Future<void> changeFrequency(
    BuildContext toast,
    MaintenanceTasksNotifier notifier,
    MaintenanceTask task,
    RecurrenceType recurrence,
  ) {
    return _run(
      toast,
      notifier,
      task,
      () => notifier.changeFrequency(task.id, recurrence),
      (_) {
        final next = TaskSchedule.nextDate(
          task,
          base: task.dueDate,
          recurrence: recurrence,
        );
        return (
          title: TasksCopy.frequencyTitle(
            task.name,
            TasksCopy.frequencyName(recurrence),
          ),
          subtitle: TasksCopy.frequencySub(
            TasksCopy.comesBack(next, TaskSchedule.dayOf(DateTime.now())),
          ),
        );
      },
    );
  }

  /// "I'll do it later": the task moves to [dueDate] and stays on the list.
  static Future<void> pushBack(
    BuildContext toast,
    MaintenanceTasksNotifier notifier,
    MaintenanceTask task,
    DateTime dueDate,
  ) {
    return _run(
      toast,
      notifier,
      task,
      () => notifier.pushBack(task.id, dueDate),
      (_) => (
        title: TasksCopy.pushedTitle(task.name),
        subtitle: TasksCopy.pushedSub(TasksCopy.laterDate(dueDate)),
      ),
    );
  }

  /// Writes a completion of [previous] (already marked done in the list),
  /// then says so with an Undo. Returns the undo, or null if the write failed.
  static Future<TaskUndo?> commitDone(
    BuildContext toast,
    MaintenanceTasksNotifier notifier,
    MaintenanceTask previous,
    QuickCompletion completion,
  ) async {
    try {
      final result = await notifier.commitDone(previous, completion);
      if (toast.mounted) {
        SnackbarService.showUndo(
          toast,
          message: TasksCopy.doneTitle(previous.name),
          subtitle: TasksCopy.doneSub,
          onUndo: () => undo(notifier, result),
        );
      }
      return result;
    } catch (_) {
      notifier.revertLocally(previous);
      if (toast.mounted) SnackbarService.showError(toast, TasksCopy.saveError);
      return null;
    }
  }

  /// Takes an action back, resyncing the list if the write fails.
  static Future<void> undo(
    MaintenanceTasksNotifier notifier,
    TaskUndo undo,
  ) async {
    try {
      await notifier.undo(undo);
    } catch (_) {
      await notifier.refresh();
    }
  }

  static Future<void> _run(
    BuildContext toast,
    MaintenanceTasksNotifier notifier,
    MaintenanceTask previous,
    Future<TaskUndo?> Function() action,
    ({String title, String subtitle}) Function(TaskUndo undo) message,
  ) async {
    try {
      final result = await action();
      if (result == null || !toast.mounted) return;
      final text = message(result);
      SnackbarService.showUndo(
        toast,
        message: text.title,
        subtitle: text.subtitle,
        onUndo: () => undo(notifier, result),
      );
    } catch (_) {
      notifier.revertLocally(previous);
      if (toast.mounted) SnackbarService.showError(toast, TasksCopy.saveError);
    }
  }
}
