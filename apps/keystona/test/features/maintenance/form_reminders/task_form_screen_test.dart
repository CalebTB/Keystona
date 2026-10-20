import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/widgets/aurora/aurora_button.dart';
import 'package:keystona/core/widgets/error_view.dart';
import 'package:keystona/features/maintenance/models/task_draft.dart';
import 'package:keystona/features/maintenance/models/task_form_options.dart';
import 'package:keystona/features/maintenance/screens/task_form_screen.dart';
import 'package:keystona/features/maintenance/task_form_copy.dart';
import 'package:keystona/features/maintenance/widgets/form/task_form_body.dart';
import 'package:keystona/features/maintenance/widgets/form/task_form_skeleton.dart';

import 'form_reminders_support.dart';

Finder get _save => find.widgetWithText(SaveButton, TaskFormCopy.save);

bool _saveEnabled(WidgetTester tester) =>
    tester.widget<SaveButton>(_save).onPressed != null;

TextEditingController _field(WidgetTester tester, int index) =>
    tester.widget<TextField>(find.byType(TextField).at(index)).controller!;

Future<void> _type(WidgetTester tester, int index, String text) async {
  await tester.ensureVisible(find.byType(TextField).at(index));
  await tester.enterText(find.byType(TextField).at(index), text);
  await tester.pump();
}

Future<void> _pickFurnace(WidgetTester tester) async {
  await tester.ensureVisible(find.text(TaskFormCopy.linkPlaceholder));
  await tester.tap(find.text(TaskFormCopy.linkPlaceholder));
  await settle(tester);
  await tester.tap(find.text('Furnace'));
  await settle(tester);
}

Future<void> _pumpForm(
  WidgetTester tester,
  FakeTaskFormRepository repo, {
  TaskFormScreen screen = const TaskFormScreen(today: null),
  Size size = const Size(390, 844),
}) => pumpRouted(tester, screen, overrides: formOverrides(repo), size: size);

TaskFormScreen _create() => TaskFormScreen(today: kToday);

void main() {
  group('create', () {
    testWidgets('Save stays off until there is a name and an item', (
      tester,
    ) async {
      await _pumpForm(tester, FakeTaskFormRepository(), screen: _create());
      expect(find.text(TaskFormCopy.title), findsOneWidget);
      expect(_saveEnabled(tester), isFalse);
      expect(
        find.text("Add a name and pick what it's for to save.".toUpperCase()),
        findsNothing,
        reason: 'the summary is sentence case, not uppercase',
      );
      expect(
        find.text("Add a name and pick what it's for to save."),
        findsOneWidget,
      );

      await _type(tester, 0, 'Check filter');
      expect(_saveEnabled(tester), isFalse);
      expect(find.text("Pick what it's for to save."), findsOneWidget);

      await _pickFurnace(tester);
      expect(_saveEnabled(tester), isTrue);
      expect(
        find.text('Due today. It shows up under the furnace and in Tasks.'),
        findsOneWidget,
      );
      expect(find.text('SYSTEM · HVAC'), findsOneWidget);
    });

    testWidgets('saves what was filled in and closes', (tester) async {
      final repo = FakeTaskFormRepository();
      await _pumpForm(tester, repo, screen: _create());
      await _type(tester, 0, 'Check filter');
      await _pickFurnace(tester);
      await tester.tap(_save);
      await settle(tester);

      final saved = repo.created.single;
      expect(saved.propertyId, 'p1');
      expect(saved.draft.name, 'Check filter');
      expect(saved.draft.link?.id, 's-furnace');
      expect(saved.today, kToday);
      expect(find.byType(TaskFormScreen), findsNothing);
    });

    testWidgets('a failed save stays open, says so and can be retried', (
      tester,
    ) async {
      final repo = FakeTaskFormRepository()..saveError = StateError('offline');
      await _pumpForm(tester, repo, screen: _create());
      await _type(tester, 0, 'Check filter');
      await _pickFurnace(tester);
      await tester.tap(_save);
      await settle(tester);

      expect(find.text(TaskFormCopy.saveError), findsOneWidget);
      expect(find.byType(TaskFormScreen), findsOneWidget);
      expect(_saveEnabled(tester), isTrue);

      repo.saveError = null;
      await tester.tap(_save);
      await settle(tester);
      expect(repo.created, hasLength(1));
    });

    testWidgets('a bad estimate blocks Save and says why', (tester) async {
      await _pumpForm(tester, FakeTaskFormRepository(), screen: _create());
      await _type(tester, 0, 'Check filter');
      await _pickFurnace(tester);
      await _type(tester, 2, 'abc');
      expect(find.text(TaskDraft.costMessage.toUpperCase()), findsOneWidget);
      expect(_saveEnabled(tester), isFalse);
      await _type(tester, 2, '25.50');
      expect(find.text(TaskDraft.costMessage.toUpperCase()), findsNothing);
      expect(_saveEnabled(tester), isTrue);
    });

    testWidgets('a common task fills the form in one tap', (tester) async {
      await _pumpForm(tester, FakeTaskFormRepository(), screen: _create());
      expect(find.text('COMMON TASKS · TAP TO FILL IN'), findsOneWidget);
      await tester.tap(find.text('Replace HVAC air filter'));
      await settle(tester);

      expect(_field(tester, 0).text, 'Replace HVAC air filter');
      expect(find.text('Furnace'), findsOneWidget);
      expect(find.text('Every 3 months'), findsOneWidget);
      expect(_field(tester, 2).text, '25');
      expect(_field(tester, 3).text, '16×25×1 filter, MERV 8');
      expect(_saveEnabled(tester), isTrue);
      // The chips go away once the name is one of them.
      expect(find.text('COMMON TASKS · TAP TO FILL IN'), findsNothing);
    });

    testWidgets('choosing an item offers its usual jobs', (tester) async {
      await _pumpForm(tester, FakeTaskFormRepository(), screen: _create());
      await _pickFurnace(tester);
      expect(find.text('USUAL FOR THE FURNACE'), findsOneWidget);
      await tester.ensureVisible(find.text('Clean the burners'));
      await tester.tap(find.text('Clean the burners'));
      await settle(tester);
      expect(_field(tester, 0).text, 'Clean the burners');
    });

    testWidgets('the picker switches between systems and appliances', (
      tester,
    ) async {
      final repo = FakeTaskFormRepository();
      await _pumpForm(tester, repo, screen: _create());
      await tester.tap(find.text(TaskFormCopy.linkPlaceholder));
      await settle(tester);
      expect(find.text('Systems · 3'), findsOneWidget);
      expect(find.text('Appliances · 1'), findsOneWidget);
      expect(find.text('HVAC · BASEMENT · 3 TASKS'), findsOneWidget);

      await tester.tap(find.text('Appliances · 1'));
      await settle(tester);
      expect(find.text('Dryer'), findsOneWidget);
      expect(find.text('Furnace'), findsNothing);
      await tester.tap(find.text('Dryer'));
      await settle(tester);
      expect(find.text('APPLIANCE · LAUNDRY'), findsOneWidget);
    });

    testWidgets('how often "every few years" shows the slider', (tester) async {
      await _pumpForm(tester, FakeTaskFormRepository(), screen: _create());
      expect(find.byType(Slider), findsNothing);
      await tester.ensureVisible(find.text(TaskFrequency.once.label));
      await tester.tap(find.text(TaskFrequency.once.label));
      await settle(tester);
      await tester.tap(find.text(TaskFrequency.everyFewYears.label));
      await settle(tester);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('3 years'), findsOneWidget);
    });

    testWidgets('the reminder note follows the due date', (tester) async {
      await _pumpForm(tester, FakeTaskFormRepository(), screen: _create());
      final warning = TaskDraft.remindSoonerCopy.toUpperCase();
      await tester.ensureVisible(find.text('2 weeks'));
      expect(
        find.text(warning),
        findsOneWidget,
        reason: 'today, 1 week before',
      );
      await tester.tap(find.text('2 weeks'));
      await settle(tester);
      expect(find.text(warning), findsNothing);
      expect(
        find.text(TaskDraft.remindDefaultCopy.toUpperCase()),
        findsOneWidget,
      );
      expect(find.text('OCT 18'), findsOneWidget);
      expect(find.text('SUN 4'), findsOneWidget);
      expect(find.text('OCT 10'), findsOneWidget);
    });

    testWidgets('Other shows a date field', (tester) async {
      await _pumpForm(tester, FakeTaskFormRepository(), screen: _create());
      await tester.ensureVisible(find.text(TaskFormCopy.dueOther));
      await tester.tap(find.text(TaskFormCopy.dueOther));
      await settle(tester);
      expect(find.text('Sunday, Oct 4, 2026'), findsOneWidget);
    });

    testWidgets('who does it changes the note under it', (tester) async {
      await _pumpForm(tester, FakeTaskFormRepository(), screen: _create());
      await tester.ensureVisible(find.text('A pro'));
      expect(find.text("YOU'LL DO IT YOURSELF"), findsOneWidget);
      await tester.tap(find.text('A pro'));
      await settle(tester);
      expect(
        find.text("WHEN YOU MARK IT DONE, WE'LL ASK WHO YOU HIRED"),
        findsOneWidget,
      );
    });

    testWidgets('Cancel closes without saving', (tester) async {
      final repo = FakeTaskFormRepository();
      await _pumpForm(tester, repo, screen: _create());
      await tester.tap(find.text(TaskFormCopy.cancel));
      await settle(tester);
      expect(find.byType(TaskFormScreen), findsNothing);
      expect(repo.created, isEmpty);
    });
  });

  group('states', () {
    testWidgets('loading shows the skeleton and a disabled Save', (
      tester,
    ) async {
      final gate = Completer<void>();
      await _pumpForm(
        tester,
        FakeTaskFormRepository(gate: gate),
        screen: _create(),
      );
      expect(find.byType(TaskFormSkeleton), findsOneWidget);
      expect(_saveEnabled(tester), isFalse);
      gate.complete();
      await settle(tester);
      expect(find.byType(TaskFormSkeleton), findsNothing);
    });

    testWidgets('an offline load shows the error with retry', (tester) async {
      final repo = FakeTaskFormRepository(contextFails: true);
      await _pumpForm(tester, repo, screen: _create());
      expect(find.byType(ErrorView), findsOneWidget);
      repo.contextFails = false;
      await tester.tap(find.text('Try again'));
      await settle(tester);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.byType(TaskFormBody), findsOneWidget);
    });

    testWidgets('a person with no home cannot save a task', (tester) async {
      await _pumpForm(
        tester,
        FakeTaskFormRepository(propertyId: null),
        screen: _create(),
      );
      expect(find.byType(ErrorView), findsOneWidget);
      expect(_saveEnabled(tester), isFalse);
    });
  });

  group('edit', () {
    testWidgets('opens filled in with the task and updates it', (tester) async {
      final repo = FakeTaskFormRepository();
      await _pumpForm(
        tester,
        repo,
        screen: TaskFormScreen(existingTask: savedTask(), today: kToday),
      );
      expect(find.text(TaskFormCopy.editTitle), findsOneWidget);
      expect(_field(tester, 0).text, 'Replace HVAC air filter');
      expect(_field(tester, 1).text, 'Behind the grille');
      expect(find.text('Furnace'), findsOneWidget);
      expect(find.text('Every 3 months'), findsOneWidget);
      expect(_saveEnabled(tester), isTrue);

      await _type(tester, 0, 'Replace the filter');
      await tester.tap(_save);
      await settle(tester);

      expect(repo.created, isEmpty);
      final saved = repo.updated.single;
      expect(saved.id, 't-1');
      expect(saved.category, 'hvac');
      expect(saved.draft.name, 'Replace the filter');
      expect(saved.draft.remindTouched, isFalse);
      expect(find.byType(TaskFormScreen), findsNothing);
    });

    testWidgets('loads the task when only its id is known', (tester) async {
      final repo = FakeTaskFormRepository(task: savedTask(id: 't-9'));
      await _pumpForm(
        tester,
        repo,
        screen: TaskFormScreen(taskId: 't-9', today: kToday),
      );
      expect(find.text(TaskFormCopy.editTitle), findsOneWidget);
      expect(_field(tester, 0).text, 'Replace HVAC air filter');
      await tester.tap(_save);
      await settle(tester);
      expect(repo.updated.single.id, 't-9');
    });

    testWidgets('an item that no longer exists must be picked again', (
      tester,
    ) async {
      final repo = FakeTaskFormRepository(task: savedTask(systemId: 'gone'));
      await _pumpForm(
        tester,
        repo,
        screen: TaskFormScreen(taskId: 't-1', today: kToday),
      );
      expect(find.text(TaskFormCopy.linkPlaceholder), findsOneWidget);
      expect(_saveEnabled(tester), isFalse);
    });
  });

  group('positions', () {
    testWidgets('Save is at the right edge, Cancel at the left', (
      tester,
    ) async {
      await _pumpForm(tester, FakeTaskFormRepository(), screen: _create());
      final save = tester.getRect(_save);
      expect(save.right, closeTo(390 - 16, 1));
      final cancel = tester.getRect(find.text(TaskFormCopy.cancel));
      expect(cancel.left, closeTo(16, 1));
      final title = tester.getRect(find.text(TaskFormCopy.title));
      expect(title.center.dx, closeTo(195, 12));
    });

    testWidgets('time and difficulty sit side by side, equal width', (
      tester,
    ) async {
      await _pumpForm(tester, FakeTaskFormRepository(), screen: _create());
      await tester.ensureVisible(
        find.text(TaskFormCopy.timeLabel.toUpperCase()),
      );
      final time = tester.getRect(find.text('TIME'));
      final difficulty = tester.getRect(find.text('DIFFICULTY'));
      expect(difficulty.left, greaterThan(time.right));
      expect(difficulty.top, closeTo(time.top, 1));
    });

    testWidgets('the four first-due chips share a row', (tester) async {
      await _pumpForm(tester, FakeTaskFormRepository(), screen: _create());
      await tester.ensureVisible(find.text('Saturday'));
      final today = tester.getRect(find.text('Today'));
      final other = tester.getRect(find.text('Other'));
      expect(other.top, closeTo(today.top, 1));
      expect(other.right, lessThanOrEqualTo(390 - 16));
    });

    testWidgets('who does it: three equal choices in one row', (tester) async {
      await _pumpForm(tester, FakeTaskFormRepository(), screen: _create());
      await tester.ensureVisible(find.text('Either'));
      final me = tester.getRect(find.text('Me'));
      final either = tester.getRect(find.text('Either'));
      expect(either.top, closeTo(me.top, 1));
      expect(either.left, greaterThan(me.right));
    });

    testWidgets('large text stacks the two-up fields instead of squeezing', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        _create(),
        overrides: formOverrides(FakeTaskFormRepository()),
        textScale: 2.0,
      );
      await tester.ensureVisible(find.text('TIME'));
      final time = tester.getRect(find.text('TIME'));
      final difficulty = tester.getRect(find.text('DIFFICULTY'));
      expect(difficulty.top, greaterThan(time.bottom));
      expect(tester.takeException(), isNull);
    });
  });

  group('keyboard', () {
    testWidgets('the form still scrolls with the keyboard up', (tester) async {
      await pumpRouted(
        tester,
        _create(),
        overrides: formOverrides(FakeTaskFormRepository()),
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await settle(tester);
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -600),
      );
      await settle(tester);
      expect(tester.takeException(), isNull);
    });
  });

  group('responsive', () {
    testResponsiveLoaded(
      'create form',
      _create,
      overrides: () => formOverrides(FakeTaskFormRepository()),
    );

    testResponsiveLoaded(
      'create form, everything open',
      _create,
      overrides: () => formOverrides(FakeTaskFormRepository()),
      after: (tester) async {
        await tapVisible(tester, find.text(TaskFormCopy.linkPlaceholder));
        await tapVisible(tester, find.text('Furnace'));
        await tapVisible(tester, find.text(TaskFrequency.once.label));
        await tapVisible(tester, find.text(TaskFrequency.everyFewYears.label));
        await tapVisible(tester, find.text(TaskFormCopy.dueOther));
        await tester.enterText(find.byType(TextField).at(2), 'abc');
        await tester.pump();
        await tapVisible(tester, find.text(TimeOptions.unknownLabel));
        await tapVisible(tester, find.text('Half a day'));
      },
    );

    testResponsiveLoaded(
      'edit form',
      () => TaskFormScreen(existingTask: savedTask(), today: kToday),
      overrides: () => formOverrides(FakeTaskFormRepository()),
    );

    testResponsiveLoaded(
      'error state',
      _create,
      overrides: () =>
          formOverrides(FakeTaskFormRepository(contextFails: true)),
    );
  });
}
