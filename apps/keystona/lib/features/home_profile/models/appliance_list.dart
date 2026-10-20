import '../lifespan/appliance_lifespan.dart';
import '../lifespan/lifespan_reading.dart';
import 'appliance.dart';

/// How the Appliances list is ordered.
enum ApplianceSort {
  /// Most of its life used first.
  oldestFirst('Oldest first'),
  alphabetical('A–Z');

  const ApplianceSort(this.label);
  final String label;
}

/// Pure shaping of the Appliances list: filter chips, sort and the eyebrow.
abstract final class ApplianceList {
  /// The categories that have an appliance, in the database's order.
  static List<ApplianceCategory> categories(Iterable<Appliance> all) {
    final present = {for (final a in all) a.category};
    return [
      for (final c in ApplianceCategory.values)
        if (present.contains(c)) c,
    ];
  }

  /// [all] narrowed to [category] (all when null) and ordered by [sort].
  ///
  /// Oldest first puts the most life used on top; an appliance with no
  /// purchase date has no percent and goes last. Ties fall back to the name.
  static List<Appliance> shown(
    Iterable<Appliance> all, {
    ApplianceCategory? category,
    ApplianceSort sort = ApplianceSort.oldestFirst,
    DateTime? now,
  }) {
    final list = [
      for (final a in all)
        if (category == null || a.category == category) a,
    ];
    int byName(Appliance a, Appliance b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase());
    if (sort == ApplianceSort.alphabetical) return list..sort(byName);
    final percent = {
      for (final a in list) a.id: a.lifespanReading(now: now).percent,
    };
    return list..sort((a, b) {
      final pa = percent[a.id];
      final pb = percent[b.id];
      if (pa == null && pb == null) return byName(a, b);
      if (pa == null) return 1;
      if (pb == null) return -1;
      final byPercent = pb.compareTo(pa);
      return byPercent != 0 ? byPercent : byName(a, b);
    });
  }

  /// "1428 ELM HOLLOW · 5 TRACKED · 1 PAST ITS LIFE". The last part is the
  /// number past their life, else the number aging, and is left out when
  /// there are none.
  static String eyebrow(
    String? address,
    Iterable<Appliance> all, {
    DateTime? now,
  }) {
    var tracked = 0;
    var past = 0;
    var aging = 0;
    for (final a in all) {
      tracked++;
      final band = a.lifespanReading(now: now).band;
      if (band == LifespanBand.past) {
        past++;
      } else if (band == LifespanBand.aging || band == LifespanBand.endOfLife) {
        aging++;
      }
    }
    final home = address?.trim();
    return [
      if (home != null && home.isNotEmpty) home,
      '$tracked TRACKED',
      if (past > 0)
        '$past PAST ITS LIFE'
      else if (aging > 0)
        '$aging AGING',
    ].join(' · ').toUpperCase();
  }
}
