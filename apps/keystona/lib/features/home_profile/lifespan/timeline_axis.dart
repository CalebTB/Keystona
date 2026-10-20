import '../../../core/theme/aurora_home_a.dart';
import '../models/home_item.dart';

/// Where a year sits across the timeline: a fixed window around today.
class TimelineAxis {
  TimelineAxis(DateTime now)
    : startYear = now.year - AuroraHomeASizes.axisYearsBefore,
      endYear = now.year + AuroraHomeASizes.axisYearsAfter,
      nowYear = now.year + _fractionOfYear(now);

  /// First and last calendar year of the window.
  final int startYear;
  final int endYear;

  /// Today as a fractional year (2026.78).
  final double nowYear;

  static const int _daysPerYear = 365;

  static double _fractionOfYear(DateTime date) =>
      date.difference(DateTime(date.year)).inDays / _daysPerYear;

  /// A year as 0 to 1 across the window, clamped.
  double x(double year) =>
      ((year - startYear) / (endYear - startYear)).clamp(0.0, 1.0);

  double get nowX => x(nowYear);

  /// Decade years inside the window, clear of today so the TODAY tag fits.
  List<int> get ticks => [
    for (var y = startYear; y <= endYear; y++)
      if (y % _decade == 0 &&
          (nowYear - y).abs() > AuroraHomeASizes.tickClearYears)
        y,
  ];

  static const int _decade = 10;
}

/// The bar of one item on the timeline, as 0 to 1 positions across the axis.
class TimelineBar {
  const TimelineBar({
    required this.startX,
    required this.endX,
    required this.nowX,
    required this.pastLife,
  });

  /// Where the item began (clamped to the window) and where its life ends.
  final double startX;
  final double endX;
  final double nowX;

  /// Today is beyond the end: the over-run is hatched.
  final bool pastLife;

  /// How far the fill reaches: today, or the end of life if that comes first.
  double get usedEndX => nowX < endX ? nowX : endX;

  @override
  bool operator ==(Object other) =>
      other is TimelineBar &&
      other.startX == startX &&
      other.endX == endX &&
      other.nowX == nowX &&
      other.pastLife == pastLife;

  @override
  int get hashCode => Object.hash(startX, endX, nowX, pastLife);

  /// Null when the item has no start date or no life.
  static TimelineBar? forItem(HomeItem item, TimelineAxis axis) {
    final age = item.reading.ageYears;
    final life = item.reading.lifeYears;
    if (age == null || life == null) return null;
    final start = axis.nowYear - age;
    return TimelineBar(
      startX: axis.x(start),
      endX: axis.x(start + life),
      nowX: axis.nowX,
      pastLife: age > life,
    );
  }
}
