import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/home_profile/lifespan/lifespan_reading.dart';

/// The day the kit's Home profile screens are drawn on.
final DateTime kNow = DateTime(2026, 10, 4);

LifespanReading ofPercent(num percent) =>
    LifespanReading.ofAge(ageYears: percent.toDouble(), lifeYears: 100);

void main() {
  group('bands at the boundaries (life 100, age = percent)', () {
    test('74 is plenty, no status', () {
      final r = ofPercent(74);
      expect(r.band, LifespanBand.plenty);
      expect(r.statusLabel, isNull);
      expect(r.isAgingOrWorse, isFalse);
    });
    test('74.99 is still plenty', () {
      expect(ofPercent(74.99).band, LifespanBand.plenty);
    });
    test('75 is aging', () {
      final r = ofPercent(75);
      expect(r.band, LifespanBand.aging);
      expect(r.statusLabel, 'AGING');
      expect(r.isAgingOrWorse, isTrue);
    });
    test('89 is aging', () {
      expect(ofPercent(89).band, LifespanBand.aging);
    });
    test('90 is at end of life', () {
      final r = ofPercent(90);
      expect(r.band, LifespanBand.endOfLife);
      expect(r.statusLabel, 'AT END OF LIFE');
    });
    test('100 is still at end of life, not past', () {
      expect(ofPercent(100).band, LifespanBand.endOfLife);
    });
    test('101 is past expected life', () {
      final r = ofPercent(101);
      expect(r.band, LifespanBand.past);
      expect(r.statusLabel, 'PAST EXPECTED LIFE');
      expect(r.isAgingOrWorse, isTrue);
    });
  });

  group('percent and bar fraction', () {
    test('percent is age over life', () {
      final r = LifespanReading.ofAge(ageYears: 5.5, lifeYears: 11);
      expect(r.percent, 50);
      expect(r.fraction, 0.5);
    });
    test('the fraction is capped at 1 past the end of life', () {
      final r = LifespanReading.ofAge(ageYears: 11.5, lifeYears: 10);
      expect(r.percent, 115);
      expect(r.fraction, 1);
    });
    test('a negative age is treated as zero', () {
      final r = LifespanReading.ofAge(ageYears: -2, lifeYears: 10);
      expect(r.ageYears, 0);
      expect(r.fraction, 0);
    });
  });

  group('expected life', () {
    test('override wins over the midpoint', () {
      expect(
        LifespanReading.expectedLife(min: 10, max: 20, override: 18),
        18,
      );
    });
    test('midpoint of min and max', () {
      expect(LifespanReading.expectedLife(min: 10, max: 20), 15);
    });
    test('a .5 midpoint rounds up to a whole year', () {
      expect(LifespanReading.expectedLife(min: 10, max: 15), 13);
      expect(LifespanReading.expectedLife(min: 12, max: 15), 14);
    });
    test('only min, only max', () {
      expect(LifespanReading.expectedLife(min: 12), 12);
      expect(LifespanReading.expectedLife(max: 15), 15);
    });
    test('an explicit lifeYears is used before the midpoint', () {
      expect(
        LifespanReading.expectedLife(lifeYears: 9, min: 10, max: 20),
        9,
      );
      expect(
        LifespanReading.expectedLife(lifeYears: 9, override: 7, min: 1),
        7,
      );
    });
    test('nothing known, or a life of zero, is unknown', () {
      expect(LifespanReading.expectedLife(), isNull);
      expect(LifespanReading.expectedLife(override: 0), isNull);
    });
  });

  group('age label', () {
    String label(double years) =>
        LifespanReading.ofAge(ageYears: years, lifeYears: 10).ageLabel;

    test('under a year reads in months', () {
      expect(label(0), '0 mo');
      expect(label(0.5), '6 mo');
      expect(label(4 / 12), '4 mo');
      expect(label(11 / 12), '11 mo');
    });
    test('a year and over rounds to the nearest half year', () {
      expect(label(1), '1 yr');
      expect(label(1.24), '1 yr');
      expect(label(1.25), '1½ yrs');
      expect(label(1.74), '1½ yrs');
      expect(label(1.75), '2 yrs');
      expect(label(5.58), '5½ yrs');
      expect(label(12), '12 yrs');
      expect(label(28.5), '28½ yrs');
    });
    test('11.5 months rounds up to a year', () {
      expect(label(0.96), '1 yr');
    });
    test('life label', () {
      expect(
        LifespanReading.ofAge(ageYears: 1, lifeYears: 12).lifeLabel,
        '~12 yrs',
      );
      expect(
        LifespanReading.ofAge(ageYears: 0, lifeYears: 1).lifeLabel,
        '~1 yr',
      );
    });
  });

  group('from dates', () {
    test('anniversaries are exact', () {
      final r = LifespanReading.from(
        start: DateTime(2014, 10, 4),
        lifeYears: 12,
        now: kNow,
      );
      expect(r.ageYears, 12);
      expect(r.percent, 100);
    });
    test('a start date in the future reads as zero', () {
      final r = LifespanReading.from(
        start: DateTime(2027),
        lifeYears: 10,
        now: kNow,
      );
      expect(r.ageYears, 0);
      expect(r.ageLabel, '0 mo');
    });
    test('replace year is start year plus life', () {
      final r = LifespanReading.from(
        start: DateTime(2021, 3, 15),
        lifeYears: 15,
        now: kNow,
      );
      expect(r.replaceYear, 2036);
    });
    test('yearsLeft is life minus age, negative once past', () {
      final a = LifespanReading.ofAge(ageYears: 5.5, lifeYears: 15);
      expect(a.yearsLeft, 9.5);
      final b = LifespanReading.ofAge(ageYears: 11.5, lifeYears: 10);
      expect(b.yearsLeft, -1.5);
    });
  });

  group('unknown readings', () {
    test('no start date: no age, no band', () {
      final r = LifespanReading.from(lifeYears: 15, now: kNow);
      expect(r.ageYears, isNull);
      expect(r.percent, isNull);
      expect(r.band, isNull);
      expect(r.ageLabel, '');
      expect(r.statusLabel, isNull);
      expect(r.replaceYear, isNull);
      expect(r.isAgingOrWorse, isFalse);
      expect(r.fraction, 0);
      expect(r.lifeLabel, '~15 yrs');
    });
    test('no life: the age shows, no band', () {
      final r = LifespanReading.from(start: DateTime(2021, 3, 4), now: kNow);
      expect(r.ageLabel, '5½ yrs');
      expect(r.band, isNull);
      expect(r.lifeLabel, '');
      expect(r.replaceYear, isNull);
    });
    test('the unknown constant', () {
      expect(LifespanReading.unknown.band, isNull);
      expect(LifespanReading.unknown.ageLabel, '');
    });
  });

  group("the kit's examples (today is Oct 4, 2026)", () {
    test('Furnace: 5½ yrs of ~15, replace 2036, plenty', () {
      final r = LifespanReading.from(
        start: DateTime(2021, 3, 4),
        min: 12,
        max: 18,
        now: kNow,
      );
      expect(r.ageLabel, '5½ yrs');
      expect(r.lifeLabel, '~15 yrs');
      expect(r.replaceYear, 2036);
      expect(r.band, LifespanBand.plenty);
      expect(r.yearsLeft, closeTo(9.4, 0.1));
    });
    test('Central AC: 4 mo of ~15, replace 2041', () {
      final r = LifespanReading.from(
        start: DateTime(2026, 6, 14),
        lifeYears: 15,
        now: kNow,
      );
      expect(r.ageLabel, '4 mo');
      expect(r.replaceYear, 2041);
      expect(r.band, LifespanBand.plenty);
    });
    test('Water heater: 12 yrs of ~12 is at end of life', () {
      final r = LifespanReading.from(
        start: DateTime(2014, 10, 4),
        override: 12,
        now: kNow,
      );
      expect(r.ageLabel, '12 yrs');
      expect(r.lifeLabel, '~12 yrs');
      expect(r.band, LifespanBand.endOfLife);
      expect(r.statusLabel, 'AT END OF LIFE');
    });
    test('Electrical panel: 28½ yrs of ~40, replace 2038', () {
      final r = LifespanReading.from(
        start: DateTime(1998, 4, 4),
        lifeYears: 40,
        now: kNow,
      );
      expect(r.ageLabel, '28½ yrs');
      expect(r.replaceYear, 2038);
      expect(r.band, LifespanBand.plenty);
    });
    test('Dishwasher: 11½ yrs of ~10 is past its life', () {
      final r = LifespanReading.from(
        start: DateTime(2015, 4, 4),
        lifeYears: 10,
        now: kNow,
      );
      expect(r.ageLabel, '11½ yrs');
      expect(r.band, LifespanBand.past);
      expect(r.statusLabel, 'PAST EXPECTED LIFE');
    });
    test('Washer: bought Dec 2023, 3 yrs of ~11, replace 2034', () {
      final r = LifespanReading.from(
        start: DateTime(2023, 12, 9),
        lifeYears: 11,
        now: kNow,
      );
      expect(r.ageLabel, '3 yrs');
      expect(r.replaceYear, 2034);
    });
  });
}
