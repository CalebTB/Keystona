import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:keystona/core/widgets/aurora/aurora_button.dart';
import 'package:keystona/core/widgets/aurora/aurora_toggle_row.dart';
import 'package:keystona/features/maintenance/models/maintenance_task.dart';
import 'package:keystona/features/maintenance/models/reminder_item.dart';
import 'package:keystona/features/maintenance/models/task_form_options.dart';
import 'package:keystona/features/maintenance/providers/reminders_providers.dart';
import 'package:keystona/features/maintenance/reminders_copy.dart';
import 'package:keystona/features/maintenance/screens/home_reminders_screen.dart';
import 'package:keystona/features/maintenance/screens/task_form_screen.dart';
import 'package:keystona/features/maintenance/task_form_copy.dart';
import 'package:keystona/features/maintenance/widgets/reminders/frequency_pill.dart';
import 'package:keystona/features/maintenance/widgets/reminders/reminder_frequency_row.dart';
import 'package:keystona/features/settings/screens/settings_reminders_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../form_reminders/form_reminders_support.dart';

Finder get _save => find.widgetWithText(SaveButton, TaskFormCopy.save);

TextEditingController _field(WidgetTester t, int i) =>
    t.widget<TextField>(find.byType(TextField).at(i)).controller!;

Future<void> _type(WidgetTester t, int i, String text) async {
  await t.ensureVisible(find.byType(TextField).at(i));
  await t.enterText(find.byType(TextField).at(i), text);
  await t.pump();
}

Future<void> _pumpForm(
  WidgetTester t,
  FakeTaskFormRepository repo,
  TaskFormScreen screen,
) => pumpRouted(t, screen, overrides: formOverrides(repo));

Future<void> _pickFurnace(WidgetTester t) async {
  await t.ensureVisible(find.text(TaskFormCopy.linkPlaceholder));
  await t.tap(find.text(TaskFormCopy.linkPlaceholder));
  await settle(t);
  await t.tap(find.text('Furnace'));
  await settle(t);
}

/// Opens the how-often picker (it shows [from]) and picks [to].
Future<void> _chooseFrequency(
  WidgetTester t,
  TaskFrequency to, {
  TaskFrequency from = TaskFrequency.once,
}) async {
  await t.ensureVisible(find.text(from.label));
  await t.pump();
  await t.tap(find.text(from.label));
  await settle(t);
  await t.tap(find.text(to.label));
  await settle(t);
}

void main() {
  group('Add a task persists the new fields', () {
    testWidgets('estimate, notes and every-few-years go into the save', (
      t,
    ) async {
      final repo = FakeTaskFormRepository();
      await _pumpForm(t, repo, TaskFormScreen(today: kToday));
      await _type(t, 0, 'Flush water heater');
      await _pickFurnace(t);
      await _type(t, 1, 'Spares are on the shelf.');
      await _type(t, 2, '25.50');
      await _chooseFrequency(t, TaskFrequency.everyFewYears);
      await t.ensureVisible(find.byType(Slider));
      t.widget<Slider>(find.byType(Slider)).onChanged!(5);
      await t.pump();
      expect(find.text('5 years'), findsOneWidget);

      await t.tap(_save);
      await settle(t);

      final saved = repo.created.single;
      final fields = saved.draft.toFields(
        today: saved.today,
        category: 'hvac',
        editing: false,
      );
      expect(fields['estimated_cost'], 25.5);
      expect(fields['notes'], 'Spares are on the shelf.');
      expect(fields['recurrence'], 'annual');
      expect(fields['recurrence_interval_years'], 5);
      expect(fields.containsKey('description'), isFalse);
    });

    testWidgets('a task that repeats monthly saves no interval', (t) async {
      final repo = FakeTaskFormRepository();
      await _pumpForm(t, repo, TaskFormScreen(today: kToday));
      await _type(t, 0, 'Check filter');
      await _pickFurnace(t);
      // Slide to 6 years, then choose a different frequency.
      await _chooseFrequency(t, TaskFrequency.everyFewYears);
      await t.ensureVisible(find.byType(Slider));
      t.widget<Slider>(find.byType(Slider)).onChanged!(6);
      await t.pump();
      await _chooseFrequency(
        t,
        TaskFrequency.monthly,
        from: TaskFrequency.everyFewYears,
      );
      await t.tap(_save);
      await settle(t);
      final saved = repo.created.single;
      final fields = saved.draft.toFields(
        today: saved.today,
        category: 'hvac',
        editing: false,
      );
      expect(fields['recurrence'], 'monthly');
      expect(fields['recurrence_interval_years'], isNull);
    });
  });

  group('edit reloads the new fields', () {
    TaskFormScreen edit(MaintenanceTask task) =>
        TaskFormScreen(existingTask: task, today: kToday);

    testWidgets('estimate, notes and the years come back', (t) async {
      final repo = FakeTaskFormRepository();
      await _pumpForm(
        t,
        repo,
        edit(
          savedTask(
            recurrence: RecurrenceType.annual,
            intervalYears: 4,
            estimatedCost: 25.5,
            notes: 'Spares are on the shelf.',
          ),
        ),
      );
      expect(_field(t, 1).text, 'Spares are on the shelf.');
      expect(_field(t, 2).text, '25.50');
      expect(find.text(TaskFrequency.everyFewYears.label), findsOneWidget);
      await t.ensureVisible(find.byType(Slider));
      expect(find.text('4 years'), findsOneWidget);
      expect(t.widget<Slider>(find.byType(Slider)).value, 4);
    });

    testWidgets('saving unchanged keeps all three', (t) async {
      final repo = FakeTaskFormRepository();
      await _pumpForm(
        t,
        repo,
        edit(
          savedTask(
            recurrence: RecurrenceType.annual,
            intervalYears: 4,
            estimatedCost: 25.5,
          ),
        ),
      );
      await t.tap(_save);
      await settle(t);
      final saved = repo.updated.single;
      final fields = saved.draft.toFields(
        today: kToday,
        category: saved.category,
        editing: true,
      );
      expect(fields['estimated_cost'], 25.5);
      expect(fields['recurrence_interval_years'], 4);
      expect(fields['notes'], 'Behind the grille');
    });

    testWidgets('clearing the estimate saves null', (t) async {
      final repo = FakeTaskFormRepository();
      await _pumpForm(t, repo, edit(savedTask(estimatedCost: 25)));
      expect(_field(t, 2).text, '25');
      await _type(t, 2, '');
      await t.tap(_save);
      await settle(t);
      final saved = repo.updated.single;
      expect(
        saved.draft.toFields(
          today: kToday,
          category: 'hvac',
          editing: true,
        )['estimated_cost'],
        isNull,
      );
    });

    testWidgets(
      'switching an every-few-years task to monthly drops the years',
      (t) async {
        final repo = FakeTaskFormRepository();
        await _pumpForm(
          t,
          repo,
          edit(savedTask(recurrence: RecurrenceType.annual, intervalYears: 4)),
        );
        await t.ensureVisible(find.text(TaskFrequency.everyFewYears.label));
        await t.tap(find.text(TaskFrequency.everyFewYears.label));
        await settle(t);
        await t.tap(find.text(TaskFrequency.monthly.label));
        await settle(t);
        await t.tap(_save);
        await settle(t);
        final fields = repo.updated.single.draft.toFields(
          today: kToday,
          category: 'hvac',
          editing: true,
        );
        expect(fields['recurrence'], 'monthly');
        expect(fields['recurrence_interval_years'], isNull);
      },
    );

    testWidgets('an unread system description is not shown as the notes', (
      t,
    ) async {
      await _pumpForm(
        t,
        FakeTaskFormRepository(),
        edit(savedTask(notes: null)),
      );
      expect(_field(t, 1).text, isEmpty);
    });
  });

  group('reminders show when, why and what for', () {
    final aug30 = DateTime(2026, 8, 30);

    Future<FakeRemindersRepository> openHome(
      WidgetTester t,
      List<ReminderItem> items,
    ) async {
      final repo = FakeRemindersRepository(
        RemindersData(items: items, climateZone: 4),
      );
      await pumpRouted(
        t,
        const HomeRemindersScreen(),
        overrides: reminderOverrides(repo),
      );
      return repo;
    }

    testWidgets('a climate tag sits beside the how-often pill', (t) async {
      await openHome(t, [
        reminder(
          'c1',
          'Drain the outdoor faucets',
          category: 'seasonal',
          origin: TaskOrigin.climateTriggered,
          tags: const ['FREEZE'],
        ),
      ]);
      final pill = t.getRect(find.byType(FrequencyPill));
      final tag = t.getRect(find.text('FREEZE'));
      expect(tag.left, greaterThan(pill.right));
      expect(tag.center.dy, closeTo(pill.center.dy, 3));
    });

    testWidgets('every tag is drawn, in order', (t) async {
      await openHome(t, [
        reminder(
          'c1',
          'Drain the outdoor faucets',
          category: 'seasonal',
          origin: TaskOrigin.climateTriggered,
          tags: const ['FREEZE', 'STORMS'],
        ),
      ]);
      // They wrap on a narrow phone: STORMS is never above or left of FREEZE
      // on the same line.
      final freeze = t.getRect(find.text('FREEZE'));
      final storms = t.getRect(find.text('STORMS'));
      expect(storms.top, greaterThanOrEqualTo(freeze.top - 1));
      if ((storms.top - freeze.top).abs() < 1) {
        expect(storms.left, greaterThan(freeze.left));
      }
    });

    testWidgets('a reminder with no tags draws none', (t) async {
      await openHome(t, [
        reminder('c1', 'Drain the outdoor faucets', category: 'seasonal'),
      ]);
      expect(find.text('FREEZE'), findsNothing);
    });

    testWidgets('off since uses the recorded time, not the last change', (
      t,
    ) async {
      await openHome(t, [
        reminder(
          'h1',
          'Power-wash the siding',
          category: 'exterior',
          enabled: false,
          offAt: aug30,
          updatedAt: DateTime(2026, 9, 12),
        ),
      ]);
      expect(find.text('OFF SINCE AUG 30 · YOU TURNED IT OFF'), findsOneWidget);
    });

    testWidgets('off since shows the reason when there is one', (t) async {
      await openHome(t, [
        reminder(
          'h1',
          'Power-wash the siding',
          category: 'exterior',
          enabled: false,
          offAt: aug30,
          offReason: 'No siding on this house',
        ),
      ]);
      expect(
        find.text('OFF SINCE AUG 30 · NO SIDING ON THIS HOUSE'),
        findsOneWidget,
      );
    });

    testWidgets('an old row without the time falls back to its last change', (
      t,
    ) async {
      await openHome(t, [
        reminder(
          'h1',
          'Power-wash the siding',
          category: 'exterior',
          enabled: false,
          updatedAt: DateTime(2026, 9, 12),
        ),
      ]);
      expect(find.text('OFF SINCE SEP 12 · YOU TURNED IT OFF'), findsOneWidget);
    });

    testWidgets('an every-3-years reminder says so on its pill', (t) async {
      await openHome(t, [
        reminder(
          'h1',
          'Re-caulk windows',
          category: 'exterior',
          intervalYears: 3,
        ),
      ]);
      expect(find.text('Every 3 years'), findsOneWidget);
      expect(find.byType(ReminderFrequencyRow), findsOneWidget);
    });

    testWidgets('turning a reminder off writes now with no reason', (t) async {
      final repo = await openHome(t, [
        reminder('h1', 'Power-wash the siding', category: 'exterior'),
      ]);
      await t.tap(find.byType(AuroraSwitch));
      await settle(t);
      expect(repo.enabledCalls, [('h1', false)]);
      expect(repo.enabledReasons, [null]);
      final today = DateFormat('MMM d').format(DateTime.now()).toUpperCase();
      expect(find.text('OFF SINCE $today · YOU TURNED IT OFF'), findsOneWidget);
    });

    testWidgets('turning it back on writes on, which clears when and why', (
      t,
    ) async {
      final repo = await openHome(t, [
        reminder(
          'h1',
          'Power-wash the siding',
          category: 'exterior',
          enabled: false,
          offAt: aug30,
          offReason: 'No siding',
        ),
      ]);
      await t.tap(find.byType(AuroraSwitch));
      await settle(t);
      expect(repo.enabledCalls, [('h1', true)]);
      expect(repo.enabledReasons, [null]);
      expect(repo.enabledOffAts, [null]);
      expect(find.textContaining('OFF SINCE'), findsNothing);
    });
  });

  group('Turned-off reminders', () {
    Future<FakeRemindersRepository> openSettings(
      WidgetTester t,
      ReminderItem item,
    ) async {
      final repo = FakeRemindersRepository(RemindersData(items: [item]));
      await pumpRouted(
        t,
        const SettingsRemindersScreen(),
        overrides: reminderOverrides(repo),
      );
      return repo;
    }

    ReminderItem off({DateTime? offAt, String? reason}) => reminder(
      'f3',
      'Replace the humidifier pad',
      enabled: false,
      systemId: 's-furnace',
      itemName: 'Furnace',
      offAt: offAt,
      offReason: reason,
      updatedAt: DateTime(2026, 9, 20),
    );

    testWidgets('shows when it was turned off and the reason', (t) async {
      await openSettings(
        t,
        off(offAt: DateTime(2026, 9, 12), reason: 'No whole-house humidifier'),
      );
      expect(
        find.text('OFF SINCE SEP 12 · NO WHOLE-HOUSE HUMIDIFIER'),
        findsOneWidget,
      );
    });

    testWidgets('without a reason it is just the date', (t) async {
      await openSettings(t, off(offAt: DateTime(2026, 9, 12)));
      expect(find.text('OFF SINCE SEP 12'), findsOneWidget);
    });

    testWidgets(
      'a row from before the time was recorded uses its last change',
      (t) async {
        await openSettings(t, off());
        expect(find.text('OFF SINCE SEP 20'), findsOneWidget);
      },
    );

    testWidgets('Undo puts back the original time and reason', (t) async {
      final repo = await openSettings(
        t,
        off(offAt: DateTime(2026, 9, 12), reason: 'No humidifier'),
      );
      await t.tap(find.text(RemindersCopy.turnOn));
      await settle(t);
      await t.tap(find.text(RemindersCopy.undo));
      await settle(t);
      expect(repo.enabledCalls, [('f3', true), ('f3', false)]);
      expect(repo.enabledReasons, [null, 'No humidifier']);
      expect(repo.enabledOffAts, [null, DateTime(2026, 9, 12)]);
      expect(find.text('OFF SINCE SEP 12 · NO HUMIDIFIER'), findsOneWidget);
    });

    testWidgets('Turn on sits at the right edge of its row', (t) async {
      await openSettings(t, off(offAt: DateTime(2026, 9, 12)));
      final pill = t.getRect(find.text(RemindersCopy.turnOn));
      expect(390 - pill.right, lessThan(16 + 14 + 14 + 8));
      expect(pill.left, greaterThan(390 / 2));
    });
  });

  group('RemindersNotifier', () {
    test('how often drops an every-N-years interval locally', () async {
      final repo = FakeRemindersRepository(
        RemindersData(
          items: [
            reminder(
              'h1',
              'Re-caulk windows',
              recurrence: RecurrenceType.annual,
              intervalYears: 3,
            ),
          ],
        ),
      );
      final c = ProviderContainer(overrides: reminderOverrides(repo));
      addTearDown(c.dispose);
      c.listen(remindersProvider, (_, _) {});
      await c.read(remindersProvider.future);
      await c
          .read(remindersProvider.notifier)
          .setRecurrence('h1', RecurrenceType.quarterly);
      final item = c.read(remindersProvider).value!.items.single;
      expect(item.recurrence, RecurrenceType.quarterly);
      expect(item.intervalYears, isNull);
    });

    test('a failed turn-off puts the old time and reason back', () async {
      final repo = FakeRemindersRepository(
        RemindersData(
          items: [reminder('h1', 'Power-wash', offAt: DateTime(2026, 8, 30))],
        ),
      )..writeError = StateError('offline');
      final c = ProviderContainer(overrides: reminderOverrides(repo));
      addTearDown(c.dispose);
      c.listen(remindersProvider, (_, _) {});
      await c.read(remindersProvider.future);
      await expectLater(
        c.read(remindersProvider.notifier).setEnabled('h1', enabled: false),
        throwsStateError,
      );
      final item = c.read(remindersProvider).value!.items.single;
      expect(item.enabled, isTrue);
      expect(item.offAt, DateTime(2026, 8, 30));
    });
  });
}
