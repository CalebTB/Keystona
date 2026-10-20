import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../maintenance/models/maintenance_task.dart';
import '../../maintenance/providers/maintenance_tasks_provider.dart';
import '../models/item_ref.dart';

part 'item_task_counts_provider.g.dart';

/// Open task counts per system and appliance ("2 TASKS").
///
/// Derived from the maintenance tasks the Tasks tab already loads: a task
/// counts for the system or appliance it links to when it is not completed or
/// skipped. The task list never contains soft-deleted rows. Items with no open
/// task are absent from the map; read with `counts[item] ?? 0`.
@riverpod
Map<ItemRef, int> itemTaskCounts(Ref ref) {
  final tasks = ref.watch(maintenanceTasksProvider).value;
  return countOpenTasksByItem(tasks ?? const <MaintenanceTask>[]);
}

/// The grouping behind [itemTaskCounts], pure so it can be tested directly.
Map<ItemRef, int> countOpenTasksByItem(Iterable<MaintenanceTask> tasks) {
  final counts = <ItemRef, int>{};
  for (final task in tasks) {
    if (task.status == TaskStatus.completed ||
        task.status == TaskStatus.skipped) {
      continue;
    }
    final system = task.linkedSystemId;
    final appliance = task.linkedApplianceId;
    if (system != null) {
      counts.update(ItemRef.system(system), (n) => n + 1, ifAbsent: () => 1);
    }
    if (appliance != null) {
      counts.update(
        ItemRef.appliance(appliance),
        (n) => n + 1,
        ifAbsent: () => 1,
      );
    }
  }
  return counts;
}
