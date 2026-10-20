import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/maintenance/models/completion_photo.dart';
import 'package:keystona/features/maintenance/models/task_parent.dart';
import 'package:keystona/features/maintenance/screens/task_history_screen.dart';
import 'package:keystona/features/maintenance/widgets/history/task_history_log_card.dart';
import 'package:keystona/features/maintenance/widgets/history/task_history_skeleton.dart';
import 'package:keystona/features/maintenance/widgets/history/task_history_stats.dart';

import 'task_detail_test_support.dart';

const double _screenW = 390;
const String _historyPath = '/maintenance/t1/history';

FakeTaskDetailRepository _repo({
  bool empty = false,
  Map<String, List<CompletionPhoto>> photos = const {},
}) => FakeTaskDetailRepository(
  fixtureDetail(
    task: fixtureTask(),
    completions: empty ? const [] : fixtureCompletions(),
  ),
  photos: photos,
);

void main() {
  group('layout', () {
    testWidgets('shows the kit copy', (t) async {
      await pumpTasks(t, _repo(), location: _historyPath);
      for (final s in [
        'Task',
        '+ Log a past one',
        'HISTORY · FURNACE',
        'Replace HVAC air filter',
        '4',
        'TIMES SINCE ${fixtureCompletions().last.completedDate.year}',
        '2 of 3',
        'ON TIME',
        r'$66',
        'SPENT IN ALL',
        'EVERY TIME, OLDEST → NEWEST',
        'LATE',
        'LOG',
        'MERV 8 from the hardware store.',
        'Summit Heating & Air · 10 min',
        'This log goes into your Home History Report — proof the furnace was looked after.',
      ]) {
        expect(find.textContaining(s), findsWidgets, reason: s);
      }
      expect(find.textContaining('3 DAYS EARLY'), findsOneWidget);
      expect(find.textContaining('2 DAYS LATE'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('top bar: back at the left, the log pill at the right edge', (
      t,
    ) async {
      await pumpTasks(t, _repo(), location: _historyPath);
      expect(t.getRect(find.text('Task')).left, lessThan(60));
      final pill = t.getRect(find.text('+ Log a past one'));
      // Page padding plus the pill's own padding and border.
      expect(_screenW - pill.right, closeTo(16 + 14 + 1.5, 1.5));
    });

    testWidgets('three stat tiles share the row equally', (t) async {
      await pumpTasks(t, _repo(), location: _historyPath);
      final tiles = find.byType(TaskHistoryStats);
      final box = t.getRect(tiles);
      final a = t.getRect(find.text('4')).left;
      final b = t.getRect(find.text('2 of 3')).left;
      final c = t.getRect(find.text(r'$66')).left;
      expect((b - a - (c - b)).abs(), lessThan(1));
      expect(box.left, closeTo(16, 1));
      expect(box.right, closeTo(_screenW - 16, 1));
      expect(c, greaterThan(_screenW / 2));
    });

    testWidgets('entry amounts sit at the right edge of the log card', (
      t,
    ) async {
      await pumpTasks(t, _repo(), location: _historyPath);
      final card = find.byType(TaskHistoryLogCard);
      await t.ensureVisible(card);
      await t.pumpAndSettle();
      final amounts = find.text(r'$22');
      expect(amounts, findsNWidgets(3));
      for (var i = 0; i < 3; i++) {
        expect(
          _screenW - t.getRect(amounts.at(i)).right,
          closeTo(16 + 1 + 14, 1.5),
        );
      }
      // Dates sit at the left, after the dot and the line.
      final firstDate = find.byWidgetPredicate(
        (w) =>
            w is Text && (w.data ?? '').contains(', ${today.year}') ||
            (w is Text && (w.data ?? '').contains(', ${today.year - 1}')),
      );
      expect(t.getRect(firstDate.first).left, greaterThan(16 + 14 + 14));
      expect(t.getRect(firstDate.first).left, lessThan(80));
    });

    testWidgets(
      'the strip draws one bar per time and names the totals',
      (t) async {
        await pumpTasks(t, _repo(), location: _historyPath);
        expect(
          find.bySemanticsLabel('2 on time, 1 late, 0 skipped'),
          findsOneWidget,
        );
      },
      semanticsEnabled: true,
    );

    testWidgets('the callout names the parent in lower case', (t) async {
      await pumpTasks(
        t,
        FakeTaskDetailRepository(
          fixtureDetail(
            completions: fixtureCompletions(),
            parent: const TaskParent(kind: TaskParentKind.area, name: 'Safety'),
          ),
        ),
        location: _historyPath,
      );
      expect(
        find.textContaining('proof the safety was looked after'),
        findsOneWidget,
      );
    });
  });

  group('photos', () {
    testWidgets('an entry shows its photos, labelled', (t) async {
      final repo = _repo(
        photos: {
          'c4': [
            const CompletionPhoto(
              id: 'p1',
              completionId: 'c4',
              path: 'u/p/c4/a.jpg',
              caption: 'before',
            ),
            const CompletionPhoto(
              id: 'p2',
              completionId: 'c4',
              path: 'u/p/c4/b.jpg',
              caption: 'after',
            ),
          ],
        },
      );
      await pumpTasks(t, repo, location: _historyPath);
      expect(find.bySemanticsLabel('before photo'), findsOneWidget);
      expect(find.bySemanticsLabel('after photo'), findsOneWidget);
    }, semanticsEnabled: true);
  });

  group('states', () {
    testWidgets('empty history says so and drops the stats', (t) async {
      await pumpTasks(t, _repo(empty: true), location: _historyPath);
      expect(find.text('Nothing logged yet'), findsOneWidget);
      expect(find.byType(TaskHistoryStats), findsNothing);
      expect(find.text('+ Log a past one'), findsOneWidget);
    });

    testWidgets('loading shows the skeleton', (t) async {
      final repo = _repo();
      final gate = Completer<void>();
      repo.fetchGate = gate;
      usePhone(t);
      await t.pumpWidget(
        ProviderScope(
          overrides: taskOverrides(repo),
          child: const MaterialApp(home: TaskHistoryScreen(taskId: 't1')),
        ),
      );
      await t.pump();
      expect(find.byType(TaskHistorySkeleton), findsOneWidget);
      gate.complete();
      await t.pumpAndSettle();
      expect(find.byType(TaskHistorySkeleton), findsNothing);
    });

    testWidgets('error offers a retry', (t) async {
      final repo = FakeTaskDetailRepository(fixtureDetail(), failFetch: true);
      await pumpTasks(t, repo, location: _historyPath);
      expect(find.text("Couldn't load this history."), findsOneWidget);
      repo.failFetch = false;
      await t.tap(find.text('Try again'));
      await t.pumpAndSettle();
      expect(find.text('LOG'), findsOneWidget);
    });
  });

  group('actions', () {
    testWidgets('back goes to the task', (t) async {
      await pumpTasks(t, _repo(), location: _historyPath);
      await t.tap(find.text('Task'));
      await t.pumpAndSettle();
      expect(find.text('Replace HVAC air filter'), findsOneWidget);
      expect(find.text('Mark done'), findsOneWidget);
    });

    testWidgets('logging a past one saves, stays here and offers Undo', (
      t,
    ) async {
      final repo = _repo();
      await pumpTasks(t, repo, location: _historyPath);
      await t.tap(find.text('+ Log a past one'));
      await t.pumpAndSettle();
      expect(find.text('Log the details'), findsOneWidget);

      // A date older than every log: history grows, the schedule stays.
      final old = daysFromToday(-1000);
      final text =
          '${old.month.toString().padLeft(2, '0')}${old.day.toString().padLeft(2, '0')}${old.year}';
      await t.enterText(find.byType(TextField).first, text);
      await t.pump();
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();

      expect(repo.inserted, hasLength(1));
      expect(repo.schedules, isEmpty);
      expect(find.text('LOG'), findsOneWidget);
      expect(find.text('Done and logged'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      await t.tap(find.text('Undo'));
      await t.pumpAndSettle();
      expect(repo.deletedCompletions, ['new-1']);
      expect(find.text('4'), findsOneWidget);
    });
  });

  group('responsive', () {
    testResponsiveLoaded(
      'history',
      () => const TaskHistoryScreen(taskId: 't1'),
      _repo,
      expectText: 'HISTORY · FURNACE',
    );

    testResponsiveLoaded(
      'history, long notes and many entries',
      () => const TaskHistoryScreen(taskId: 't1'),
      () => FakeTaskDetailRepository(
        fixtureDetail(
          completions: [
            for (var i = 0; i < 20; i++)
              fixtureCompletion(
                'c$i',
                daysFromToday(-30 * (i + 1)),
                labor: 1234.5,
                company: i.isEven
                    ? 'A very long company name & sons heating'
                    : null,
                by: i.isEven ? 'contractor' : 'diy',
                notes:
                    'Replaced the filter and noticed a hairline crack along the '
                    'housing, so I wrapped it and will look again next time.',
              ),
          ],
        ),
      ),
      expectText: 'HISTORY · FURNACE',
    );

    testResponsiveLoaded(
      'history, empty',
      () => const TaskHistoryScreen(taskId: 't1'),
      () => _repo(empty: true),
      expectText: 'Nothing logged yet',
    );
  });
}
