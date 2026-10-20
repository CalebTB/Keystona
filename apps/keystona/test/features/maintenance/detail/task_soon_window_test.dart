import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/theme/aurora_colors.dart';
import 'package:keystona/features/maintenance/models/maintenance_task.dart';
import 'package:keystona/features/maintenance/models/task_draft.dart';
import 'package:keystona/features/maintenance/models/task_schedule.dart';
import 'package:keystona/features/maintenance/repositories/task_columns.dart';
import 'package:keystona/features/maintenance/services/task_due.dart';
import 'package:keystona/features/maintenance/widgets/detail/task_due_card.dart';

import 'task_detail_test_support.dart';

MaintenanceTask _task(int dueInDays, int? window) =>
    fixtureTask(due: daysFromToday(dueInDays), reminderDays: window);

void main() {
  group('the soon window is the task\'s own reminder window', () {
    test('3, 7 and 14 day windows', () {
      for (final window in [3, 7, 14]) {
        expect(TaskSchedule.soonWindowDays(_task(1, window)), window);
        expect(TaskSchedule.isSoon(_task(window, window), today), isTrue);
        expect(TaskSchedule.isSoon(_task(window + 1, window), today), isFalse);
        expect(TaskSchedule.isSoon(_task(0, window), today), isTrue);
      }
    });

    test('an empty reminder window counts as 7 days', () {
      expect(TaskSchedule.soonWindowDays(_task(1, null)), 7);
      expect(TaskSchedule.isSoon(_task(7, null), today), isTrue);
      expect(TaskSchedule.isSoon(_task(8, null), today), isFalse);
    });

    test('the same due date is soon for one task and later for another', () {
      expect(TaskSchedule.isSoon(_task(10, 14), today), isTrue);
      expect(TaskSchedule.isSoon(_task(10, 3), today), isFalse);
      expect(TaskSchedule.isSoon(_task(10, null), today), isFalse);
    });

    test('a window of 0 is soon only on the day', () {
      expect(TaskSchedule.isSoon(_task(0, 0), today), isTrue);
      expect(TaskSchedule.isSoon(_task(1, 0), today), isFalse);
    });

    test('overdue is never soon and wins the tone', () {
      final late = _task(-1, 14);
      expect(TaskSchedule.isSoon(late, today), isFalse);
      expect(TaskDue.of(late, today).tone, TaskDueTone.overdue);
    });

    test('TaskDue tone follows the window, boundary day included', () {
      expect(TaskDue.of(_task(3, 3), today).tone, TaskDueTone.soon);
      expect(TaskDue.of(_task(4, 3), today).tone, TaskDueTone.later);
      expect(TaskDue.of(_task(14, 14), today).tone, TaskDueTone.soon);
      expect(TaskDue.of(_task(15, 14), today).tone, TaskDueTone.later);
      expect(TaskDue.of(_task(7, null), today).tone, TaskDueTone.soon);
      expect(TaskDue.of(_task(8, null), today).tone, TaskDueTone.later);
    });
  });

  group('the column reaches the task', () {
    test('every task query selects reminder_days_before', () {
      expect(TaskColumns.task.split(', '), contains('reminder_days_before'));
    });

    test('a row maps to reminderDaysBefore; NULL stays null (read as 7)', () {
      final json = fixtureTask().toJson();
      expect(
        MaintenanceTask.fromJson({
          ...json,
          'reminder_days_before': 3,
        }).reminderDaysBefore,
        3,
      );
      final none = MaintenanceTask.fromJson({
        ...json,
        'reminder_days_before': null,
      });
      expect(none.reminderDaysBefore, isNull);
      expect(TaskSchedule.soonWindowDays(none), 7);
    });

    test('the edit form starts on the task\'s own lead time', () {
      expect(TaskDraft.fromTask(_task(5, 3)).remindDays, 3);
      expect(TaskDraft.fromTask(_task(5, null)).remindDays, 7);
      expect(TaskDraft.fromTask(_task(5, 3)).remindTouched, isFalse);
    });
  });

  group('detail due card', () {
    Future<Color> ringFor(WidgetTester t, MaintenanceTask task) async {
      await pumpTasks(t, FakeTaskDetailRepository(fixtureDetail(task: task)));
      return t.widget<TaskDueCard>(find.byType(TaskDueCard)).ring;
    }

    testWidgets('amber inside the task\'s window', (t) async {
      expect(await ringFor(t, _task(10, 14)), AuroraColors.amber);
    });

    testWidgets('not amber outside a short window', (t) async {
      expect(await ringFor(t, _task(10, 3)), AuroraColors.cobalt);
    });

    testWidgets('coral when overdue whatever the window', (t) async {
      expect(await ringFor(t, _task(-2, 14)), AuroraColors.coral);
    });

    testWidgets('amber on the boundary day of a 3 day window', (t) async {
      expect(await ringFor(t, _task(3, 3)), AuroraColors.amber);
    });
  });
}
