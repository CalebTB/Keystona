// The toast context is the root navigator's, captured before any await: it
// outlives the row that started the action, and every use checks `mounted`.
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/aurora_colors.dart';
import '../../models/maintenance_task.dart';
import '../../models/task_menu_choice.dart';
import '../../providers/maintenance_tasks_provider.dart';
import '../../providers/tasks_today_provider.dart';
import '../../tasks_copy.dart';
import 'menu/task_menu_overlay.dart';
import 'task_actions.dart';

/// The long-press menu on every task row (TaskMenu).
abstract final class TaskMenu {
  /// Opens the menu for [task] and carries out the choice: skip, change how
  /// often and stop reminding end with an Undo snackbar; "Open the task" goes
  /// to its detail.
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    MaintenanceTask task,
  ) async {
    final notifier = ref.read(maintenanceTasksProvider.notifier);
    final today = ref.read(tasksTodayProvider);
    final router = GoRouter.maybeOf(context);
    final toast = Navigator.of(context, rootNavigator: true).context;

    final choice = await showGeneralDialog<TaskMenuChoice>(
      context: context,
      barrierDismissible: true,
      barrierLabel: TasksCopy.dismissSemantics,
      barrierColor: AuroraStructure.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => TaskMenuOverlay(task: task, today: today),
    );
    if (choice == null) return;

    switch (choice.action) {
      case TaskMenuAction.open:
        router?.push(
          AppRoutes.maintenanceTaskDetail.replaceFirst(':taskId', task.id),
        );
      case TaskMenuAction.skip:
        await TaskActions.skip(toast, notifier, task);
      case TaskMenuAction.stop:
        await TaskActions.stop(toast, notifier, task);
      case TaskMenuAction.frequency:
        await TaskActions.changeFrequency(
          toast,
          notifier,
          task,
          choice.frequency!,
        );
    }
  }
}
