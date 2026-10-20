import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/maintenance/screens/maintenance_screen.dart';
import 'package:keystona/features/maintenance/widgets/actions/done/quick_done_body.dart';
import 'package:keystona/features/maintenance/widgets/tasks_tab/task_check_button.dart';

import 'tasks_test_support.dart';

Future<FakeMaintenanceTasksRepository> _load(
  WidgetTester tester, {
  List<String>? visited,
  bool phone = false,
}) async {
  final repo = FakeMaintenanceTasksRepository(kitTasks());
  phone ? phoneSurface(tester) : tallSurface(tester);
  await tester.pumpWidget(
    RoutedApp(
      home: const MaintenanceScreen(),
      overrides: tasksOverrides(repo),
      visited: visited,
    ),
  );
  await settle(tester);
  return repo;
}

Finder _checkOf(String id) => find.bySemanticsLabel(
  'Mark done: ${kitTasks().firstWhere((t) => t.id == id).name}',
);

Future<void> _longPress(WidgetTester tester, String name) async {
  await tester.longPress(find.text(name));
  await settle(tester);
}

void main() {
  group('Quick mark-done (TaskDoneQuick)', () {
    testWidgets('opens the sheet with the kit copy and Undo / Save', (
      tester,
    ) async {
      await _load(tester);
      await tapAndSettle(tester, _checkOf('hvac'));
      expect(find.text('Nice — it’s done'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('WHEN'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('Pick a day'), findsOneWidget);
      expect(find.text('WHO DID IT'), findsOneWidget);
      expect(find.text('Me'), findsOneWidget);
      expect(find.text('A pro'), findsOneWidget);
      expect(find.text('COST'), findsOneWidget);
      expect(find.text('QUICK NOTE'), findsOneWidget);
      expect(find.text('Add photos, a receipt or more'), findsOneWidget);
      expect(find.text('DONE · NEXT ONE JAN 4, 2027'), findsOneWidget);
    });

    testWidgets('Undo in the sheet writes nothing and restores the row', (
      tester,
    ) async {
      final repo = await _load(tester);
      await tapAndSettle(tester, _checkOf('hvac'));
      await tapAndSettle(tester, find.text('Undo'));
      expect(find.text('Nice — it’s done'), findsNothing);
      expect(repo.calls, isEmpty);
      expect(find.text('Replace HVAC air filter'), findsOneWidget);
    });

    testWidgets('Save logs the day, who and cost and schedules the next', (
      tester,
    ) async {
      final repo = await _load(tester);
      await tapAndSettle(tester, _checkOf('hvac'));
      await tapAndSettle(tester, find.text('Yesterday'));
      await tapAndSettle(tester, find.text('A pro'));
      final fields = find.descendant(
        of: find.byType(QuickDoneBody),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.first, r'$22.50');
      await tester.enterText(fields.last, 'new filter');
      await tapAndSettle(tester, find.text('Save'));

      final completion = repo.completions.single;
      expect(completion.completedOn, day(10, 3));
      expect(completion.byPro, isTrue);
      expect(completion.cost, 22.5);
      expect(completion.note, 'new filter');
      // Quarterly from the completion day.
      expect(repo.updates.single['due_date'], '2027-01-03');
      expect(repo.updates.single['status'], 'scheduled');
      expect(find.text('Replace HVAC air filter done'), findsOneWidget);
      expect(find.text('Replace HVAC air filter'), findsNothing);
    });

    testWidgets('dismissing the sheet keeps it done with defaults', (
      tester,
    ) async {
      final repo = await _load(tester);
      await tapAndSettle(tester, _checkOf('hvac'));
      await tester.tapAt(const Offset(20, 20));
      await settle(tester);
      expect(repo.completions.single.completedOn, kToday);
      expect(repo.completions.single.byPro, isFalse);
    });

    testWidgets('the snackbar Undo deletes the completion and restores it', (
      tester,
    ) async {
      final repo = await _load(tester);
      await tapAndSettle(tester, _checkOf('hvac'));
      await tapAndSettle(tester, find.text('Save'));
      await tapAndSettle(tester, find.text('Undo'));
      expect(repo.calls, contains('delete:c1'));
      expect(repo.updates.last['due_date'], '2026-10-07');
      expect(find.text('Replace HVAC air filter'), findsOneWidget);
    });

    testWidgets('finishing the overdue task shows "nothing overdue" + Undo', (
      tester,
    ) async {
      final repo = await _load(tester);
      await tapAndSettle(tester, find.text('Mark done'));
      await tapAndSettle(tester, find.text('Save'));
      expect(repo.completions, hasLength(1));
      expect(find.text('OVERDUE'), findsNothing);
      expect(
        find.text('Clean gutters & downspouts done — nothing overdue'),
        findsOneWidget,
      );
    });

    testWidgets('Add photos goes to the full log and writes nothing', (
      tester,
    ) async {
      final visited = <String>[];
      final repo = await _load(tester, visited: visited);
      await tapAndSettle(tester, _checkOf('hvac'));
      await tapAndSettle(tester, find.text('Add photos, a receipt or more'));
      expect(visited, ['/maintenance/complete/hvac']);
      expect(repo.calls, isEmpty);
    });

    testWidgets('sheet buttons: Undo at the left, Save at the right', (
      tester,
    ) async {
      await _load(tester, phone: true);
      await tapAndSettle(tester, _checkOf('hvac'));
      final undo = tester.getRect(find.text('Undo'));
      final title = tester.getRect(find.text('Nice — it’s done'));
      final save = tester.getRect(find.text('Save'));
      expect(undo.right, lessThan(title.left));
      expect(save.left, greaterThan(title.right));
      expect(390 - save.right, lessThan(40));
      expect(undo.left, lessThan(40));
    });
  });

  group('Long-press menu (TaskMenu)', () {
    testWidgets('opens four stacked choices and a close hint', (tester) async {
      await _load(tester);
      await _longPress(tester, 'Replace HVAC air filter');
      final skip = tester.getRect(find.text('Skip this time'));
      final often = tester.getRect(find.text('Change how often'));
      final open = tester.getRect(find.text('Open the task'));
      final stop = tester.getRect(find.text('Stop reminding me'));
      expect(skip.top, lessThan(often.top));
      expect(often.top, lessThan(open.top));
      expect(open.top, lessThan(stop.top));
      expect(skip.left, closeTo(often.left, 1));
      expect(stop.left, closeTo(open.left, 1));
      expect(find.text('TAP ANYWHERE TO CLOSE'), findsOneWidget);
      expect(
        find.text('Comes back in January. Your score won’t drop.'),
        findsOneWidget,
      );
      expect(
        find.text('For this home. Undo any time in Around the house.'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('tapping outside closes it', (tester) async {
      final repo = await _load(tester);
      await _longPress(tester, 'Replace HVAC air filter');
      await tester.tapAt(const Offset(5, 5));
      await settle(tester);
      expect(find.text('Skip this time'), findsNothing);
      expect(repo.calls, isEmpty);
    });

    testWidgets('Skip this time skips with an Undo', (tester) async {
      final repo = await _load(tester);
      await _longPress(tester, 'Replace HVAC air filter');
      await tapAndSettle(tester, find.text('Skip this time'));
      expect(repo.updates.single['due_date'], '2027-01-07');
      expect(find.text('Skipped — see you in January'), findsOneWidget);
      expect(
        find.text('Your Home Health score didn’t change.'),
        findsOneWidget,
      );
      await tapAndSettle(tester, find.text('Undo'));
      expect(repo.updates.last['due_date'], '2026-10-07');
    });

    testWidgets('Change how often shows three chips and applies one', (
      tester,
    ) async {
      final repo = await _load(tester);
      await _longPress(tester, 'Replace HVAC air filter');
      await tapAndSettle(tester, find.text('Change how often'));
      final chips = [
        tester.getRect(find.text('Every 3 mo')),
        tester.getRect(find.text('Twice a year')),
        tester.getRect(find.text('Yearly')),
      ];
      expect(chips[0].left, lessThan(chips[1].left));
      expect(chips[1].left, lessThan(chips[2].left));
      expect(chips[0].center.dy, closeTo(chips[2].center.dy, 1));
      await tapAndSettle(tester, find.text('Yearly'));
      expect(repo.updates.single['recurrence'], 'annual');
      expect(find.text('Replace HVAC air filter: every year'), findsOneWidget);
    });

    testWidgets('Stop reminding me hides the task with an Undo', (
      tester,
    ) async {
      final repo = await _load(tester);
      await _longPress(tester, 'Replace HVAC air filter');
      await tapAndSettle(tester, find.text('Stop reminding me'));
      expect(repo.updates.single['notifications_enabled'], false);
      expect(find.text('Replace HVAC air filter'), findsNothing);
      await tapAndSettle(tester, find.text('Undo'));
      expect(find.text('Replace HVAC air filter'), findsOneWidget);
    });

    testWidgets('Open the task goes to its detail', (tester) async {
      final visited = <String>[];
      await _load(tester, visited: visited);
      await _longPress(tester, 'Replace HVAC air filter');
      await tapAndSettle(tester, find.text('Open the task'));
      expect(visited, ['/maintenance/hvac']);
    });

    testWidgets('the lifted card shows the task and how overdue it is', (
      tester,
    ) async {
      await _load(tester);
      await _longPress(tester, 'Clean gutters & downspouts');
      expect(find.text('6 DAYS OVERDUE'), findsOneWidget);
      expect(find.text('EXTERIOR · TWICE A YEAR'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
    });
  });

  group('Not now? (TaskSkip)', () {
    Future<FakeMaintenanceTasksRepository> openSheet(
      WidgetTester tester,
    ) async {
      final repo = await _load(tester);
      await tapAndSettle(tester, find.text('Snooze'));
      return repo;
    }

    testWidgets('shows the four reasons and the default result', (
      tester,
    ) async {
      await openSheet(tester);
      expect(find.text('Not now?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('I’ll do it later'), findsOneWidget);
      expect(find.text('Someone else did it'), findsOneWidget);
      expect(find.text('Doesn’t apply to my home'), findsOneWidget);
      expect(find.text('Just skip this one'), findsOneWidget);
      expect(find.text('REMIND ME'), findsOneWidget);
      expect(find.text('1 week'), findsOneWidget);
      expect(find.text('Push it back'), findsOneWidget);
      expect(
        find.textContaining('Moves to next Sunday, Oct 11.'),
        findsOneWidget,
      );
    });

    testWidgets('reason cards stack and the button spans the sheet', (
      tester,
    ) async {
      phoneSurface(tester);
      await tester.pumpWidget(
        RoutedApp(
          home: const MaintenanceScreen(),
          overrides: tasksOverrides(FakeMaintenanceTasksRepository(kitTasks())),
        ),
      );
      await settle(tester);
      await tapAndSettle(tester, find.text('Snooze'));
      final a = tester.getRect(find.text('I’ll do it later'));
      final b = tester.getRect(find.text('Someone else did it'));
      final c = tester.getRect(find.text('Doesn’t apply to my home'));
      final d = tester.getRect(find.text('Just skip this one'));
      expect(a.top, lessThan(b.top));
      expect(b.top, lessThan(c.top));
      expect(c.top, lessThan(d.top));
      expect(a.left, closeTo(d.left, 1));
      final button = tester.getRect(
        find
            .ancestor(
              of: find.text('Push it back'),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(button.width, greaterThan(300));
    });

    testWidgets('Push it back moves the due date and says so', (tester) async {
      final repo = await openSheet(tester);
      await tapAndSettle(tester, find.text('2 weeks'));
      await tapAndSettle(tester, find.text('Push it back'));
      expect(repo.updates.single['due_date'], '2026-10-18');
      expect(
        find.text('Pushed back: Clean gutters & downspouts'),
        findsOneWidget,
      );
    });

    testWidgets('Someone else did it logs a completion by a pro', (
      tester,
    ) async {
      final repo = await openSheet(tester);
      await tapAndSettle(tester, find.text('Someone else did it'));
      expect(find.text('WHO DID IT'), findsOneWidget);
      await tapAndSettle(tester, find.text('A pro'));
      await tapAndSettle(tester, find.text('Log it as done'));
      expect(repo.completions.single.byPro, isTrue);
      expect(repo.completions.single.completedOn, kToday);
    });

    testWidgets('Doesn’t apply turns the reminder off in coral', (
      tester,
    ) async {
      final repo = await openSheet(tester);
      await tapAndSettle(tester, find.text('Doesn’t apply to my home'));
      await tapAndSettle(tester, find.text('Stop reminding me'));
      expect(repo.updates.single['notifications_enabled'], false);
    });

    testWidgets('Just skip this one skips the occurrence', (tester) async {
      final repo = await openSheet(tester);
      await tapAndSettle(tester, find.text('Just skip this one'));
      await tapAndSettle(tester, find.text('Skip this one'));
      expect(repo.updates.single['skip_reason'], 'Just skip this one');
      expect(repo.updates.single['status'], 'scheduled');
    });

    testWidgets('Cancel closes without writing', (tester) async {
      final repo = await openSheet(tester);
      await tapAndSettle(tester, find.text('Cancel'));
      expect(find.text('Not now?'), findsNothing);
      expect(repo.calls, isEmpty);
      expect(find.text('Clean gutters & downspouts'), findsOneWidget);
    });
  });

  testWidgets('check buttons are the only completion control on a row', (
    tester,
  ) async {
    await _load(tester);
    expect(find.byType(TaskCheckButton), findsWidgets);
    expect(find.byIcon(Icons.more_horiz), findsNothing);
  });
}
