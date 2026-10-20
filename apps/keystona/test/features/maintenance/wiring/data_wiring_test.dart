import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/maintenance/models/maintenance_task.dart';
import 'package:keystona/features/maintenance/models/quick_completion.dart';
import 'package:keystona/features/maintenance/models/task_completion.dart';
import 'package:keystona/features/maintenance/models/task_draft.dart';
import 'package:keystona/features/maintenance/models/task_finding.dart';
import 'package:keystona/features/maintenance/models/task_form_options.dart';
import 'package:keystona/features/maintenance/models/task_history.dart';
import 'package:keystona/features/maintenance/models/task_log_draft.dart';
import 'package:keystona/features/maintenance/models/task_occurrence.dart';
import 'package:keystona/features/maintenance/models/task_schedule.dart';
import 'package:keystona/features/maintenance/providers/maintenance_tasks_provider.dart';
import 'package:keystona/features/maintenance/repositories/supabase_task_detail_repository.dart';
import 'package:keystona/features/maintenance/repositories/task_columns.dart';
import 'package:keystona/features/maintenance/repositories/task_rows.dart';
import 'package:keystona/features/maintenance/services/reminder_switch.dart';
import 'package:keystona/features/maintenance/services/task_dates.dart';
import 'package:keystona/features/maintenance/services/task_timing.dart';

import '../detail/task_detail_test_support.dart' as detail;
import '../form_reminders/form_reminders_support.dart' as form;
import '../tab/tasks_test_support.dart';

MaintenanceTask _task({
  RecurrenceType recurrence = RecurrenceType.annual,
  int? years,
  DateTime? due,
}) => task(
  'a1',
  'Flush water heater',
  due: due ?? DateTime(2026, 11, 1),
  recurrence: recurrence,
  intervalYears: years,
);

void main() {
  group('rows written to the database', () {
    test('a quick completion carries the due date it answered', () {
      final row = TaskRows.quickCompletion(
        task: _task(),
        completion: QuickCompletion(
          completedOn: DateTime(2026, 10, 30),
          dueDate: DateTime(2026, 11, 1),
          cost: 25,
        ),
        userId: 'u1',
      );
      expect(row['due_date'], '2026-11-01');
      expect(row['completed_date'], '2026-10-30');
      expect(row['materials_cost'], 25);
    });

    test('a quick completion without an occurrence omits due_date', () {
      final row = TaskRows.quickCompletion(
        task: _task(),
        completion: QuickCompletion(completedOn: DateTime(2026, 10, 30)),
        userId: 'u1',
      );
      expect(row.containsKey('due_date'), isFalse);
    });

    test('a log carries findings, the history switch and the due date', () {
      final row = TaskRows.logCompletion(
        task: _task(),
        draft: TaskLogDraft(
          completedDate: DateTime(2026, 10, 30),
          doer: TaskDoer.me,
          findings: const [TaskFinding.ok, TaskFinding.quote],
          addToItemHistory: true,
        ),
        userId: 'u1',
        dueDate: DateTime(2026, 11, 1),
      );
      expect(row['findings'], ['ok', 'quote']);
      expect(row['log_to_item_history'], isTrue);
      expect(row['due_date'], '2026-11-01');
    });

    test('a log with the switch off writes false, not nothing', () {
      final row = TaskRows.logCompletion(
        task: _task(),
        draft: TaskLogDraft(
          completedDate: DateTime(2026, 10, 30),
          doer: TaskDoer.me,
        ),
        userId: 'u1',
      );
      expect(row['log_to_item_history'], isFalse);
      expect(row['findings'], isEmpty);
      expect(row.containsKey('due_date'), isFalse, reason: 'a past entry');
    });

    test('a skip names the task, home, occurrence and reason', () {
      final row = TaskRows.skip(
        task: _task(),
        userId: 'u1',
        dueDate: DateTime(2026, 11, 1),
        skippedOn: DateTime(2026, 10, 30),
        reason: '  Alex was traveling ',
      );
      expect(row, {
        'task_id': 'a1',
        'property_id': 'p1',
        'user_id': 'u1',
        'skipped_on': '2026-10-30',
        'due_date': '2026-11-01',
        'reason': 'Alex was traveling',
      });
    });

    test('a skip with a blank reason stores null', () {
      final row = TaskRows.skip(
        task: _task(),
        userId: 'u1',
        dueDate: DateTime(2026, 11, 1),
        skippedOn: DateTime(2026, 10, 30),
        reason: '  ',
      );
      expect(row['reason'], isNull);
    });

    test('delete and restore call the functions, with the task id', () {
      expect(TaskRpc.softDelete, 'soft_delete_task');
      expect(TaskRpc.restore, 'restore_task');
      expect(TaskRpc.args('t9'), {'p_task_id': 't9'});
    });

    test('the column lists name every new column', () {
      for (final c in [
        'estimated_cost',
        'notes',
        'recurrence_interval_years',
        'notifications_off_at',
        'notifications_off_reason',
        'tags',
      ]) {
        expect(TaskColumns.task.split(', '), contains(c), reason: c);
      }
      for (final c in ['findings', 'log_to_item_history', 'due_date']) {
        expect(TaskColumns.completion.split(', '), contains(c), reason: c);
      }
      expect(TaskColumns.skip.split(', '), contains('due_date'));
    });
  });

  group('reminder on and off columns', () {
    test('off stamps the time (UTC) and keeps the reason', () {
      final now = DateTime.utc(2026, 10, 4, 9, 30);
      final cols = ReminderSwitch.columns(
        enabled: false,
        reason: ' Doesn’t apply to my home ',
        now: now,
      );
      expect(cols, {
        'notifications_enabled': false,
        'notifications_off_at': '2026-10-04T09:30:00.000Z',
        'notifications_off_reason': 'Doesn’t apply to my home',
      });
    });

    test('off without a reason stores null for it', () {
      final cols = ReminderSwitch.columns(enabled: false, reason: '');
      expect(cols['notifications_off_reason'], isNull);
      expect(
        DateTime.parse(cols['notifications_off_at'] as String).isUtc,
        true,
      );
    });

    test('on clears both', () {
      expect(ReminderSwitch.columns(enabled: true, reason: 'ignored'), {
        'notifications_enabled': true,
        'notifications_off_at': null,
        'notifications_off_reason': null,
      });
    });
  });

  group('rows read from the database', () {
    test('a task reads its new columns', () {
      final t = MaintenanceTask.fromJson({
        'id': 't1',
        'property_id': 'p1',
        'user_id': 'u1',
        'name': 'Flush',
        'category': 'plumbing',
        'due_date': '2026-11-01',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
        'estimated_cost': 25,
        'notes': 'Spares are on the shelf.',
        'recurrence': 'annual',
        'recurrence_interval_years': 3,
        'notifications_enabled': false,
        'notifications_off_at': '2026-09-12T10:00:00Z',
        'notifications_off_reason': 'No humidifier',
        'tags': ['FREEZE', 'STORMS'],
      });
      expect(t.estimatedCost, 25.0);
      expect(t.notes, 'Spares are on the shelf.');
      expect(t.recurrenceIntervalYears, 3);
      expect(t.notificationsOffAt, DateTime.utc(2026, 9, 12, 10));
      expect(t.notificationsOffReason, 'No humidifier');
      expect(t.tags, ['FREEZE', 'STORMS']);
    });

    test('a task from before the columns existed has safe defaults', () {
      final t = MaintenanceTask.fromJson({
        'id': 't1',
        'property_id': 'p1',
        'user_id': 'u1',
        'name': 'Flush',
        'category': 'plumbing',
        'due_date': '2026-11-01',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      });
      expect(t.estimatedCost, isNull);
      expect(t.notes, isNull);
      expect(t.recurrenceIntervalYears, isNull);
      expect(t.tags, isEmpty);
    });

    test('a completion reads findings, the switch and its due date', () {
      final c = TaskCompletion.fromJson({
        'id': 'c1',
        'task_id': 't1',
        'user_id': 'u1',
        'property_id': 'p1',
        'completed_date': '2026-10-04',
        'created_at': '2026-10-04T10:00:00Z',
        'findings': ['ok', 'soon'],
        'log_to_item_history': true,
        'due_date': '2026-10-07',
      });
      expect(c.findings, ['ok', 'soon']);
      expect(c.logToItemHistory, isTrue);
      expect(c.dueDate, DateTime(2026, 10, 7));
    });

    test('a detail row reads its skips newest first', () {
      final d = SupabaseTaskDetailRepository.parseDetail({
        'id': 't1',
        'property_id': 'p1',
        'user_id': 'u1',
        'name': 'Flush',
        'category': 'plumbing',
        'due_date': '2026-11-01',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
        'completions': <dynamic>[],
        'skips': [
          {
            'id': 's1',
            'task_id': 't1',
            'skipped_on': '2025-10-02',
            'due_date': '2025-10-01',
            'reason': null,
          },
          {
            'id': 's2',
            'task_id': 't1',
            'skipped_on': '2026-04-02',
            'due_date': '2026-04-01',
            'reason': 'Alex was traveling',
          },
        ],
      }, now: DateTime(2026, 10, 4));
      expect(d.skips.map((s) => s.id), ['s2', 's1']);
      expect(d.skips.first.reason, 'Alex was traveling');
      expect(d.skips.last.hasReason, isFalse);
    });

    test('a finding the app does not know is ignored, not a crash', () {
      expect(TaskFinding.fromValue('fix'), TaskFinding.fix);
      expect(TaskFinding.fromValue('from-the-future'), isNull);
    });
  });

  group('every few years rolls forward by its interval', () {
    test('next date adds the interval, not one year', () {
      final t = _task(years: 3);
      expect(
        TaskSchedule.nextDate(t, base: DateTime(2026, 10, 30)),
        DateTime(2029, 10, 30),
      );
      expect(
        TaskDates.next(
          RecurrenceType.annual,
          DateTime(2026, 10, 30),
          intervalYears: 3,
        ),
        DateTime(2029, 10, 30),
      );
    });

    test('a plain annual task still adds one year', () {
      expect(
        TaskSchedule.nextDate(_task(), base: DateTime(2026, 10, 30)),
        DateTime(2027, 10, 30),
      );
    });

    test('a different recurrence override ignores the interval', () {
      expect(
        TaskSchedule.nextDate(
          _task(years: 3),
          base: DateTime(2026, 10, 30),
          recurrence: RecurrenceType.annual,
        ),
        DateTime(2027, 10, 30),
      );
    });

    test('Feb 29 plus years lands on the last day of February', () {
      expect(
        TaskDates.next(
          RecurrenceType.annual,
          DateTime(2028, 2, 29),
          intervalYears: 3,
        ),
        DateTime(2031, 2, 28),
      );
    });

    test('marking it done moves the due date three years out', () {
      final rolled = MaintenanceTasksNotifier.rolledForward(
        _task(years: 3),
        DateTime(2026, 10, 30),
      );
      expect(rolled.dueDate, DateTime(2029, 10, 30));
      expect(rolled.status, TaskStatus.scheduled);
    });

    test('the all-year view does not project a repeat inside 12 months', () {
      final every3 = TaskOccurrences.inWindow(
        [_task(years: 3, due: DateTime(2026, 11, 1))],
        from: DateTime(2026, 10, 4),
        months: 12,
      );
      expect(every3, hasLength(1));
      final yearly = TaskOccurrences.inWindow(
        [_task(due: DateTime(2026, 11, 1))],
        from: DateTime(2026, 10, 4),
        months: 12,
      );
      expect(yearly, hasLength(1), reason: 'next repeat is Nov 2027');
      final monthlyControl = TaskOccurrences.inWindow(
        [
          _task(
            recurrence: RecurrenceType.quarterly,
            due: DateTime(2026, 11, 1),
          ),
        ],
        from: DateTime(2026, 10, 4),
        months: 12,
      );
      expect(monthlyControl.length, greaterThan(1));
    });

    test(
      'a three-year task due early in the window projects past 36 months',
      () {
        final spread = TaskOccurrences.inWindow(
          [_task(years: 3, due: DateTime(2026, 11, 1))],
          from: DateTime(2026, 10, 4),
          months: 40,
        );
        expect(spread.map((o) => o.date), [
          DateTime(2026, 11, 1),
          DateTime(2029, 11, 1),
        ]);
        expect(spread.last.projected, isTrue);
      },
    );
  });

  group('timing uses the stored due date', () {
    TaskCompletion done(String id, DateTime on, {DateTime? due}) =>
        detail.fixtureCompletion(id, on, dueDate: due);

    test('a stored due date decides early, on time and late', () {
      final timings = TaskTimings.derive(RecurrenceType.quarterly, [
        done('a', DateTime(2026, 10, 4), due: DateTime(2026, 10, 7)),
        done('b', DateTime(2026, 7, 8), due: DateTime(2026, 7, 6)),
        done('c', DateTime(2026, 4, 1), due: DateTime(2026, 4, 1)),
      ]);
      expect(timings['a']!.kind, TaskTimingKind.early);
      expect(timings['a']!.days, 3);
      expect(timings['b']!.kind, TaskTimingKind.late);
      expect(timings['b']!.days, 2);
      expect(timings['c']!.kind, TaskTimingKind.onTime);
    });

    test('the oldest completion is known when it stored its due date', () {
      final timings = TaskTimings.derive(RecurrenceType.quarterly, [
        done('only', DateTime(2026, 4, 3), due: DateTime(2026, 4, 1)),
      ]);
      expect(timings['only']!.kind, TaskTimingKind.late);
    });

    test('old rows keep the derived fallback', () {
      final timings = TaskTimings.derive(RecurrenceType.quarterly, [
        done('new', DateTime(2026, 4, 10)),
        done('old', DateTime(2026, 1, 5)),
      ]);
      expect(timings['old']!.isKnown, isFalse);
      expect(timings['new']!.isKnown, isTrue);
    });

    test('a stored date beats what the previous completion implies', () {
      // A skip moved the schedule: derived says 9 days late, stored says on time.
      final timings = TaskTimings.derive(RecurrenceType.quarterly, [
        done('b', DateTime(2026, 5, 1), due: DateTime(2026, 5, 1)),
        done('a', DateTime(2026, 1, 1)),
      ]);
      expect(timings['b']!.kind, TaskTimingKind.onTime);
    });
  });

  group('history with skips', () {
    TaskHistory history() => TaskHistory.from(
      detail.fixtureDetail(
        completions: [
          detail.fixtureCompletion(
            'c2',
            DateTime(2026, 7, 6),
            dueDate: DateTime(2026, 7, 6),
          ),
          detail.fixtureCompletion(
            'c1',
            DateTime(2026, 1, 5),
            dueDate: DateTime(2026, 1, 9),
          ),
        ],
        skips: [detail.fixtureSkip('s1', DateTime(2026, 4, 2), reason: 'Alex')],
      ),
      const {},
    );

    test('skips sit between the completions by date, newest first', () {
      expect(history().items.map((i) => i.runtimeType.toString()), [
        'CompletionLogItem',
        'SkipLogItem',
        'CompletionLogItem',
      ]);
    });

    test('the strip marks them oldest first', () {
      expect(history().marks, [
        HistoryMark.onTime,
        HistoryMark.skipped,
        HistoryMark.onTime,
      ]);
    });

    test('skips are not counted as times it was done', () {
      expect(history().count, 2);
      expect(history().isEmpty, isFalse);
    });

    test('only skips still make a history', () {
      final h = TaskHistory.from(
        detail.fixtureDetail(
          completions: const [],
          skips: [detail.fixtureSkip('s1', DateTime(2026, 4, 2))],
        ),
        const {},
      );
      expect(h.isEmpty, isFalse);
      expect(h.marks, [HistoryMark.skipped]);
    });
  });

  group('Add a task payload', () {
    final furnace = form.kLinkOptions.first;

    Map<String, dynamic> fields(TaskDraft d) =>
        d.toFields(today: form.kToday, category: 'hvac', editing: false);

    test('the estimate is saved as a number, rounded to cents', () {
      final d = const TaskDraft().copyWith(
        name: 'x',
        link: furnace,
        cost: '25.506',
      );
      expect(fields(d)['estimated_cost'], 25.51);
      expect(fields(d.copyWith(cost: '25'))['estimated_cost'], 25.0);
    });

    test('an empty estimate saves null so editing can clear it', () {
      final d = const TaskDraft().copyWith(name: 'x', link: furnace);
      expect(fields(d)['estimated_cost'], isNull);
    });

    test('a bad estimate blocks saving instead of being dropped', () {
      for (final bad in [r'$25', 'abc', '-5', 'NaN', 'Infinity', '1e12']) {
        final d = const TaskDraft().copyWith(
          name: 'x',
          link: furnace,
          cost: bad,
        );
        expect(d.costError, isNotNull, reason: bad);
        expect(d.isReady, isFalse, reason: bad);
      }
    });

    test(
      'the notes go to the notes column and leave the description alone',
      () {
        final d = const TaskDraft().copyWith(
          name: 'x',
          link: furnace,
          notes: ' Spares on the shelf ',
        );
        final f = fields(d);
        expect(f['notes'], 'Spares on the shelf');
        expect(f.containsKey('description'), isFalse);
      },
    );

    test('every few years saves annual plus the slider value', () {
      final d = const TaskDraft().copyWith(
        name: 'x',
        link: furnace,
        frequency: TaskFrequency.everyFewYears,
        years: 5,
      );
      final f = fields(d);
      expect(f['recurrence'], 'annual');
      expect(f['recurrence_interval_years'], 5);
    });

    test(
      'every other frequency saves no interval, even after a slider move',
      () {
        for (final freq in TaskFrequency.values.where(
          (f) => f != TaskFrequency.everyFewYears,
        )) {
          final d = const TaskDraft().copyWith(
            name: 'x',
            link: furnace,
            frequency: freq,
            years: 7,
          );
          expect(
            fields(d)['recurrence_interval_years'],
            isNull,
            reason: '$freq',
          );
        }
      },
    );

    test('editing loads the estimate, notes and years back', () {
      final d = TaskDraft.fromTask(
        form.savedTask(
          recurrence: RecurrenceType.annual,
          intervalYears: 4,
          estimatedCost: 25.5,
          notes: 'Behind the grille',
        ),
        link: furnace,
      );
      expect(d.frequency, TaskFrequency.everyFewYears);
      expect(d.years, 4);
      expect(d.cost, '25.50');
      expect(d.notes, 'Behind the grille');
      expect(
        TaskDraft.fromTask(
          form.savedTask(estimatedCost: 25),
          link: furnace,
        ).cost,
        '25',
      );
    });

    test('an annual task with no interval reads as every year', () {
      final d = TaskDraft.fromTask(
        form.savedTask(recurrence: RecurrenceType.annual),
        link: furnace,
      );
      expect(d.frequency, TaskFrequency.yearly);
      expect(d.years, YearsRange.initial);
    });

    test('a saved interval outside the slider is pulled inside it', () {
      final d = TaskDraft.fromTask(
        form.savedTask(recurrence: RecurrenceType.annual, intervalYears: 99),
        link: furnace,
      );
      expect(d.years, YearsRange.max);
    });
  });

  group('MaintenanceTasksNotifier writes', () {
    Future<(ProviderContainer, FakeMaintenanceTasksRepository)> open(
      List<MaintenanceTask> tasks, {
      bool failWrites = false,
    }) async {
      final repo = FakeMaintenanceTasksRepository(tasks);
      final container = ProviderContainer(overrides: tasksOverrides(repo));
      addTearDown(container.dispose);
      container.listen(maintenanceTasksProvider, (_, _) {});
      await container.read(maintenanceTasksProvider.future);
      return (container, repo);
    }

    test('marking done writes the occurrence it answered', () async {
      final (c, repo) = await open(kitTasks());
      final notifier = c.read(maintenanceTasksProvider.notifier);
      final previous = notifier.markDoneLocally('hvac', on: kToday)!;
      await notifier.commitDone(previous, QuickCompletion(completedOn: kToday));
      expect(repo.completions.single.dueDate, day(10, 7));
    });

    test(
      'an every-3-years task is due three years after the day it was done',
      () async {
        final (c, repo) = await open([
          task(
            'wh',
            'Flush water heater',
            due: day(10, 7),
            recurrence: RecurrenceType.annual,
            intervalYears: 3,
          ),
        ]);
        final notifier = c.read(maintenanceTasksProvider.notifier);
        final previous = notifier.markDoneLocally('wh', on: kToday)!;
        await notifier.commitDone(
          previous,
          QuickCompletion(completedOn: kToday),
        );
        expect(repo.updates.single['due_date'], '2029-10-04');
        expect(repo.updates.single['status'], 'scheduled');
      },
    );

    test('skipping logs the skipped occurrence and its reason', () async {
      final (c, repo) = await open(kitTasks());
      final notifier = c.read(maintenanceTasksProvider.notifier);
      final undo = await notifier.skipTask('hvac', reason: 'Alex was away');
      expect(repo.skips.single.taskId, 'hvac');
      expect(repo.skips.single.due, day(10, 7));
      expect(repo.skips.single.reason, 'Alex was away');
      expect(undo!.skipId, repo.skips.single.id);
      // The schedule moved to the next date as before.
      expect(repo.updates.single['due_date'], '2027-01-07');
    });

    test('Undo deletes the skip row and puts the date back', () async {
      final (c, repo) = await open(kitTasks());
      final notifier = c.read(maintenanceTasksProvider.notifier);
      final undo = await notifier.skipTask('hvac');
      await notifier.undo(undo!);
      expect(repo.deletedSkips, [undo.skipId]);
      expect(repo.updates.last['due_date'], '2026-10-07');
    });

    test('a one-time task skipped is logged too', () async {
      final (c, repo) = await open(kitTasks());
      await c.read(maintenanceTasksProvider.notifier).skipTask('smoke');
      expect(repo.skips.single.taskId, 'smoke');
      expect(repo.updates.single['status'], 'skipped');
    });

    test('if the schedule write fails the skip row is taken back', () async {
      final (c, repo) = await open(kitTasks());
      final notifier = c.read(maintenanceTasksProvider.notifier);
      // Let the skip insert through, then fail the task update.
      repo.failUpdates = true;
      await expectLater(notifier.skipTask('hvac'), throwsStateError);
      expect(repo.skips, hasLength(1));
      expect(repo.deletedSkips, [repo.skips.single.id]);
    });

    test('stopping reminders stamps when and why', () async {
      final (c, repo) = await open(kitTasks());
      final before = DateTime.now().toUtc();
      await c
          .read(maintenanceTasksProvider.notifier)
          .stopReminders('hvac', reason: 'Doesn’t apply to my home');
      final u = repo.updates.single;
      expect(u['notifications_enabled'], false);
      expect(u['notifications_off_reason'], 'Doesn’t apply to my home');
      final at = DateTime.parse(u['notifications_off_at'] as String);
      expect(at.isUtc, isTrue);
      expect(at.isBefore(before.subtract(const Duration(seconds: 1))), isFalse);
    });

    test('stopping without a reason keeps the reason empty', () async {
      final (c, repo) = await open(kitTasks());
      await c.read(maintenanceTasksProvider.notifier).stopReminders('hvac');
      expect(repo.updates.single['notifications_off_reason'], isNull);
      expect(repo.updates.single['notifications_off_at'], isNotNull);
    });

    test('Undo of stopping turns it on and clears when and why', () async {
      final (c, repo) = await open(kitTasks());
      final notifier = c.read(maintenanceTasksProvider.notifier);
      final undo = await notifier.stopReminders(
        'hvac',
        reason: 'No humidifier',
      );
      await notifier.undo(undo!);
      final u = repo.updates.last;
      expect(u['notifications_enabled'], true);
      expect(u['notifications_off_at'], isNull);
      expect(u['notifications_off_reason'], isNull);
    });

    test('changing how often drops an every-N-years interval', () async {
      final (c, repo) = await open([
        task(
          'wh',
          'Flush water heater',
          due: day(11, 1),
          recurrence: RecurrenceType.annual,
          intervalYears: 3,
        ),
      ]);
      final notifier = c.read(maintenanceTasksProvider.notifier);
      final undo = await notifier.changeFrequency(
        'wh',
        RecurrenceType.quarterly,
      );
      expect(repo.updates.single['recurrence'], 'quarterly');
      expect(repo.updates.single['recurrence_interval_years'], isNull);
      await notifier.undo(undo!);
      expect(repo.updates.last['recurrence'], 'annual');
      expect(repo.updates.last['recurrence_interval_years'], 3);
    });

    test('an unrelated action keeps the interval it already had', () async {
      final (c, repo) = await open([
        task(
          'wh',
          'Flush water heater',
          due: day(11, 1),
          recurrence: RecurrenceType.annual,
          intervalYears: 3,
        ),
      ]);
      await c
          .read(maintenanceTasksProvider.notifier)
          .pushBack('wh', day(11, 20));
      expect(repo.updates.single['recurrence_interval_years'], 3);
    });
  });
}
