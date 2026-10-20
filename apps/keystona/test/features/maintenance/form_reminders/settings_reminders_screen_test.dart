import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/widgets/empty_state.dart';
import 'package:keystona/core/widgets/error_view.dart';
import 'package:keystona/features/maintenance/models/reminder_item.dart';
import 'package:keystona/features/maintenance/reminders_copy.dart';
import 'package:keystona/features/maintenance/widgets/reminders/reminder_turn_on_row.dart';
import 'package:keystona/features/maintenance/widgets/reminders/reminders_skeleton.dart';
import 'package:keystona/features/settings/screens/settings_reminders_screen.dart';

import 'form_reminders_support.dart';

Future<FakeRemindersRepository> _open(
  WidgetTester tester, {
  RemindersData? data,
  FakeRemindersRepository? repo,
  Size size = const Size(390, 844),
  double textScale = 1.0,
}) async {
  final fake = repo ?? FakeRemindersRepository(data ?? kReminders());
  await pumpRouted(
    tester,
    const SettingsRemindersScreen(),
    overrides: reminderOverrides(fake),
    size: size,
    textScale: textScale,
  );
  return fake;
}

RemindersData _allOn() => RemindersData(
  items: [for (final i in kReminders().items) i.copyWith(enabled: true)],
);

void main() {
  group('content', () {
    testWidgets('lists only what is off, grouped by parent', (tester) async {
      await _open(tester);
      expect(find.text(RemindersCopy.settingsTitle), findsOneWidget);
      expect(find.text('HOME · 1428 ELM HOLLOW LN'), findsOneWidget);
      expect(find.text(RemindersCopy.settingsBlurb), findsOneWidget);

      expect(find.text('FURNACE'), findsOneWidget);
      expect(find.text('WASHER'), findsOneWidget);
      expect(find.text('AROUND THE HOUSE'), findsOneWidget);
      expect(find.text(RemindersCopy.seeAll), findsNWidgets(3));

      expect(find.text('Replace the humidifier pad'), findsOneWidget);
      expect(find.text('Clean the drain pump filter'), findsOneWidget);
      expect(find.text('Power-wash the siding'), findsOneWidget);
      expect(find.text('Shut off and drain the sprinklers'), findsOneWidget);
      expect(
        find.text('Replace HVAC air filter'),
        findsNothing,
        reason: 'that one is on',
      );
      expect(find.text(RemindersCopy.turnOn), findsNWidgets(4));
    });

    testWidgets('each row says since when', (tester) async {
      await _open(tester);
      expect(find.text('OFF SINCE SEP 12'), findsOneWidget);
      expect(find.text('OFF SINCE SEP 24'), findsOneWidget);
      expect(find.text('OFF SINCE AUG 30'), findsOneWidget);
      expect(find.text('OFF SINCE SEP 2'), findsOneWidget);
    });

    testWidgets('says these are saved for this house only', (tester) async {
      await _open(tester);
      await reveal(tester, find.text(RemindersCopy.savedForThisHouse));
      expect(find.text(RemindersCopy.savedForThisHouse), findsOneWidget);
    });
  });

  group('turning on', () {
    testWidgets('Turn on saves, and the row offers Undo', (tester) async {
      final repo = await _open(tester);
      await tester.tap(find.text(RemindersCopy.turnOn).first);
      await settle(tester);
      expect(repo.enabledCalls, [('f3', true)]);
      expect(find.text(RemindersCopy.undo), findsOneWidget);
      expect(find.text(RemindersCopy.backOn.toUpperCase()), findsOneWidget);
      expect(find.text(RemindersCopy.turnOn), findsNWidgets(3));
      expect(
        find.text('Replace the humidifier pad'),
        findsOneWidget,
        reason: 'it stays listed so Undo is possible',
      );
    });

    testWidgets('Undo turns it off again', (tester) async {
      final repo = await _open(tester);
      await tester.tap(find.text(RemindersCopy.turnOn).first);
      await settle(tester);
      await tester.tap(find.text(RemindersCopy.undo));
      await settle(tester);
      expect(repo.enabledCalls, [('f3', true), ('f3', false)]);
      expect(find.text(RemindersCopy.undo), findsNothing);
      expect(find.text(RemindersCopy.turnOn), findsNWidgets(4));
      expect(find.text('OFF SINCE SEP 12'), findsOneWidget);
    });

    testWidgets('a failed save leaves it off and says so', (tester) async {
      final repo = FakeRemindersRepository(kReminders())
        ..writeError = StateError('offline');
      await _open(tester, repo: repo);
      await tester.tap(find.text(RemindersCopy.turnOn).first);
      await settle(tester);
      expect(find.text(RemindersCopy.changeError), findsOneWidget);
      expect(find.text(RemindersCopy.turnOn), findsNWidgets(4));
      expect(find.text(RemindersCopy.undo), findsNothing);
    });

    testWidgets(
      'turning on the last one keeps the screen, not the empty state',
      (tester) async {
        final repo = await _open(
          tester,
          data: RemindersData(items: [kReminders().items[2]]),
        );
        await tester.tap(find.text(RemindersCopy.turnOn));
        await settle(tester);
        expect(find.byType(EmptyState), findsNothing);
        expect(find.text(RemindersCopy.undo), findsOneWidget);
        expect(repo.enabledCalls, hasLength(1));
      },
    );
  });

  group('see all', () {
    testWidgets('a system goes to the system', (tester) async {
      await _open(tester);
      await tester.tap(find.text(RemindersCopy.seeAll).at(0));
      await settle(tester);
      expect(find.text('at /home/systems/s-furnace'), findsOneWidget);
    });

    testWidgets('an appliance goes to the appliance', (tester) async {
      await _open(tester);
      await tester.tap(find.text(RemindersCopy.seeAll).at(1));
      await settle(tester);
      expect(find.text('at /home/appliances/a-washer'), findsOneWidget);
    });

    testWidgets('around the house goes to its screen', (tester) async {
      await _open(tester);
      await reveal(tester, find.text(RemindersCopy.seeAll).at(2));
      await tester.tap(find.text(RemindersCopy.seeAll).at(2));
      await settle(tester);
      expect(find.text('at /home/reminders'), findsOneWidget);
    });
  });

  group('states', () {
    testWidgets('nothing turned off shows the empty state', (tester) async {
      await _open(tester, data: _allOn());
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(RemindersCopy.settingsEmptyTitle), findsOneWidget);
    });

    testWidgets('loading shows a skeleton', (tester) async {
      final gate = Completer<void>();
      await _open(
        tester,
        repo: FakeRemindersRepository(kReminders(), gate: gate),
      );
      expect(find.byType(RemindersSkeleton), findsOneWidget);
      gate.complete();
      await settle(tester);
      expect(find.byType(RemindersSkeleton), findsNothing);
    });

    testWidgets('an offline load shows the error with retry', (tester) async {
      await _open(
        tester,
        repo: FakeRemindersRepository(kReminders(), fetchFailures: 1),
      );
      expect(find.byType(ErrorView), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await settle(tester);
      expect(find.text(RemindersCopy.settingsTitle), findsOneWidget);
    });

    testWidgets('pull to refresh reads again and relists', (tester) async {
      final repo = await _open(tester);
      await tester.tap(find.text(RemindersCopy.turnOn).first);
      await settle(tester);
      repo.data = RemindersData(
        addressLine: '1428 Elm Hollow Ln',
        items: [
          for (final i in kReminders().items)
            i.id == 'f3' ? i.copyWith(enabled: true) : i,
        ],
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
      await settle(tester);
      expect(repo.fetches, 2);
      expect(find.text('Replace the humidifier pad'), findsNothing);
      expect(find.text(RemindersCopy.undo), findsNothing);
    });

    testWidgets('the back link leaves the screen', (tester) async {
      await _open(tester);
      await tester.tap(find.text(RemindersCopy.settingsBack));
      await settle(tester);
      expect(find.byType(SettingsRemindersScreen), findsNothing);
    });
  });

  group('positions', () {
    testWidgets('Turn on sits at every row\'s right edge, name at the left', (
      tester,
    ) async {
      await _open(tester);
      final rows = find.byType(ReminderTurnOnRow);
      expect(rows, findsNWidgets(4));
      for (var i = 0; i < 4; i++) {
        final row = tester.getRect(rows.at(i));
        final pill = tester.getRect(find.text(RemindersCopy.turnOn).at(i));
        // the pill's text is inset by the pill padding; the target ends at
        // the row padding
        expect(pill.right, lessThan(row.right - 14), reason: 'row $i');
        expect(
          pill.right,
          greaterThan(row.right - 14 - 14 - 4),
          reason: 'row $i',
        );
      }
      final firstRow = tester.getRect(rows.first);
      final name = tester.getRect(find.text('Replace the humidifier pad'));
      expect(name.left, closeTo(firstRow.left + 14, 1));
    });

    testWidgets('See all sits at the right edge of its header', (tester) async {
      await _open(tester);
      final seeAll = tester.getRect(find.text(RemindersCopy.seeAll).first);
      expect(seeAll.right, closeTo(390 - 16, 1));
      expect(tester.getRect(find.text('FURNACE')).left, closeTo(16, 1));
    });

    testWidgets('the reason wraps beside the button, never under it', (
      tester,
    ) async {
      await _open(tester, textScale: 1.5);
      final reason = tester.getRect(find.text('OFF SINCE SEP 12'));
      final pill = tester.getRect(find.text(RemindersCopy.turnOn).first);
      expect(reason.right, lessThanOrEqualTo(pill.left));
    });
  });

  group('responsive', () {
    testResponsiveLoaded(
      'turned-off reminders',
      () => const SettingsRemindersScreen(),
      overrides: () => reminderOverrides(FakeRemindersRepository(kReminders())),
      after: (tester) async {
        await tapVisible(tester, find.text(RemindersCopy.turnOn).first);
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -2000),
        );
        await settle(tester);
      },
    );

    testResponsiveLoaded(
      'turned-off reminders, long reasons',
      () => const SettingsRemindersScreen(),
      overrides: () => reminderOverrides(
        FakeRemindersRepository(
          RemindersData(
            items: [
              reminder(
                'x1',
                'Replace the humidifier pad on the whole-house humidifier in the basement',
                systemId: 's',
                itemName: 'A furnace with a very long name that wraps',
                enabled: false,
              ),
            ],
          ),
        ),
      ),
    );

    testResponsiveLoaded(
      'turned-off reminders, empty',
      () => const SettingsRemindersScreen(),
      overrides: () => reminderOverrides(FakeRemindersRepository(_allOn())),
    );

    testResponsiveLoaded(
      'turned-off reminders, error',
      () => const SettingsRemindersScreen(),
      overrides: () => reminderOverrides(
        FakeRemindersRepository(kReminders(), fetchFailures: 1),
      ),
    );
  });
}
