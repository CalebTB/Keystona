import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/maintenance/models/maintenance_task.dart';
import 'package:keystona/features/maintenance/models/task_log_draft.dart';
import 'package:keystona/features/maintenance/providers/task_detail_provider.dart';
import 'package:keystona/features/maintenance/services/task_dates.dart';

import 'task_detail_test_support.dart';

Future<(ProviderContainer, FakeTaskDetailRepository)> _setup({
  MaintenanceTask? task,
  bool failInsert = false,
  Completer<void>? insertGate,
}) async {
  final repo = FakeTaskDetailRepository(
    fixtureDetail(task: task ?? fixtureTask(due: daysFromToday(3))),
    failInsert: failInsert,
    insertGate: insertGate,
  );
  final container = ProviderContainer(overrides: taskOverrides(repo));
  addTearDown(container.dispose);
  // Keep the auto-dispose provider alive for the test.
  container.listen(taskDetailProvider('t1'), (_, _) {});
  await container.read(taskDetailProvider('t1').future);
  return (container, repo);
}

TaskLogDraft _draft(DateTime date) =>
    TaskLogDraft(completedDate: date, doer: TaskDoer.me, laborCost: 20);

void main() {
  test(
    'logging the newest completion rolls a recurring task forward',
    () async {
      final (container, repo) = await _setup();
      final oldDue = repo.detail.task.dueDate;
      final notifier = container.read(taskDetailProvider('t1').notifier);

      final receipt = await notifier.logCompletion(_draft(today));

      expect(repo.inserted, hasLength(1));
      expect(repo.schedules.single.status, TaskStatus.scheduled);
      expect(
        repo.schedules.single.due,
        TaskDates.next(RecurrenceType.quarterly, today),
      );
      expect(receipt.completionId, 'new-1');
      expect(receipt.originalDueDate, oldDue);

      final after = await container.read(taskDetailProvider('t1').future);
      expect(after.completions.first.id, 'new-1');
      expect(after.task.dueDate, repo.schedules.single.due);
    },
  );

  test(
    'logging a past one adds history and leaves the schedule alone',
    () async {
      final (container, repo) = await _setup();
      final notifier = container.read(taskDetailProvider('t1').notifier);

      final receipt = await notifier.logCompletion(
        _draft(daysFromToday(-1000)),
      );

      expect(repo.inserted, hasLength(1));
      expect(repo.schedules, isEmpty);
      expect(receipt.originalDueDate, isNull);
    },
  );

  test('a one-time task is completed, not rolled', () async {
    final (container, repo) = await _setup(
      task: fixtureTask(recurrence: RecurrenceType.none),
    );
    final notifier = container.read(taskDetailProvider('t1').notifier);

    await notifier.logCompletion(_draft(today));

    expect(repo.schedules.single.status, TaskStatus.completed);
  });

  test('the write is optimistic: data first, never AsyncLoading', () async {
    final gate = Completer<void>();
    final (container, repo) = await _setup(insertGate: gate);
    final before = container.read(taskDetailProvider('t1')).value!;
    final notifier = container.read(taskDetailProvider('t1').notifier);

    final pending = notifier.logCompletion(_draft(today));
    await Future<void>.delayed(Duration.zero);

    final during = container.read(taskDetailProvider('t1'));
    expect(during.isLoading, isFalse);
    expect(during.value!.completions.length, before.completions.length + 1);
    expect(during.value!.task.dueDate, isNot(before.task.dueDate));
    expect(repo.inserted, isEmpty);

    gate.complete();
    await pending;
    expect(repo.inserted, hasLength(1));
  });

  test('a failed write puts the old state back and rethrows', () async {
    final (container, repo) = await _setup(failInsert: true);
    final before = container.read(taskDetailProvider('t1')).value!;
    final notifier = container.read(taskDetailProvider('t1').notifier);

    await expectLater(notifier.logCompletion(_draft(today)), throwsStateError);

    final after = await container.read(taskDetailProvider('t1').future);
    expect(after.completions.length, before.completions.length);
    expect(after.task.dueDate, before.task.dueDate);
    expect(repo.schedules, isEmpty);
  });

  test('undo deletes the completion and restores the due date', () async {
    final (container, repo) = await _setup();
    final oldDue = repo.detail.task.dueDate;
    final notifier = container.read(taskDetailProvider('t1').notifier);
    final receipt = await notifier.logCompletion(_draft(today));

    await notifier.undoCompletion(receipt);

    expect(repo.deletedCompletions, ['new-1']);
    expect(repo.schedules.last.due, oldDue);
    expect(repo.schedules.last.status, TaskStatus.scheduled);
    final after = await container.read(taskDetailProvider('t1').future);
    expect(after.task.dueDate, oldDue);
    expect(after.completions.any((c) => c.id == 'new-1'), isFalse);
  });

  test(
    'undo of a task that was already overdue puts it back overdue',
    () async {
      final (container, repo) = await _setup(
        task: fixtureTask(due: daysFromToday(-4)),
      );
      final notifier = container.read(taskDetailProvider('t1').notifier);
      final receipt = await notifier.logCompletion(_draft(today));

      await notifier.undoCompletion(receipt);

      expect(repo.schedules.last.status, TaskStatus.overdue);
    },
  );

  test('undo of a past one only deletes the completion', () async {
    final (container, repo) = await _setup();
    final notifier = container.read(taskDetailProvider('t1').notifier);
    final receipt = await notifier.logCompletion(_draft(daysFromToday(-1000)));

    await notifier.undoCompletion(receipt);

    expect(repo.deletedCompletions, ['new-1']);
    expect(repo.schedules, isEmpty);
  });

  test('deleting the task goes through the repository', () async {
    final (container, repo) = await _setup();
    await container.read(taskDetailProvider('t1').notifier).deleteTask();
    expect(repo.deletedTasks, ['t1']);
  });
}
