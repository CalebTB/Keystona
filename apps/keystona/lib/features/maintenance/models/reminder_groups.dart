import 'maintenance_task.dart';
import 'reminder_item.dart';

/// The kinds of group on Around the house and Review your reminders.
enum ReminderGroupKind { item, safety, outside, yard, climate, other }

/// A titled set of reminders.
class ReminderGroup {
  const ReminderGroup({
    required this.kind,
    required this.title,
    required this.items,
    this.itemId,
    this.itemIsAppliance = false,
    this.itemName,
  });

  final ReminderGroupKind kind;
  final String title;
  final List<ReminderItem> items;

  /// For [ReminderGroupKind.item]: the system or appliance.
  final String? itemId;
  final bool itemIsAppliance;
  final String? itemName;

  int get onCount => items.where((i) => i.enabled).length;

  /// "3 OF 4 ON".
  String get countLabel => '$onCount OF ${items.length} ON';
}

/// Pure grouping of reminders for the three reminder screens.
abstract final class ReminderGroups {
  static const String climateTitle = 'From your climate';

  static ReminderGroupKind _kindOf(ReminderItem item) {
    if (item.origin == TaskOrigin.climateTriggered) {
      return ReminderGroupKind.climate;
    }
    final c = item.category.toLowerCase();
    if (c.contains('safety')) return ReminderGroupKind.safety;
    if (c.contains('yard') ||
        c.contains('landscap') ||
        c.contains('lawn') ||
        c.contains('irrigation')) {
      return ReminderGroupKind.yard;
    }
    if (c.contains('exterior') || c.contains('outside') || c.contains('roof')) {
      return ReminderGroupKind.outside;
    }
    return ReminderGroupKind.other;
  }

  static String _titleOf(ReminderGroupKind kind) => switch (kind) {
    ReminderGroupKind.safety => 'Safety',
    ReminderGroupKind.outside => 'Outside',
    ReminderGroupKind.yard => 'Yard',
    ReminderGroupKind.climate => climateTitle,
    ReminderGroupKind.other => 'Other',
    ReminderGroupKind.item => '',
  };

  static const List<ReminderGroupKind> _houseOrder = [
    ReminderGroupKind.safety,
    ReminderGroupKind.outside,
    ReminderGroupKind.yard,
    ReminderGroupKind.climate,
    ReminderGroupKind.other,
  ];

  /// Reminders for the house as a whole that the app suggested, by kind.
  static List<ReminderGroup> house(Iterable<ReminderItem> items) {
    final byKind = <ReminderGroupKind, List<ReminderItem>>{};
    for (final item in items) {
      if (item.isMine || !item.isAroundTheHouse) continue;
      byKind.putIfAbsent(_kindOf(item), () => []).add(item);
    }
    return [
      for (final kind in _houseOrder)
        if (byKind[kind] != null)
          ReminderGroup(
            kind: kind,
            title: _titleOf(kind),
            items: byKind[kind]!,
          ),
    ];
  }

  /// The person's own reminders for the house.
  static List<ReminderItem> mine(Iterable<ReminderItem> items) => [
    for (final i in items)
      if (i.isMine && i.isAroundTheHouse) i,
  ];

  static List<ReminderGroup> _byItem(Iterable<ReminderItem> items) {
    final groups = <String, List<ReminderItem>>{};
    final meta = <String, ReminderItem>{};
    for (final item in items) {
      final id = item.systemId ?? item.applianceId;
      if (id == null) continue;
      groups.putIfAbsent(id, () => []).add(item);
      meta.putIfAbsent(id, () => item);
    }
    final ids = groups.keys.toList()
      ..sort((a, b) {
        final ma = meta[a]!;
        final mb = meta[b]!;
        if (ma.belongsToAppliance != mb.belongsToAppliance) {
          return ma.belongsToAppliance ? 1 : -1;
        }
        return (ma.itemName ?? '').toLowerCase().compareTo(
          (mb.itemName ?? '').toLowerCase(),
        );
      });
    return [
      for (final id in ids)
        ReminderGroup(
          kind: ReminderGroupKind.item,
          title: meta[id]!.itemName ?? '',
          items: groups[id]!,
          itemId: id,
          itemIsAppliance: meta[id]!.belongsToAppliance,
          itemName: meta[id]!.itemName,
        ),
    ];
  }

  /// Review your reminders: the app's suggestions by system or appliance,
  /// then by kind for the house.
  static List<ReminderGroup> review(Iterable<ReminderItem> items) {
    final suggested = items.where((i) => !i.isMine).toList();
    return [..._byItem(suggested), ...house(suggested)];
  }

  /// Turned-off reminders: by system, then appliance, then the house.
  static List<ReminderGroup> turnedOff(Iterable<ReminderItem> off) {
    final houseItems = off.where((i) => i.isAroundTheHouse).toList();
    return [
      ..._byItem(off),
      if (houseItems.isNotEmpty)
        ReminderGroup(
          kind: ReminderGroupKind.other,
          title: aroundTheHouseTitle,
          items: houseItems,
        ),
    ];
  }

  static const String aroundTheHouseTitle = 'Around the house';
}
