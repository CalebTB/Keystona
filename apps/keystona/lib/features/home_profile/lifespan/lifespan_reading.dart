/// How far through its expected life an item is. Percent of life used decides
/// the band, everywhere in Home profile (lists, detail, HomeLifespan).
enum LifespanBand {
  /// Under 75 percent used.
  plenty,

  /// 75 up to (not including) 90 percent: "AGING".
  aging,

  /// 90 to 100 percent: "AT END OF LIFE".
  endOfLife,

  /// Over 100 percent: "PAST EXPECTED LIFE".
  past,
}

/// A pure reading of an item's age against its single expected life.
///
/// Systems age from `installation_date`, appliances from `purchase_date`.
/// With no start date there is no age; with no life there is no band.
class LifespanReading {
  const LifespanReading._({
    required this.ageYears,
    required this.lifeYears,
    required this.startYear,
  });

  /// Unknown reading: no start date and no life.
  static const LifespanReading unknown = LifespanReading._(
    ageYears: null,
    lifeYears: null,
    startYear: null,
  );

  /// Reads [start] against the expected life.
  ///
  /// The single life is `override ?? lifeYears ?? midpoint(min, max) ?? min ??
  /// max`. The midpoint is rounded to a whole year (half rounds up). [now]
  /// defaults to the current time.
  factory LifespanReading.from({
    DateTime? start,
    int? lifeYears,
    int? min,
    int? max,
    int? override,
    DateTime? now,
  }) {
    final life = expectedLife(
      lifeYears: lifeYears,
      min: min,
      max: max,
      override: override,
    );
    if (start == null) {
      return LifespanReading._(
        ageYears: null,
        lifeYears: life,
        startYear: null,
      );
    }
    return LifespanReading._(
      ageYears: _ageYears(start, now ?? DateTime.now()),
      lifeYears: life,
      startYear: start.year,
    );
  }

  /// A reading from a known age (no dates). Used when the age is already
  /// computed, and by tests to hit exact percentages.
  factory LifespanReading.ofAge({
    required double ageYears,
    int? lifeYears,
    int? startYear,
  }) => LifespanReading._(
    ageYears: ageYears < 0 ? 0 : ageYears,
    lifeYears: lifeYears != null && lifeYears > 0 ? lifeYears : null,
    startYear: startYear,
  );

  /// The single expected life, or null when none is known (or it is not
  /// positive).
  static int? expectedLife({
    int? lifeYears,
    int? min,
    int? max,
    int? override,
  }) {
    final life =
        override ??
        lifeYears ??
        (min != null && max != null ? ((min + max) / 2).round() : null) ??
        min ??
        max;
    return life != null && life > 0 ? life : null;
  }

  /// Whole calendar months between the dates plus a day fraction, in years.
  /// Anniversaries are exact. Never negative.
  static double _ageYears(DateTime start, DateTime now) {
    final months =
        (now.year - start.year) * _monthsPerYear +
        (now.month - start.month) +
        (now.day - start.day) / _daysPerMonth;
    return months < 0 ? 0 : months / _monthsPerYear;
  }

  static const int _monthsPerYear = 12;
  static const double _daysPerMonth = 30.4375;

  /// Percent where "aging" starts, "end of life" starts, and "past" starts.
  static const double agingFrom = 75;
  static const double endOfLifeFrom = 90;
  static const double pastAfter = 100;

  /// Age in years, null when there is no start date.
  final double? ageYears;

  /// The single expected life in whole years, null when unknown.
  final int? lifeYears;

  /// Year the item started (install or purchase), null when unknown.
  final int? startYear;

  /// Percent of life used, null when age or life is unknown. Can exceed 100.
  double? get percent {
    final age = ageYears;
    final life = lifeYears;
    if (age == null || life == null) return null;
    return age * 100 / life;
  }

  /// Band, null when [percent] is unknown.
  LifespanBand? get band {
    final p = percent;
    if (p == null) return null;
    if (p < agingFrom) return LifespanBand.plenty;
    if (p < endOfLifeFrom) return LifespanBand.aging;
    if (p <= pastAfter) return LifespanBand.endOfLife;
    return LifespanBand.past;
  }

  /// Bar fill, 0 to 1. Zero when unknown.
  double get fraction {
    final p = percent;
    if (p == null) return 0;
    return (p / 100).clamp(0.0, 1.0);
  }

  /// Aging, at end of life or past it.
  bool get isAgingOrWorse {
    final b = band;
    return b != null && b != LifespanBand.plenty;
  }

  /// "N mo" under a year, otherwise the nearest half year: "1 yr",
  /// "5½ yrs". Empty when there is no start date.
  String get ageLabel {
    final age = ageYears;
    if (age == null) return '';
    final months = (age * _monthsPerYear).round();
    if (months < _monthsPerYear) return '$months mo';
    final halves = (age * 2).round();
    final whole = halves ~/ 2;
    final half = halves.isOdd ? '½' : '';
    return '$whole$half ${halves == 2 ? 'yr' : 'yrs'}';
  }

  /// "~12 yrs" ("~1 yr"). Empty when the life is unknown.
  String get lifeLabel {
    final life = lifeYears;
    if (life == null) return '';
    return '~$life ${life == 1 ? 'yr' : 'yrs'}';
  }

  /// "AGING", "AT END OF LIFE" or "PAST EXPECTED LIFE". Null when plenty of
  /// life is left or the reading is unknown.
  String? get statusLabel => switch (band) {
    LifespanBand.aging => 'AGING',
    LifespanBand.endOfLife => 'AT END OF LIFE',
    LifespanBand.past => 'PAST EXPECTED LIFE',
    _ => null,
  };

  /// Start year plus life. Null when either is unknown.
  int? get replaceYear {
    final start = startYear;
    final life = lifeYears;
    if (start == null || life == null) return null;
    return start + life;
  }

  /// Years of life left, null when unknown. Negative once past.
  double? get yearsLeft {
    final age = ageYears;
    final life = lifeYears;
    if (age == null || life == null) return null;
    return life - age;
  }
}
