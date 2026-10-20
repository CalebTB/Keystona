import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../maintenance/models/maintenance_task.dart';
import '../../maintenance/providers/home_health_score_provider.dart';
import '../../maintenance/providers/maintenance_tasks_provider.dart';
import '../../maintenance/providers/reminders_providers.dart';
import '../../maintenance/providers/task_repositories_provider.dart';
import '../models/appliance.dart';
import '../models/appliance_warranty_check.dart';

/// Adds or takes back the one-off "check before the warranty ends" task.
abstract final class ApplianceWarrantyCheckActions {
  /// Creates the task due [due] for [appliance]. The task list refreshes.
  static Future<void> add(WidgetRef ref, Appliance appliance, DateTime due) =>
      ref
          .read(maintenanceTasksProvider.notifier)
          .addTask(ApplianceWarrantyCheck.fields(appliance, due));

  /// Deletes [task] (`soft_delete_task`) and refreshes what shows tasks.
  static Future<void> remove(WidgetRef ref, MaintenanceTask task) async {
    await ref.read(taskDetailRepositoryProvider).deleteTask(task.id);
    ref
      ..invalidate(maintenanceTasksProvider)
      ..invalidate(remindersProvider)
      ..invalidate(homeHealthScoreProvider);
  }
}
