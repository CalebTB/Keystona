import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/maintenance/models/task_detail.dart';
import 'package:keystona/features/maintenance/models/task_undo.dart';
import 'package:keystona/features/maintenance/providers/maintenance_tasks_provider.dart';
import 'package:keystona/features/maintenance/providers/task_detail_provider.dart';

import '../tab/tasks_test_support.dart' as tab;
import 'task_detail_test_support.dart';

/// Counts how many times the detail is fetched.
class _CountingDetailRepository extends FakeTaskDetailRepository {
  _CountingDetailRepository(super.detail);

  int fetches = 0;

  @override
  Future<TaskDetail> fetchDetail(String taskId) {
    fetches++;
    return super.fetchDetail(taskId);
  }
}

void main() {
  test('undoing a task action refetches that task\'s open detail', () async {
    final task = tab.task(
      't1',
      'Change the furnace filter',
      due: DateTime(2026, 10, 4),
    );
    final detailRepo = _CountingDetailRepository(fixtureDetail(task: task));
    final tasksRepo = tab.FakeMaintenanceTasksRepository([task]);
    final container = ProviderContainer(
      overrides: [
        ...taskOverrides(detailRepo),
        ...tab.tasksOverrides(tasksRepo),
      ],
    );
    addTearDown(container.dispose);

    // The detail screen is open (and listening).
    final sub = container.listen(taskDetailProvider('t1'), (_, _) {});
    addTearDown(sub.close);
    await container.read(taskDetailProvider('t1').future);
    await container.read(maintenanceTasksProvider.future);
    final before = detailRepo.fetches;

    await container
        .read(maintenanceTasksProvider.notifier)
        .undo(TaskUndo(previous: task));
    await container.read(taskDetailProvider('t1').future);

    expect(detailRepo.fetches, greaterThan(before));
  });
}
