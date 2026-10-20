import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_health_score_provider.dart';
import 'maintenance_tasks_provider.dart';
import 'reminders_providers.dart';
import 'task_detail_provider.dart';
import 'task_repositories_provider.dart';

/// Takes a deleted task back. It runs against a [ProviderContainer], not a
/// notifier: by the time Undo is tapped the task's screen is gone and its
/// auto-disposed notifier with it.
abstract final class TaskDeletion {
  /// Restores [taskId] (`restore_task`) and refreshes every list and screen
  /// that shows tasks.
  static Future<void> restore(
    ProviderContainer container,
    String taskId,
  ) async {
    await container.read(taskDetailRepositoryProvider).restoreTask(taskId);
    container
      ..invalidate(maintenanceTasksProvider)
      ..invalidate(homeHealthScoreProvider)
      ..invalidate(remindersProvider)
      ..invalidate(taskDetailProvider(taskId));
  }
}
