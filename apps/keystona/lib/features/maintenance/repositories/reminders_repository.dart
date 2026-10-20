import 'package:supabase_flutter/supabase_flutter.dart';

import '../../documents/repositories/current_property.dart';
import '../models/maintenance_task.dart';
import '../models/reminder_item.dart';
import '../services/reminder_switch.dart';
import 'task_rows.dart';

/// Data access for the reminder screens (turn on and off, how often, delete).
///
/// Whether a reminder is on is `maintenance_tasks.notifications_enabled`;
/// turning one off also records when and why (`notifications_off_at`,
/// `notifications_off_reason`).
abstract interface class RemindersRepository {
  Future<RemindersData> fetch();

  /// Turns a reminder on or off. Off stamps `notifications_off_at` (now, or
  /// [offAt] when putting back an earlier one) and keeps [reason]; on clears
  /// both.
  Future<void> setEnabled(
    String id, {
    required bool enabled,
    String? reason,
    DateTime? offAt,
  });

  /// Switches several reminders at once.
  Future<void> setManyEnabled(
    List<String> ids, {
    required bool enabled,
    String? reason,
  });

  /// Changes how often a reminder repeats. Any "every N years" interval is
  /// cleared: the choices are plain recurrences.
  Future<void> setRecurrence(String id, RecurrenceType recurrence);

  /// Removes one of the person's own reminders (`soft_delete_task`).
  Future<void> delete(String id);
}

class SupabaseRemindersRepository implements RemindersRepository {
  SupabaseRemindersRepository(this._client);

  final SupabaseClient _client;

  static const String _taskColumns =
      'id, name, category, recurrence, recurrence_interval_years, '
      'task_origin, notifications_enabled, notifications_off_at, '
      'notifications_off_reason, tags, linked_system_id, '
      'linked_appliance_id, created_at, updated_at';

  /// Finished tasks are history, not reminders.
  static const String _finished = '(completed,skipped)';

  @override
  Future<RemindersData> fetch() async {
    final propertyId = await currentPropertyId(_client);
    if (propertyId == null) return const RemindersData();

    final results = await Future.wait([
      _client
          .from('maintenance_tasks')
          .select(_taskColumns)
          .eq('property_id', propertyId)
          .isFilter('deleted_at', null)
          .not('status', 'in', _finished)
          .order('name', ascending: true),
      _client
          .from('systems')
          .select('id, name')
          .eq('property_id', propertyId)
          .isFilter('deleted_at', null),
      _client
          .from('appliances')
          .select('id, name')
          .eq('property_id', propertyId)
          .isFilter('deleted_at', null),
      _client
          .from('properties')
          .select('address_line1, climate_zone')
          .eq('id', propertyId)
          .maybeSingle(),
    ]);

    final names = <String, String>{
      for (final r in [...results[1] as List, ...results[2] as List])
        (r as Map<String, dynamic>)['id'] as String: r['name'] as String,
    };
    final property = results[3] as Map<String, dynamic>?;

    return RemindersData(
      items: [
        for (final row in results[0] as List)
          _toItem(row as Map<String, dynamic>, names),
      ],
      addressLine: property?['address_line1'] as String?,
      climateZone: (property?['climate_zone'] as num?)?.toInt(),
    );
  }

  ReminderItem _toItem(Map<String, dynamic> row, Map<String, String> names) {
    final systemId = row['linked_system_id'] as String?;
    final applianceId = row['linked_appliance_id'] as String?;
    return ReminderItem(
      id: row['id'] as String,
      name: row['name'] as String,
      category: row['category'] as String,
      recurrence: RecurrenceType.values.firstWhere(
        (r) => r.value == row['recurrence'],
        orElse: () => RecurrenceType.none,
      ),
      origin: TaskOrigin.values.firstWhere(
        (o) => o.value == row['task_origin'],
        orElse: () => TaskOrigin.custom,
      ),
      enabled: (row['notifications_enabled'] as bool?) ?? true,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      offAt: DateTime.tryParse(row['notifications_off_at'] as String? ?? ''),
      offReason: row['notifications_off_reason'] as String?,
      tags: [
        ...((row['tags'] as List<dynamic>?) ?? const []).whereType<String>(),
      ],
      intervalYears: (row['recurrence_interval_years'] as num?)?.toInt(),
      systemId: systemId,
      applianceId: applianceId,
      itemName: names[systemId ?? applianceId],
    );
  }

  @override
  Future<void> setEnabled(
    String id, {
    required bool enabled,
    String? reason,
    DateTime? offAt,
  }) => _client
      .from('maintenance_tasks')
      .update(
        ReminderSwitch.columns(enabled: enabled, reason: reason, now: offAt),
      )
      .eq('id', id);

  @override
  Future<void> setManyEnabled(
    List<String> ids, {
    required bool enabled,
    String? reason,
  }) {
    if (ids.isEmpty) return Future.value();
    return _client
        .from('maintenance_tasks')
        .update(ReminderSwitch.columns(enabled: enabled, reason: reason))
        .inFilter('id', ids);
  }

  @override
  Future<void> setRecurrence(String id, RecurrenceType recurrence) => _client
      .from('maintenance_tasks')
      .update({
        'recurrence': recurrence.value,
        'recurrence_interval_years': null,
      })
      .eq('id', id);

  @override
  Future<void> delete(String id) =>
      _client.rpc(TaskRpc.softDelete, params: TaskRpc.args(id));
}
