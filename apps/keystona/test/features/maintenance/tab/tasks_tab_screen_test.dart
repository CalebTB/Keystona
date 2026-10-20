import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/maintenance/screens/maintenance_screen.dart';
import 'package:keystona/features/maintenance/widgets/tasks_tab/task_check_button.dart';
import 'package:keystona/features/maintenance/widgets/tasks_tab/task_row_item.dart';
import 'package:keystona/features/maintenance/widgets/tasks_tab/tasks_skeleton.dart';

import 'tasks_test_support.dart';

Widget _app(FakeMaintenanceTasksRepository repo, {List<String>? visited}) =>
    RoutedApp(
      home: const MaintenanceScreen(),
      overrides: tasksOverrides(repo),
      visited: visited,
    );

Future<void> _load(
  WidgetTester tester,
  FakeMaintenanceTasksRepository repo, {
  List<String>? visited,
}) async {
  tallSurface(tester);
  await tester.pumpWidget(_app(repo, visited: visited));
  await settle(tester);
}

Finder _row(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(TaskRowItem));

void main() {
  group('Tasks tab states', () {
    testWidgets('shows the skeleton on the first frame', (tester) async {
      final gate = Completer<void>();
      final repo = FakeMaintenanceTasksRepository(kitTasks(), gate: gate);
      tallSurface(tester);
      await tester.pumpWidget(_app(repo));
      await tester.pump();
      expect(find.byType(TasksSkeleton), findsOneWidget);
      expect(find.text('Tasks'), findsNothing);
      gate.complete();
      await settle(tester);
      expect(find.byType(TasksSkeleton), findsNothing);
      expect(find.text('Tasks'), findsOneWidget);
    });

    testWidgets('shows an error with retry', (tester) async {
      final repo = FakeMaintenanceTasksRepository(kitTasks())
        ..failWith = StateError('down');
      await _load(tester, repo);
      expect(find.text('We couldn\'t load your tasks.'), findsOneWidget);
      repo.failWith = null;
      await tapAndSettle(tester, find.text('Try again'));
      expect(find.text('Clean gutters & downspouts'), findsOneWidget);
      expect(repo.loads, 2);
    });

    testWidgets('shows the kit copy for the populated tab', (tester) async {
      await _load(tester, FakeMaintenanceTasksRepository(kitTasks()));
      expect(find.text('OCTOBER · 6 OF 11 DONE'), findsOneWidget);
      expect(find.text('1 overdue · 1 due today'), findsOneWidget);
      expect(find.text('OVERDUE'), findsOneWidget);
      expect(find.text('6 DAYS LATE'), findsOneWidget);
      expect(find.text('Mark done'), findsOneWidget);
      expect(find.text('Snooze'), findsOneWidget);
      expect(find.text("Doesn't apply to my home"), findsOneWidget);
      expect(find.text('TODAY · 1'), findsOneWidget);
      expect(find.text('THIS WEEK · 1'), findsOneWidget);
      expect(find.text('LATER THIS MONTH · 2'), findsOneWidget);
      expect(find.text('EXTERIOR · 45 MIN · DIY OR PRO'), findsOneWidget);
      expect(find.text('PRO'), findsOneWidget);
      expect(find.text('OCT 7'), findsOneWidget);
      expect(find.textContaining('See all '), findsOneWidget);
      expect(find.text('4 tasks done this week'), findsOneWidget);
      // Long-press replaces the ⋯ button.
      expect(find.byIcon(Icons.more_horiz), findsNothing);
      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('says all caught up when nothing is overdue or due today', (
      tester,
    ) async {
      final tasks = kitTasks()
          .where((t) => t.id != 'gutters' && t.id != 'smoke')
          .toList();
      await _load(tester, FakeMaintenanceTasksRepository(tasks));
      expect(find.text("You're all caught up"), findsOneWidget);
      expect(find.text('Nothing due for 3 days'), findsOneWidget);
      expect(find.text('NEXT UP'), findsOneWidget);
      expect(find.text('See all upcoming'), findsOneWidget);
      expect(find.text('Replace HVAC air filter'), findsOneWidget);
      expect(find.text('OVERDUE'), findsNothing);
    });
  });

  group('Tasks tab layout positions', () {
    testWidgets('check circle at the left, date at the right edge', (
      tester,
    ) async {
      await _load(tester, FakeMaintenanceTasksRepository(kitTasks()));
      final row = tester.getRect(_row('Replace HVAC air filter'));
      final check = tester.getRect(
        find.descendant(
          of: _row('Replace HVAC air filter'),
          matching: find.byType(TaskCheckButton),
        ),
      );
      final title = tester.getRect(find.text('Replace HVAC air filter'));
      final date = tester.getRect(find.text('OCT 7'));
      expect(check.left - row.left, lessThan(60));
      expect(check.right, lessThan(title.left));
      expect(row.right - date.right, lessThan(30));
      expect(date.left, greaterThan(title.right));
    });

    testWidgets('PRO chip sits between the title and the date', (tester) async {
      await _load(tester, FakeMaintenanceTasksRepository(kitTasks()));
      final chip = tester.getRect(find.text('PRO'));
      final date = tester.getRect(find.text('OCT 25'));
      final title = tester.getRect(find.text('Inspect roof flashing'));
      expect(chip.left, greaterThan(title.right - 1));
      expect(chip.right, lessThan(date.left));
    });

    testWidgets('Mark done fills the card and Snooze sits at its right', (
      tester,
    ) async {
      await _load(tester, FakeMaintenanceTasksRepository(kitTasks()));
      final done = tester.getRect(find.text('Mark done'));
      final snooze = tester.getRect(find.text('Snooze'));
      final title = tester.getRect(find.text('Clean gutters & downspouts'));
      expect(done.left, lessThan(snooze.left));
      expect(snooze.right, greaterThan(title.left + 100));
      expect(done.center.dy, closeTo(snooze.center.dy, 4));
    });

    testWidgets('every row check circle is a 44 pt touch target', (
      tester,
    ) async {
      await _load(tester, FakeMaintenanceTasksRepository(kitTasks()));
      final buttons = find.bySemanticsLabel(RegExp('^Mark done: '));
      expect(buttons, findsWidgets);
      for (final element in buttons.evaluate()) {
        final size = tester.getSize(find.byWidget(element.widget));
        expect(size.width, greaterThanOrEqualTo(44));
        expect(size.height, greaterThanOrEqualTo(44));
      }
    });
  });

  group('Tasks tab actions', () {
    testWidgets('add opens the new task form, See all opens All tasks', (
      tester,
    ) async {
      final visited = <String>[];
      await _load(
        tester,
        FakeMaintenanceTasksRepository(kitTasks()),
        visited: visited,
      );
      await tapAndSettle(tester, find.bySemanticsLabel('Create a task'));
      expect(visited, ['/maintenance/create']);
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await settle(tester);
      await tapAndSettle(tester, find.textContaining('See all '));
      expect(visited.last, '/maintenance/all');
    });

    testWidgets('tapping a row opens the task', (tester) async {
      final visited = <String>[];
      await _load(
        tester,
        FakeMaintenanceTasksRepository(kitTasks()),
        visited: visited,
      );
      await tapAndSettle(tester, find.text('Replace HVAC air filter'));
      expect(visited, ['/maintenance/hvac']);
    });

    testWidgets('search filters by name and says when nothing matches', (
      tester,
    ) async {
      await _load(tester, FakeMaintenanceTasksRepository(kitTasks()));
      await tester.enterText(find.byType(TextField), 'roof');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('MATCHING TASKS'), findsOneWidget);
      expect(find.text('Inspect roof flashing'), findsOneWidget);
      expect(find.text('Replace HVAC air filter'), findsNothing);
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('No tasks match that search.'), findsOneWidget);
    });

    testWidgets('By date offers By area and regroups', (tester) async {
      await _load(tester, FakeMaintenanceTasksRepository(kitTasks()));
      await tapAndSettle(tester, find.text('By date'));
      await tapAndSettle(tester, find.text('By area'));
      expect(find.text('PLUMBING · 1'), findsOneWidget);
      expect(find.text('TODAY · 1'), findsNothing);
      expect(find.text('By area'), findsOneWidget);
    });

    testWidgets('Doesn\'t apply to my home stops the reminder with an Undo', (
      tester,
    ) async {
      final repo = FakeMaintenanceTasksRepository(kitTasks());
      await _load(tester, repo);
      await tapAndSettle(tester, find.text("Doesn't apply to my home"));
      expect(repo.updates.single['notifications_enabled'], false);
      expect(
        find.text('Stopped reminders: Clean gutters & downspouts'),
        findsOneWidget,
      );
      expect(find.text('OVERDUE'), findsNothing);
      await tapAndSettle(tester, find.text('Undo').last);
      expect(repo.updates.last['notifications_enabled'], true);
      expect(find.text('OVERDUE'), findsOneWidget);
    });

    testWidgets('a failed write puts the task back and says so', (
      tester,
    ) async {
      final repo = FakeMaintenanceTasksRepository(kitTasks())
        ..failWrites = StateError('offline');
      await _load(tester, repo);
      await tapAndSettle(tester, find.text("Doesn't apply to my home"));
      expect(find.text('That didn’t save. Please try again.'), findsOneWidget);
      expect(find.text('OVERDUE'), findsOneWidget);
    });
  });
}
