import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/widgets/aurora/aurora_toggle_row.dart';
import 'package:keystona/features/maintenance/models/maintenance_task.dart';
import 'package:keystona/features/maintenance/models/task_finding.dart';

import 'package:keystona/features/maintenance/widgets/history/task_hatch_fill.dart';
import 'package:keystona/features/maintenance/widgets/history/task_history_strip.dart';

import '../detail/task_detail_test_support.dart';

const double _screenW = 390;
const String _logPath = '/maintenance/complete/t1';
const String _historyPath = '/maintenance/t1/history';

Future<void> _reveal(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
}

void main() {
  group('detail: cost tile and your notes', () {
    testWidgets('four spec tiles share one row, Cost last', (t) async {
      await pumpTasks(
        t,
        FakeTaskDetailRepository(
          fixtureDetail(task: fixtureTask(estimatedCost: 25)),
        ),
      );
      final labels = [
        for (final l in ['TIME', 'LEVEL', 'WHO', 'COST'])
          t.getRect(find.text(l)),
      ];
      for (var i = 1; i < labels.length; i++) {
        expect(labels[i].left, greaterThan(labels[i - 1].left));
        expect(labels[i].top, closeTo(labels[0].top, 1));
      }
      // Equal columns, and the last tile ends at the page edge.
      expect(
        (labels[1].left - labels[0].left - (labels[3].left - labels[2].left))
            .abs(),
        lessThan(1),
      );
      expect(find.text('~\$25'), findsOneWidget);
      final value = t.getRect(find.text('~\$25'));
      expect(value.left, closeTo(labels[3].left, 1));
      expect(value.top, greaterThan(labels[3].top), reason: 'under its label');
      expect(_screenW - value.right, greaterThan(16));
    });

    testWidgets('an estimate with cents shows them', (t) async {
      await pumpTasks(
        t,
        FakeTaskDetailRepository(
          fixtureDetail(task: fixtureTask(estimatedCost: 24.5)),
        ),
      );
      expect(find.text('~\$24.50'), findsOneWidget);
    });

    testWidgets('no estimate, no Cost tile', (t) async {
      await pumpTasks(t, FakeTaskDetailRepository(fixtureDetail()));
      expect(find.text('COST'), findsNothing);
      expect(find.text('TIME'), findsOneWidget);
    });

    testWidgets('your notes sit between what you need and the history', (
      t,
    ) async {
      await pumpTasks(
        t,
        FakeTaskDetailRepository(
          fixtureDetail(task: fixtureTask(notes: 'Spares are on the shelf.')),
        ),
      );
      final need = find.text("YOU'LL NEED");
      final notes = find.text('YOUR NOTES');
      final history = find.text('HISTORY · 3');
      await _reveal(t, history);
      expect(find.text('Spares are on the shelf.'), findsOneWidget);
      expect(t.getRect(notes).top, greaterThan(t.getRect(need).top));
      expect(
        t.getRect(find.text('Spares are on the shelf.')).top,
        greaterThan(t.getRect(notes).bottom),
      );
      expect(
        t.getRect(history).top,
        greaterThan(t.getRect(find.text('Spares are on the shelf.')).bottom),
      );
    });

    testWidgets('the notes Edit link is on the label row at the right', (
      t,
    ) async {
      await pumpTasks(
        t,
        FakeTaskDetailRepository(
          fixtureDetail(task: fixtureTask(notes: 'Spares are on the shelf.')),
        ),
      );
      final label = find.text('YOUR NOTES');
      await _reveal(t, label);
      // The top bar's Edit comes first; the notes link is the last one.
      final link = t.getRect(find.text('Edit').last);
      expect(link.center.dy, closeTo(t.getRect(label).center.dy, 2));
      expect(link.left, greaterThan(_screenW / 2));
      expect(_screenW - link.right, lessThan(16 + 44));
    });

    testWidgets('the notes text starts at the page edge plus its rule', (
      t,
    ) async {
      await pumpTasks(
        t,
        FakeTaskDetailRepository(
          fixtureDetail(task: fixtureTask(notes: 'Spares are on the shelf.')),
        ),
      );
      final text = find.text('Spares are on the shelf.');
      await _reveal(t, text);
      // Page padding 16 + rule 2 + gap 14.
      expect(t.getRect(text).left, closeTo(16 + 2 + 14, 1.5));
    });

    testWidgets('tapping Edit under the notes opens the form', (t) async {
      await pumpTasks(
        t,
        FakeTaskDetailRepository(
          fixtureDetail(task: fixtureTask(notes: 'Spares are on the shelf.')),
        ),
      );
      final label = find.text('YOUR NOTES');
      await _reveal(t, label);
      await t.tap(find.text('Edit').last);
      await t.pumpAndSettle();
      expect(find.text('EDIT PAGE'), findsOneWidget);
    });

    testWidgets('no notes, no section', (t) async {
      await pumpTasks(t, FakeTaskDetailRepository(fixtureDetail()));
      expect(find.text('YOUR NOTES'), findsNothing);
    });

    testWidgets('blank notes are not a section either', (t) async {
      await pumpTasks(
        t,
        FakeTaskDetailRepository(
          fixtureDetail(task: fixtureTask(notes: '   ')),
        ),
      );
      expect(find.text('YOUR NOTES'), findsNothing);
    });

    testWidgets('an every-3-years task says so', (t) async {
      await pumpTasks(
        t,
        FakeTaskDetailRepository(
          fixtureDetail(
            task: fixtureTask(
              recurrence: RecurrenceType.annual,
              intervalYears: 3,
            ),
          ),
        ),
      );
      expect(find.text('HVAC · EVERY 3 YEARS'), findsOneWidget);
      await _reveal(t, find.text('Every 3 years').last);
      expect(find.text('Every 3 years'), findsOneWidget);
    });
  });

  group('detail: delete with Undo', () {
    Future<FakeTaskDetailRepository> deleteIt(WidgetTester t) async {
      final repo = FakeTaskDetailRepository(fixtureDetail());
      await pumpTasks(t, repo);
      final del = find.text('Delete this task');
      await _reveal(t, del);
      await t.tap(del);
      await t.pumpAndSettle();
      await t.tap(find.text('Delete task'));
      await t.pumpAndSettle();
      return repo;
    }

    testWidgets('deleting soft-deletes, leaves, and offers Undo', (t) async {
      final repo = await deleteIt(t);
      expect(repo.deletedTasks, ['t1']);
      expect(repo.restoredTasks, isEmpty);
      expect(find.text('TASKS TAB'), findsOneWidget);
      expect(find.text('Task deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('the snackbar Undo sits to the right of its message', (
      t,
    ) async {
      await deleteIt(t);
      expect(
        t.getRect(find.text('Undo')).left,
        greaterThan(t.getRect(find.text('Task deleted')).right),
      );
    });

    testWidgets('Undo restores the task', (t) async {
      final repo = await deleteIt(t);
      await t.tap(find.text('Undo'));
      await t.pumpAndSettle();
      expect(repo.restoredTasks, ['t1']);
    });

    testWidgets('a failed restore says so', (t) async {
      final repo = await deleteIt(t);
      repo.failRestore = true;
      await t.tap(find.text('Undo'));
      await t.pumpAndSettle();
      expect(find.text('That didn’t save. Please try again.'), findsOneWidget);
    });

    testWidgets('a failed delete stays on the task and does not offer Undo', (
      t,
    ) async {
      final repo = FakeTaskDetailRepository(fixtureDetail())..failDelete = true;
      await pumpTasks(t, repo);
      final del = find.text('Delete this task');
      await _reveal(t, del);
      await t.tap(del);
      await t.pumpAndSettle();
      await t.tap(find.text('Delete task'));
      await t.pumpAndSettle();
      expect(find.text("Couldn't delete the task. Try again."), findsOneWidget);
      expect(find.text('Undo'), findsNothing);
      expect(find.text('Replace HVAC air filter'), findsOneWidget);
    });
  });

  group('log screen: findings, history switch, due date', () {
    FakeTaskDetailRepository repo() => FakeTaskDetailRepository(
      fixtureDetail(task: fixtureTask(due: daysFromToday(10))),
    );

    testWidgets('the picks and the switch are saved', (t) async {
      final r = repo();
      await pumpTasks(t, r, location: _logPath);
      await _reveal(t, find.text('Gave a quote'));
      await t.tap(find.text('Gave a quote'));
      await t.pump();
      await t.tap(find.text('All good'));
      await t.pump();
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect(r.inserted.single.findings, [TaskFinding.quote]);
      expect(r.inserted.single.addToItemHistory, isTrue);
    });

    testWidgets('turning the history switch off is saved as off', (t) async {
      final r = repo();
      await pumpTasks(t, r, location: _logPath);
      final row = find.text("Add to the furnace's history");
      await _reveal(t, row);
      await t.tap(find.byType(AuroraSwitch));
      await t.pump();
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect(r.inserted.single.addToItemHistory, isFalse);
      expect(r.inserted.single.findings, [TaskFinding.ok]);
    });

    testWidgets('the log answers the due date the task was on', (t) async {
      final r = repo();
      await pumpTasks(t, r, location: _logPath);
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect(r.insertedDueDates.single, daysFromToday(10));
      expect(r.detail.completions.first.dueDate, daysFromToday(10));
    });

    testWidgets('a past entry answers no due date', (t) async {
      final r = repo();
      await pumpTasks(t, r, location: _logPath);
      // Older than every existing completion.
      final date = daysFromToday(-1000);
      final mm = date.month.toString().padLeft(2, '0');
      final dd = date.day.toString().padLeft(2, '0');
      await t.enterText(find.byType(TextField).at(0), '$mm$dd${date.year}');
      await t.pump();
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect(r.insertedDueDates.single, isNull);
      expect(r.inserted.single.completedDate, date);
    });
  });

  group('history: skips, findings and the stored due date', () {
    FakeTaskDetailRepository repo() => FakeTaskDetailRepository(
      fixtureDetail(
        task: fixtureTask(),
        completions: [
          fixtureCompletion(
            'c3',
            daysFromToday(-20),
            labor: 22,
            findings: const ['ok', 'quote'],
            dueDate: daysFromToday(-23),
          ),
          fixtureCompletion(
            'c1',
            daysFromToday(-200),
            dueDate: daysFromToday(-200),
          ),
        ],
        skips: [
          fixtureSkip('s1', daysFromToday(-100), reason: 'Alex was traveling'),
          fixtureSkip('s2', daysFromToday(-150), reason: 'Away'),
        ],
      ),
    );

    testWidgets('skipped entries show Skipped, the reason and a dash', (
      t,
    ) async {
      await pumpTasks(t, repo(), location: _historyPath);
      final skipped = find.textContaining('SKIPPED', findRichText: true);
      expect(skipped, findsWidgets);
      expect(
        find.textContaining('Alex was traveling', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('Away', findRichText: true), findsOneWidget);
      // A dash for each skip, and one for the done entry with no cost.
      expect(find.text('—'), findsNWidgets(3));
    });

    testWidgets('the log is newest first across done and skipped', (t) async {
      await pumpTasks(t, repo(), location: _historyPath);
      final done = t.getRect(
        find.textContaining('3 DAYS LATE', findRichText: true),
      );
      final skip = t.getRect(
        find.textContaining('Alex was traveling', findRichText: true),
      );
      final oldest = t.getRect(
        find.textContaining('ON TIME', findRichText: true).last,
      );
      expect(done.top, lessThan(skip.top));
      expect(skip.top, lessThan(oldest.top));
    });

    testWidgets(
      'a skipped entry keeps its date at the left, dash at the right',
      (t) async {
        await pumpTasks(t, repo(), location: _historyPath);
        final dash = t.getRect(find.text('—').first);
        expect(_screenW - dash.right, closeTo(16 + 1 + 14, 1.5));
        final reason = t.getRect(
          find.textContaining('Alex was traveling', findRichText: true),
        );
        expect(reason.left, lessThan(_screenW / 2));
        expect(reason.top, greaterThan(dash.top));
      },
    );

    testWidgets('the legend names Skipped after On time and Late', (t) async {
      await pumpTasks(t, repo(), location: _historyPath);
      Finder inStrip(String text) => find.descendant(
        of: find.byType(TaskHistoryStrip),
        matching: find.text(text),
      );
      final onTime = t.getRect(inStrip('ON TIME'));
      final late = t.getRect(inStrip('LATE'));
      final skipped = t.getRect(inStrip('SKIPPED'));
      expect(onTime.left, lessThan(late.left));
      expect(late.left, lessThan(skipped.left));
      expect(skipped.top, closeTo(late.top, 2));
    });

    testWidgets('the strip counts skipped ones for screen readers', (t) async {
      await pumpTasks(t, repo(), location: _historyPath);
      expect(
        find.bySemanticsLabel('1 on time, 1 late, 2 skipped'),
        findsOneWidget,
      );
    }, semanticsEnabled: true);

    testWidgets('the strip draws one bar per done or skipped time', (t) async {
      await pumpTasks(t, repo(), location: _historyPath);
      final strip = find.byType(TaskHistoryStrip);
      // Two done and two skipped.
      expect(
        find.descendant(of: strip, matching: find.byType(Expanded)),
        findsNWidgets(4),
      );
      // The skipped bars are hatched, and so is the legend swatch.
      expect(
        find.descendant(of: strip, matching: find.byType(TaskHatchFill)),
        findsNWidgets(3),
      );
    });

    testWidgets('stored due date decides the timing words', (t) async {
      await pumpTasks(t, repo(), location: _historyPath);
      expect(
        find.textContaining('3 DAYS LATE', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('ON TIME', findRichText: true), findsWidgets);
    });

    testWidgets('saved findings show on their entry', (t) async {
      await pumpTasks(t, repo(), location: _historyPath);
      expect(find.text('All good · Gave a quote'), findsOneWidget);
    });

    testWidgets('stats count only completions', (t) async {
      await pumpTasks(t, repo(), location: _historyPath);
      expect(find.text('2'), findsWidgets);
      expect(find.text('1 of 2'), findsOneWidget);
    });

    testWidgets('a task with only skips shows the log, not the empty state', (
      t,
    ) async {
      await pumpTasks(
        t,
        FakeTaskDetailRepository(
          fixtureDetail(
            completions: const [],
            skips: [fixtureSkip('s1', daysFromToday(-100))],
          ),
        ),
        location: _historyPath,
      );
      expect(find.text('Nothing logged yet'), findsNothing);
      expect(find.textContaining('SKIPPED', findRichText: true), findsWidgets);
    });
  });
}
