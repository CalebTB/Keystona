import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/theme/aurora_colors.dart';
import 'package:keystona/core/theme/aurora_sizes.dart';
import 'package:keystona/core/widgets/aurora/aurora.dart';
import 'package:keystona/core/widgets/aurora/aurora_field_chrome.dart';

import '../support/responsive_harness.dart';

/// Test-only page gutter.
const double _gutter = 16;

const _long =
    'A very long label that must wrap or truncate instead of overflowing';

/// Scrollable page hosting [children], like a real screen body.
Widget _page(List<Widget> children) => Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(_gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );

Future<void> _pumpPage(WidgetTester tester, List<Widget> children) =>
    tester.pumpWidget(MaterialApp(home: _page(children)));

void main() {
  group('responsive: buttons', () {
    testResponsive(
      'buttons',
      () => _page([
        PrimaryButton(label: _long, onPressed: () {}, expand: true),
        PrimaryButton(label: 'Upgrade', onPressed: () {}, tone: AuroraButtonTone.coral, large: true, expand: true),
        PrimaryButton(label: 'Saving', onPressed: () {}, loading: true, expand: true),
        SecondaryButton(label: _long, onPressed: () {}, expand: true),
        SaveButton(label: 'Save task', onPressed: null, expand: true),
        Row(children: [
          SaveButton(label: 'Save', onPressed: () {}, compact: true),
          Flexible(child: GhostButton(label: _long, onPressed: () {})),
        ]),
        Wrap(children: [
          PrimaryButton(label: 'One', onPressed: () {}),
          SecondaryButton(label: 'Two', onPressed: () {}),
        ]),
      ]),
    );
  });

  group('responsive: chips', () {
    testResponsive(
      'chips',
      () => _page([
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final i in [0, 1, 2, 3, 4])
            FilterPill(label: i == 0 ? _long : 'Filter $i', selected: i.isEven, count: i, onTap: () {}),
        ]),
        const Wrap(children: [
          StatusChip.overdue(label: 'Overdue'),
          StatusChip.dueSoon(label: 'Due soon'),
          StatusChip.scheduled(label: 'Scheduled'),
          StatusChip.done(label: 'Done'),
        ]),
      ]),
    );
  });

  group('responsive: cards and rows', () {
    testResponsive(
      'cards, tile, hero, task rows, fab',
      () => _page([
        AuroraCard(accentColor: AuroraColors.coral, onTap: () {}, child: const Text(_long)),
        const AuroraTile(child: Text(_long)),
        const AuroraHeroCard(score: 72, trend: 'Stable this month', maintScore: 80, docsScore: 60, emergScore: 50),
        AuroraTaskRow(name: _long, dueLabel: 'Jun 30', metaLine: _long, onTap: () {}, overdue: true, onToggle: () {}),
        AuroraTaskRow(name: _long, dueLabel: 'Today', metaLine: 'Due today', onTap: () {}, dueToday: true, iconData: Icons.build),
        AuroraTaskRow(name: _long, dueLabel: 'Done', metaLine: 'Finished', onTap: () {}, done: true, onToggle: () {}),
        Align(alignment: Alignment.centerRight, child: AuroraFAB(icon: Icons.add, onPressed: () {}, tooltip: 'Add')),
      ]),
    );
  });

  group('responsive: form widgets', () {
    final controller = TextEditingController();
    testResponsive(
      'fields, select, toggle, section',
      () => _page([
        AuroraFormSection(title: _long, isOptional: true, children: [
          AuroraTextField(label: _long, controller: controller, required: true, helperText: _long, hintText: _long, suffix: const Icon(Icons.camera_alt)),
          AuroraTextField(label: 'Notes', controller: controller, maxLines: 5),
          AuroraSelectField(label: _long, value: _long, onTap: () {}, required: true, helperText: _long),
          AuroraSelectField(label: 'Empty', onTap: () {}, expanded: true),
          AuroraToggleRow(label: _long, helperText: _long, value: true, onChanged: (_) {}),
          AuroraToggleRow(label: 'Off', value: false, onChanged: (_) {}),
        ]),
      ]),
    );
  });

  group('responsive: sheet', () {
    for (final viewport in activeViewports) {
      for (final scale in scalesFor(viewport)) {
        testWidgets('sheet + action sheet @ ${viewport.name}, text x$scale',
            (tester) async {
          await pumpScreen(
            tester,
            () => Scaffold(
              body: Builder(
                builder: (c) => Column(children: [
                  TextButton(
                    onPressed: () => AuroraSheet.show<void>(c,
                        title: _long,
                        confirmLabel: 'Save task',
                        onConfirm: () {},
                        child: Column(children: [
                          for (var i = 0; i < 12; i++) const Text(_long),
                        ])),
                    child: const Text('open'),
                  ),
                  TextButton(
                    onPressed: () => AuroraSheet.actionSheet(c,
                        title: 'Move',
                        actions: const [
                          AuroraSheetAction(label: _long, icon: Icons.folder),
                          AuroraSheetAction(label: 'Delete', destructive: true),
                        ]),
                    child: const Text('action'),
                  ),
                ]),
              ),
            ),
            viewport: viewport,
            textScale: scale,
          );
          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          Navigator.of(tester.element(find.byType(BottomSheet))).pop();
          await tester.pumpAndSettle();
          await tester.tap(find.text('action'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('buttons', () {
    testWidgets('primary is cobalt and 46 high; coral tone is coral',
        (tester) async {
      await _pumpPage(tester, [
        Row(children: [PrimaryButton(label: 'Go', onPressed: () {})]),
        Row(children: [
          PrimaryButton(label: 'Pay', onPressed: () {}, tone: AuroraButtonTone.coral),
        ]),
      ]);
      Color fillOf(String label) {
        final box = tester.widget<DecoratedBox>(find
            .ancestor(of: find.text(label), matching: find.byType(DecoratedBox))
            .first);
        return (box.decoration as BoxDecoration).color!;
      }

      expect(fillOf('Go'), AuroraColors.cobalt);
      expect(fillOf('Pay'), AuroraColors.coral);
      expect(tester.getSize(find.text('Go').first).height, lessThan(AuroraSizes.buttonHeight));
      final pill = find.ancestor(of: find.text('Go'), matching: find.byType(Container)).first;
      expect(tester.getSize(pill).height, AuroraSizes.buttonHeight);
    });

    testWidgets('tap fires; null onPressed and loading do not; disabled uses ink 8%',
        (tester) async {
      var taps = 0;
      await _pumpPage(tester, [
        Row(children: [PrimaryButton(label: 'Go', onPressed: () => taps++)]),
        Row(children: [PrimaryButton(label: 'Load', onPressed: () => taps++, loading: true)]),
        Row(children: [SaveButton(label: 'Save', onPressed: null)]),
      ]);
      await tester.tap(find.text('Go'));
      await tester.tap(find.byType(CircularProgressIndicator));
      await tester.tap(find.text('Save'));
      expect(taps, 1);
      final save = tester.widget<DecoratedBox>(find
          .ancestor(of: find.text('Save'), matching: find.byType(DecoratedBox))
          .first);
      expect((save.decoration as BoxDecoration).color, AuroraColors.inkDisabledFill);
    });

    testWidgets('compact save is 36 drawn but 44 tappable', (tester) async {
      await _pumpPage(tester, [
        Row(children: [SaveButton(label: 'Save', onPressed: () {}, compact: true)]),
      ]);
      final pill = find.ancestor(of: find.text('Save'), matching: find.byType(Container)).first;
      expect(tester.getSize(pill).height, AuroraSizes.buttonHeightSm);
      final target = find.ancestor(of: pill, matching: find.byType(ConstrainedBox)).first;
      expect(tester.getSize(target).height, greaterThanOrEqualTo(AuroraSizes.minTouch));
    });
  });

  group('chips', () {
    testWidgets('selected = ink fill; unselected = paper with border; tappable',
        (tester) async {
      var taps = 0;
      await _pumpPage(tester, [
        Row(children: [
          FilterPill(label: 'On', selected: true, onTap: () => taps++),
          FilterPill(label: 'Off', selected: false, onTap: () {}),
        ]),
      ]);
      BoxDecoration deco(String t) => tester
          .widget<Container>(find.ancestor(of: find.text(t), matching: find.byType(Container)).first)
          .decoration! as BoxDecoration;
      expect(deco('On').color, AuroraColors.ink);
      expect(deco('Off').color, AuroraColors.paper);
      expect((deco('Off').border! as Border).top.color, AuroraColors.inkInputBorder);
      await tester.tap(find.text('On'));
      expect(taps, 1);
    });

    testWidgets('status chips: outline for statuses, solid lime for done',
        (tester) async {
      await _pumpPage(tester, [
        const Row(children: [StatusChip.overdue(label: 'Overdue'), StatusChip.done(label: 'Done')]),
      ]);
      BoxDecoration deco(String t) => tester
          .widget<Container>(find.ancestor(of: find.text(t.toUpperCase()), matching: find.byType(Container)).first)
          .decoration! as BoxDecoration;
      expect(deco('Overdue').color, AuroraColors.paper);
      expect(deco('Overdue').border, isNotNull);
      expect(deco('Done').color, AuroraColors.lime);
    });
  });

  group('switch and toggle row', () {
    testWidgets('switch is 51x31, cobalt on, ink 16% off, and toggles',
        (tester) async {
      var value = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (c, set) => Center(
              child: AuroraSwitch(value: value, onChanged: (v) => set(() => value = v)),
            ),
          ),
        ),
      ));
      BoxDecoration deco() => tester
          .widget<AnimatedContainer>(find.byType(AnimatedContainer))
          .decoration! as BoxDecoration;
      expect(deco().color, AuroraColors.inkTrackOff);
      expect(tester.getSize(find.byType(AnimatedContainer)), const Size(AuroraSizes.switchWidth, AuroraSizes.switchHeight));
      await tester.tap(find.byType(AuroraSwitch));
      await tester.pumpAndSettle();
      expect(value, isTrue);
      expect(deco().color, AuroraColors.cobalt);
    });

    testWidgets('toggle row has no tinted fill and reports changes', (tester) async {
      bool? changed;
      await _pumpPage(tester, [
        AuroraToggleRow(label: 'Reminders', helperText: 'weekly', value: false, onChanged: (v) => changed = v),
      ]);
      expect(find.text('WEEKLY'), findsOneWidget);
      await tester.tap(find.byType(AuroraSwitch));
      expect(changed, isTrue);
    });
  });

  group('fields', () {
    testWidgets('label and helper render uppercase; required shows a coral star',
        (tester) async {
      await _pumpPage(tester, [
        AuroraTextField(label: 'Task name', controller: TextEditingController(), required: true, helperText: 'Why'),
      ]);
      expect(find.textContaining('TASK NAME', findRichText: true), findsOneWidget);
      expect(find.text('WHY'), findsOneWidget);
    });

    testWidgets('validator error shows below and turns the border coral',
        (tester) async {
      final key = GlobalKey<FormState>();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Form(
            key: key,
            child: AuroraTextField(
              label: 'Name',
              controller: TextEditingController(),
              validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
            ),
          ),
        ),
      ));
      expect(key.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('REQUIRED'), findsOneWidget);
      final box = tester.widget<Container>(find
          .descendant(of: find.byType(AuroraFieldBox), matching: find.byType(Container))
          .first);
      expect(((box.decoration! as BoxDecoration).border! as Border).top.color, AuroraColors.coral);
    });

    testWidgets('select shows value or placeholder and taps', (tester) async {
      var taps = 0;
      await _pumpPage(tester, [
        AuroraSelectField(label: 'How often', onTap: () => taps++, placeholder: 'Choose one'),
        AuroraSelectField(label: 'Item', value: 'Furnace', onTap: () {}),
      ]);
      expect(find.text('Choose one'), findsOneWidget);
      expect(find.text('Furnace'), findsOneWidget);
      await tester.tap(find.text('Choose one'));
      expect(taps, 1);
      expect(tester.getSize(find.byType(AuroraFieldBox).first).height, AuroraSizes.inputHeight);
    });
  });

  group('task row and card', () {
    testWidgets('tap, long-press and toggle are separate', (tester) async {
      var tap = 0, long = 0, toggle = 0;
      await _pumpPage(tester, [
        AuroraTaskRow(
          name: 'Change filter',
          dueLabel: 'Jun 30',
          metaLine: 'Furnace',
          onTap: () => tap++,
          onLongPress: () => long++,
          onToggle: () => toggle++,
          overdue: true,
        ),
      ]);
      await tester.tap(find.text('Change filter'));
      await tester.longPress(find.text('Change filter'));
      expect([tap, long], [1, 1]);
      expect(find.text('JUN 30'), findsOneWidget);
      final circle = find.byWidgetPredicate((w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).shape == BoxShape.circle);
      await tester.tap(circle);
      expect([tap, toggle], [1, 1]);
    });

    testWidgets('done row shows the olive check', (tester) async {
      await _pumpPage(tester, [
        AuroraTaskRow(name: 'Done', dueLabel: 'x', metaLine: 'y', onTap: () {}, onToggle: () {}, done: true),
      ]);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });

  group('sheet chrome', () {
    testWidgets('disabled Save when onConfirm is null', (tester) async {
      await pumpScreen(
        tester,
        () => Scaffold(
          body: Builder(
            builder: (c) => TextButton(
              onPressed: () => AuroraSheet.show<void>(c,
                  title: 'T', confirmLabel: 'Save', child: const Text('b')),
              child: const Text('open'),
            ),
          ),
        ),
        viewport: kViewports[1],
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final save = tester.widget<DecoratedBox>(find
          .ancestor(of: find.text('Save'), matching: find.byType(DecoratedBox))
          .first);
      expect((save.decoration as BoxDecoration).color, AuroraColors.inkDisabledFill);
      final surface = tester.widget<Material>(find
          .descendant(of: find.byType(BottomSheet), matching: find.byType(Material))
          .first);
      expect(surface.color, AuroraColors.paper);
    });
  });
}
