import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/theme/aurora_sizes.dart';
import 'package:keystona/core/widgets/aurora/aurora_field_chrome.dart';
import 'package:keystona/core/widgets/aurora/aurora_text_field.dart';

/// Regression tests for the `minLines can't be greater than maxLines`
/// assertion. AuroraTextField treats any maxLines > 1 as a textarea and used
/// to hard-code minLines: 4, so every caller passing maxLines 2 or 3 threw on
/// first build (shutoff_detail_screen passes both).
Future<void> _pump(WidgetTester tester, int maxLines) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AuroraTextField(
          label: 'Location Description',
          controller: TextEditingController(),
          maxLines: maxLines,
        ),
      ),
    ),
  );
}

void main() {
  group('AuroraTextField maxLines', () {
    // 2 and 3 are the values that actually crashed.
    for (final n in [1, 2, 3, 4, 5, 10]) {
      testWidgets('builds without asserting at maxLines: $n', (tester) async {
        await _pump(tester, n);
        expect(tester.takeException(), isNull);
        expect(find.byType(TextField), findsOneWidget);
      });
    }

    testWidgets('minLines never exceeds maxLines', (tester) async {
      for (final n in [1, 2, 3, 4, 10]) {
        await _pump(tester, n);
        final field = tester.widget<TextField>(find.byType(TextField));
        final minLines = field.minLines;
        final maxLines = field.maxLines;
        expect(minLines, isNotNull);
        expect(maxLines, n);
        expect(
          minLines! <= maxLines!,
          isTrue,
          reason: 'maxLines: $n produced minLines: $minLines',
        );
      }
    });

    testWidgets('a 3+ line textarea opens at 3 lines (kit rows=3)',
        (tester) async {
      await _pump(tester, 6);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.minLines, 3);
    });

    testWidgets('a single-line field stays at 1 line', (tester) async {
      await _pump(tester, 1);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.minLines, 1);
    });

    testWidgets('box is at least 50 high and grows with the lines',
        (tester) async {
      var previous = 0.0;
      for (final maxLines in [1, 2, 3, 8]) {
        await _pump(tester, maxLines);
        final height = tester.getSize(find.byType(AuroraFieldBox)).height;
        expect(height, greaterThanOrEqualTo(AuroraSizes.inputHeight));
        expect(height, greaterThanOrEqualTo(previous));
        previous = height;
      }
    });
  });
}
