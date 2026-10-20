import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/maintenance/screens/maintenance_screen.dart';
import 'package:keystona/features/maintenance/tasks_copy.dart';
import 'package:keystona/features/maintenance/widgets/tasks_tab/task_check_button.dart';

import '../tab/tasks_test_support.dart';

Future<FakeMaintenanceTasksRepository> _load(WidgetTester tester) async {
  final repo = FakeMaintenanceTasksRepository(kitTasks());
  tallSurface(tester);
  await tester.pumpWidget(
    RoutedApp(home: const MaintenanceScreen(), overrides: tasksOverrides(repo)),
  );
  await settle(tester);
  return repo;
}

Finder _checkOf(String id) => find.bySemanticsLabel(
  'Mark done: ${kitTasks().firstWhere((t) => t.id == id).name}',
);

Future<void> _longPress(WidgetTester tester, String name) async {
  await tester.longPress(find.text(name));
  await settle(tester);
}

/// The overdue gutters task is the hero; "Snooze" opens the Not now? sheet.
Future<FakeMaintenanceTasksRepository> _openSkipSheet(
  WidgetTester tester,
) async {
  final repo = await _load(tester);
  await tapAndSettle(tester, find.text('Snooze'));
  return repo;
}

void main() {
  group('skips are recorded', () {
    testWidgets('Just skip this one inserts a skip for the occurrence', (
      tester,
    ) async {
      final repo = await _openSkipSheet(tester);
      await tapAndSettle(tester, find.text('Just skip this one'));
      await tapAndSettle(tester, find.text('Skip this one'));
      final skip = repo.skips.single;
      expect(skip.taskId, 'gutters');
      expect(skip.due, day(9, 28), reason: 'the occurrence that was skipped');
      expect(skip.reason, 'Just skip this one');
      expect(repo.updates.single['status'], 'scheduled');
    });

    testWidgets('its Undo deletes the skip and puts the date back', (
      tester,
    ) async {
      final repo = await _openSkipSheet(tester);
      await tapAndSettle(tester, find.text('Just skip this one'));
      await tapAndSettle(tester, find.text('Skip this one'));
      await tapAndSettle(tester, find.text('Undo'));
      expect(repo.deletedSkips, [repo.skips.single.id]);
      expect(repo.updates.last['due_date'], '2026-09-28');
    });

    testWidgets('Skip this time on the long-press menu logs it, no reason', (
      tester,
    ) async {
      final repo = await _load(tester);
      await _longPress(tester, 'Replace HVAC air filter');
      await tapAndSettle(tester, find.text('Skip this time'));
      expect(repo.skips.single.taskId, 'hvac');
      expect(repo.skips.single.due, day(10, 7));
      expect(repo.skips.single.reason, isNull);
      await tapAndSettle(tester, find.text('Undo'));
      expect(repo.deletedSkips, [repo.skips.single.id]);
    });

    testWidgets('the Undo snackbar sits at the right of its message', (
      tester,
    ) async {
      phoneSurface(tester);
      final repo = FakeMaintenanceTasksRepository(kitTasks());
      await tester.pumpWidget(
        RoutedApp(
          home: const MaintenanceScreen(),
          overrides: tasksOverrides(repo),
        ),
      );
      await settle(tester);
      await _longPress(tester, 'Replace HVAC air filter');
      await tapAndSettle(tester, find.text('Skip this time'));
      final title = tester.getRect(find.text('Skipped — see you in January'));
      final undo = tester.getRect(find.text('Undo'));
      expect(undo.left, greaterThan(title.right));
      expect(390 - undo.right, lessThan(40));
    });

    testWidgets('pushing it back is not a skip', (tester) async {
      final repo = await _openSkipSheet(tester);
      await tapAndSettle(tester, find.text('Push it back'));
      expect(repo.skips, isEmpty);
      expect(repo.updates.single['status'], 'scheduled');
    });

    testWidgets('a failed skip leaves nothing in the history', (tester) async {
      final repo = await _openSkipSheet(tester);
      repo.failUpdates = true;
      await tapAndSettle(tester, find.text('Just skip this one'));
      await tapAndSettle(tester, find.text('Skip this one'));
      expect(repo.deletedSkips, [repo.skips.single.id]);
      expect(find.text(TasksCopy.saveError), findsOneWidget);
    });
  });

  group('every completion path writes the due date it answered', () {
    testWidgets('quick done, Save', (tester) async {
      final repo = await _load(tester);
      await tapAndSettle(tester, _checkOf('hvac'));
      await tapAndSettle(tester, find.text('Save'));
      expect(repo.completions.single.dueDate, day(10, 7));
    });

    testWidgets('quick done, dismissed with the defaults', (tester) async {
      final repo = await _load(tester);
      await tapAndSettle(tester, _checkOf('hvac'));
      await tester.tapAt(const Offset(20, 20));
      await settle(tester);
      expect(repo.completions.single.dueDate, day(10, 7));
    });

    testWidgets('quick done on a day in the past still answers that due date', (
      tester,
    ) async {
      final repo = await _load(tester);
      await tapAndSettle(tester, _checkOf('hvac'));
      await tapAndSettle(tester, find.text('Yesterday'));
      await tapAndSettle(tester, find.text('Save'));
      expect(repo.completions.single.completedOn, day(10, 3));
      expect(repo.completions.single.dueDate, day(10, 7));
    });

    testWidgets('someone else did it, from the skip sheet', (tester) async {
      final repo = await _openSkipSheet(tester);
      await tapAndSettle(tester, find.text('Someone else did it'));
      await tapAndSettle(tester, find.text('Log it as done'));
      expect(repo.completions.single.dueDate, day(9, 28));
      expect(repo.skips, isEmpty, reason: 'it was done, not skipped');
    });

    testWidgets('marking the overdue task done answers its overdue date', (
      tester,
    ) async {
      final repo = await _load(tester);
      await tapAndSettle(tester, find.text('Mark done'));
      await tapAndSettle(tester, find.text('Save'));
      expect(repo.completions.single.dueDate, day(9, 28));
    });
  });

  group('turning a reminder off from the Tasks tab', () {
    testWidgets('Doesn’t apply, from the skip sheet, keeps that reason', (
      tester,
    ) async {
      final repo = await _openSkipSheet(tester);
      await tapAndSettle(tester, find.text('Doesn’t apply to my home'));
      await tapAndSettle(tester, find.text('Stop reminding me'));
      final u = repo.updates.single;
      expect(u['notifications_enabled'], false);
      expect(u['notifications_off_reason'], 'Doesn’t apply to my home');
      expect(DateTime.tryParse(u['notifications_off_at'] as String), isNotNull);
    });

    testWidgets('Doesn’t apply, on the overdue card, keeps that reason', (
      tester,
    ) async {
      final repo = await _load(tester);
      await tapAndSettle(tester, find.text(TasksCopy.doesntApply));
      final u = repo.updates.single;
      expect(u['notifications_enabled'], false);
      expect(u['notifications_off_reason'], 'Doesn’t apply to my home');
      expect(u['notifications_off_at'], isNotNull);
    });

    testWidgets('Stop reminding me has no reason, only the time', (
      tester,
    ) async {
      final repo = await _load(tester);
      await _longPress(tester, 'Replace HVAC air filter');
      await tapAndSettle(tester, find.text('Stop reminding me'));
      final u = repo.updates.single;
      expect(u['notifications_enabled'], false);
      expect(u['notifications_off_reason'], isNull);
      expect(u['notifications_off_at'], isNotNull);
    });

    testWidgets('Undo turns it on and clears the time and reason', (
      tester,
    ) async {
      final repo = await _load(tester);
      await _longPress(tester, 'Replace HVAC air filter');
      await tapAndSettle(tester, find.text('Stop reminding me'));
      await tapAndSettle(tester, find.text('Undo'));
      final u = repo.updates.last;
      expect(u['notifications_enabled'], true);
      expect(u['notifications_off_at'], isNull);
      expect(u['notifications_off_reason'], isNull);
    });
  });

  testWidgets('check buttons remain the only completion control', (
    tester,
  ) async {
    await _load(tester);
    expect(find.byType(TaskCheckButton), findsWidgets);
  });
}
