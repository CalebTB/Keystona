import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/theme/aurora_colors.dart';
import 'package:keystona/features/home_profile/lifespan/lifespan_reading.dart';
import 'package:keystona/features/home_profile/widgets/shared/lifespan_bar.dart';
import 'package:keystona/features/home_profile/widgets/shared/lifespan_colors.dart';

import '../support/home_widget_harness.dart';

LifespanReading at(double percent) =>
    LifespanReading.ofAge(ageYears: percent, lifeYears: 100);

double fillRatio(WidgetTester tester) {
  final fill = tester.getSize(
    find.descendant(
      of: find.byType(FractionallySizedBox).first,
      matching: find.byType(DecoratedBox),
    ).first,
  );
  final track = tester.getSize(find.byType(LifespanBar));
  return fill.width / track.width;
}

void main() {
  testWidgetResponsive('LifespanBar', () => LifespanBar(reading: at(50)));
  testWidgetResponsive(
    'LifespanBar large with tick',
    () => LifespanBar(reading: at(120), large: true, showTick: true),
  );

  group('colors by band', () {
    test('plenty is cobalt, aging and end of life amber, past coral', () {
      expect(at(10).barColor, AuroraColors.cobalt);
      expect(at(75).barColor, AuroraColors.amber);
      expect(at(95).barColor, AuroraColors.amber);
      expect(at(101).barColor, AuroraColors.coral);
      expect(LifespanReading.unknown.barColor, AuroraColors.cobalt);
    });
    test('text colors', () {
      expect(at(10).textColor, AuroraColors.ink);
      expect(at(80).textColor, AuroraColors.amberDeep);
      expect(at(110).textColor, AuroraColors.coralDeep);
    });
  });

  testWidgets('the fill is proportional to percent of life used', (t) async {
    for (final p in [0.0, 25.0, 50.0, 71.0, 100.0]) {
      await pumpPhone(t, LifespanBar(reading: at(p)));
      expect(fillRatio(t), closeTo(p / 100, 0.001), reason: '$p percent');
    }
  });

  testWidgets('past its life the fill stops at the full width', (t) async {
    await pumpPhone(t, LifespanBar(reading: at(140)));
    expect(fillRatio(t), 1);
  });

  testWidgets('the bar spans the content width', (t) async {
    await pumpPhone(t, LifespanBar(reading: at(50)));
    final rect = t.getRect(find.byType(LifespanBar));
    expect(rect.left, kPad);
    expect(rect.right, contentRight);
  });

  testWidgets('the fill paints the band color', (t) async {
    await pumpPhone(t, LifespanBar(reading: at(110)));
    final box = t.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(FractionallySizedBox).first,
        matching: find.byType(DecoratedBox),
      ).first,
    );
    expect((box.decoration as BoxDecoration).color, AuroraColors.coral);
  });

  testWidgets('the tick sits at three quarters', (t) async {
    await pumpPhone(
      t,
      LifespanBar(reading: at(10), large: true, showTick: true),
    );
    final bar = t.getRect(find.byType(LifespanBar));
    final tick = t.getRect(
      find.descendant(
        of: find.byType(LifespanBar),
        matching: find.byType(ColoredBox),
      ).last,
    );
    expect((tick.right - bar.left) / bar.width, closeTo(0.75, 0.02));
  });
}
