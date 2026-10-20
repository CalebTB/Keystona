import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/maintenance_task.dart';
import '../models/suggested_task.dart';
import '../models/task_form_options.dart';

/// Data access for the generated reminders the person keeps.
abstract interface class GeneratedTasksRepository {
  /// Adds [tasks] for a system or appliance in one round trip.
  Future<void> addAll({
    required List<SuggestedTask> tasks,
    required String propertyId,
    String? linkedSystemId,
    String? linkedApplianceId,
  });
}

class SupabaseGeneratedTasksRepository implements GeneratedTasksRepository {
  SupabaseGeneratedTasksRepository(this._client);

  final SupabaseClient _client;

  /// Difficulty assumed for a generated task.
  static const TaskDifficulty _difficulty = TaskDifficulty.easy;

  /// The date a new generated task first comes due: one period from [now].
  static String firstDue(RecurrenceType recurrence, DateTime now) {
    final due = switch (recurrence) {
      RecurrenceType.quarterly => DateTime(now.year, now.month + 3, now.day),
      RecurrenceType.biannual => DateTime(now.year, now.month + 6, now.day),
      RecurrenceType.annual => DateTime(now.year + 1, now.month, now.day),
      _ => DateTime(now.year, now.month + 1, now.day),
    };
    return DateFormat('yyyy-MM-dd').format(due);
  }

  @override
  Future<void> addAll({
    required List<SuggestedTask> tasks,
    required String propertyId,
    String? linkedSystemId,
    String? linkedApplianceId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null || tasks.isEmpty) return;
    final now = DateTime.now();

    // Batch insert through the client, not a notifier: the Tasks provider may
    // be disposed when this runs.
    final rows = [
      for (final t in tasks)
        {
          'property_id': propertyId,
          'user_id': user.id,
          'task_origin': TaskOrigin.systemGenerated.value,
          'name': t.name,
          'description': t.description,
          'category': t.category,
          'due_date': firstDue(t.recurrenceType, now),
          'recurrence': t.recurrenceType.value,
          'status': TaskStatus.scheduled.value,
          'priority': t.priority,
          'difficulty': _difficulty.value,
          'diy_or_pro': t.diyOrPro,
          'estimated_minutes': t.estimatedMinutes,
          'linked_system_id': ?linkedSystemId,
          'linked_appliance_id': ?linkedApplianceId,
          'reminder_days_before': RemindOptions.defaultDays,
          'notifications_enabled': true,
        },
    ];
    await _client.from('maintenance_tasks').insert(rows);
  }
}
