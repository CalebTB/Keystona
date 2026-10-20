import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/maintenance/models/maintenance_task.dart';
import 'package:keystona/features/maintenance/models/reminder_frequency.dart';
import 'package:keystona/features/maintenance/models/task_draft.dart';
import 'package:keystona/features/maintenance/models/task_form_options.dart';
import 'package:keystona/features/maintenance/models/task_suggestions.dart';

import 'form_reminders_support.dart';

void main() {
  final furnace = kLinkOptions.first;

  group('validation', () {
    test('needs a name and an item', () {
      const empty = TaskDraft();
      expect(empty.isReady, isFalse);
      expect(empty.copyWith(name: 'Check filter').isReady, isFalse);
      expect(empty.copyWith(link: furnace).isReady, isFalse);
      expect(empty.copyWith(name: ' ', link: furnace).isReady, isFalse);
      expect(
        empty.copyWith(name: 'Check filter', link: furnace).isReady,
        isTrue,
      );
    });

    test('a bad cost blocks save, a good or empty one does not', () {
      final ready = const TaskDraft().copyWith(name: 'x', link: furnace);
      expect(ready.copyWith(cost: 'abc').isReady, isFalse);
      expect(ready.copyWith(cost: 'abc').costError, TaskDraft.costMessage);
      expect(ready.copyWith(cost: '-3').isReady, isFalse);
      expect(ready.copyWith(cost: '25.50').isReady, isTrue);
      expect(ready.copyWith(cost: '').costError, isNull);
    });

    test('name and notes have length limits', () {
      final ready = const TaskDraft().copyWith(name: 'x', link: furnace);
      expect(ready.copyWith(name: 'a' * 81).isReady, isFalse);
      expect(ready.copyWith(name: 'a' * 80).isReady, isTrue);
      expect(ready.copyWith(notes: 'a' * 501).isReady, isFalse);
    });

    test('a null link and null minutes can be set explicitly', () {
      final d = const TaskDraft().copyWith(link: furnace, minutes: 30);
      expect(d.copyWith(link: null).link, isNull);
      expect(d.copyWith(minutes: null).minutes, isNull);
      expect(d.copyWith(name: 'x').link, furnace);
      expect(d.copyWith(name: 'x').minutes, 30);
    });
  });

  group('dates', () {
    test('the chips match the kit, drawn on Sunday Oct 4', () {
      final d = const TaskDraft();
      expect(d.dateFor(DueChoice.today, kToday), DateTime(2026, 10, 4));
      expect(d.dateFor(DueChoice.saturday, kToday), DateTime(2026, 10, 10));
      expect(d.dateFor(DueChoice.twoWeeks, kToday), DateTime(2026, 10, 18));
    });

    test('Saturday on a Saturday means next week', () {
      expect(
        TaskDraft.nextSaturday(DateTime(2026, 10, 10)),
        DateTime(2026, 10, 17),
      );
      expect(
        TaskDraft.nextSaturday(DateTime(2026, 10, 9)),
        DateTime(2026, 10, 10),
      );
    });

    test('Other is the picked date, or today until one is picked', () {
      final d = const TaskDraft().copyWith(due: DueChoice.other);
      expect(d.dueDate(kToday), DateTime(2026, 10, 4));
      expect(
        d.copyWith(customDate: DateTime(2026, 11, 1)).dueDate(kToday),
        DateTime(2026, 11, 1),
      );
    });

    test('the reminder warns when the lead time is longer than the wait', () {
      final d = const TaskDraft();
      expect(d.remindHelp(kToday), TaskDraft.remindSoonerCopy);
      expect(
        d.copyWith(remindDays: 0).remindHelp(kToday),
        TaskDraft.remindDefaultCopy,
      );
      expect(
        d.copyWith(due: DueChoice.twoWeeks, remindDays: 7).remindHelp(kToday),
        TaskDraft.remindDefaultCopy,
      );
      expect(
        d.copyWith(due: DueChoice.saturday, remindDays: 7).remindHelp(kToday),
        TaskDraft.remindSoonerCopy,
      );
    });
  });

  group('summary', () {
    test('says what is missing', () {
      const d = TaskDraft();
      expect(d.summary(kToday), "Add a name and pick what it's for to save.");
      expect(d.copyWith(link: furnace).summary(kToday), 'Add a name to save.');
      expect(
        d.copyWith(name: 'x').summary(kToday),
        "Pick what it's for to save.",
      );
    });

    test('says what saving does', () {
      final d = const TaskDraft().copyWith(name: 'x', link: furnace);
      expect(
        d.summary(kToday),
        'Due today. It shows up under the furnace and in Tasks.',
      );
      expect(
        d
            .copyWith(
              due: DueChoice.saturday,
              frequency: TaskFrequency.everyThreeMonths,
            )
            .summary(kToday),
        'Due Saturday, Oct 10, then every 3 months. '
        'It shows up under the furnace and in Tasks.',
      );
      expect(
        d
            .copyWith(frequency: TaskFrequency.everyFewYears, years: 5)
            .summary(kToday),
        contains(', then every 5 years.'),
      );
    });

    test('who help follows the choice', () {
      const d = TaskDraft();
      expect(d.whoHelp, "You'll do it yourself");
      expect(
        d.copyWith(who: TaskWho.pro).whoHelp,
        "When you mark it done, we'll ask who you hired",
      );
      expect(
        d.copyWith(who: TaskWho.either).whoHelp,
        "We'll show a pro option if it gets late",
      );
    });
  });

  group('payload', () {
    test('create writes the form as columns', () {
      final d = const TaskDraft().copyWith(
        name: '  Replace filter ',
        link: furnace,
        frequency: TaskFrequency.everyThreeMonths,
        due: DueChoice.saturday,
        notes: ' behind the grille ',
        minutes: 15,
        effort: TaskEffort.medium,
        who: TaskWho.pro,
        supplies: '16×25×1 filter, MERV 8, ,',
      );
      final fields = d.toFields(
        today: kToday,
        category: furnace.category,
        editing: false,
      );
      expect(fields, {
        'name': 'Replace filter',
        'notes': 'behind the grille',
        'category': 'hvac',
        'due_date': '2026-10-10',
        'recurrence': 'quarterly',
        'recurrence_interval_years': null,
        'estimated_cost': null,
        'difficulty': 'moderate',
        'diy_or_pro': 'professional',
        'estimated_minutes': 15,
        'supplies_needed': ['16×25×1 filter', 'MERV 8'],
        'linked_system_id': 's-furnace',
        'linked_appliance_id': null,
        'reminder_days_before': 7,
      });
      expect(d.origin, TaskOrigin.custom);
    });

    test('a task on an appliance clears the system link', () {
      final d = const TaskDraft().copyWith(name: 'x', link: kLinkOptions.last);
      final fields = d.toFields(
        today: kToday,
        category: 'appliance',
        editing: false,
      );
      expect(fields['linked_appliance_id'], 'a-dryer');
      expect(fields['linked_system_id'], isNull);
    });

    test('a one-time task is saved as one-time', () {
      expect(const TaskDraft().origin, TaskOrigin.oneTime);
    });

    test('empty notes become null; due date is YYYY-MM-DD', () {
      final d = const TaskDraft().copyWith(name: 'x', link: furnace);
      final fields = d.toFields(
        today: DateTime(2026, 3, 5),
        category: 'hvac',
        editing: false,
      );
      expect(fields['notes'], isNull);
      expect(fields['due_date'], '2026-03-05');
    });

    test('edit leaves the reminder lead time alone unless it changed', () {
      final seeded = TaskDraft.fromTask(savedTask(), link: furnace);
      final untouched = seeded.toFields(
        today: kToday,
        category: 'hvac',
        editing: true,
      );
      expect(untouched.containsKey('reminder_days_before'), isFalse);
      final touched = seeded
          .copyWith(remindDays: 3)
          .toFields(today: kToday, category: 'hvac', editing: true);
      expect(touched['reminder_days_before'], 3);
    });
  });

  group('edit mode seed', () {
    test('fills every field from the saved task', () {
      final d = TaskDraft.fromTask(savedTask(), link: furnace);
      expect(d.name, 'Replace HVAC air filter');
      expect(d.frequency, TaskFrequency.everyThreeMonths);
      expect(d.due, DueChoice.other);
      expect(d.customDate, DateTime(2026, 11, 1));
      expect(d.notes, 'Behind the grille');
      expect(d.minutes, 30);
      expect(d.supplies, '16×25×1 filter, MERV 8');
      expect(d.isReady, isTrue);
    });

    test('weekly tasks read as monthly rather than breaking the picker', () {
      expect(
        TaskFrequency.fromRecurrence(RecurrenceType.weekly),
        TaskFrequency.monthly,
      );
    });
  });

  group('suggestions', () {
    test('common tasks show on an empty form, then hide once typed', () {
      const d = TaskDraft();
      expect(TaskSuggestions.shown(d), [
        'Replace HVAC air filter',
        'Clean gutters',
        'Flush water heater',
        'Clean dryer vent',
      ]);
      expect(TaskSuggestions.titleFor(d), 'Common tasks · tap to fill in');
      expect(TaskSuggestions.shown(d.copyWith(name: 'Something')), isEmpty);
    });

    test('an item brings its usual jobs', () {
      final d = const TaskDraft().copyWith(link: furnace);
      expect(TaskSuggestions.shown(d), [
        'Replace HVAC air filter',
        'Service the furnace',
        'Clean the burners',
      ]);
      expect(TaskSuggestions.titleFor(d), 'Usual for the furnace');
      expect(
        TaskSuggestions.shown(d.copyWith(name: 'Service the furnace')),
        isEmpty,
        reason: 'a usual job already chosen',
      );
    });

    test(
      'tapping a common one fills name, item, how often, who and details',
      () {
        final d = TaskSuggestions.apply(
          const TaskDraft(),
          'Replace HVAC air filter',
          kLinkOptions,
        );
        expect(d.name, 'Replace HVAC air filter');
        expect(d.link?.id, 's-furnace');
        expect(d.frequency, TaskFrequency.everyThreeMonths);
        expect(d.who, TaskWho.me);
        expect(d.minutes, 15);
        expect(d.cost, '25');
        expect(d.supplies, '16×25×1 filter, MERV 8');
      },
    );

    test('a common task whose item the home lacks keeps the current item', () {
      final d = TaskSuggestions.apply(
        const TaskDraft().copyWith(link: kLinkOptions[1]),
        'Clean dryer vent',
        [kLinkOptions[1]],
      );
      expect(d.link?.id, 's-wh');
    });

    test('an item job only fills the name', () {
      final d = TaskSuggestions.apply(
        const TaskDraft().copyWith(link: furnace),
        'Clean the burners',
        kLinkOptions,
      );
      expect(d.name, 'Clean the burners');
      expect(d.frequency, TaskFrequency.once);
    });
  });

  group('options', () {
    test('time keeps a saved value that is not in the list', () {
      expect(TimeOptions.choices(null).first, isNull);
      expect(TimeOptions.choices(25), contains(25));
      expect(TimeOptions.choices(30).where((m) => m == 30), hasLength(1));
      expect(TimeOptions.label(null), 'Not sure');
      expect(TimeOptions.label(60), '1 hr');
      expect(TimeOptions.label(240), 'Half a day');
    });

    test('remind labels', () {
      expect(RemindOptions.label(0), 'The morning of');
      expect(RemindOptions.label(7), '1 week before');
      expect(RemindOptions.label(14), '2 weeks before');
    });

    test('difficulty and who map to the schema', () {
      expect(
        TaskEffort.fromDifficulty(TaskDifficulty.involved),
        TaskEffort.hard,
      );
      expect(
        TaskEffort.fromDifficulty(TaskDifficulty.professional),
        TaskEffort.hard,
      );
      expect(TaskWho.fromDiyOrPro(DiyOrPro.professional), TaskWho.pro);
    });

    test('link meta reads as the kit', () {
      expect(kLinkOptions.first.listMeta, 'HVAC · BASEMENT · 3 TASKS');
      expect(kLinkOptions.first.fieldMeta, 'SYSTEM · HVAC');
      expect(kLinkOptions[2].listMeta, 'ROOFING · 1 TASK');
      expect(kLinkOptions.last.fieldMeta, 'APPLIANCE · LAUNDRY');
    });
  });

  group('how often for reminders', () {
    test('per month never rounds a real list to zero', () {
      expect(ReminderFrequency.perMonth(const []), 0);
      expect(ReminderFrequency.perMonth([RecurrenceType.annual]), 1);
      expect(
        ReminderFrequency.perMonth([
          RecurrenceType.monthly,
          RecurrenceType.monthly,
          RecurrenceType.quarterly,
        ]),
        2,
      );
    });

    test('labels and parsing', () {
      expect(
        ReminderFrequency.label(RecurrenceType.quarterly),
        'Every 3 months',
      );
      expect(ReminderFrequency.label(RecurrenceType.biannual), 'Twice a year');
      expect(ReminderFrequency.parse('quarterly'), RecurrenceType.quarterly);
      expect(ReminderFrequency.parse('weird'), RecurrenceType.none);
    });
  });
}
