import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/widgets/aurora/aurora_button.dart';
import 'package:keystona/features/maintenance/models/maintenance_task.dart';
import 'package:keystona/features/maintenance/models/task_parent.dart';
import 'package:keystona/features/maintenance/screens/task_detail_screen.dart';
import 'package:keystona/features/maintenance/widgets/detail/task_detail_skeleton.dart';
import 'package:keystona/features/maintenance/widgets/detail/task_due_card.dart';
import 'package:keystona/features/maintenance/widgets/detail/task_parent_card.dart';

import 'task_detail_test_support.dart';

const double _screenW = 390;

/// Right-edge distance of [text] from the screen edge.
double _fromRight(WidgetTester t, Finder f) => _screenW - t.getRect(f).right;

void main() {
  group('open task', () {
    testWidgets('shows the kit copy in order', (t) async {
      await pumpTasks(t, FakeTaskDetailRepository(fixtureDetail()));

      for (final s in [
        'Replace HVAC air filter',
        'HVAC · EVERY 3 MONTHS',
        'DUE IN 3 DAYS',
        'A clogged filter makes the furnace work harder.',
        'Mark done',
        'Not now',
        'Done — add cost, photos or a receipt',
        'FOR',
        'Furnace',
        'NF95-080B · BASEMENT',
        'HEALTHY',
        'TIME',
        '15 min',
        'LEVEL',
        'Easy',
        'WHO',
        'You',
        'HOW TO DO IT',
        'Set the thermostat to Off so the blower stops.',
        'Slide the old filter out of the slot.',
        "YOU'LL NEED",
        'SUPPLIES',
        '16 × 25 × 1 · MERV 8',
        'TOOLS',
        'A marker',
        'HISTORY · 3',
        'ON TIME 2 OF 2',
        'SCHEDULE',
        'REPEATS',
        'Every 3 months',
        'NEXT AFTER THIS',
        'REMINDER',
        '1 week before',
        'ADDED',
        'Suggested for the furnace',
        'Delete this task',
      ]) {
        expect(find.text(s), findsWidgets, reason: s);
      }
      // The numbering is drawn by the layout, not the text.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('the due card says when and that the reminder went out', (
      t,
    ) async {
      await pumpTasks(t, FakeTaskDetailRepository(fixtureDetail()));
      expect(find.textContaining('Due '), findsWidgets);
      expect(
        find.textContaining('IN 3 DAYS · REMINDER WENT OUT'),
        findsOneWidget,
      );
    });

    testWidgets('top bar: back at the left, Edit at the right edge', (t) async {
      await pumpTasks(t, FakeTaskDetailRepository(fixtureDetail()));
      expect(t.getRect(find.text('Tasks')).left, lessThan(60));
      // 16 pt page padding plus the 44 pt target around the word.
      expect(_fromRight(t, find.text('Edit')), closeTo(16, 1));
    });

    testWidgets(
      'Mark done is the wide button at the left, Not now at the right',
      (t) async {
        await pumpTasks(t, FakeTaskDetailRepository(fixtureDetail()));
        final card = t.getRect(find.byType(TaskDueCard));
        final mark = t.getRect(find.text('Mark done'));
        final notNow = t.getRect(find.text('Not now'));
        expect(mark.left, greaterThan(card.left));
        expect(mark.center.dx, lessThan(notNow.center.dx));
        // Not now's pill ends at the card padding.
        // Card padding + both borders + the pill's own padding.
        expect(card.right - notNow.right, closeTo(16 + 1.5 + 1.5 + 18, 1));
        // Mark done takes the room Not now leaves (the test font is wide, so
        // compare the two pills rather than a fraction of the card).
        final markPill = t.getRect(
          find.ancestor(
            of: find.text('Mark done'),
            matching: find.byType(PrimaryButton),
          ),
        );
        final notNowPill = t.getRect(find.byType(SecondaryButton));
        expect(markPill.width, greaterThan(notNowPill.width));
        expect(markPill.right, lessThan(notNowPill.left));
      },
    );

    testWidgets('the parent card: health pill and chevron sit at the right', (
      t,
    ) async {
      await pumpTasks(t, FakeTaskDetailRepository(fixtureDetail()));
      final card = t.getRect(find.byType(TaskParentCard));
      final pill = t.getRect(find.text('HEALTHY'));
      final chevron = t.getRect(
        find.descendant(
          of: find.byType(TaskParentCard),
          matching: find.byIcon(Icons.chevron_right),
        ),
      );
      expect(card.right - chevron.right, lessThan(16));
      expect(chevron.left, greaterThan(pill.right));
      expect(t.getRect(find.text('Furnace')).left, lessThan(card.left + 70));
    });

    testWidgets('spec tiles share the row equally', (t) async {
      await pumpTasks(t, FakeTaskDetailRepository(fixtureDetail()));
      final a = t.getRect(find.text('TIME')).left;
      final b = t.getRect(find.text('LEVEL')).left;
      final c = t.getRect(find.text('WHO')).left;
      expect((b - a - (c - b)).abs(), lessThan(1));
      expect(t.getRect(find.text('WHO')).left, greaterThan(_screenW / 2));
    });

    testWidgets('fact values sit at the right edge of their card', (t) async {
      await pumpTasks(t, FakeTaskDetailRepository(fixtureDetail()));
      final value = find.text('Every 3 months');
      // Card padding 14 plus page padding 16, and a 1 pt border.
      expect(_fromRight(t, value), closeTo(16 + 1 + 14, 1.5));
    });

    testWidgets('history amounts sit at the right edge of the timeline card', (
      t,
    ) async {
      await pumpTasks(t, FakeTaskDetailRepository(fixtureDetail()));
      final amount = find.text(r'$22').first;
      await t.ensureVisible(amount);
      await t.pumpAndSettle();
      expect(_fromRight(t, amount), closeTo(16 + 1 + 14, 1.5));
      // Dates and "Done" stay at the left, next to the dot.
      expect(t.getRect(find.text('Done').first).left, lessThan(80));
    });

    testWidgets('Delete this task is centered', (t) async {
      await pumpTasks(t, FakeTaskDetailRepository(fixtureDetail()));
      final del = find.text('Delete this task');
      await t.ensureVisible(del);
      await t.pumpAndSettle();
      expect(t.getRect(del).center.dx, closeTo(_screenW / 2, 2));
    });

    testWidgets('overdue is coral and says how late', (t) async {
      final repo = FakeTaskDetailRepository(
        fixtureDetail(task: fixtureTask(due: daysFromToday(-3))),
      );
      await pumpTasks(t, repo);
      expect(find.text('3 DAYS OVERDUE'), findsOneWidget);
      expect(find.textContaining('3 DAYS AGO'), findsOneWidget);
    });

    testWidgets('a one-time task has no next-after-this row', (t) async {
      final repo = FakeTaskDetailRepository(
        fixtureDetail(
          task: fixtureTask(recurrence: RecurrenceType.none),
          completions: const [],
        ),
      );
      await pumpTasks(t, repo);
      expect(find.text('One time'), findsWidgets);
      expect(find.text('NEXT AFTER THIS'), findsNothing);
      expect(find.text('Nothing logged yet.'), findsOneWidget);
      expect(find.text('HISTORY · 0'), findsOneWidget);
    });

    testWidgets('an area has no page: no chevron on the parent card', (
      t,
    ) async {
      final repo = FakeTaskDetailRepository(
        fixtureDetail(
          parent: const TaskParent(kind: TaskParentKind.area, name: 'Safety'),
        ),
      );
      await pumpTasks(t, repo);
      expect(find.text('Safety'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TaskParentCard),
          matching: find.byIcon(Icons.chevron_right),
        ),
        findsNothing,
      );
    });

    testWidgets('without steps, supplies or tools those sections are gone', (
      t,
    ) async {
      final repo = FakeTaskDetailRepository(
        fixtureDetail(
          task: fixtureTask(instructions: null, supplies: [], tools: []),
        ),
      );
      await pumpTasks(t, repo);
      expect(find.text('HOW TO DO IT'), findsNothing);
      expect(find.text("YOU'LL NEED"), findsNothing);
    });
  });

  group('done and skipped', () {
    testWidgets(
      'done today shows the lime card, the pill and when it is next',
      (t) async {
        final repo = FakeTaskDetailRepository(
          fixtureDetail(
            task: fixtureTask(due: daysFromToday(90)),
            completions: [
              fixtureCompletion('x', today),
              ...fixtureCompletions(),
            ],
          ),
        );
        await pumpTasks(t, repo);
        expect(find.text('DONE TODAY'), findsOneWidget);
        expect(find.textContaining('Done today'), findsWidgets);
        expect(find.textContaining('NEXT ONE IS DUE'), findsOneWidget);
        expect(find.text('Mark done'), findsNothing);
        // Reopened: nothing to undo from here.
        expect(find.text('Undo'), findsNothing);
      },
    );

    testWidgets('a skipped one-time task shows the reason and no actions', (
      t,
    ) async {
      final repo = FakeTaskDetailRepository(
        fixtureDetail(
          task: fixtureTask(
            recurrence: RecurrenceType.none,
            status: TaskStatus.skipped,
            skipReason: 'Alex was traveling',
          ),
          completions: const [],
        ),
      );
      await pumpTasks(t, repo);
      expect(find.text('Skipped'), findsOneWidget);
      expect(find.text('ALEX WAS TRAVELING'), findsOneWidget);
      expect(find.text('Mark done'), findsNothing);
    });
  });

  group('states', () {
    testWidgets('loading shows the skeleton with the back link', (t) async {
      final gate = Completer<void>();
      final repo = FakeTaskDetailRepository(fixtureDetail(), fetchGate: gate);
      usePhone(t);
      await t.pumpWidget(
        ProviderScope(
          overrides: taskOverrides(repo),
          child: const MaterialApp(home: TaskDetailScreen(taskId: 't1')),
        ),
      );
      await t.pump();
      expect(find.byType(TaskDetailSkeleton), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);

      gate.complete();
      await t.pumpAndSettle();
      expect(find.byType(TaskDetailSkeleton), findsNothing);
      expect(find.text('Replace HVAC air filter'), findsOneWidget);
    });

    testWidgets('error shows a message and retry brings the task back', (
      t,
    ) async {
      final repo = FakeTaskDetailRepository(fixtureDetail(), failFetch: true);
      await pumpTasks(t, repo);
      expect(find.text("Couldn't load this task."), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);

      repo.failFetch = false;
      await t.tap(find.text('Try again'));
      await t.pumpAndSettle();
      expect(find.text('Replace HVAC air filter'), findsOneWidget);
    });
  });

  group('navigation and actions', () {
    testWidgets('Edit opens the form', (t) async {
      await pumpTasks(t, FakeTaskDetailRepository(fixtureDetail()));
      await t.tap(find.text('Edit'));
      await t.pumpAndSettle();
      expect(find.text('EDIT PAGE'), findsOneWidget);
    });

    testWidgets('the parent card opens the system', (t) async {
      await pumpTasks(t, FakeTaskDetailRepository(fixtureDetail()));
      await t.tap(find.text('Furnace'));
      await t.pumpAndSettle();
      expect(find.text('SYSTEM PAGE'), findsOneWidget);
    });

    testWidgets('the history card opens the full history', (t) async {
      await pumpTasks(t, FakeTaskDetailRepository(fixtureDetail()));
      final label = find.text('HISTORY · 3');
      await t.ensureVisible(label);
      await t.pumpAndSettle();
      await t.tap(find.text(r'$22').first);
      await t.pumpAndSettle();
      expect(find.text('LOG'), findsOneWidget);
      expect(find.textContaining('HISTORY · FURNACE'), findsOneWidget);
    });

    testWidgets('back returns to the Tasks tab', (t) async {
      await pumpTasks(t, FakeTaskDetailRepository(fixtureDetail()));
      await t.tap(find.text('Tasks'));
      await t.pumpAndSettle();
      expect(find.text('TASKS TAB'), findsOneWidget);
    });

    testWidgets('logging details saves, offers Undo and opens the history', (
      t,
    ) async {
      final repo = FakeTaskDetailRepository(fixtureDetail());
      await pumpTasks(t, repo);
      await t.tap(find.text('Done — add cost, photos or a receipt'));
      await t.pumpAndSettle();
      expect(find.text('Log the details'), findsOneWidget);

      await t.tap(find.text('Save'));
      await t.pumpAndSettle();

      expect(repo.inserted, hasLength(1));
      // Save went to the history, with the Undo snackbar over it.
      expect(find.textContaining('HISTORY · FURNACE'), findsOneWidget);
      expect(find.text('Done and logged'), findsOneWidget);
      expect(find.textContaining('Next one is due'), findsOneWidget);

      await t.tap(find.text('Undo'));
      await t.pumpAndSettle();
      expect(repo.deletedCompletions, ['new-1']);
    });

    testWidgets('Mark done refreshes the task and offers an inline Undo', (
      t,
    ) async {
      final repo = FakeTaskDetailRepository(fixtureDetail());
      await pumpTasks(t, repo);
      final oldDue = repo.detail.task.dueDate;
      // What the database holds once quick-done has run.
      repo.detail = repo.detail.copyWith(
        task: repo.detail.task.copyWith(dueDate: daysFromToday(90)),
        completions: [
          fixtureCompletion('x', today),
          ...repo.detail.completions,
        ],
      );

      await t.tap(find.text('Mark done'));
      await t.pumpAndSettle();

      expect(find.text('Done today, 3 days early'), findsOneWidget);
      expect(find.text('DONE TODAY'), findsOneWidget);
      expect(find.text('Mark done'), findsNothing);
      // The Undo link sits at the right edge of the done card.
      expect(_fromRight(t, find.text('Undo')), closeTo(16 + 1.5 + 16, 1.5));

      await t.tap(find.text('Undo'));
      await t.pumpAndSettle();

      expect(repo.deletedCompletions, ['x']);
      expect(repo.schedules.last.due, oldDue);
      expect(find.text('Mark done'), findsOneWidget);
      expect(find.text('Undo'), findsNothing);
    });

    testWidgets('delete asks first, then removes the task', (t) async {
      final repo = FakeTaskDetailRepository(fixtureDetail());
      await pumpTasks(t, repo);
      final del = find.text('Delete this task');
      await t.ensureVisible(del);
      await t.pumpAndSettle();
      await t.tap(del);
      await t.pumpAndSettle();
      expect(find.text('Delete this task?'), findsOneWidget);
      expect(repo.deletedTasks, isEmpty);

      await t.tap(find.text('Delete task'));
      await t.pumpAndSettle();
      expect(repo.deletedTasks, ['t1']);
      expect(find.text('Task deleted'), findsOneWidget);
      expect(find.text('TASKS TAB'), findsOneWidget);
    });

    testWidgets('cancelling the delete keeps the task', (t) async {
      final repo = FakeTaskDetailRepository(fixtureDetail());
      await pumpTasks(t, repo);
      final del = find.text('Delete this task');
      await t.ensureVisible(del);
      await t.pumpAndSettle();
      await t.tap(del);
      await t.pumpAndSettle();
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(repo.deletedTasks, isEmpty);
      expect(find.text('Replace HVAC air filter'), findsOneWidget);
    });
  });

  group('responsive', () {
    testResponsiveLoaded(
      'detail, open',
      () => const TaskDetailScreen(taskId: 't1'),
      () => FakeTaskDetailRepository(fixtureDetail()),
      expectText: 'Mark done',
    );

    testResponsiveLoaded(
      'detail, overdue with long copy',
      () => const TaskDetailScreen(taskId: 't1'),
      () => FakeTaskDetailRepository(
        fixtureDetail(
          task: fixtureTask(
            due: daysFromToday(-12),
            name:
                'Have the whole-house humidifier serviced and descaled by a licensed pro',
            description:
                'Mineral build-up makes the unit work harder and can shorten the life of the whole system if it is left for a season.',
            supplies: [
              'Descaling solution, one bottle per unit',
              'Replacement pad',
            ],
            tools: ['Soft brush', 'Bucket', 'Adjustable wrench'],
          ),
          parent: const TaskParent(
            kind: TaskParentKind.appliance,
            id: 'a1',
            name: 'Whole-house humidifier with the long name',
            model: 'HE360A1075 · UTILITY ROOM',
            health: TaskParentHealth.endOfLife,
          ),
        ),
      ),
      expectText: 'OVERDUE',
    );

    testResponsiveLoaded(
      'detail, done today',
      () => const TaskDetailScreen(taskId: 't1'),
      () => FakeTaskDetailRepository(
        fixtureDetail(
          task: fixtureTask(due: daysFromToday(90)),
          completions: [fixtureCompletion('x', today), ...fixtureCompletions()],
        ),
      ),
      expectText: 'Done today',
    );
  });
}
