import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/router/app_router.dart';
import 'package:keystona/core/widgets/empty_state.dart';
import 'package:keystona/core/widgets/error_view.dart';
import 'package:keystona/features/home_profile/models/item_completion.dart';
import 'package:keystona/features/home_profile/models/item_ref.dart';
import 'package:keystona/features/home_profile/screens/item_tasks_screen.dart';
import 'package:keystona/features/maintenance/models/maintenance_task.dart';
import 'package:keystona/features/maintenance/tasks_copy.dart';

import '../../maintenance/form_reminders/form_reminders_support.dart'
    show testResponsiveLoaded;
import 'c_support.dart';

const ItemTasksScreen washer = ItemTasksScreen(item: ItemRef.appliance('wa'));
const ItemTasksScreen furnace = ItemTasksScreen(item: ItemRef.system('fu'));

FakeMaintenanceTasksRepository washerTasks() => FakeMaintenanceTasksRepository([
  washerTask('g', 'Wipe the door gasket', due: day(10, 7), minutes: 15)
      .copyWith(estimatedCost: 25, recurrence: RecurrenceType.quarterly),
  washerTask(
    's',
    'Service the washer',
    due: day(10, 28),
    minutes: 60,
    who: DiyOrPro.professional,
    recurrence: RecurrenceType.annual,
  ).copyWith(estimatedCost: 129, season: 'fall'),
  washerTask('d', 'Clean the drain filter', due: day(1, 15, 2027)),
  task('other', 'Not mine', due: day(10, 9)).copyWith(linkedApplianceId: 'dw'),
]);

List<ItemCompletion> done() => [
  ItemCompletion(id: '1', taskName: 'Replaced the filter', completedOn: DateTime(2026, 7, 6), doneBy: 'You', cost: 22),
  ItemCompletion(id: '2', taskName: 'Annual tune-up', completedOn: DateTime(2025, 10, 5), doneBy: 'Summit Heating & Air', cost: 129),
];

void main() {
  testWidgets('Coming up lists the item\'s open tasks, soonest first, as kit cards', (
    tester,
  ) async {
    await openScreen(
      tester,
      washer,
      overrides: cOverrides(tasks: washerTasks(), completions: FakeItemCompletionsRepository(done())),
    );
    expect(find.text('WASHER · HALDEN HW45-FL2'), findsOneWidget);
    expect(find.text('Washer tasks'), findsOneWidget);
    expect(find.text('Coming up · 3'), findsOneWidget);
    expect(find.text('Done · 2'), findsOneWidget);
    expect(find.text('Not mine'), findsNothing);
    expect(find.text('EVERY 3 MONTHS'), findsOneWidget);
    expect(find.text('EVERY FALL'), findsOneWidget);
    expect(find.text('PRO'), findsOneWidget);
    expect(find.text('15 MIN · \$25'), findsOneWidget);
    expect(find.text('1 HR · ~\$129'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Wipe the door gasket')).dy,
      lessThan(tester.getTopLeft(find.text('Service the washer')).dy),
    );
    // The date sits at the card's right edge.
    final date = tester.getTopRight(find.text('OCT 7')).dx;
    expect(date, greaterThan(390 - 60));
    expect(date, lessThan(390 - 16));
    expect(find.text('Add a washer task'), findsOneWidget);
  });

  testWidgets('rows have no edit or delete buttons', (tester) async {
    await openScreen(tester, washer, overrides: cOverrides(tasks: washerTasks()));
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.byIcon(Icons.more_horiz), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  testWidgets('a long press opens the task menu', (tester) async {
    await openScreen(tester, washer, overrides: cOverrides(tasks: washerTasks()));
    await tester.longPress(find.text('Wipe the door gasket'));
    await settle(tester);
    expect(find.text(TasksCopy.menuSkip), findsOneWidget);
    expect(find.text(TasksCopy.menuFrequency), findsOneWidget);
    expect(find.text(TasksCopy.menuOpen), findsOneWidget);
    expect(find.text(TasksCopy.menuStop), findsOneWidget);
  });

  testWidgets('a tap opens the task; Manage opens the reminders; Add opens the form', (
    tester,
  ) async {
    var visits = await openScreen(tester, washer, overrides: cOverrides(tasks: washerTasks()));
    await tester.tap(find.text('Wipe the door gasket'));
    await settle(tester);
    expect(visits.single.path, '/maintenance/g');

    visits = await openScreen(tester, washer, overrides: cOverrides(tasks: washerTasks()));
    final manage = find.text('Manage');
    expect(tester.getTopRight(manage).dx, greaterThan(390 - 40));
    await tester.tap(manage);
    await settle(tester);
    expect(visits.single.path, '/home/appliances/wa/reminders');

    visits = await openScreen(tester, washer, overrides: cOverrides(tasks: washerTasks()));
    await tester.ensureVisible(find.text('Add a washer task'));
    await tester.pump();
    await tester.tap(find.text('Add a washer task'));
    await settle(tester);
    expect(visits.single.path, AppRoutes.maintenanceCreate);
  });

  testWidgets('Done lists finished tasks with a total', (tester) async {
    await openScreen(
      tester,
      washer,
      overrides: cOverrides(tasks: washerTasks(), completions: FakeItemCompletionsRepository(done())),
    );
    await tester.tap(find.text('Done · 2'));
    await settle(tester);
    expect(find.text('\$151'), findsOneWidget);
    expect(find.text('SPENT ON UPKEEP SINCE 2025 · 2 TIMES'), findsOneWidget);
    expect(find.text('ON SCHEDULE'), findsOneWidget);
    expect(find.text('Replaced the filter'), findsOneWidget);
    expect(find.text('Annual tune-up'), findsOneWidget);
    expect(find.text('\$22'), findsOneWidget);
    expect(find.text('Wipe the door gasket'), findsNothing);
  });

  testWidgets('the Done tab drops "on schedule" when something is overdue', (tester) async {
    final tasks = FakeMaintenanceTasksRepository([washerTask('l', 'Late', due: day(9, 1))]);
    await openScreen(
      tester,
      washer,
      overrides: cOverrides(tasks: tasks, completions: FakeItemCompletionsRepository(done())),
    );
    await tester.tap(find.text('Done · 2'));
    await settle(tester);
    expect(find.text('ON SCHEDULE'), findsNothing);
  });

  testWidgets('more than twenty finished tasks end in a link that shows the rest', (
    tester,
  ) async {
    final many = [
      for (var i = 0; i < 23; i++)
        ItemCompletion(id: 'c$i', taskName: 'Task $i', completedOn: DateTime(2026, 1, 1).subtract(Duration(days: i))),
    ];
    await openScreen(
      tester,
      washer,
      size: const Size(390, 6000),
      overrides: cOverrides(tasks: washerTasks(), completions: FakeItemCompletionsRepository(many)),
    );
    await tester.tap(find.text('Done · 23'));
    await settle(tester);
    expect(find.text('Task 19'), findsOneWidget);
    expect(find.text('Task 20'), findsNothing);
    expect(find.textContaining('+ 3 EARLIER'), findsOneWidget);
    await tester.tap(find.textContaining('+ 3 EARLIER'));
    await settle(tester);
    expect(find.text('Task 22'), findsOneWidget);
  });

  testWidgets('empty tabs say so and offer the next step', (tester) async {
    final visits = await openScreen(tester, washer, overrides: cOverrides());
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Nothing coming up'), findsOneWidget);
    await tester.tap(find.text('Add a washer task'));
    await settle(tester);
    expect(visits.single.path, AppRoutes.maintenanceCreate);

    await openScreen(tester, washer, overrides: cOverrides());
    await tester.tap(find.text('Done · 0'));
    await settle(tester);
    expect(find.text('Nothing done yet'), findsOneWidget);
  });

  testWidgets('a system works the same, named after the system', (tester) async {
    final tasks = FakeMaintenanceTasksRepository([
      task('f', 'Replace HVAC air filter', due: day(10, 7)).copyWith(linkedSystemId: 'fu'),
    ]);
    await openScreen(tester, furnace, overrides: cOverrides(tasks: tasks));
    expect(find.text('FURNACE · NORTHLINE NF95-080B'), findsOneWidget);
    expect(find.text('Furnace tasks'), findsOneWidget);
    expect(find.text('Add a furnace task'), findsOneWidget);
    expect(find.text('Replace HVAC air filter'), findsOneWidget);
  });

  testWidgets('an item that no longer exists says so', (tester) async {
    await openScreen(
      tester,
      const ItemTasksScreen(item: ItemRef.appliance('gone')),
      overrides: cOverrides(),
    );
    expect(find.text('We can’t find that'), findsOneWidget);
  });

  testWidgets('a failed Done tab offers Try again', (tester) async {
    final completions = FakeItemCompletionsRepository()..error = StateError('x');
    await openScreen(tester, washer, overrides: cOverrides(tasks: washerTasks(), completions: completions));
    await tester.tap(find.text('Done · 0'));
    await settle(tester);
    expect(find.byType(ErrorView), findsOneWidget);
  });

  testResponsiveLoaded(
    'item tasks hold up',
    () => washer,
    overrides: () => cOverrides(tasks: washerTasks(), completions: FakeItemCompletionsRepository(done())),
  );
}
