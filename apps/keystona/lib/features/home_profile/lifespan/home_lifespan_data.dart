import '../models/home_item.dart';
import '../models/item_ref.dart';
import 'lifespan_forecast.dart';
import 'lifespan_reading.dart';

/// Systems and appliances ordered by how much of their life is used, with the
/// five-year forecast. Built once per load of the overview.
class HomeLifespanData {
  HomeLifespanData._(this.items, this.now)
    : forecast = LifespanForecast.of(items, now);

  /// Sorts [items] by percent of life used, highest first. Items with no
  /// reading go last, then by name.
  factory HomeLifespanData.from(Iterable<HomeItem> items, {DateTime? now}) {
    final sorted = [...items]
      ..sort((a, b) {
        final pa = a.reading.percent;
        final pb = b.reading.percent;
        if (pa != null && pb != null && pa != pb) return pb.compareTo(pa);
        if (pa == null && pb != null) return 1;
        if (pa != null && pb == null) return -1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return HomeLifespanData._(sorted, now ?? DateTime.now());
  }

  final List<HomeItem> items;
  final DateTime now;

  /// The forecast for every item.
  final LifespanForecast forecast;

  /// The item furthest through its life, when it is at the end of it or past.
  HomeItem? get worst {
    for (final item in items) {
      final band = item.reading.band;
      if (band == LifespanBand.endOfLife || band == LifespanBand.past) {
        return item;
      }
      if (band != null) return null;
    }
    return null;
  }

  /// Items of one kind, or all when [kind] is null.
  List<HomeItem> forKind(ItemKind? kind) => kind == null
      ? items
      : [for (final i in items) if (i.ref.kind == kind) i];

  /// The forecast for one kind (the HomeLifespan total follows the tab).
  LifespanForecast forecastFor(ItemKind? kind) =>
      kind == null ? forecast : LifespanForecast.of(forKind(kind), now);

  /// Systems that are aging, at the end of life or past it.
  int get agingSystems => items
      .where((i) => i.isSystem && i.reading.isAgingOrWorse)
      .length;
}
