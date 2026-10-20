import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/maintenance/models/task_completion.dart';
import 'package:keystona/features/maintenance/models/task_log_draft.dart';
import 'package:keystona/features/maintenance/services/task_log_form_state.dart';
import 'package:keystona/features/maintenance/services/task_pro_prefill.dart';

import 'task_detail_test_support.dart';

const _sam = TaskPro(
  id: 'k1',
  name: 'Sam Rivera',
  company: 'Summit Heating & Air',
  phone: '(555) 010-1',
);
const _dana = TaskPro(id: 'k2', name: 'Dana Lee', phone: '555-0102');

/// An earlier completion by Sam's company, plus one done by the owner.
List<TaskCompletion> _withPro() => [
  fixtureCompletion('c3', daysFromToday(-30)),
  fixtureCompletion(
    'c2',
    daysFromToday(-120),
    by: 'contractor',
    contractorName: 'Sam Rivera',
    company: 'Summit Heating & Air',
    phone: '555 010 1',
  ),
  fixtureCompletion(
    'c1',
    daysFromToday(-300),
    by: 'contractor',
    contractorName: 'Old Pro',
  ),
];

TaskLogFormState _form({
  List<TaskCompletion>? completions,
  List<TaskPro> pros = const [],
}) => TaskLogFormState(
  detail: fixtureDetail(
    task: fixtureTask(due: daysFromToday(10)),
    completions: completions ?? _withPro(),
  ),
  today: today,
  pros: pros,
);

void main() {
  group('TaskProPrefill', () {
    test('takes the most recent earlier completion done by a pro', () {
      final pro = TaskProPrefill.lastPro(_withPro())!;
      expect(pro.name, 'Sam Rivera');
      expect(pro.company, 'Summit Heating & Air');
      expect(pro.phone, '555 010 1');
      expect(pro.id, TaskPro.storedId);
    });

    test('is null when nobody ever hired a pro', () {
      expect(
        TaskProPrefill.lastPro([fixtureCompletion('a', daysFromToday(-5))]),
        isNull,
      );
    });

    test('a company alone is enough to name the pro', () {
      final pro = TaskProPrefill.lastPro([
        fixtureCompletion(
          'a',
          daysFromToday(-5),
          by: 'contractor',
          company: 'Summit',
        ),
      ])!;
      expect(pro.name, 'Summit');
      expect(pro.display, 'Summit');
    });

    test('matches an entry of Who to call by phone digits, then by name', () {
      final stored = TaskProPrefill.lastPro(_withPro())!;
      expect(TaskProPrefill.resolve(stored, [_dana, _sam]).id, 'k1');
      const byName = TaskPro(id: 'x', name: 'sam rivera');
      expect(TaskProPrefill.resolve(stored, [_dana, byName]).id, 'x');
      expect(TaskProPrefill.resolve(stored, [_dana]), same(stored));
    });
  });

  group('TaskLogFormState pro pre-fill', () {
    test('Me never gets a pro', () {
      final f = _form();
      expect(f.pro, isNull);
      f.setDoer(TaskDoer.me);
      expect(f.pro, isNull);
      f.dispose();
    });

    test('A pro starts on the last pro, matched to Who to call', () {
      final f = _form(pros: const [_dana, _sam]);
      f.setDoer(TaskDoer.pro);
      expect(f.pro!.id, 'k1');
      f.dispose();
    });

    test('with no match it is a read-only pro built from what was saved', () {
      final f = _form(pros: const [_dana]);
      f.setDoer(TaskDoer.pro);
      expect(f.pro!.id, TaskPro.storedId);
      expect(f.pro!.display, 'Summit Heating & Air');
      expect(f.pro!.phone, '555 010 1');
      f.dispose();
    });

    test('Who to call loading later swaps the untouched pre-fill', () {
      final f = _form();
      f.setDoer(TaskDoer.pro);
      expect(f.pro!.id, TaskPro.storedId);
      f.setKnownPros(const [_sam]);
      expect(f.pro!.id, 'k1');
      f.dispose();
    });

    test('a pro the user picked is never replaced', () {
      final f = _form();
      f.setPro(_dana);
      f.setDoer(TaskDoer.pro);
      expect(f.pro, _dana);
      f.setKnownPros(const [_sam]);
      expect(f.pro, _dana);
      f.dispose();
    });

    test('a pick made after the pre-fill is not swapped back', () {
      final f = _form();
      f.setDoer(TaskDoer.pro);
      f.setPro(_dana);
      f.setKnownPros(const [_sam]);
      expect(f.pro, _dana);
      f.dispose();
    });

    test('cleared stays cleared, even after Me and back to A pro', () {
      final f = _form(pros: const [_sam]);
      f.setDoer(TaskDoer.pro);
      f.clearPro();
      expect(f.pro, isNull);
      f.setDoer(TaskDoer.me);
      f.setDoer(TaskDoer.pro);
      expect(f.pro, isNull);
      f.setKnownPros(const [_sam]);
      expect(f.pro, isNull);
      f.dispose();
    });

    test('it applies once: Me and back keeps the same pro', () {
      final f = _form(pros: const [_sam]);
      f.setDoer(TaskDoer.pro);
      f.setDoer(TaskDoer.me);
      f.setDoer(TaskDoer.pro);
      expect(f.pro!.id, 'k1');
      f.dispose();
    });

    test('no earlier pro completion leaves the card empty', () {
      final f = _form(completions: [fixtureCompletion('a', daysFromToday(-5))]);
      f.setDoer(TaskDoer.pro);
      expect(f.pro, isNull);
      f.dispose();
    });
  });

  group('Log screen', () {
    FakeTaskDetailRepository repo() => FakeTaskDetailRepository(
      fixtureDetail(
        task: fixtureTask(due: daysFromToday(10)),
        completions: _withPro(),
      ),
    );

    const path = '/maintenance/complete/t1';

    testWidgets('A pro shows the last pro in the card, saved only on Save', (
      t,
    ) async {
      final fake = repo();
      await pumpTasks(t, fake, location: path, pros: const [_sam, _dana]);
      expect(find.text('Choose a pro'), findsNothing);

      await t.tap(find.text('A pro'));
      await t.pumpAndSettle();
      expect(find.text('Summit Heating & Air'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
      expect(fake.inserted, isEmpty);

      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      final saved = fake.inserted.single;
      expect(saved.doer, TaskDoer.pro);
      expect(saved.pro!.name, 'Sam Rivera');
      expect(saved.pro!.company, 'Summit Heating & Air');
      expect(saved.pro!.phone, '(555) 010-1');
    });

    testWidgets('Me saves no pro', (t) async {
      final fake = repo();
      await pumpTasks(t, fake, location: path, pros: const [_sam]);
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect(fake.inserted.single.doer, TaskDoer.me);
      expect(fake.inserted.single.pro, isNull);
    });

    testWidgets('Clear empties the card and Save then saves no pro', (t) async {
      final fake = repo();
      await pumpTasks(t, fake, location: path, pros: const [_sam]);
      await t.tap(find.text('A pro'));
      await t.pumpAndSettle();

      // Change at the right; the clear control is the last thing in the card.
      final change = t.getRect(find.text('Change'));
      final clear = t.getRect(find.byIcon(Icons.close).first);
      expect(clear.left, greaterThan(change.right));
      // Page padding, card border and padding, and the 44 pt target's slack.
      expect(390 - clear.right, closeTo(16 + 1.5 + 14 + 15, 2));

      await t.tap(find.byIcon(Icons.close).first);
      await t.pumpAndSettle();
      expect(find.text('Choose a pro'), findsOneWidget);
      expect(find.text('Summit Heating & Air'), findsNothing);

      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect(fake.inserted.single.pro, isNull);
    });

    testWidgets('picking another pro replaces the pre-fill', (t) async {
      final fake = repo();
      await pumpTasks(t, fake, location: path, pros: const [_sam, _dana]);
      await t.tap(find.text('A pro'));
      await t.pumpAndSettle();
      await t.tap(find.text('Change'));
      await t.pumpAndSettle();
      await t.tap(find.text('Dana Lee'));
      await t.pumpAndSettle();
      expect(find.text('Dana Lee'), findsOneWidget);
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect(fake.inserted.single.pro!.name, 'Dana Lee');
    });
  });
}
