import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/maintenance/models/maintenance_task.dart';
import 'package:keystona/features/maintenance/models/task_finding.dart';
import 'package:keystona/features/maintenance/models/task_history.dart';
import 'package:keystona/features/maintenance/models/task_log_draft.dart';
import 'package:keystona/features/maintenance/models/task_parent.dart';
import 'package:keystona/features/maintenance/services/task_dates.dart';
import 'package:keystona/features/maintenance/services/task_detail_view.dart';
import 'package:keystona/features/maintenance/services/task_due.dart';
import 'package:keystona/features/maintenance/services/task_format.dart';
import 'package:keystona/features/maintenance/services/task_instructions.dart';
import 'package:keystona/features/maintenance/services/task_log_form_state.dart';
import 'package:keystona/features/maintenance/services/task_log_input.dart';
import 'package:keystona/features/maintenance/services/task_timing.dart';

import 'task_detail_test_support.dart';

void main() {
  group('TaskDates', () {
    test('adds months without overflowing short months', () {
      expect(
        TaskDates.next(RecurrenceType.monthly, DateTime(2026, 1, 31)),
        DateTime(2026, 2, 28),
      );
      expect(
        TaskDates.next(RecurrenceType.quarterly, DateTime(2026, 10, 4)),
        DateTime(2027, 1, 4),
      );
      expect(
        TaskDates.next(RecurrenceType.annual, DateTime(2028, 2, 29)),
        DateTime(2029, 2, 28),
      );
    });

    test('a DATE column gets YYYY-MM-DD with no time', () {
      expect(TaskDates.dateStr(DateTime(2026, 3, 7, 23, 59)), '2026-03-07');
    });

    test('daysBetween ignores the time of day', () {
      expect(
        TaskDates.daysBetween(
          DateTime(2026, 3, 7, 23),
          DateTime(2026, 3, 10, 1),
        ),
        3,
      );
    });
  });

  group('TaskTimings', () {
    test('derives due dates from the previous completion', () {
      final timings = TaskTimings.derive(
        RecurrenceType.quarterly,
        fixtureCompletions(),
      );
      expect(timings['c1']!.kind, TaskTimingKind.unknown);
      expect(timings['c2']!.kind, TaskTimingKind.late);
      expect(timings['c2']!.days, 2);
      expect(timings['c3']!.kind, TaskTimingKind.onTime);
      expect(timings['c4']!.kind, TaskTimingKind.early);
      expect(timings['c4']!.days, 3);
    });

    test('a one-time task has no known due dates', () {
      final timings = TaskTimings.derive(
        RecurrenceType.none,
        fixtureCompletions(),
      );
      expect(timings.values.every((t) => !t.isKnown), isTrue);
    });
  });

  group('TaskDue', () {
    test('overdue, soon and later', () {
      final t = DateTime(2026, 10, 4);
      expect(TaskDue.of(DateTime(2026, 10, 1), t).tone, TaskDueTone.overdue);
      expect(TaskDue.of(DateTime(2026, 10, 1), t).pill, '3 days overdue');
      expect(TaskDue.of(DateTime(2026, 10, 7), t).tone, TaskDueTone.soon);
      expect(TaskDue.of(DateTime(2026, 10, 7), t).pill, 'Due in 3 days');
      expect(TaskDue.of(DateTime(2026, 10, 7), t).relative, 'In 3 days');
      expect(TaskDue.of(DateTime(2026, 12, 25), t).tone, TaskDueTone.later);
      expect(TaskDue.of(t, t).pill, 'Due today');
    });
  });

  group('TaskFormat', () {
    test('minutes and money', () {
      expect(TaskFormat.minutes(15), '15 min');
      expect(TaskFormat.minutes(60), '1 hr');
      expect(TaskFormat.minutes(70), '1 hr 10 min');
      expect(TaskFormat.money(24), r'$24');
      expect(TaskFormat.money(24.5), r'$24.50');
      expect(TaskFormat.money(5318), r'$5,318');
    });

    test('how often', () {
      expect(TaskFormat.every(RecurrenceType.quarterly), 'Every 3 months');
      expect(
        TaskFormat.every(RecurrenceType.annual, season: 'fall'),
        'Every fall',
      );
      expect(TaskFormat.every(RecurrenceType.none), 'One time');
    });

    test('reminder lead time', () {
      expect(TaskFormat.reminder(7), '1 week before');
      expect(TaskFormat.reminder(14), '2 weeks before');
      expect(TaskFormat.reminder(3), '3 days before');
      expect(TaskFormat.reminder(0), 'On the day');
    });

    test('initials and next-one label', () {
      expect(TaskFormat.initials('Summit Heating & Air'), 'SH');
      expect(
        TaskFormat.nextOne(DateTime(2027, 9, 1), season: 'fall'),
        'Fall 2027',
      );
      expect(TaskFormat.nextOne(DateTime(2027, 1, 4)), 'Jan 2027');
    });
  });

  group('TaskLogInput', () {
    test('masks a date as digits are typed', () {
      expect(TaskLogInput.maskDate('1'), '1');
      expect(TaskLogInput.maskDate('100'), '10 / 0');
      expect(TaskLogInput.maskDate('10022026'), '10 / 02 / 2026');
      expect(TaskLogInput.maskDate('1002202699'), '10 / 02 / 2026');
    });

    test('parses only real dates', () {
      expect(TaskLogInput.parseDate('10 / 02 / 2026'), DateTime(2026, 10, 2));
      expect(TaskLogInput.parseDate('10/02/2026'), DateTime(2026, 10, 2));
      expect(TaskLogInput.parseDate('02 / 30 / 2026'), isNull);
      expect(TaskLogInput.parseDate('13 / 01 / 2026'), isNull);
      expect(TaskLogInput.parseDate('10 / 02'), isNull);
    });

    test('parses the time it took', () {
      expect(TaskLogInput.parseMinutes('1 hr 10 min'), 70);
      expect(TaskLogInput.parseMinutes('90'), 90);
      expect(TaskLogInput.parseMinutes('45 min'), 45);
      expect(TaskLogInput.parseMinutes('1.5 hr'), 90);
      expect(TaskLogInput.parseMinutes(''), isNull);
      expect(TaskLogInput.parseMinutes('a while'), isNull);
      expect(TaskLogInput.parseMinutes('99999'), isNull);
    });

    test('parses money, never negative', () {
      expect(TaskLogInput.parseMoney(r'$129'), 129);
      expect(TaskLogInput.parseMoney('12.50'), 12.5);
      expect(TaskLogInput.parseMoney(''), 0);
      expect(TaskLogInput.parseMoney('-5'), 5);
    });
  });

  group('TaskInstructions', () {
    test('splits steps, drops numbering and finds bold', () {
      final steps = TaskInstructions.steps(
        '1. Turn it **off**\n- Slide it out\n\n3) Slide it in',
      );
      expect(steps, ['Turn it **off**', 'Slide it out', 'Slide it in']);
      final spans = TaskInstructions.spans(steps.first);
      expect(spans.map((s) => s.text), ['Turn it ', 'off']);
      expect(spans.map((s) => s.bold), [false, true]);
      expect(TaskInstructions.steps(null), isEmpty);
    });
  });

  group('TaskParent.healthOf', () {
    final now = DateTime(2026, 10, 1);
    TaskParentHealth? health(int years, {int min = 15, int max = 25}) =>
        TaskParent.healthOf(
          installed: DateTime(2026 - years, 10, 1),
          lifespanMin: min,
          lifespanMax: max,
          lifespanOverride: null,
          now: now,
        );

    test('healthy, aging and past', () {
      expect(health(5), TaskParentHealth.healthy);
      expect(health(16), TaskParentHealth.aging);
      expect(health(21), TaskParentHealth.endOfLife);
    });

    test('unknown without an install date or lifespan', () {
      expect(
        TaskParent.healthOf(
          installed: null,
          lifespanMin: 15,
          lifespanMax: 25,
          lifespanOverride: null,
          now: now,
        ),
        isNull,
      );
      expect(
        TaskParent.healthOf(
          installed: DateTime(2020),
          lifespanMin: null,
          lifespanMax: null,
          lifespanOverride: null,
          now: now,
        ),
        isNull,
      );
    });
  });

  group('TaskDetailView', () {
    test('open task: due tone, next after this, on time counts', () {
      final detail = fixtureDetail(completions: fixtureCompletions());
      final view = TaskDetailView.of(detail, today: today);
      expect(view.phase, TaskPhase.open);
      expect(view.due!.tone, TaskDueTone.soon);
      expect(view.known, 3);
      expect(view.onTime, 2);
      expect(
        view.nextAfterThis,
        TaskDates.next(RecurrenceType.quarterly, detail.task.dueDate),
      );
    });

    test('done today names how early, and Undo needs the old due date', () {
      final done = fixtureDetail(
        task: fixtureTask(due: daysFromToday(90)),
        completions: [fixtureCompletion('x', today), ...fixtureCompletions()],
      );
      final withMemory = TaskDetailView.of(
        done,
        today: today,
        dueBeforeDone: daysFromToday(3),
      );
      expect(withMemory.phase, TaskPhase.done);
      expect(withMemory.doneTitle, 'Done today, 3 days early');
      expect(withMemory.canUndo, isTrue);
      expect(withMemory.nextLine, startsWith('Next one is due '));

      final reopened = TaskDetailView.of(done, today: today);
      expect(reopened.canUndo, isFalse);
    });

    test('a skipped one-time task', () {
      final detail = fixtureDetail(
        task: fixtureTask(
          recurrence: RecurrenceType.none,
          status: TaskStatus.skipped,
        ),
        completions: const [],
      );
      expect(TaskDetailView.of(detail, today: today).phase, TaskPhase.skipped);
    });

    test('one-time open task has no next after this', () {
      final detail = fixtureDetail(
        task: fixtureTask(recurrence: RecurrenceType.none),
      );
      expect(TaskDetailView.of(detail, today: today).nextAfterThis, isNull);
    });
  });

  group('TaskHistory', () {
    test('stats: count, on time of known, total spent, first year', () {
      final history = TaskHistory.from(
        fixtureDetail(completions: fixtureCompletions()),
        const {},
      );
      expect(history.count, 4);
      expect(history.known, 3);
      expect(history.onTime, 2);
      expect(history.totalSpent, 66);
      expect(history.marks.length, 4);
      expect(history.entries.last.completion.id, 'c1');
    });
  });

  group('TaskLogFormState', () {
    TaskLogFormState form({
      MaintenanceTask? task,
      List<dynamic>? completions,
    }) => TaskLogFormState(
      detail: fixtureDetail(
        task: task ?? fixtureTask(due: daysFromToday(10)),
        completions: fixtureCompletions().take(3).toList(),
      ),
      today: today,
    );

    test('starts on today and can save', () {
      final f = form();
      expect(f.canSave, isTrue);
      expect(f.parsedDate, today);
      f.dispose();
    });

    test('a bad or future date cannot be saved', () {
      final f = form();
      f.date.text = '10 / 0';
      expect(f.canSave, isFalse);
      expect(f.dateHelp, 'Use MM / DD / YYYY');
      f.date.text = TaskLogInput.formatDate(daysFromToday(2));
      expect(f.canSave, isFalse);
      expect(f.dateHelp, "Can't be in the future");
      f.dispose();
    });

    test('date help says how early and when the next one is', () {
      final f = form();
      expect(f.dateHelp, startsWith('10 days early · Next one '));
      f.dispose();
    });

    test('a date older than the newest log is a past one', () {
      final f = form();
      f.date.text = TaskLogInput.formatDate(daysFromToday(-1000));
      expect(f.dateHelp, 'A past one · the due date stays');
      f.dispose();
    });

    test('total and helper follow the cost fields', () {
      final f = form();
      expect(f.costHelp, r'Leave at $0 if it was free');
      f.labor.text = r'$129';
      f.parts.text = '10.50';
      expect(f.total, 139.5);
      expect(f.totalText, r'$139.50');
      expect(f.costHelp, "Counts toward the furnace's lifetime cost");
      f.dispose();
    });

    test('the draft carries what was entered', () {
      final f = form();
      f.setDoer(TaskDoer.pro);
      f.setPro(const TaskPro(id: 'k', name: 'Sam', company: 'Summit'));
      f.time.text = '1 hr 10 min';
      f.labor.text = '129';
      f.notes.text = 'Cleaned the sensor.';
      f.addReceipt(const ReceiptOption(id: 'd1', name: 'Invoice'));
      f.addReceipt(const ReceiptOption(id: 'd1', name: 'Invoice'));
      f.addPhoto(const LogPhoto(path: '/a.jpg', name: 'a.jpg'));
      f.addPhoto(const LogPhoto(path: '/b.jpg', name: 'b.jpg'));
      f.addPhoto(const LogPhoto(path: '/c.jpg', name: 'c.jpg'));
      final d = f.buildDraft();
      expect(d.doer, TaskDoer.pro);
      expect(d.pro!.company, 'Summit');
      expect(d.minutes, 70);
      expect(d.laborCost, 129);
      expect(d.receiptIds, ['d1']);
      expect(d.photos.map((p) => p.caption), ['before', 'after', null]);
      f.dispose();
    });

    test('findings toggle; All good starts on', () {
      final f = form();
      expect(f.findings, {TaskFinding.ok});
      f.toggleFinding(TaskFinding.fix);
      f.toggleFinding(TaskFinding.ok);
      expect(f.findings, {TaskFinding.fix});
      f.dispose();
    });
  });
}
