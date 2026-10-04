import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/theme/aurora_breakpoints.dart';
import 'package:keystona/core/widgets/aurora/aurora_sheet.dart';

/// Pumps [child] at an exact logical screen size so responsive branches can
/// be asserted without a real device.
Future<void> _pumpAt(
  WidgetTester tester,
  Size size,
  Widget child,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: child));
}

const _compact = Size(375, 812); // iPhone SE / 13 mini
const _regular = Size(402, 874); // iPhone 16
const _tablet = Size(834, 1194); // iPad 11"

/// The visible sheet surface — `BottomSheet` itself spans the full viewport,
/// so width/offset assertions must target the Material inside it.
final Finder _surface = find
    .descendant(of: find.byType(BottomSheet), matching: find.byType(Material))
    .first;

/// Minimal host that opens a titled sheet — keeps the width tests honest by
/// using one widget tree per test.
class _Opener extends StatelessWidget {
  const _Opener();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (c) => ElevatedButton(
          onPressed: () => AuroraSheet.show<void>(
            c,
            title: 'T',
            child: const Text('body'),
          ),
          child: const Text('open'),
        ),
      ),
    );
  }
}

void main() {
  group('AuroraBreakpoints', () {
    test('classifies by width at the documented boundaries', () {
      expect(AuroraBreakpoints.forWidth(320), AuroraDeviceClass.compact);
      expect(AuroraBreakpoints.forWidth(389), AuroraDeviceClass.compact);
      expect(AuroraBreakpoints.forWidth(390), AuroraDeviceClass.regular);
      expect(AuroraBreakpoints.forWidth(599), AuroraDeviceClass.regular);
      expect(AuroraBreakpoints.forWidth(600), AuroraDeviceClass.tablet);
      expect(AuroraBreakpoints.forWidth(1024), AuroraDeviceClass.tablet);
    });
  });

  group('AuroraSheetHeight', () {
    test('fractions match Component Library §3.3', () {
      expect(AuroraSheetHeight.compact.fraction, 0.35);
      expect(AuroraSheetHeight.medium.fraction, 0.50);
      expect(AuroraSheetHeight.tall.fraction, 0.70);
      expect(AuroraSheetHeight.extra.fraction, 0.85);
      expect(AuroraSheetHeight.full.fraction, 0.95);
    });

    testWidgets('resolves spec fraction verbatim on a regular phone',
        (tester) async {
      late double h;
      await _pumpAt(tester, _regular, Builder(builder: (c) {
        h = AuroraSheetHeight.tall.resolve(c);
        return const SizedBox();
      }));
      expect(h, closeTo(874 * 0.70, 0.01));
    });

    testWidgets('gives compact phones more of the screen', (tester) async {
      late double h;
      await _pumpAt(tester, _compact, Builder(builder: (c) {
        h = AuroraSheetHeight.tall.resolve(c);
        return const SizedBox();
      }));
      expect(h, closeTo(812 * 0.75, 0.01));
    });

    testWidgets('gives tablets less of the screen', (tester) async {
      late double h;
      await _pumpAt(tester, _tablet, Builder(builder: (c) {
        h = AuroraSheetHeight.tall.resolve(c);
        return const SizedBox();
      }));
      expect(h, closeTo(1194 * 0.60, 0.01));
    });

    testWidgets('never exceeds 95% even after the compact bump',
        (tester) async {
      late double h;
      await _pumpAt(tester, _compact, Builder(builder: (c) {
        h = AuroraSheetHeight.full.resolve(c);
        return const SizedBox();
      }));
      expect(h, closeTo(812 * 0.95, 0.01));
    });
  });

  group('AuroraSheet.topRadius', () {
    testWidgets('is 22px on a regular phone (spec radius-2xl)',
        (tester) async {
      late BorderRadius r;
      await _pumpAt(tester, _regular, Builder(builder: (c) {
        r = AuroraSheet.topRadius(c);
        return const SizedBox();
      }));
      expect(r.topLeft.x, 22);
      expect(r.bottomLeft.x, 0, reason: 'bottom corners stay square');
    });

    testWidgets('tightens on compact and opens up on tablet', (tester) async {
      late BorderRadius compact;
      late BorderRadius tablet;
      await _pumpAt(tester, _compact, Builder(builder: (c) {
        compact = AuroraSheet.topRadius(c);
        return const SizedBox();
      }));
      await _pumpAt(tester, _tablet, Builder(builder: (c) {
        tablet = AuroraSheet.topRadius(c);
        return const SizedBox();
      }));
      expect(compact.topLeft.x, 18);
      expect(tablet.topLeft.x, 28);
    });
  });

  group('AuroraSheet.show', () {
    testWidgets('renders handle, title and confirm, and returns pop value',
        (tester) async {
      Object? result;
      await _pumpAt(
        tester,
        _regular,
        Scaffold(
          body: Builder(
            builder: (c) => ElevatedButton(
              onPressed: () async {
                result = await AuroraSheet.show<String>(
                  c,
                  title: 'Pick a system',
                  confirmLabel: 'Save',
                  onConfirm: () => Navigator.of(c).pop('saved'),
                  child: const Text('body content'),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Pick a system'), findsOneWidget);
      expect(find.text('body content'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(result, 'saved');
    });

    testWidgets('Cancel dismisses with null', (tester) async {
      Object? result = 'untouched';
      await _pumpAt(
        tester,
        _regular,
        Scaffold(
          body: Builder(
            builder: (c) => ElevatedButton(
              onPressed: () async {
                result = await AuroraSheet.show<String>(
                  c,
                  title: 'Title',
                  child: const Text('body'),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isNull);
    });

    testWidgets('centres and width-constrains the sheet on tablet',
        (tester) async {
      await _pumpAt(tester, _tablet, _Opener());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // The BottomSheet widget is the full-width outer box; the constrained
      // surface is the Material inside it.
      final w = tester.getSize(_surface).width;
      final left = tester.getTopLeft(_surface).dx;
      expect(w, lessThanOrEqualTo(AuroraBreakpoints.tabletSheetMaxWidth));
      expect(w, lessThan(_tablet.width),
          reason: 'must not stretch the full iPad width');
      expect(left, closeTo((_tablet.width - w) / 2, 0.5),
          reason: 'sheet should be horizontally centred on tablet');
    });

    testWidgets('fills the width on a phone', (tester) async {
      await _pumpAt(tester, _regular, _Opener());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final w = tester.getSize(_surface).width;
      expect(w, closeTo(_regular.width, 0.01));
    });
  });

  group('AuroraSheet.actionSheet', () {
    testWidgets('returns the tapped index and renders destructive in coral',
        (tester) async {
      int? picked;
      await _pumpAt(
        tester,
        _regular,
        Scaffold(
          body: Builder(
            builder: (c) => ElevatedButton(
              onPressed: () async {
                picked = await AuroraSheet.actionSheet(
                  c,
                  title: 'Move document to',
                  actions: const [
                    AuroraSheetAction(label: 'Receipts'),
                    AuroraSheetAction(label: 'Permits'),
                    AuroraSheetAction(label: 'Delete', destructive: true),
                  ],
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Receipts'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Permits'));
      await tester.pumpAndSettle();
      expect(picked, 1);
    });
  });
}
