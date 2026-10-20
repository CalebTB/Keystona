import 'home_profile_format.dart';
import 'lifespan/lifespan_forecast.dart';
import 'lifespan/lifespan_reading.dart';
import 'lifespan/timeline_axis.dart';
import 'models/home_item.dart';

/// Copy for HomeLifespan. Kit text is verbatim; lines marked "invented" had
/// none (listed in the build report).
abstract final class HomeLifespanCopy {
  static const String back = 'Home profile';
  static const String title = 'How long things last';
  static const String totalSub = 'due in the next 5 years';
  static const String footnote =
      'Ages come from install dates and scanned labels. Expected lives are '
      'typical for your climate, not a promise.';
  static const String tabSystems = 'Systems';
  static const String tabAppliances = 'Appliances';
  static const String setAside = 'WHAT TO SET ASIDE';
  static const String premium = 'PREMIUM';
  static const String nothingExpected = 'NOTHING EXPECTED';
  static const String legendPlenty = 'PLENTY LEFT';
  static const String legendLast = 'LAST QUARTER';
  static const String legendPast = 'PAST EXPECTED LIFE';
  static const String today = 'TODAY';

  /// Invented.
  static const String loadError = "We couldn't load your lifespans.";
  static const String emptyTitle = 'Nothing tracked yet';
  static const String emptyBody =
      'Add a system or an appliance to see how long it should last.';
  static const String emptyAction = 'Scan a label to add one';
  static const String tabEmpty = 'Nothing here yet.';
  static const String noDate = 'ADD A DATE TO SEE ITS AGE';
  static const String noLife = 'EXPECTED LIFE UNKNOWN';

  static String eyebrow(int count) =>
      '$count ${count == 1 ? 'THING' : 'THINGS'} · SYSTEMS AND APPLIANCES';

  static String tabAll(int count) => 'All $count';

  /// "REPLACE ~2038", or the past-life line.
  static String endText(LifespanReading r, int firstYear) {
    final replace = r.replaceYear;
    if (replace == null) return r.lifeYears == null ? noLife : noDate;
    if ((r.percent ?? 0) > LifespanReading.pastAfter) {
      return 'PAST ITS LIFE · REPLACE ANY TIME';
    }
    final year = (r.percent ?? 0) >= LifespanReading.endOfLifeFrom &&
            replace < firstYear
        ? firstYear
        : replace;
    return 'REPLACE ~$year';
  }

  /// "INSTALLED 2021 · 5½ YRS OF ~15" ("SINCE 1998" before the window).
  static String meta(HomeItem item, TimelineAxis axis) {
    final r = item.reading;
    final start = r.startYear;
    if (start == null) return r.lifeLabel.isEmpty ? '' : 'OF ${r.lifeLabel}';
    final head = start < axis.startYear ? 'SINCE $start' : 'INSTALLED $start';
    final age = r.ageLabel.toUpperCase();
    final life = r.lifeLabel;
    return [head, if (life.isEmpty) age else '$age OF $life'].join(' · ');
  }

  /// "~$1,800", empty with no cost.
  static String cost(HomeItem item) =>
      item.cost == null ? '' : '~${HomeFormat.money(item.cost!)}';

  /// "WATER HEATER, DISHWASHER" or "NOTHING EXPECTED".
  static String whatNames(ForecastYear y) =>
      y.names.isEmpty ? nothingExpected : y.names.join(', ').toUpperCase();

  static String amount(ForecastYear y) =>
      y.amount > 0 ? HomeFormat.money(y.amount) : '—';

  /// "ABOUT $73 A MONTH COVERS ALL OF IT · LOWEST-COST ESTIMATES".
  static String monthly(LifespanForecast f) =>
      'ABOUT ${HomeFormat.money(f.perMonth)} A MONTH COVERS ALL OF IT · '
      'LOWEST-COST ESTIMATES';
}
