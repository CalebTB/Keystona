import 'maintenance_task.dart';

/// One reminder on the reminder screens: a maintenance task seen as
/// something that can be on or off.
class ReminderItem {
  const ReminderItem({
    required this.id,
    required this.name,
    required this.category,
    required this.recurrence,
    required this.origin,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
    this.offAt,
    this.offReason,
    this.tags = const [],
    this.intervalYears,
    this.systemId,
    this.applianceId,
    this.itemName,
  });

  final String id;
  final String name;
  final String category;
  final RecurrenceType recurrence;
  final TaskOrigin origin;

  /// `notifications_enabled`: off reminders are hidden everywhere and left
  /// out of the Home score.
  final bool enabled;
  final DateTime createdAt;

  /// When it last changed.
  final DateTime updatedAt;

  /// When it was turned off (`notifications_off_at`); null while it is on and
  /// for reminders turned off before that was recorded.
  final DateTime? offAt;

  /// Why it was turned off, when the person said.
  final String? offReason;

  /// Why the reminder exists for this home: FREEZE, HUMID, STORMS...
  final List<String> tags;

  /// "Every N years" of an annual reminder; null means every year.
  final int? intervalYears;

  /// When it was turned off: the recorded time, else the last change.
  DateTime get offSince => offAt ?? updatedAt;

  final String? systemId;
  final String? applianceId;

  /// Name of the system or appliance it belongs to.
  final String? itemName;

  /// Created by the person (Edit and Delete, no switch).
  bool get isMine =>
      origin == TaskOrigin.custom || origin == TaskOrigin.oneTime;

  bool get isAroundTheHouse => systemId == null && applianceId == null;

  bool get belongsToAppliance => applianceId != null;

  /// Sentinel so [copyWith] can set a nullable field to null.
  static const Object _keep = Object();

  /// A copy with [enabled] or [recurrence] changed. [offAt] and [offReason]
  /// are replaced only when given, so a reminder just turned on still holds
  /// when and why it was off, which is what lets Undo put it back exactly.
  ReminderItem copyWith({
    bool? enabled,
    RecurrenceType? recurrence,
    bool clearInterval = false,
    Object? offAt = _keep,
    Object? offReason = _keep,
  }) => ReminderItem(
    id: id,
    name: name,
    category: category,
    recurrence: recurrence ?? this.recurrence,
    origin: origin,
    enabled: enabled ?? this.enabled,
    createdAt: createdAt,
    updatedAt: updatedAt,
    offAt: identical(offAt, _keep) ? this.offAt : offAt as DateTime?,
    offReason: identical(offReason, _keep)
        ? this.offReason
        : offReason as String?,
    tags: tags,
    intervalYears: clearInterval ? null : intervalYears,
    systemId: systemId,
    applianceId: applianceId,
    itemName: itemName,
  );
}

/// Every reminder for the property plus what the headers need.
class RemindersData {
  const RemindersData({
    this.items = const [],
    this.addressLine,
    this.climateZone,
  });

  final List<ReminderItem> items;

  /// First line of the home's address, for the eyebrow.
  final String? addressLine;

  /// IECC zone 1-8.
  final int? climateZone;

  RemindersData mapItem(
    String id,
    ReminderItem Function(ReminderItem item) change,
  ) => RemindersData(
    items: [for (final i in items) i.id == id ? change(i) : i],
    addressLine: addressLine,
    climateZone: climateZone,
  );

  RemindersData withoutItem(String id) => RemindersData(
    items: [
      for (final i in items)
        if (i.id != id) i,
    ],
    addressLine: addressLine,
    climateZone: climateZone,
  );
}
