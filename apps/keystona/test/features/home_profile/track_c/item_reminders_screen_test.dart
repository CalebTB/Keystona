import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/widgets/aurora/aurora_toggle_row.dart';
import 'package:keystona/core/widgets/empty_state.dart';
import 'package:keystona/features/home_profile/models/item_ref.dart';
import 'package:keystona/features/home_profile/screens/item_reminders_screen.dart';
import 'package:keystona/features/maintenance/models/maintenance_task.dart';
import 'package:keystona/features/maintenance/models/reminder_item.dart';

import '../../maintenance/form_reminders/form_reminders_support.dart';
import 'c_support.dart' as c;

const ItemRemindersScreen washer = ItemRemindersScreen(item: ItemRef.appliance('wa'));
const ItemRemindersScreen furnace = ItemRemindersScreen(item: ItemRef.system('fu'));

RemindersData data() => RemindersData(
  items: [
    reminder('r1', 'Wipe the door gasket', category: 'laundry', recurrence: RecurrenceType.quarterly, applianceId: 'wa', itemName: 'Washer'),
    reminder('r2', 'Service the washer', category: 'laundry', applianceId: 'wa', itemName: 'Washer'),
    reminder(
      'r3',
      'Replace the hoses',
      category: 'laundry',
      enabled: false,
      applianceId: 'wa',
      itemName: 'Washer',
      offAt: DateTime(2026, 9, 12),
      offReason: 'Steel-braided already',
    ),
    reminder('r4', 'Check the flue', category: 'hvac', systemId: 'fu', itemName: 'Furnace'),
    reminder('h1', 'Test smoke detectors', category: 'safety'),
  ],
);

List<dynamic> overrides(FakeRemindersRepository repo) => [
  ...c.cOverrides(
    tasks: c.FakeMaintenanceTasksRepository([
      c.task('r2', 'Service the washer', due: c.day(10, 28), who: DiyOrPro.professional),
    ]),
  ),
  ...reminderOverrides(repo),
];

Finder switchAt(int i) => find.byType(AuroraSwitch).at(i);

void main() {
  testWidgets('lists this item\'s reminders: ON card, TURNED OFF card with why', (
    tester,
  ) async {
    await pumpRouted(tester, washer, overrides: overrides(FakeRemindersRepository(data())).cast());
    expect(find.text('WASHER · HALDEN HW45-FL2'), findsOneWidget);
    expect(find.text('Washer reminders'), findsOneWidget);
    expect(find.textContaining('Turn off anything that doesn’t fit your washer'), findsOneWidget);
    expect(find.text('ON · 2'), findsOneWidget);
    expect(find.text('SHOWS IN YOUR TASKS'), findsOneWidget);
    expect(find.text('TURNED OFF · 1'), findsOneWidget);
    expect(find.text('HIDDEN EVERYWHERE'), findsOneWidget);
    expect(find.text('Wipe the door gasket'), findsOneWidget);
    expect(find.text('Every 3 months'), findsOneWidget);
    expect(find.text('OFF SINCE SEP 12 · STEEL-BRAIDED ALREADY'), findsOneWidget);
    expect(find.text('PRO'), findsOneWidget);
    // Other items' and the house's reminders stay off this screen.
    expect(find.text('Check the flue'), findsNothing);
    expect(find.text('Test smoke detectors'), findsNothing);
    expect(find.byType(AuroraSwitch), findsNWidgets(3));
    expect(find.text('Add your own washer task'), findsOneWidget);
    expect(find.text('SUGGESTIONS COME FROM THE WASHER TYPE AND HOW OLD IT IS'), findsOneWidget);
  });

  testWidgets('switches sit at the right edge and Done at the top right', (tester) async {
    await pumpRouted(tester, washer, overrides: overrides(FakeRemindersRepository(data())).cast());
    for (var i = 0; i < 3; i++) {
      expect(tester.getTopRight(switchAt(i)).dx, greaterThan(390 - 60));
    }
    expect(tester.getTopRight(find.text('Done')).dx, greaterThan(390 - 40));
    expect(tester.getTopLeft(find.text('Washer tasks')).dx, lessThan(80));
  });

  testWidgets('turning one off saves it and moves it to TURNED OFF; on brings it back', (
    tester,
  ) async {
    final repo = FakeRemindersRepository(data());
    await pumpRouted(tester, washer, overrides: overrides(repo).cast());
    await tester.tap(switchAt(0));
    await settle(tester);
    expect(repo.enabledCalls, [('r1', false)]);
    expect(find.text('ON · 1'), findsOneWidget);
    expect(find.text('TURNED OFF · 2'), findsOneWidget);
    expect(find.textContaining('YOU TURNED IT OFF'), findsOneWidget);

    await tester.tap(switchAt(1));
    await settle(tester);
    expect(repo.enabledCalls.last.$2, true);
  });

  testWidgets('a failed save puts the switch back and says so', (tester) async {
    final repo = FakeRemindersRepository(data())..writeError = StateError('offline');
    await pumpRouted(tester, washer, overrides: overrides(repo).cast());
    await tester.tap(switchAt(0));
    await settle(tester);
    expect(find.text("Couldn't change that reminder. Try again."), findsOneWidget);
    expect(find.text('ON · 2'), findsOneWidget);
  });

  testWidgets('the how-often pill offers the choices and saves one', (tester) async {
    final repo = FakeRemindersRepository(data());
    await pumpRouted(tester, washer, overrides: overrides(repo).cast());
    await tester.tap(find.text('Every 3 months'));
    await settle(tester);
    await tester.tap(find.text('Twice a year'));
    await settle(tester);
    expect(repo.recurrenceCalls, [('r1', RecurrenceType.biannual)]);
  });

  testWidgets('Done and the back link return to the tasks', (tester) async {
    await pumpRouted(tester, washer, overrides: overrides(FakeRemindersRepository(data())).cast());
    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(find.text('start'), findsOneWidget);
  });

  testWidgets('Add your own opens the task form', (tester) async {
    await pumpRouted(tester, washer, overrides: overrides(FakeRemindersRepository(data())).cast());
    await tapVisible(tester, find.text('Add your own washer task'));
    expect(find.textContaining('at /maintenance/create'), findsOneWidget);
  });

  testWidgets('a system reads the same, named after the system', (tester) async {
    await pumpRouted(tester, furnace, overrides: overrides(FakeRemindersRepository(data())).cast());
    expect(find.text('Furnace reminders'), findsOneWidget);
    expect(find.text('Check the flue'), findsOneWidget);
    expect(find.text('SUGGESTIONS COME FROM THE FURNACE TYPE, ITS AGE AND YOUR CLIMATE'), findsOneWidget);
  });

  testWidgets('an item with no reminders offers to add one', (tester) async {
    await pumpRouted(
      tester,
      washer,
      overrides: overrides(FakeRemindersRepository(const RemindersData())).cast(),
    );
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('No reminders yet'), findsOneWidget);
  });

  testResponsiveLoaded(
    'item reminders hold up',
    () => washer,
    overrides: () => overrides(FakeRemindersRepository(data())).cast(),
  );
}
