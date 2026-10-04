import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

    testWidgets('a 4+ line textarea still opens at 4 lines', (tester) async {
      await _pump(tester, 6);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.minLines, 4);
    });

    testWidgets('a single-line field stays at 1 line', (tester) async {
      await _pump(tester, 1);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.minLines, 1);
    });

    testWidgets('container height grows with minLines, 4 lines stays 120',
        (tester) async {
      // 48 + (minLines - 1) * 24 — the 4-line case must keep its old 120px.
      for (final (maxLines, expected) in [(1, 48.0), (2, 72.0), (3, 96.0), (4, 120.0), (8, 120.0)]) {
        await _pump(tester, maxLines);
        final box = tester.widget<Container>(
          find
              .ancestor(
                of: find.byType(TextField),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(
          box.constraints?.minHeight,
          expected,
          reason: 'maxLines: $maxLines',
        );
      }
    });
  });
}
