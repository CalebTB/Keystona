import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/documents/models/document_ocr.dart';
import 'package:keystona/features/documents/models/document_scan.dart';
import 'package:keystona/features/documents/screens/document_camera_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/responsive_harness.dart';
import 'upload_test_support.dart';

/// Opens the camera from a button and keeps what it pops.
class _Host extends StatefulWidget {
  const _Host({required this.smart});

  final bool smart;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  ScanFlowResult? result;
  bool closed = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        TextButton(
          onPressed: () async {
            final r = await Navigator.of(context).push<ScanFlowResult>(
              MaterialPageRoute(
                builder: (_) => DocumentCameraScreen(startSmart: widget.smart),
              ),
            );
            setState(() {
              result = r;
              closed = r == null;
            });
          },
          child: const Text('open camera'),
        ),
        Text(closed ? 'closed' : 'open'),
        Text(
          result == null
              ? 'no result'
              : 'pages ${result!.outcome.pageCount} found ${result!.found?.detailCount}',
        ),
      ],
    ),
  );
}

Future<FakeOcr> _pump(
  WidgetTester tester, {
  bool smart = true,
  bool premium = true,
  FakeOcr? ocr,
  FakeScanner? scanner,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final reader = ocr ?? FakeOcr();
  await tester.pumpWidget(
    ProviderScope(
      overrides: uploadOverrides(
        premium: premium,
        ocr: reader,
        scanner: scanner,
      ),
      child: MaterialApp(home: _Host(smart: smart)),
    ),
  );
  await tester.tap(find.text('open camera'));
  await tester.pumpAndSettle();
  return reader;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testResponsive(
    'DocCamera',
    () => const DocumentCameraScreen(startSmart: true),
    wrap: (app) => scopeWrap(uploadOverrides(premium: true), app),
  );

  testWidgets('smart mode shows the kit chrome and no Done before a page', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('★ SMART SCAN · PAGE 1'), findsOneWidget);
    expect(find.text('Move closer · fill the frame'), findsOneWidget);
    expect(find.text('Smart scan'), findsOneWidget);
    expect(find.text('Just the photo'), findsOneWidget);
    expect(find.text('Done'), findsNothing);
    expect(find.bySemanticsLabel('Take picture'), findsOneWidget);
  });

  testWidgets('each shot adds a page, bumps the label and shows Done', (
    tester,
  ) async {
    final scanner = FakeScanner();
    await _pump(tester, scanner: scanner);
    await tester.tap(find.bySemanticsLabel('Take picture'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Take picture'));
    await tester.pumpAndSettle();
    expect(scanner.captures, 2);
    expect(find.text('★ SMART SCAN · PAGE 3'), findsOneWidget);
    expect(find.text('2'), findsOneWidget, reason: 'page count badge');
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('a failed capture says so and keeps the pages', (tester) async {
    await _pump(tester, scanner: FakeScanner(fail: true));
    await tester.tap(find.bySemanticsLabel('Take picture'));
    await tester.pump();
    await tester.pump();
    expect(find.text("Couldn't take that picture. Try again."), findsOneWidget);
    expect(find.text('Done'), findsNothing);
  });

  testWidgets('Just the photo then Done closes with the file, no reading', (
    tester,
  ) async {
    final ocr = FakeOcr();
    await _pump(tester, smart: false, ocr: ocr);
    expect(find.text('PAGE 1'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Take picture'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('pages 1 found null'), findsOneWidget);
    expect(ocr.reads, 0);
  });

  testWidgets('free plan: choosing Smart scan offers the upgrade', (
    tester,
  ) async {
    await _pump(tester, smart: false, premium: false);
    await tester.tap(find.text('Smart scan'));
    await tester.pumpAndSettle();
    expect(find.text('Unlock Smart scan'), findsOneWidget);
    expect(find.text('PAGE 1'), findsOneWidget, reason: 'stayed in plain mode');
  });

  testWidgets('close pops with nothing', (tester) async {
    await _pump(tester);
    await tester.tap(find.bySemanticsLabel('Close camera'));
    await tester.pumpAndSettle();
    expect(find.text('closed'), findsOneWidget);
  });

  group('reading your document', () {
    Future<FakeOcr> toReading(WidgetTester tester) async {
      final ocr = await _pump(tester);
      await tester.tap(find.bySemanticsLabel('Take picture'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pump();
      await tester.pump();
      return ocr;
    }

    testWidgets('shows the card while the reader works, then the result', (
      tester,
    ) async {
      final ocr = await toReading(tester);
      expect(find.text('Reading your document…'), findsOneWidget);
      expect(find.text('★ SMART SCAN · 1 PAGE'), findsOneWidget);
      expect(find.text('12%'), findsOneWidget);
      expect(find.text('Keep going in the background'), findsOneWidget);
      expect(
        find.text(
          'USUALLY UNDER 10 SECONDS · NOTHING IS SAVED UNTIL YOU CHECK IT',
        ),
        findsOneWidget,
      );

      ocr.emit(
        2,
        const OcrResult(
          textSummary: 'Northline · Limited Warranty Certificate',
          categoryName: 'Warranty',
        ),
      );
      await tester.pump();
      expect(find.text('62%'), findsOneWidget);
      expect(
        find.text('Northline · Limited Warranty Certificate'),
        findsOneWidget,
      );
      expect(find.text('Warranty'), findsOneWidget);

      ocr.emit(4, fullResult());
      await tester.pump();
      await tester.pump();
      expect(find.text('Found 4 details'), findsOneWidget);
      expect(find.text('Expires Mar 15, 2031'), findsOneWidget);
      expect(find.text('Your furnace — serial 2103A47719'), findsOneWidget);
      expect(find.text('Check what we found'), findsOneWidget);
      expect(find.text('Keep going in the background'), findsNothing);

      await tester.tap(find.text('Check what we found'));
      await tester.pumpAndSettle();
      expect(find.text('pages 1 found 4'), findsOneWidget);
    });

    testWidgets('keep going in the background closes without a result', (
      tester,
    ) async {
      await toReading(tester);
      await tester.tap(find.text('Keep going in the background'));
      await tester.pumpAndSettle();
      expect(find.text('pages 1 found null'), findsOneWidget);
    });

    testWidgets('a reader that cannot run offers retry and skip', (
      tester,
    ) async {
      await _pump(tester, ocr: FakeOcr(fail: true));
      await tester.tap(find.bySemanticsLabel('Take picture'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pump();
      await tester.pump();
      expect(find.text("We couldn't read that one"), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      await tester.tap(find.text('Fill it in myself'));
      await tester.pumpAndSettle();
      expect(find.text('pages 1 found null'), findsOneWidget);
    });
  });
}
