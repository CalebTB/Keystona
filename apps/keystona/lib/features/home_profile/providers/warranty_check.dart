import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/aurora_home_b.dart';
import '../../maintenance/models/maintenance_task.dart';
import '../../maintenance/models/task_schedule.dart';
import '../../maintenance/providers/maintenance_repository_provider.dart';
import '../../maintenance/providers/maintenance_tasks_provider.dart';
import '../../maintenance/providers/task_repositories_provider.dart';
import '../models/system.dart';

/// The one-off task "check it before the warranty ends": found again by its
/// tag, so the card can show "added" and take it back.
abstract final class WarrantyCheck {
  /// Tag on the task. This is how the detail screen finds it.
  static const String tag = 'warranty-check';

  /// The warranty-check task of [systemId] among [tasks], if there is one.
  static MaintenanceTask? taskFor(
    Iterable<MaintenanceTask> tasks,
    String systemId,
  ) {
    for (final t in tasks) {
      if (t.linkedSystemId == systemId && t.tags.contains(tag)) return t;
    }
    return null;
  }

  /// A fortnight before the warranty ends, but never in the past.
  static DateTime dueDate(DateTime warrantyEnds, DateTime today) {
    final lead = warrantyEnds.subtract(AuroraHomeBSizes.warrantyCheckLead);
    return lead.isBefore(today) ? today : lead;
  }

  /// Creates the task and refreshes the Tasks list.
  static Future<void> add(
    WidgetRef ref, {
    required HomeSystem system,
    required DateTime warrantyEnds,
    required String taskName,
  }) async {
    final today = TaskSchedule.dayOf(DateTime.now());
    final due = dueDate(warrantyEnds, today);
    await ref.read(maintenanceTasksRepositoryProvider).insertTask({
      'property_id': system.propertyId,
      'user_id': system.userId,
      'name': taskName,
      'category': system.category.label,
      'due_date': TaskSchedule.dateColumn(due),
      'recurrence': RecurrenceType.none.value,
      'task_origin': TaskOrigin.oneTime.value,
      'diy_or_pro': DiyOrPro.either.value,
      'linked_system_id': system.id,
      'tags': [tag],
    });
    ref.invalidate(maintenanceTasksProvider);
  }

  /// Deletes the task again (second tap on the card).
  static Future<void> remove(WidgetRef ref, String taskId) async {
    await ref.read(taskDetailRepositoryProvider).deleteTask(taskId);
    ref.invalidate(maintenanceTasksProvider);
  }
}
