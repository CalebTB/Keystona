import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/maintenance/models/maintenance_task.dart';
import 'package:keystona/features/maintenance/models/quick_done_form.dart';
import 'package:keystona/features/maintenance/models/skip_plan.dart';
import 'package:keystona/features/maintenance/models/task_occurrence.dart';
import 'package:keystona/features/maintenance/models/task_progress.dart';
import 'package:keystona/features/maintenance/models/task_schedule.dart';
import 'package:keystona/features/maintenance/models/tasks_tab_data.dart';
import 'package:keystona/features/maintenance/models/tasks_year_data.dart';

import 'tasks_test_support.dart';

void main() {
  group('TaskSchedule', () {
    test('overdue is judged by date, not by the status column', () {
      final late = task(
        'a',
        'A',
        due: day(10, 3),
        status: TaskStatus.scheduled,
      );
      final today = task('b', 'B', due: day(10, 4), status: TaskStatus.overdue);
      expect(TaskSchedule.isOverdue(late, kToday), isTrue);
      expect(TaskSchedule.isOverdue(today, kToday), isFalse);
    });

    test('done, skipped and turned-off tasks are not open', () {
      for (final t in [
        task('a', 'A', due: day(9, 1), status: TaskStatus.completed),
        task('b', 'B', due: day(9, 1), status: TaskStatus.skipped),
        task('c', 'C', due: day(9, 1), enabled: false),
      ]) {
        expect(TaskSchedule.isOpen(t), isFalse);
        expect(TaskSchedule.isOverdue(t, kToday), isFalse);
      }
    });

    test('nextDate follows the recurrence', () {
      final base = task('a', 'A', due: day(10, 7));
      DateTime next(RecurrenceType r) =>
          TaskSchedule.nextDate(base, recurrence: r);
      expect(next(RecurrenceType.quarterly), day(1, 7, 2027));
      expect(next(RecurrenceType.biannual), day(4, 7, 2027));
      expect(next(RecurrenceType.annual), day(10, 7, 2027));
      expect(next(RecurrenceType.none), day(10, 7));
    });

    test('dateColumn is YYYY-MM-DD', () {
      expect(TaskSchedule.dateColumn(day(3, 9)), '2026-03-09');
    });
  });

  group('TasksTabData', () {
    final data = TasksTabData.from(
      kitTasks(),
      today: kToday,
      progress: const TaskProgress(doneThisMonth: 6, doneThisWeek: 4),
    );

    test('the most overdue task is the hero', () {
      expect(data.hero?.id, 'gutters');
      expect(data.overdueCount, 1);
      expect(data.moreOverdue, isEmpty);
    });

    test('groups are today, this week and later this month', () {
      expect(data.groups.map((g) => g.title), [
        'TODAY · 1',
        'THIS WEEK · 1',
        'LATER THIS MONTH · 2',
      ]);
      expect(data.groups.last.tasks.map((t) => t.id), ['flush', 'roof']);
    });

    test('counts match the kit', () {
      expect(data.monthDone, 6);
      // 6 done + 1 overdue + 4 more due this month.
      expect(data.monthTotal, 11);
      expect(data.weekDone, 4);
      expect(data.dueTodayCount, 1);
      expect(data.caughtUp, isFalse);
    });

    test('open count includes projected repeats in the next 12 months', () {
      // gutters (1) + smoke + flush + roof (one each) + hvac quarterly (4)
      // + faucets yearly (1).
      expect(data.openCount, greaterThan(kitTasks().length));
    });

    test('caught up when nothing is overdue or due today', () {
      final caught = TasksTabData.from(
        kitTasks().where((t) => t.id != 'gutters' && t.id != 'smoke').toList(),
        today: kToday,
      );
      expect(caught.caughtUp, isTrue);
      expect(caught.nextUp.map((t) => t.id), ['hvac', 'flush', 'roof']);
      expect(caught.daysUntilNext, 3);
    });

    test('grouping by area titles groups by system or category', () {
      final byArea = TasksTabData.from(
        kitTasks(),
        today: kToday,
        grouping: TaskGrouping.area,
      );
      expect(byArea.groups.map((g) => g.title), contains('PLUMBING · 1'));
    });

    test('a search matches name, area and system', () {
      final byName = TasksTabData.from(
        kitTasks(),
        today: kToday,
        query: 'gutter',
      );
      expect(byName.hasQuery, isTrue);
      expect(byName.matches.map((t) => t.id), ['gutters']);
      final byArea = TasksTabData.from(
        kitTasks(),
        today: kToday,
        query: 'plumb',
      );
      expect(
        byArea.matches.map((t) => t.id),
        containsAll(['flush', 'faucets']),
      );
    });
  });

  group('TaskOccurrences', () {
    test('projects recurring tasks across the window, once each month', () {
      final hvac = task(
        'h',
        'Filter',
        due: day(10, 7),
        recurrence: RecurrenceType.monthly,
      );
      final list = TaskOccurrences.inWindow([hvac], from: kToday, months: 12);
      expect(list, hasLength(12));
      expect(list.first.projected, isFalse);
      expect(list.skip(1).every((o) => o.projected), isTrue);
    });

    test('weekly tasks are not projected and overdue ones are left out', () {
      final weekly = task(
        'w',
        'W',
        due: day(10, 5),
        recurrence: RecurrenceType.weekly,
      );
      final late = task(
        'l',
        'L',
        due: day(9, 1),
        recurrence: RecurrenceType.annual,
      );
      final list = TaskOccurrences.inWindow(
        [weekly, late],
        from: kToday,
        months: 12,
      );
      expect(list.map((o) => o.task.id), ['w']);
    });
  });

  group('TasksYearData', () {
    test('has 12 months from the current one and counts pros', () {
      final year = TasksYearData.from(kitTasks(), today: kToday);
      expect(year.months, hasLength(12));
      expect(year.months.first.month, day(10, 1));
      expect(year.months.first.count, 4);
      expect(year.months.first.pros, 1);
      expect(year.overdue.map((t) => t.id), ['gutters']);
      expect(year.range, 'OCT 2026 – SEP 2027');
    });
  });

  group('SkipPlan', () {
    final hvac = task(
      'h',
      'Filter',
      due: day(10, 7),
      recurrence: RecurrenceType.quarterly,
    );

    test('push back moves the due date by the delay', () {
      expect(const SkipPlan().pushedTo(hvac, kToday), day(10, 14));
      expect(
        const SkipPlan(delay: SkipDelay.oneMonth).pushedTo(hvac, kToday),
        day(11, 6),
      );
    });

    test('an overdue task is pushed from today', () {
      final late = task('l', 'L', due: day(9, 1));
      expect(const SkipPlan().pushedTo(late, kToday), day(10, 11));
    });

    test('result sentences name the date and the outcome', () {
      expect(
        const SkipPlan().result(hvac, kToday),
        'Moves to next Wednesday, Oct 14. Home Health doesn’t drop while it’s pushed back.',
      );
      expect(
        const SkipPlan(
          reason: SkipReason.other,
          byPro: true,
        ).result(hvac, kToday),
        'Logged as done today by a pro. Next one is due Jan 4, 2027.',
      );
      expect(const SkipPlan(reason: SkipReason.skip).cta, 'Skip this one');
    });
  });

  group('QuickDoneForm', () {
    test('cost parsing accepts symbols and commas', () {
      expect(QuickDoneForm.parseCost(r'$22.00'), 22);
      expect(QuickDoneForm.parseCost('1,200'), 1200);
      expect(QuickDoneForm.parseCost(''), isNull);
    });

    test('yesterday and the picked day set the completion date', () {
      final form = QuickDoneForm(today: kToday);
      expect(form.copyWith(when: DoneWhen.yesterday).completedOn, day(10, 3));
      expect(
        form.copyWith(when: DoneWhen.picked, picked: day(9, 20)).completedOn,
        day(9, 20),
      );
    });

    test('a pro files the cost as service cost via byPro', () {
      final completion = QuickDoneForm(
        today: kToday,
      ).copyWith(byPro: true).toCompletion(cost: '40', note: ' hi ');
      expect(completion.byPro, isTrue);
      expect(completion.cost, 40);
      expect(completion.note, 'hi');
    });
  });
}
