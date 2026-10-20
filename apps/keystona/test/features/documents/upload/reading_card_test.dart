import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/documents/models/document_ocr.dart';
import 'package:keystona/features/documents/providers/scan_reading_provider.dart';
import 'package:keystona/features/documents/widgets/upload/camera/document_reading_card.dart';

import '../../../support/responsive_harness.dart';
import 'upload_test_support.dart';

Widget _card(ScanReadingState state, {List<String>? log}) => Scaffold(
  body: SingleChildScrollView(
    child: DocumentReadingCard(
      reading: state,
      pageCount: 2,
      onCheck: () => log?.add('check'),
      onBackground: () => log?.add('background'),
      onRetry: () => log?.add('retry'),
      onSkip: () => log?.add('skip'),
    ),
  ),
);

final ScanReadingState _midway = ScanReadingState(
  status: ScanReadingStatus.reading,
  completed: 2,
  result: const OcrResult(
    textSummary: 'Northline · Limited Warranty Certificate',
    categoryName: 'Warranty',
  ),
);

final ScanReadingState _done = ScanReadingState(
  status: ScanReadingStatus.done,
  completed: 4,
  result: fullResult(),
);

void main() {
  testResponsive('DocReading, mid-way', () => _card(_midway));
  testResponsive('DocReading, finished', () => _card(_done));
  testResponsive(
    'DocReading, failed',
    () => _card(const ScanReadingState(status: ScanReadingStatus.failed)),
  );

  testWidgets('mid-way shows 62%, found text and the background button', (
    tester,
  ) async {
    final log = <String>[];
    await tester.pumpWidget(MaterialApp(home: _card(_midway, log: log)));
    expect(find.text('★ SMART SCAN · 2 PAGES'), findsOneWidget);
    expect(find.text('62%'), findsOneWidget);
    expect(find.text('Reading your document…'), findsOneWidget);
    for (final stage in OcrStage.values) {
      expect(find.text(stage.label), findsOneWidget);
    }
    expect(find.text('Warranty'), findsOneWidget);
    expect(
      find.byIcon(Icons.check),
      findsNWidgets(2),
      reason: 'two steps done',
    );
    await tester.tap(find.text('Keep going in the background'));
    expect(log, ['background']);
  });

  testWidgets('finished shows the count and Check what we found', (
    tester,
  ) async {
    final log = <String>[];
    await tester.pumpWidget(MaterialApp(home: _card(_done, log: log)));
    expect(find.text('Found 4 details'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNWidgets(4));
    await tester.tap(find.text('Check what we found'));
    expect(log, ['check']);
  });

  testWidgets('failed offers retry and fill-in-myself', (tester) async {
    final log = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: _card(
          const ScanReadingState(status: ScanReadingStatus.failed),
          log: log,
        ),
      ),
    );
    await tester.tap(find.text('Try again'));
    await tester.tap(find.text('Fill it in myself'));
    expect(log, ['retry', 'skip']);
    expect(find.textContaining('%'), findsNothing);
  });
}
