import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/home_profile/models/item_ref.dart';
import 'package:keystona/features/home_profile/providers/item_task_counts_provider.dart';
import 'package:keystona/features/maintenance/models/maintenance_task.dart';
import 'package:keystona/features/maintenance/providers/maintenance_tasks_provider.dart';

import '../maintenance/tab/tasks_test_support.dart';

MaintenanceTask linked(
  String id, {
  String? system,
  String? appliance,
  TaskStatus status = TaskStatus.scheduled,
}) => task(
  id,
  'Task $id',
  due: day(10, 7),
  status: status,
).copyWith(linkedSystemId: system, linkedApplianceId: appliance);

void main() {
  group('countOpenTasksByItem', () {
    test('groups by linked system and linked appliance', () {
      final counts = countOpenTasksByItem([
        linked('1', system: 's1'),
        linked('2', system: 's1'),
        linked('3', system: 's2'),
        linked('4', appliance: 'a1'),
      ]);
      expect(counts[const ItemRef.system('s1')], 2);
      expect(counts[const ItemRef.system('s2')], 1);
      expect(counts[const ItemRef.appliance('a1')], 1);
      expect(counts.length, 3);
    });

    test('completed and skipped tasks do not count', () {
      final counts = countOpenTasksByItem([
        linked('1', system: 's1'),
        linked('2', system: 's1', status: TaskStatus.completed),
        linked('3', system: 's1', status: TaskStatus.skipped),
      ]);
      expect(counts[const ItemRef.system('s1')], 1);
    });

    test('overdue, due and scheduled tasks are open', () {
      final counts = countOpenTasksByItem([
        linked('1', system: 's1', status: TaskStatus.overdue),
        linked('2', system: 's1', status: TaskStatus.due),
        linked('3', system: 's1'),
      ]);
      expect(counts[const ItemRef.system('s1')], 3);
    });

    test('tasks linked to nothing are ignored; a system id is not an appliance id', () {
      final counts = countOpenTasksByItem([
        linked('1'),
        linked('2', system: 'x'),
      ]);
      expect(counts.length, 1);
      expect(counts[const ItemRef.appliance('x')], isNull);
    });

    test('an item with no open task is absent', () {
      expect(countOpenTasksByItem(const []), isEmpty);
    });
  });

  group('itemTaskCountsProvider', () {
    test('follows the maintenance tasks provider', () async {
      final repo = FakeMaintenanceTasksRepository([
        linked('1', system: 's1'),
        linked('2', appliance: 'a1'),
        linked('3', appliance: 'a1', status: TaskStatus.completed),
      ]);
      final container = ProviderContainer(
        overrides: tasksOverrides(repo),
      );
      addTearDown(container.dispose);

      container.listen(itemTaskCountsProvider, (_, _) {});
      await container.read(maintenanceTasksProvider.future);

      final counts = container.read(itemTaskCountsProvider);
      expect(counts[const ItemRef.system('s1')], 1);
      expect(counts[const ItemRef.appliance('a1')], 1);
    });

    test('is empty while the tasks load', () {
      final container = ProviderContainer(
        overrides: tasksOverrides(FakeMaintenanceTasksRepository(const [])),
      );
      addTearDown(container.dispose);
      expect(container.read(itemTaskCountsProvider), isEmpty);
    });
  });
}
