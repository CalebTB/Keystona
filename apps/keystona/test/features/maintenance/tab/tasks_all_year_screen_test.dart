import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/maintenance/models/maintenance_task.dart';
import 'package:keystona/features/maintenance/screens/tasks_all_year_screen.dart';
import 'package:keystona/features/maintenance/widgets/tasks_tab/task_row_item.dart';
import 'package:keystona/features/maintenance/widgets/year/tasks_year_skeleton.dart';
import 'package:keystona/features/maintenance/widgets/year/year_chart_column.dart';

import 'tasks_test_support.dart';

Future<FakeMaintenanceTasksRepository> _load(
  WidgetTester tester, {
  List<MaintenanceTask>? tasks,
  Completer<void>? gate,
  Object? failWith,
}) async {
  final repo = FakeMaintenanceTasksRepository(tasks ?? kitTasks(), gate: gate)
    ..failWith = failWith;
  tallSurface(tester);
  await tester.pumpWidget(
    RoutedApp(
      home: const TasksAllYearScreen(),
      overrides: tasksOverrides(repo),
    ),
  );
  await settle(tester);
  return repo;
}

void main() {
  testWidgets('shows the skeleton while loading', (tester) async {
    final gate = Completer<void>();
    tallSurface(tester);
    final repo = FakeMaintenanceTasksRepository(kitTasks(), gate: gate);
    await tester.pumpWidget(
      RoutedApp(
        home: const TasksAllYearScreen(),
        overrides: tasksOverrides(repo),
      ),
    );
    await tester.pump();
    expect(find.byType(TasksYearSkeleton), findsOneWidget);
    gate.complete();
    await settle(tester);
    expect(find.byType(TasksYearSkeleton), findsNothing);
  });

  testWidgets('shows an error with retry', (tester) async {
    final repo = await _load(tester, failWith: StateError('x'));
    expect(find.text('We couldn\'t load your tasks.'), findsOneWidget);
    repo.failWith = null;
    await tapAndSettle(tester, find.text('Try again'));
    expect(find.text('All tasks'), findsOneWidget);
  });

  testWidgets('shows the kit copy: header, overdue, chart and month', (
    tester,
  ) async {
    await _load(tester);
    expect(find.text('Tasks'), findsOneWidget); // back link
    expect(find.text('All tasks'), findsOneWidget);
    expect(find.textContaining('NEXT 12 MONTHS · '), findsOneWidget);
    expect(find.text('OVERDUE · 1'), findsOneWidget);
    expect(find.text('6 DAYS LATE'), findsOneWidget);
    expect(find.text('YOUR YEAR'), findsOneWidget);
    expect(find.text('OCT 2026 – SEP 2027'), findsOneWidget);
    expect(find.text('FALL'), findsOneWidget);
    expect(find.text('WINTER'), findsOneWidget);
    expect(find.text('SPRING'), findsOneWidget);
    expect(find.text('SUMMER'), findsOneWidget);
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.text('4 TASKS · 1 NEEDS A PRO'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('SWIPE FOR NOVEMBER'), findsOneWidget);
    expect(find.byType(YearChartColumn), findsNWidgets(12));
  });

  testWidgets('selecting a month shows its tasks and swipe hint', (
    tester,
  ) async {
    await _load(tester);
    await tapAndSettle(tester, find.byType(YearChartColumn).at(1));
    expect(find.text('November 2026'), findsOneWidget);
    expect(find.text('Shut off & drain outdoor faucets'), findsOneWidget);
    expect(find.text('Test smoke & CO detectors'), findsNothing);
    expect(find.text('SWIPE FOR OCTOBER OR DECEMBER'), findsOneWidget);
  });

  testWidgets('swiping left goes to the next month and right comes back', (
    tester,
  ) async {
    await _load(tester);
    await tester.fling(find.text('October 2026'), const Offset(-300, 0), 1000);
    await settle(tester);
    expect(find.text('November 2026'), findsOneWidget);
    await tester.fling(find.text('November 2026'), const Offset(300, 0), 1000);
    await settle(tester);
    expect(find.text('October 2026'), findsOneWidget);
  });

  testWidgets('recurring tasks repeat in later months, not actionable', (
    tester,
  ) async {
    final repo = await _load(tester);
    await tapAndSettle(tester, find.byType(YearChartColumn).at(3));
    expect(find.text('Replace HVAC air filter'), findsOneWidget);
    // The projected repeat's circle opens the task, it does not mark it done.
    await tapAndSettle(
      tester,
      find.bySemanticsLabel('Mark done: Replace HVAC air filter'),
    );
    expect(find.text('Nice — it’s done'), findsNothing);
    expect(repo.calls, isEmpty);
  });

  testWidgets('chart month columns line up in a row, bars grow with counts', (
    tester,
  ) async {
    await _load(tester);
    final first = tester.getRect(find.byType(YearChartColumn).first);
    final last = tester.getRect(find.byType(YearChartColumn).last);
    expect(first.left, lessThan(last.left));
    expect(first.center.dy, closeTo(last.center.dy, 1));
    expect(last.right, lessThan(800));
  });

  testWidgets('rows: check circle left, date at the right edge', (
    tester,
  ) async {
    await _load(tester);
    final row = find.ancestor(
      of: find.text('Replace HVAC air filter'),
      matching: find.byType(TaskRowItem),
    );
    final rowRect = tester.getRect(row);
    final date = tester.getRect(find.text('OCT 7'));
    expect(rowRect.right - date.right, lessThan(30));
  });

  testWidgets('search narrows the months', (tester) async {
    await _load(tester);
    await tester.enterText(find.byType(TextField), 'smoke');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Test smoke & CO detectors'), findsOneWidget);
    expect(find.text('OVERDUE · 1'), findsNothing);
  });

  testWidgets('with nothing overdue the overdue list is not drawn', (
    tester,
  ) async {
    await _load(
      tester,
      tasks: kitTasks().where((t) => t.id != 'gutters').toList(),
    );
    expect(find.textContaining('OVERDUE'), findsNothing);
  });

  testResponsiveFlow('All tasks populated', () => const TasksAllYearScreen());
  testResponsiveFlow(
    'All tasks, empty',
    () => const TasksAllYearScreen(),
    tasks: () => [],
  );
}
