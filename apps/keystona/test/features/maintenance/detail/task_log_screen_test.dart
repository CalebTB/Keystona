import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/widgets/aurora/aurora_button.dart';
import 'package:keystona/core/widgets/aurora/aurora_text_field.dart';
import 'package:keystona/core/widgets/aurora/aurora_toggle_row.dart';
import 'package:keystona/features/maintenance/models/task_log_draft.dart';
import 'package:keystona/features/maintenance/screens/task_log_screen.dart';
import 'package:keystona/features/maintenance/widgets/log/task_log_photos_section.dart';
import 'package:keystona/features/maintenance/widgets/log/task_photo_slot.dart';
import 'package:keystona/features/maintenance/widgets/log/task_photo_tile.dart';

import 'task_detail_test_support.dart';

const double _screenW = 390;
const String _logPath = '/maintenance/complete/t1';

const _pros = [
  TaskPro(
    id: 'k1',
    name: 'Sam Rivera',
    company: 'Summit Heating & Air',
    phone: '555-0101',
  ),
  TaskPro(id: 'k2', name: 'Dana Lee', phone: '555-0102'),
];

const _receipts = [
  ReceiptOption(id: 'd1', name: 'Summit invoice #4471'),
  ReceiptOption(id: 'd2', name: 'Filter receipt'),
];

FakeTaskDetailRepository _repo({bool failInsert = false}) =>
    FakeTaskDetailRepository(
      fixtureDetail(task: fixtureTask(due: daysFromToday(10))),
      failInsert: failInsert,
    );

Finder _field(int index) => find.byType(TextField).at(index);

SaveButton _save(WidgetTester t) =>
    t.widget<SaveButton>(find.widgetWithText(SaveButton, 'Save'));

/// The whole labelled field (label, box and helper), by position.
Finder _box(int index) => find.byType(AuroraTextField).at(index);

void main() {
  group('layout', () {
    testWidgets('shows the kit copy', (t) async {
      await pumpTasks(t, _repo(), location: _logPath);
      for (final s in [
        'Cancel',
        'Log the details',
        'Save',
        'Replace HVAC air filter',
        'DONE ON',
        'TIME IT TOOK',
        'WHO DID IT',
        'Me',
        'A pro',
        'COST',
        r'$0',
        'LABOR',
        'PARTS',
        'LEAVE AT \$0 IF IT WAS FREE',
        'RECEIPT',
        'Add a receipt',
        'PHOTOS',
        'BEFORE & AFTER HELP AT RESALE',
        'WHAT THEY FOUND',
        'All good',
        'Needs a part soon',
        'Needed a repair',
        'Gave a quote',
        'NOTES',
        "Add to the furnace's history",
        'SHOWS ON THE FURNACE PAGE AND YOUR HOME REPORT',
      ]) {
        expect(find.textContaining(s), findsWidgets, reason: s);
      }
      expect(
        find.textContaining('FURNACE · EVERY 3 MONTHS · DUE '),
        findsOneWidget,
      );
    });

    testWidgets('Cancel at the left edge, Save at the right, title centered', (
      t,
    ) async {
      await pumpTasks(t, _repo(), location: _logPath);
      final cancel = t.getRect(find.text('Cancel'));
      final title = t.getRect(find.text('Log the details'));
      final save = t.getRect(find.byType(SaveButton));
      expect(cancel.left, closeTo(16, 1));
      expect(_screenW - save.right, closeTo(16, 1));
      expect(title.center.dx, closeTo(_screenW / 2, 2));
      expect(save.height, lessThan(48));
    });

    testWidgets('done-on and time-it-took share the row; cost fields too', (
      t,
    ) async {
      await pumpTasks(t, _repo(), location: _logPath);
      final date = t.getRect(_box(0));
      final time = t.getRect(_box(1));
      expect(date.top, closeTo(time.top, 1));
      expect(time.left, greaterThan(date.right));
      expect(date.width, closeTo(time.width, 1));
      expect(_screenW - time.right, closeTo(16, 1));
      final labor = t.getRect(_box(2));
      final parts = t.getRect(_box(3));
      expect(labor.left, closeTo(date.left, 1));
      expect(parts.right, closeTo(time.right, 1));
    });

    testWidgets('the cost total sits at the right edge of the COST header', (
      t,
    ) async {
      await pumpTasks(t, _repo(), location: _logPath);
      final total = find.text(r'$0').first;
      expect(_screenW - t.getRect(total).right, closeTo(16, 1));
      expect(t.getRect(find.text('COST')).left, closeTo(16, 1));
    });

    testWidgets('the photo hint sits at the right edge of its header', (
      t,
    ) async {
      await pumpTasks(t, _repo(), location: _logPath);
      final hint = find.text('BEFORE & AFTER HELP AT RESALE');
      await t.ensureVisible(hint);
      await t.pumpAndSettle();
      expect(_screenW - t.getRect(hint).right, closeTo(16, 1));
    });

    testWidgets('the history toggle: switch at the right edge', (t) async {
      await pumpTasks(t, _repo(), location: _logPath);
      final row = find.text("Add to the furnace's history");
      await t.ensureVisible(row);
      await t.pumpAndSettle();
      final sw = t.getRect(find.byType(AuroraSwitch));
      // Page padding, the row's border and its padding.
      expect(_screenW - sw.right, closeTo(16 + 1 + 14, 1.5));
      expect(sw.left, greaterThan(_screenW / 2));
    });
  });

  group('form', () {
    testWidgets('typing digits builds the MM / DD / YYYY mask', (t) async {
      await pumpTasks(t, _repo(), location: _logPath);
      await t.enterText(_field(0), '10022026');
      await t.pump();
      expect(find.text('10 / 02 / 2026'), findsOneWidget);
    });

    testWidgets('Save is off for a date that is not complete', (t) async {
      await pumpTasks(t, _repo(), location: _logPath);
      expect(_save(t).onPressed, isNotNull);
      await t.enterText(_field(0), '1002');
      await t.pump();
      expect(_save(t).onPressed, isNull);
      expect(find.text('USE MM / DD / YYYY'), findsOneWidget);
    });

    testWidgets('a future date cannot be saved', (t) async {
      await pumpTasks(t, _repo(), location: _logPath);
      final d = daysFromToday(3);
      final text =
          '${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}${d.year}';
      await t.enterText(_field(0), text);
      await t.pump();
      expect(_save(t).onPressed, isNull);
      expect(find.text("CAN'T BE IN THE FUTURE"), findsOneWidget);
    });

    testWidgets('the date line says how early and when the next one is', (
      t,
    ) async {
      await pumpTasks(t, _repo(), location: _logPath);
      expect(find.textContaining('10 DAYS EARLY · NEXT ONE '), findsOneWidget);
    });

    testWidgets('labor and parts add up in the header', (t) async {
      await pumpTasks(t, _repo(), location: _logPath);
      await t.enterText(_field(2), r'$129');
      await t.enterText(_field(3), '10.50');
      await t.pump();
      expect(find.text(r'$139.50'), findsOneWidget);
      expect(
        find.text("COUNTS TOWARD THE FURNACE'S LIFETIME COST"),
        findsOneWidget,
      );
    });

    testWidgets('A pro shows the pro card; choosing one fills it', (t) async {
      await pumpTasks(t, _repo(), location: _logPath, pros: _pros);
      expect(find.text('FROM WHO TO CALL'), findsNothing);

      await t.tap(find.text('A pro'));
      await t.pumpAndSettle();
      expect(find.text('Choose a pro'), findsOneWidget);
      expect(find.text('FROM WHO TO CALL'), findsOneWidget);
      // The Change link sits at the right edge of the card.
      expect(
        _screenW - t.getRect(find.text('Choose')).right,
        closeTo(16 + 14 + 1.5, 1.5),
      );

      await t.tap(find.text('Choose a pro'));
      await t.pumpAndSettle();
      expect(find.text('Who did it?'), findsOneWidget);
      await t.tap(find.text('Summit Heating & Air'));
      await t.pumpAndSettle();

      expect(find.text('Summit Heating & Air'), findsOneWidget);
      expect(find.text('SH'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
      // Back on the form: the sheet is gone, the form is still here.
      expect(find.text('Log the details'), findsOneWidget);
    });

    testWidgets('the pro sheet explains an empty Who to call', (t) async {
      await pumpTasks(t, _repo(), location: _logPath);
      await t.tap(find.text('A pro'));
      await t.pumpAndSettle();
      await t.tap(find.text('Choose a pro'));
      await t.pumpAndSettle();
      expect(
        find.text('Nobody in Who to call yet. Add a contact there first.'),
        findsOneWidget,
      );
    });

    testWidgets('a receipt can be linked and removed', (t) async {
      await pumpTasks(t, _repo(), location: _logPath, receipts: _receipts);
      await t.ensureVisible(find.text('Add a receipt'));
      await t.pumpAndSettle();
      await t.tap(find.text('Add a receipt'));
      await t.pumpAndSettle();
      expect(find.text('Link a receipt'), findsOneWidget);
      await t.tap(find.text('Summit invoice #4471'));
      await t.pumpAndSettle();

      expect(find.text('Summit invoice #4471'), findsOneWidget);
      expect(find.text('LINKED FROM DOCS'), findsOneWidget);
      expect(find.text('Add another receipt'), findsOneWidget);
      // The remove button sits at the right edge of the row.
      final x = find.byIcon(Icons.close);
      expect(_screenW - t.getRect(x).right, closeTo(16 + 1 + 14, 3));

      // Already linked: not offered again.
      await t.tap(find.text('Add another receipt'));
      await t.pumpAndSettle();
      expect(find.text('Filter receipt'), findsOneWidget);
      expect(find.text('Summit invoice #4471'), findsOneWidget);
      await t.tapAt(const Offset(10, 10));
      await t.pumpAndSettle();

      await t.tap(find.bySemanticsLabel('Remove receipt'));
      await t.pumpAndSettle();
      expect(find.text('LINKED FROM DOCS'), findsNothing);
    });
  });

  group('saving', () {
    testWidgets('Cancel closes without saving', (t) async {
      final repo = _repo();
      await pumpTasks(t, repo, location: _logPath);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(find.text('TASKS TAB'), findsOneWidget);
      expect(repo.inserted, isEmpty);
    });

    testWidgets('Save sends what was typed and closes', (t) async {
      final repo = _repo();
      await pumpTasks(t, repo, location: _logPath, pros: _pros);
      await t.tap(find.text('A pro'));
      await t.pumpAndSettle();
      await t.tap(find.text('Choose a pro'));
      await t.pumpAndSettle();
      await t.tap(find.text('Dana Lee'));
      await t.pumpAndSettle();
      await t.enterText(_field(1), '1 hr 10 min');
      await t.enterText(_field(2), '129');
      await t.enterText(_field(4), 'Cleaned the flame sensor.');
      await t.pumpAndSettle();

      await t.tap(find.text('Save'));
      await t.pumpAndSettle();

      final d = repo.inserted.single;
      expect(d.completedDate, today);
      expect(d.minutes, 70);
      expect(d.laborCost, 129);
      expect(d.doer, TaskDoer.pro);
      expect(d.pro!.name, 'Dana Lee');
      expect(d.notes, 'Cleaned the flame sensor.');
      expect(find.byType(TaskLogScreen), findsNothing);
    });

    testWidgets('a failed save keeps the form and says so', (t) async {
      final repo = _repo(failInsert: true);
      await pumpTasks(t, repo, location: _logPath);
      await t.enterText(_field(2), '50');
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect(find.text("Couldn't save the log. Try again."), findsOneWidget);
      expect(find.byType(TaskLogScreen), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(_save(t).onPressed, isNotNull);
    });
  });

  group('photos', () {
    Future<void> pumpPhotos(WidgetTester t, int count) async {
      usePhone(t);
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: TaskLogPhotosSection(
                photos: [
                  for (var i = 0; i < count; i++)
                    LogPhoto(path: '/missing/$i.jpg', name: '$i.jpg'),
                ],
                onAdd: () {},
                onRemove: (_) {},
              ),
            ),
          ),
        ),
      );
      await t.pump();
    }

    testWidgets('two photos: before and after, two empty slots', (t) async {
      await pumpPhotos(t, 2);
      expect(find.text('BEFORE'), findsOneWidget);
      expect(find.text('AFTER'), findsOneWidget);
      expect(find.byType(TaskPhotoTile), findsNWidgets(2));
      expect(find.byType(TaskPhotoSlot), findsNWidgets(2));
    });

    testWidgets('four across, edge to edge', (t) async {
      await pumpPhotos(t, 0);
      final slots = find.byType(TaskPhotoSlot);
      expect(slots, findsNWidgets(4));
      final first = t.getRect(slots.at(0));
      final last = t.getRect(slots.at(3));
      expect(first.left, closeTo(16, 0.5));
      expect(last.right, closeTo(_screenW - 16, 0.5));
      expect(first.width, closeTo(first.height, 0.5));
      expect(t.getRect(slots.at(1)).left, greaterThan(first.right));
    });

    testWidgets('a full row grows by one empty slot', (t) async {
      await pumpPhotos(t, 4);
      expect(find.byType(TaskPhotoTile), findsNWidgets(4));
      expect(find.byType(TaskPhotoSlot), findsNWidgets(1));
      // Only the first two get badges.
      expect(find.text('BEFORE'), findsOneWidget);
      expect(find.text('AFTER'), findsOneWidget);
    });
  });

  group('states', () {
    testWidgets('error offers a retry', (t) async {
      final repo = FakeTaskDetailRepository(fixtureDetail(), failFetch: true);
      await pumpTasks(t, repo, location: _logPath);
      expect(find.text("Couldn't load this task."), findsOneWidget);
      expect(_save(t).onPressed, isNull);
      repo.failFetch = false;
      await t.tap(find.text('Try again'));
      await t.pumpAndSettle();
      expect(find.text('Replace HVAC air filter'), findsOneWidget);
    });
  });

  group('responsive', () {
    testResponsiveLoaded(
      'log form',
      () => const TaskLogScreen(taskId: 't1'),
      _repo,
      expectText: 'Log the details',
      pros: _pros,
    );

    testResponsiveLoaded(
      'log form, long names',
      () => const TaskLogScreen(taskId: 't1'),
      () => FakeTaskDetailRepository(
        fixtureDetail(
          task: fixtureTask(
            name: 'Have the whole-house humidifier serviced and descaled',
            due: daysFromToday(-5),
          ),
        ),
      ),
      expectText: 'Log the details',
    );
  });
}
