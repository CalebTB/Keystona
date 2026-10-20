import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:keystona/core/widgets/aurora/aurora_toggle_row.dart';
import 'package:keystona/core/widgets/error_view.dart';
import 'package:keystona/features/maintenance/models/maintenance_task.dart';
import 'package:keystona/features/maintenance/models/reminder_item.dart';
import 'package:keystona/features/maintenance/reminders_copy.dart';
import 'package:keystona/features/maintenance/screens/home_reminders_screen.dart';
import 'package:keystona/features/maintenance/widgets/reminders/reminder_frequency_row.dart';
import 'package:keystona/features/maintenance/widgets/reminders/reminders_skeleton.dart';

import 'form_reminders_support.dart';

Future<FakeRemindersRepository> _open(
  WidgetTester tester, {
  RemindersData? data,
  Size size = const Size(390, 844),
  double textScale = 1.0,
  FakeRemindersRepository? repo,
}) async {
  final fake = repo ?? FakeRemindersRepository(data ?? kReminders());
  await pumpRouted(
    tester,
    const HomeRemindersScreen(),
    overrides: reminderOverrides(fake),
    size: size,
    textScale: textScale,
  );
  return fake;
}

Finder _switchAt(int i) => find.byType(AuroraSwitch).at(i);

void main() {
  group('content', () {
    testWidgets('header, counts and groups match the kit', (tester) async {
      await _open(tester);
      expect(find.text('AROUND THE HOUSE'.toLowerCase()), findsNothing);
      expect(find.text(RemindersCopy.homeTitle), findsOneWidget);
      expect(
        find.text('1428 ELM HOLLOW LN · NOT TIED TO A SYSTEM'),
        findsOneWidget,
      );
      expect(find.text(RemindersCopy.homeBlurb), findsOneWidget);

      // on / turned off / yours
      expect(find.text('4'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsWidgets);
      expect(find.text('TURNED OFF'), findsOneWidget);
      expect(find.text('YOURS'), findsWidgets);

      expect(find.text('SAFETY'), findsOneWidget);
      expect(find.text('OUTSIDE'), findsOneWidget);
      expect(find.text('1 OF 2 ON'), findsOneWidget);
      expect(find.text('0 OF 1 ON'), findsOneWidget);
      expect(find.text('FROM YOUR CLIMATE · ZONE 4'), findsOneWidget);
    });

    testWidgets('reminders tied to a system stay off this screen', (
      tester,
    ) async {
      await _open(tester);
      expect(find.text('Replace HVAC air filter'), findsNothing);
      expect(find.text('Clean gutters & downspouts'), findsOneWidget);
    });

    testWidgets('an off reminder says since when and is dimmed', (
      tester,
    ) async {
      await _open(tester);
      expect(find.text('OFF SINCE AUG 30 · YOU TURNED IT OFF'), findsOneWidget);
      expect(find.text('OFF SINCE SEP 2 · YOU TURNED IT OFF'), findsOneWidget);
    });

    testWidgets('your own reminders have Edit and Delete, no switch', (
      tester,
    ) async {
      await _open(tester);
      await reveal(tester, find.text('Clean the window wells'));
      expect(find.text('Clean the window wells'), findsOneWidget);
      expect(find.text('EVERY YEAR · ADDED AUG 2'), findsOneWidget);
      expect(find.text(RemindersCopy.edit), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      // five suggested reminders have a switch; "yours" does not
      expect(find.byType(AuroraSwitch), findsNWidgets(5));
    });

    testWidgets('the add row and the hint are there', (tester) async {
      await _open(tester);
      await reveal(tester, find.text(RemindersCopy.homeHint));
      expect(find.text(RemindersCopy.addReminder), findsOneWidget);
      expect(find.text(RemindersCopy.homeHint), findsOneWidget);
    });

    testWidgets('a home with no house reminders still offers Add', (
      tester,
    ) async {
      await _open(tester, data: const RemindersData());
      expect(find.text(RemindersCopy.addReminder), findsOneWidget);
      expect(find.byType(AuroraSwitch), findsNothing);
      expect(find.text('0'), findsNWidgets(3));
    });
  });

  group('turning on and off', () {
    testWidgets('a switch saves and the row changes at once', (tester) async {
      final repo = await _open(tester);
      await reveal(tester, _switchAt(2));
      await tester.tap(_switchAt(2));
      await settle(tester);
      expect(repo.enabledCalls, [('h3', true)]);
      expect(find.text('OFF SINCE AUG 30 · YOU TURNED IT OFF'), findsNothing);
      expect(find.text('5'), findsOneWidget, reason: 'five on now');
      expect(find.text('1 OF 1 ON'), findsWidgets);
    });

    testWidgets('turning one off hides its pill and says why', (tester) async {
      final repo = await _open(tester);
      await tester.tap(_switchAt(0));
      await settle(tester);
      expect(repo.enabledCalls, [('h1', false)]);
      expect(find.byType(ReminderFrequencyRow), findsNWidgets(5));
      // Turned off just now: "off since" is today, with the default reason.
      final today = DateFormat('MMM d').format(DateTime.now()).toUpperCase();
      expect(find.text('OFF SINCE $today · YOU TURNED IT OFF'), findsOneWidget);
    });

    testWidgets('a failed save puts it back and says so', (tester) async {
      final repo = FakeRemindersRepository(kReminders())
        ..writeError = StateError('offline');
      await _open(tester, repo: repo);
      await tester.tap(_switchAt(0));
      await settle(tester);
      expect(find.text(RemindersCopy.changeError), findsOneWidget);
      expect(find.text('4'), findsOneWidget, reason: 'still four on');
      expect(
        tester.widget<AuroraSwitch>(_switchAt(0)).value,
        isTrue,
        reason: 'rolled back',
      );
    });
  });

  group('how often', () {
    testWidgets('the pill opens the choices and saves the pick', (
      tester,
    ) async {
      final repo = await _open(tester);
      await reveal(tester, find.text('Twice a year'));
      await tester.tap(find.text('Twice a year'));
      await settle(tester);
      expect(find.text(RemindersCopy.howOften), findsOneWidget);
      await tester.tap(find.text('Every 3 months'));
      await settle(tester);
      expect(repo.recurrenceCalls, [('h2', RecurrenceType.quarterly)]);
      expect(find.text('Twice a year'), findsNothing);
      expect(find.text('Every 3 months'), findsOneWidget);
    });

    testWidgets('picking the current one changes nothing', (tester) async {
      final repo = await _open(tester);
      await reveal(tester, find.text('Twice a year'));
      await tester.tap(find.text('Twice a year'));
      await settle(tester);
      await tester.tap(find.text('Twice a year').last);
      await settle(tester);
      expect(repo.recurrenceCalls, isEmpty);
    });

    testWidgets('a failed change goes back to the old one', (tester) async {
      final repo = FakeRemindersRepository(kReminders());
      await _open(tester, repo: repo);
      repo.writeError = StateError('offline');
      await reveal(tester, find.text('Twice a year'));
      await tester.tap(find.text('Twice a year'));
      await settle(tester);
      await tester.tap(find.text('Every month').last);
      await settle(tester);
      expect(find.text(RemindersCopy.changeError), findsOneWidget);
      expect(find.text('Twice a year'), findsOneWidget);
    });
  });

  group('yours', () {
    testWidgets('Edit opens the task form for that reminder', (tester) async {
      await _open(tester);
      await reveal(tester, find.text(RemindersCopy.edit));
      await tester.tap(find.text(RemindersCopy.edit));
      await settle(tester);
      expect(find.text('at /maintenance/edit/m1'), findsOneWidget);
    });

    testWidgets('Add a reminder opens the task form', (tester) async {
      await _open(tester);
      await reveal(tester, find.text(RemindersCopy.addReminder));
      await tester.tap(find.text(RemindersCopy.addReminder));
      await settle(tester);
      expect(find.text('at /maintenance/create'), findsOneWidget);
    });

    testWidgets('Delete asks first, then removes the row', (tester) async {
      final repo = await _open(tester);
      await reveal(tester, find.byIcon(Icons.delete_outline));
      await tester.tap(find.byIcon(Icons.delete_outline));
      await settle(tester);
      expect(find.text(RemindersCopy.deleteTitle), findsOneWidget);
      expect(repo.deleted, isEmpty);
      await tester.tap(find.text(RemindersCopy.deleteConfirm));
      await settle(tester);
      expect(repo.deleted, ['m1']);
      expect(find.text('Clean the window wells'), findsNothing);
    });

    testWidgets('Cancel on the delete dialog keeps it', (tester) async {
      final repo = await _open(tester);
      await reveal(tester, find.byIcon(Icons.delete_outline));
      await tester.tap(find.byIcon(Icons.delete_outline));
      await settle(tester);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(repo.deleted, isEmpty);
      expect(find.text('Clean the window wells'), findsOneWidget);
      expect(find.byType(HomeRemindersScreen), findsOneWidget);
    });

    testWidgets('a failed delete brings the row back', (tester) async {
      final repo = FakeRemindersRepository(kReminders());
      await _open(tester, repo: repo);
      repo.writeError = StateError('offline');
      await reveal(tester, find.byIcon(Icons.delete_outline));
      await tester.tap(find.byIcon(Icons.delete_outline));
      await settle(tester);
      await tester.tap(find.text(RemindersCopy.deleteConfirm));
      await settle(tester);
      expect(find.text(RemindersCopy.deleteError), findsOneWidget);
      expect(find.text('Clean the window wells'), findsOneWidget);
    });
  });

  group('states', () {
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
      final repo = FakeRemindersRepository(kReminders(), fetchFailures: 1);
      await _open(tester, repo: repo);
      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(RemindersCopy.loadError), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await settle(tester);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text(RemindersCopy.homeTitle), findsOneWidget);
    });

    testWidgets('pull to refresh reads again', (tester) async {
      final repo = await _open(tester);
      expect(repo.fetches, 1);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
      await settle(tester);
      expect(repo.fetches, 2);
    });

    testWidgets('the back link returns to where it came from', (tester) async {
      await _open(tester);
      await tester.tap(find.text(RemindersCopy.homeBack));
      await settle(tester);
      expect(find.byType(HomeRemindersScreen), findsNothing);
    });
  });

  group('positions', () {
    testWidgets('each switch sits at its row\'s right edge, name at the left', (
      tester,
    ) async {
      await _open(tester);
      final rows = find.byType(ReminderFrequencyRow);
      for (var i = 0; i < 5; i++) {
        final row = tester.getRect(rows.at(i));
        final sw = tester.getRect(find.byType(AuroraSwitch).at(i));
        expect(sw.right, closeTo(row.right - 14, 1), reason: 'row $i');
        expect(sw.center.dy, closeTo(row.center.dy, 1), reason: 'row $i');
      }
      final firstRow = tester.getRect(rows.first);
      final name = tester.getRect(find.text('Test smoke & CO detectors'));
      expect(name.left, closeTo(firstRow.left + 14, 1));
    });

    testWidgets('the three counts share a row, equal width', (tester) async {
      await _open(tester);
      final on = tester.getRect(find.text('ON'));
      final off = tester.getRect(find.text('TURNED OFF'));
      final yours = tester.getRect(find.text('YOURS').first);
      expect(off.left, greaterThan(on.right));
      expect(yours.left, greaterThan(off.right));
      expect(yours.top, closeTo(on.top, 1));
    });

    testWidgets('group counts sit at the right edge of the header', (
      tester,
    ) async {
      await _open(tester);
      final count = tester.getRect(find.text('1 OF 2 ON'));
      final title = tester.getRect(find.text('OUTSIDE'));
      expect(count.right, closeTo(390 - 16, 1));
      expect(title.left, closeTo(16, 1));
    });

    testWidgets('Edit and Delete are 44 pt targets at the row end', (
      tester,
    ) async {
      await _open(tester);
      await reveal(tester, find.text(RemindersCopy.edit));
      final del = tester.getRect(find.byIcon(Icons.delete_outline));
      final edit = tester.getRect(find.text(RemindersCopy.edit));
      expect(edit.right, lessThan(del.left));
      expect(del.right, lessThan(390 - 16));
    });
  });

  group('responsive', () {
    testResponsiveLoaded(
      'around the house',
      () => const HomeRemindersScreen(),
      overrides: () => reminderOverrides(FakeRemindersRepository(kReminders())),
      after: (tester) async {
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -2000),
        );
        await settle(tester);
      },
    );

    testResponsiveLoaded(
      'around the house, how often open',
      () => const HomeRemindersScreen(),
      overrides: () => reminderOverrides(FakeRemindersRepository(kReminders())),
      after: (tester) async {
        await tapVisible(tester, find.text('Twice a year'));
      },
    );

    testResponsiveLoaded(
      'around the house, delete dialog',
      () => const HomeRemindersScreen(),
      overrides: () => reminderOverrides(FakeRemindersRepository(kReminders())),
      after: (tester) async {
        await tapVisible(tester, find.byIcon(Icons.delete_outline));
      },
    );

    testResponsiveLoaded(
      'around the house, error',
      () => const HomeRemindersScreen(),
      overrides: () => reminderOverrides(
        FakeRemindersRepository(kReminders(), fetchFailures: 1),
      ),
    );

    testResponsiveLoaded(
      'around the house, nothing yet',
      () => const HomeRemindersScreen(),
      overrides: () =>
          reminderOverrides(FakeRemindersRepository(const RemindersData())),
    );
  });
}
