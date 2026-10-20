import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/widgets/aurora/aurora_button.dart';
import 'package:keystona/core/widgets/aurora/aurora_toggle_row.dart';
import 'package:keystona/core/widgets/empty_state.dart';
import 'package:keystona/core/widgets/error_view.dart';
import 'package:keystona/core/widgets/task_generation_sheet.dart';
import 'package:keystona/features/maintenance/models/reminder_item.dart';
import 'package:keystona/features/maintenance/providers/reminders_providers.dart';
import 'package:keystona/features/maintenance/reminders_copy.dart';
import 'package:keystona/features/maintenance/screens/task_review_screen.dart';
import 'package:keystona/features/maintenance/widgets/reminders/reminder_switch_row.dart';
import 'package:keystona/features/maintenance/widgets/reminders/reminders_skeleton.dart';
import 'package:keystona/features/maintenance/widgets/review/task_review_sheet.dart';

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
    const TaskReviewScreen(),
    overrides: reminderOverrides(fake),
    size: size,
    textScale: textScale,
  );
  return fake;
}

Finder get _cta => find.widgetWithText(PrimaryButton, 'Looks good — keep 5');

void main() {
  group('review screen', () {
    testWidgets('header, summary and groups match the kit', (tester) async {
      await _open(tester);
      expect(find.text(RemindersCopy.setupStep.toUpperCase()), findsOneWidget);
      expect(find.text(RemindersCopy.reviewTitle), findsOneWidget);
      expect(find.text(RemindersCopy.reviewBlurb), findsOneWidget);
      expect(find.textContaining('5 of 9 on'), findsOneWidget);
      expect(find.text('ABOUT 2 A MONTH'), findsOneWidget);
      expect(find.text(RemindersCopy.turnAllOn), findsOneWidget);
      expect(_cta, findsOneWidget);

      expect(find.text('FURNACE'), findsOneWidget);
      expect(find.text('BECAUSE YOU ADDED A FURNACE'), findsOneWidget);
      expect(find.text('WASHER'), findsOneWidget);
      expect(find.text('SAFETY'), findsOneWidget);
      expect(find.text('EVERY HOUSE'), findsWidgets);
      await reveal(tester, find.text('ZONE 4'));
      expect(find.text('FROM YOUR CLIMATE'), findsOneWidget);
      expect(find.text('ZONE 4'), findsOneWidget);
      await reveal(tester, find.text(RemindersCopy.reviewFooter.toUpperCase()));
      expect(
        find.text(RemindersCopy.reviewFooter.toUpperCase()),
        findsOneWidget,
      );
    });

    testWidgets('your own reminders are not part of the review', (
      tester,
    ) async {
      await _open(tester);
      expect(find.text('Clean the window wells'), findsNothing);
    });

    testWidgets('on rows show how often, off rows say they won\'t show up', (
      tester,
    ) async {
      await _open(tester);
      expect(find.text('EVERY 3 MONTHS'), findsOneWidget);
      expect(find.text("OFF · WON'T SHOW UP"), findsWidgets);
    });

    testWidgets('a switch saves, and the count and button follow', (
      tester,
    ) async {
      final repo = await _open(tester);
      await tester.tap(find.byType(AuroraSwitch).at(2));
      await settle(tester);
      expect(repo.enabledCalls, [('f3', true)]);
      expect(find.textContaining('6 of 9 on'), findsOneWidget);
      expect(
        find.widgetWithText(PrimaryButton, 'Looks good — keep 6'),
        findsOneWidget,
      );
    });

    testWidgets('a failed save rolls back and says so', (tester) async {
      final repo = FakeRemindersRepository(kReminders())
        ..writeError = StateError('offline');
      await _open(tester, repo: repo);
      await tester.tap(find.byType(AuroraSwitch).at(0));
      await settle(tester);
      expect(find.text(RemindersCopy.changeError), findsOneWidget);
      expect(find.textContaining('5 of 9 on'), findsOneWidget);
    });

    testWidgets('Turn all on turns on everything that is off, in one write', (
      tester,
    ) async {
      final repo = await _open(tester);
      await tester.tap(find.text(RemindersCopy.turnAllOn));
      await settle(tester);
      expect(
        repo.manyCalls.single.$1,
        unorderedEquals(['f3', 'w1', 'h3', 'h4']),
      );
      expect(repo.manyCalls.single.$2, isTrue);
      expect(find.textContaining('9 of 9 on'), findsOneWidget);
      expect(
        find.widgetWithText(PrimaryButton, 'Looks good — keep 9'),
        findsOneWidget,
      );
    });

    testWidgets('Looks good goes home', (tester) async {
      await _open(tester);
      await tester.tap(_cta);
      await settle(tester);
      expect(find.text('at /home'), findsOneWidget);
    });

    testWidgets('nothing kept: the button is off', (tester) async {
      await _open(
        tester,
        data: RemindersData(
          items: [kReminders().items[2]], // the humidifier pad, off
        ),
      );
      final button = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'Looks good — keep 0'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('no suggestions shows the empty state', (tester) async {
      await _open(
        tester,
        data: RemindersData(items: [kReminders().items.last]),
      );
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(RemindersCopy.reviewEmptyTitle), findsOneWidget);
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
      expect(find.text(RemindersCopy.reviewTitle), findsOneWidget);
    });

    testWidgets('pull to refresh reads again', (tester) async {
      final repo = await _open(tester);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
      await settle(tester);
      expect(repo.fetches, 2);
    });
  });

  group('review screen positions', () {
    testWidgets('switches at each row\'s right edge', (tester) async {
      await _open(tester);
      final rows = find.byType(ReminderSwitchRow);
      for (var i = 0; i < 3; i++) {
        final row = tester.getRect(rows.at(i));
        final sw = tester.getRect(find.byType(AuroraSwitch).at(i));
        expect(sw.right, closeTo(row.right - 14, 1), reason: 'row $i');
        expect(sw.center.dy, closeTo(row.center.dy, 1), reason: 'row $i');
      }
    });

    testWidgets('Turn all on is at the right edge, Home at the left', (
      tester,
    ) async {
      await _open(tester);
      expect(
        tester.getRect(find.text(RemindersCopy.turnAllOn)).right,
        closeTo(390 - 16, 1),
      );
      expect(
        tester
            .getRect(
              find.byIcon(Icons.chevron_left).evaluate().isEmpty
                  ? find.text(RemindersCopy.reviewBack)
                  : find.text(RemindersCopy.reviewBack),
            )
            .left,
        lessThan(60),
      );
    });

    testWidgets('the button is full width and stays at the bottom', (
      tester,
    ) async {
      await _open(tester);
      var button = tester.getRect(_cta);
      expect(button.left, closeTo(16, 1));
      expect(button.right, closeTo(390 - 16, 1));
      expect(button.bottom, lessThanOrEqualTo(844));
      final before = button.bottom;
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
      await settle(tester);
      button = tester.getRect(_cta);
      expect(button.bottom, closeTo(before, 1), reason: 'does not scroll away');
    });

    testWidgets('the summary count is left, the rate is right', (tester) async {
      await _open(tester);
      final rate = tester.getRect(find.text('ABOUT 2 A MONTH'));
      expect(rate.right, closeTo(390 - 16 - 14 - 1, 3));
    });
  });

  group('review sheet', () {
    Future<(bool?, FakeGeneratedTasksRepository)> run(
      WidgetTester tester, {
      List<SuggestedTask> tasks = kSuggested,
      FakeGeneratedTasksRepository? repo,
      Size size = const Size(390, 844),
      double textScale = 1.0,
      Future<void> Function()? whileOpen,
    }) async {
      final fake = repo ?? FakeGeneratedTasksRepository();
      bool? result;
      var finished = false;
      await pumpRouted(
        tester,
        Consumer(
          builder: (context, ref, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  result = await showTaskGenerationSheet(
                    context: context,
                    ref: ref,
                    itemName: 'Furnace',
                    brand: 'Northline',
                    category: 'hvac',
                    formType: 'system',
                    linkedSystemId: 's-furnace',
                    propertyId: 'p1',
                    prefetchedFuture: Future.value(tasks),
                  );
                  finished = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
        overrides: [generatedTasksRepositoryProvider.overrideWithValue(fake)],
        size: size,
        textScale: textScale,
      );
      await tester.tap(find.text('open'));
      await settle(tester);
      if (whileOpen != null) await whileOpen();
      return (finished ? result : null, fake);
    }

    testWidgets('shows the suggestions for that item, all on', (tester) async {
      await run(tester);
      expect(find.byType(TaskReviewSheet), findsOneWidget);
      expect(find.text(RemindersCopy.reviewTitle), findsOneWidget);
      expect(find.text('FURNACE'), findsNWidgets(2));
      expect(find.text('BECAUSE YOU ADDED A FURNACE'), findsOneWidget);
      expect(find.text('Replace HVAC air filter'), findsOneWidget);
      expect(find.textContaining('3 of 3 on'), findsOneWidget);
      expect(
        find.widgetWithText(PrimaryButton, 'Looks good — keep 3'),
        findsOneWidget,
      );
    });

    testWidgets(
      'keep adds the ones left on, closes the sheet, and returns true',
      (tester) async {
        bool? result;
        final fake = FakeGeneratedTasksRepository();
        var closed = false;
        await pumpRouted(
          tester,
          Consumer(
            builder: (context, ref, _) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showTaskGenerationSheet(
                    context: context,
                    ref: ref,
                    itemName: 'Furnace',
                    brand: '',
                    category: 'hvac',
                    formType: 'system',
                    linkedSystemId: 's-furnace',
                    propertyId: 'p1',
                    prefetchedFuture: Future.value(kSuggested),
                  );
                  closed = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
          overrides: [generatedTasksRepositoryProvider.overrideWithValue(fake)],
        );
        await tester.tap(find.text('open'));
        await settle(tester);

        await tester.tap(find.byType(AuroraSwitch).at(1));
        await settle(tester);
        expect(find.textContaining('2 of 3 on'), findsOneWidget);
        await tapVisible(
          tester,
          find.widgetWithText(PrimaryButton, 'Looks good — keep 2'),
        );

        expect(result, isTrue);
        expect(closed, isTrue);
        expect(fake.added.single.map((t) => t.name), [
          'Replace HVAC air filter',
          'Check the flue pipe for rust',
        ]);
        expect(fake.system, 's-furnace');
        expect(fake.appliance, isNull);
        expect(fake.property, 'p1');
        expect(find.byType(TaskReviewSheet), findsNothing);
        expect(
          find.text('open'),
          findsOneWidget,
          reason: 'the page is still there',
        );
      },
    );

    testWidgets('Skip returns false and adds nothing', (tester) async {
      final fake = FakeGeneratedTasksRepository();
      bool? result;
      await pumpRouted(
        tester,
        Consumer(
          builder: (context, ref, _) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await showTaskGenerationSheet(
                context: context,
                ref: ref,
                itemName: 'Furnace',
                brand: '',
                category: 'hvac',
                formType: 'system',
                propertyId: 'p1',
                prefetchedFuture: Future.value(kSuggested),
              ),
              child: const Text('open'),
            ),
          ),
        ),
        overrides: [generatedTasksRepositoryProvider.overrideWithValue(fake)],
      );
      await tester.tap(find.text('open'));
      await settle(tester);
      await tester.tap(find.text(RemindersCopy.reviewSkip));
      await settle(tester);
      expect(result, isFalse);
      expect(fake.added, isEmpty);
      expect(find.byType(TaskReviewSheet), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('Turn all on brings back the ones switched off', (
      tester,
    ) async {
      await run(tester);
      await tester.tap(find.byType(AuroraSwitch).at(0));
      await tester.tap(find.byType(AuroraSwitch).at(1));
      await settle(tester);
      expect(find.textContaining('1 of 3 on'), findsOneWidget);
      await tester.tap(find.text(RemindersCopy.turnAllOn));
      await settle(tester);
      expect(find.textContaining('3 of 3 on'), findsOneWidget);
    });

    testWidgets('nothing left on: the button is off', (tester) async {
      await run(tester);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byType(AuroraSwitch).at(i));
      }
      await settle(tester);
      final button = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'Looks good — keep 0'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('a failed add keeps the sheet, says so, and can be retried', (
      tester,
    ) async {
      final fake = FakeGeneratedTasksRepository()
        ..error = StateError('offline');
      await run(tester, repo: fake);
      await tapVisible(
        tester,
        find.widgetWithText(PrimaryButton, 'Looks good — keep 3'),
      );
      expect(find.byType(TaskReviewSheet), findsOneWidget);
      expect(find.text(RemindersCopy.changeError), findsOneWidget);
      fake.error = null;
      await tapVisible(
        tester,
        find.widgetWithText(PrimaryButton, 'Looks good — keep 3'),
      );
      expect(fake.added, hasLength(1));
      expect(find.byType(TaskReviewSheet), findsNothing);
    });

    testWidgets('no suggestions means no sheet and false', (tester) async {
      final (result, fake) = await run(tester, tasks: const []);
      expect(find.byType(TaskReviewSheet), findsNothing);
      expect(result, isFalse);
      expect(fake.added, isEmpty);
    });

    testWidgets('switches sit at the right edge of their rows', (tester) async {
      await run(tester);
      final rows = find.byType(ReminderSwitchRow);
      for (var i = 0; i < 3; i++) {
        final row = tester.getRect(rows.at(i));
        final sw = tester.getRect(find.byType(AuroraSwitch).at(i));
        expect(sw.right, closeTo(row.right - 14, 1), reason: 'row $i');
      }
    });

    for (final viewport in [
      const Size(320, 568),
      const Size(390, 844),
      const Size(430, 932),
      const Size(844, 390),
      const Size(834, 1194),
    ]) {
      for (final scale in [1.0, 1.5, 2.0]) {
        testWidgets(
          'no overflow @ ${viewport.width}x${viewport.height}, text x$scale',
          (tester) async {
            await run(tester, size: viewport, textScale: scale);
            expect(tester.takeException(), isNull);
            await tester.drag(
              find
                  .ancestor(
                    of: find.byType(TaskReviewSheet),
                    matching: find.byType(SingleChildScrollView),
                  )
                  .first,
              const Offset(0, -2000),
            );
            await settle(tester);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });

  group('review screen responsive', () {
    testResponsiveLoaded(
      'review your reminders',
      () => const TaskReviewScreen(),
      overrides: () => reminderOverrides(FakeRemindersRepository(kReminders())),
      after: (tester) async {
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -3000),
        );
        await settle(tester);
      },
    );

    testResponsiveLoaded(
      'review your reminders, empty',
      () => const TaskReviewScreen(),
      overrides: () => reminderOverrides(
        FakeRemindersRepository(
          RemindersData(items: [kReminders().items.last]),
        ),
      ),
    );

    testResponsiveLoaded(
      'review your reminders, error',
      () => const TaskReviewScreen(),
      overrides: () => reminderOverrides(
        FakeRemindersRepository(kReminders(), fetchFailures: 1),
      ),
    );
  });
}
