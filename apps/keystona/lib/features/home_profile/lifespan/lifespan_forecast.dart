import '../../../core/theme/aurora_home_a.dart';
import '../models/home_item.dart';

/// What is expected to be replaced in one calendar year.
class ForecastYear {
  const ForecastYear({
    required this.year,
    required this.amount,
    required this.names,
  });

  final int year;

  /// Sum of the known replacement costs due this year.
  final double amount;

  /// Names of everything due this year, soonest to latest.
  final List<String> names;
}

/// The next five years of replacements, from each item's replace year and
/// replacement cost. An item already past its life is due in the first year.
/// Items with no start date or life have no replace year and are left out;
/// items with no cost count as things but add nothing to the amounts.
class LifespanForecast {
  const LifespanForecast._({
    required this.years,
    required this.total,
    required this.dueItems,
  });

  /// One entry per forecast year, first year first.
  final List<ForecastYear> years;

  /// Sum of every known cost in the window.
  final double total;

  /// Items due in the window, soonest first.
  final List<HomeItem> dueItems;

  /// An empty forecast starting the year after [now].
  factory LifespanForecast.of(Iterable<HomeItem> items, DateTime now) {
    final first = now.year + 1;
    final due = <(int, HomeItem)>[];
    for (final item in items) {
      final replace = item.reading.replaceYear;
      if (replace == null) continue;
      final year = replace < first ? first : replace;
      if (year >= first + AuroraHomeASizes.forecastYears) continue;
      due.add((year, item));
    }
    due.sort((a, b) => a.$1.compareTo(b.$1));
    final years = <ForecastYear>[
      for (var i = 0; i < AuroraHomeASizes.forecastYears; i++)
        _year(first + i, due),
    ];
    return LifespanForecast._(
      years: years,
      total: years.fold(0.0, (sum, y) => sum + y.amount),
      dueItems: [for (final d in due) d.$2],
    );
  }

  static ForecastYear _year(int year, List<(int, HomeItem)> due) {
    final inYear = [for (final d in due) if (d.$1 == year) d.$2];
    return ForecastYear(
      year: year,
      amount: inYear.fold(0.0, (sum, i) => sum + (i.cost ?? 0)),
      names: [for (final i in inYear) i.name],
    );
  }

  int get firstYear => years.first.year;

  /// The largest yearly amount, for scaling bars. Never zero.
  double get peak {
    final max = years.fold(0.0, (m, y) => y.amount > m ? y.amount : m);
    return max > 0 ? max : 1;
  }

  /// Whole dollars to set aside each month to cover [total].
  int get perMonth => (total /
          (AuroraHomeASizes.forecastYears * AuroraHomeASizes.monthsPerYear))
      .round();

  /// The year an item falls in (past-due items land in the first year).
  int yearFor(HomeItem item) {
    final replace = item.reading.replaceYear ?? firstYear;
    return replace < firstYear ? firstYear : replace;
  }
}
