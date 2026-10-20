import '../../../core/theme/aurora_home_b.dart';
import '../lifespan/lifespan_reading.dart';
import 'system.dart';
import 'system_reading.dart';

/// How the Systems list is ordered.
enum SystemSort {
  /// The most used-up first (percent of life used, highest first).
  oldestFirst,

  /// By name.
  az,
}

/// One row of the list: the system with what the row shows besides it.
class SystemListItem {
  const SystemListItem({
    required this.system,
    required this.reading,
    this.warrantyEndsOn,
  });

  final HomeSystem system;
  final LifespanReading reading;

  /// A warranty ending soon, for the row's footnote.
  final DateTime? warrantyEndsOn;
}

/// Pure list logic for the Systems screen: filter, sort and count.
abstract final class SystemsListView {
  /// Items for [systems], filtered to [group] (all when null) and ordered by
  /// [sort]. [now] is injectable for tests.
  static List<SystemListItem> items(
    List<HomeSystem> systems, {
    SystemGroup? group,
    SystemSort sort = SystemSort.oldestFirst,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final items = [
      for (final s in systems)
        if (group == null || s.category.group == group)
          SystemListItem(
            system: s,
            reading: s.reading(now: today),
            warrantyEndsOn: _warrantyNote(s, today),
          ),
    ];
    items.sort(switch (sort) {
      SystemSort.oldestFirst => _byPercent,
      SystemSort.az => _byName,
    });
    return items;
  }

  static int _byPercent(SystemListItem a, SystemListItem b) {
    final pa = a.reading.percent;
    final pb = b.reading.percent;
    if (pa == null && pb == null) return _byName(a, b);
    if (pa == null) return 1;
    if (pb == null) return -1;
    final c = pb.compareTo(pa);
    return c != 0 ? c : _byName(a, b);
  }

  static int _byName(SystemListItem a, SystemListItem b) => a.system.name
      .toLowerCase()
      .compareTo(b.system.name.toLowerCase());

  /// The warranty end date when it falls inside the note window.
  static DateTime? _warrantyNote(HomeSystem s, DateTime today) {
    final ends = s.warrantyEndsOn;
    if (ends == null) return null;
    final days = ends.difference(DateTime(today.year, today.month, today.day));
    return days.inDays >= 0 &&
            days.inDays <= AuroraHomeBSizes.warrantyNoteWindowDays
        ? ends
        : null;
  }

  /// How many systems are aging, at the end of their life or past it.
  static int agingCount(List<HomeSystem> systems, {DateTime? now}) => systems
      .where((s) => s.reading(now: now).isAgingOrWorse)
      .length;

  /// The filter groups that have at least one system, in chip order.
  static List<SystemGroup> groupsPresent(List<HomeSystem> systems) => [
    for (final g in SystemGroup.values)
      if (systems.any((s) => s.category.group == g)) g,
  ];
}
