import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/maintenance/screens/maintenance_screen.dart';

import 'tasks_test_support.dart';

Future<void> _longPress(WidgetTester tester, String name) async {
  await tester.ensureVisible(find.text(name));
  await tester.pump();
  await tester.longPress(find.text(name));
  await settle(tester);
}

void main() {
  group('Tasks tab responsive', () {
    testResponsiveFlow('populated', () => const MaintenanceScreen());
    testResponsiveFlow(
      'many overdue',
      () => const MaintenanceScreen(),
      tasks: () => [
        ...kitTasks(),
        task(
          'x',
          'Replace the very long named smoke detector batteries in every bedroom',
          due: day(9, 1),
          category: 'Safety Systems',
        ),
        task('y', 'Another overdue chore', due: day(9, 10)),
      ],
    );
    testResponsiveFlow(
      'caught up',
      () => const MaintenanceScreen(),
      tasks: () => kitTasks()
          .where((t) => t.id != 'gutters' && t.id != 'smoke')
          .toList(),
    );
    testResponsiveFlow(
      'nothing scheduled',
      () => const MaintenanceScreen(),
      tasks: () => [],
    );
    testResponsiveFlow(
      'loading',
      () => const MaintenanceScreen(),
      repository: () =>
          FakeMaintenanceTasksRepository(kitTasks(), gate: Completer<void>()),
    );
    testResponsiveFlow(
      'error',
      () => const MaintenanceScreen(),
      repository: () =>
          FakeMaintenanceTasksRepository(kitTasks())
            ..failWith = StateError('x'),
    );
  });

  group('Sheets and menu responsive', () {
    testResponsiveFlow(
      'long-press menu',
      () => const MaintenanceScreen(),
      act: (tester) => _longPress(tester, 'Replace HVAC air filter'),
    );
    testResponsiveFlow(
      'long-press menu on the overdue card, frequency open',
      () => const MaintenanceScreen(),
      act: (tester) async {
        await _longPress(tester, 'Clean gutters & downspouts');
        await tapAndSettle(tester, find.text('Change how often'));
      },
    );
    testResponsiveFlow(
      'skip sheet, push back',
      () => const MaintenanceScreen(),
      act: (tester) => tapAndSettle(tester, find.text('Snooze')),
    );
    testResponsiveFlow(
      'skip sheet, someone else did it',
      () => const MaintenanceScreen(),
      act: (tester) async {
        await tapAndSettle(tester, find.text('Snooze'));
        await tapAndSettle(tester, find.text('Someone else did it'));
      },
    );
    testResponsiveFlow(
      'skip sheet, doesn’t apply',
      () => const MaintenanceScreen(),
      act: (tester) async {
        await tapAndSettle(tester, find.text('Snooze'));
        await tapAndSettle(tester, find.text('Doesn’t apply to my home'));
      },
    );
    testResponsiveFlow(
      'quick done sheet',
      () => const MaintenanceScreen(),
      act: (tester) => tapAndSettle(
        tester,
        find.bySemanticsLabel('Mark done: Replace HVAC air filter'),
      ),
    );
  });
}
