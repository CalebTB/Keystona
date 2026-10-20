import 'package:supabase_flutter/supabase_flutter.dart';

import '../../documents/repositories/current_property.dart';
import '../../home_profile/models/appliance.dart';
import '../../home_profile/models/system.dart';
import '../models/maintenance_task.dart';
import '../models/task_draft.dart';
import '../models/task_link_option.dart';
import 'task_columns.dart';

/// What the Add a task form needs before it can save.
class TaskFormContext {
  const TaskFormContext({this.propertyId, this.options = const []});

  /// The home the task is added to; null until the person has one.
  final String? propertyId;

  /// Systems and appliances a task can belong to.
  final List<TaskLinkOption> options;
}

/// Data access for the Add a task form (create, edit).
abstract interface class TaskFormRepository {
  Future<TaskFormContext> loadContext();

  /// The saved task for edit mode, or null when it no longer exists.
  Future<MaintenanceTask?> loadTask(String taskId);

  Future<void> create(
    TaskDraft draft, {
    required String propertyId,
    required DateTime today,
  });

  Future<void> update(
    String taskId,
    TaskDraft draft, {
    required String category,
    required DateTime today,
  });
}

class SupabaseTaskFormRepository implements TaskFormRepository {
  SupabaseTaskFormRepository(this._client);

  final SupabaseClient _client;

  /// `maintenance_tasks.category` for a task on an appliance.
  static const String applianceCategory = 'appliance';

  @override
  Future<TaskFormContext> loadContext() async {
    final propertyId = await currentPropertyId(_client);
    if (propertyId == null) return const TaskFormContext();

    final results = await Future.wait([
      _client
          .from('systems')
          .select('id, name, category, location')
          .eq('property_id', propertyId)
          .isFilter('deleted_at', null)
          .order('name', ascending: true),
      _client
          .from('appliances')
          .select('id, name, category, location')
          .eq('property_id', propertyId)
          .isFilter('deleted_at', null)
          .order('name', ascending: true),
      _client
          .from('maintenance_tasks')
          .select('linked_system_id, linked_appliance_id')
          .eq('property_id', propertyId)
          .isFilter('deleted_at', null),
    ]);

    final counts = <String, int>{};
    for (final row in results[2]) {
      final id =
          (row['linked_system_id'] ?? row['linked_appliance_id']) as String?;
      if (id != null) counts[id] = (counts[id] ?? 0) + 1;
    }

    return TaskFormContext(
      propertyId: propertyId,
      options: [
        for (final r in results[0])
          TaskLinkOption(
            id: r['id'] as String,
            kind: TaskLinkKind.system,
            name: r['name'] as String,
            category: r['category'] as String,
            categoryLabel: SystemCategory.values
                .firstWhere(
                  (c) => c.value == r['category'],
                  orElse: () => SystemCategory.other,
                )
                .label,
            location: r['location'] as String?,
            taskCount: counts[r['id']] ?? 0,
          ),
        for (final r in results[1])
          TaskLinkOption(
            id: r['id'] as String,
            kind: TaskLinkKind.appliance,
            name: r['name'] as String,
            category: applianceCategory,
            categoryLabel: ApplianceCategory.values
                .firstWhere(
                  (c) => c.value == r['category'],
                  orElse: () => ApplianceCategory.other,
                )
                .label,
            location: r['location'] as String?,
            taskCount: counts[r['id']] ?? 0,
          ),
      ],
    );
  }

  @override
  Future<MaintenanceTask?> loadTask(String taskId) async {
    final row = await _client
        .from('maintenance_tasks')
        .select('${TaskColumns.task}, systems(id, name)')
        .eq('id', taskId)
        .isFilter('deleted_at', null)
        .maybeSingle();
    if (row == null) return null;
    final system = row['systems'] as Map<String, dynamic>?;
    final cleaned = Map<String, dynamic>.from(row)..remove('systems');
    return MaintenanceTask.fromJson(
      cleaned,
    ).copyWith(linkedSystemName: system?['name'] as String?);
  }

  @override
  Future<void> create(
    TaskDraft draft, {
    required String propertyId,
    required DateTime today,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Signed out');
    await _client.from('maintenance_tasks').insert({
      ...draft.toFields(
        today: today,
        category: draft.link!.category,
        editing: false,
      ),
      'property_id': propertyId,
      'user_id': user.id,
      'task_origin': draft.origin.value,
      'tools_needed': <String>[],
    });
  }

  @override
  Future<void> update(
    String taskId,
    TaskDraft draft, {
    required String category,
    required DateTime today,
  }) async {
    await _client
        .from('maintenance_tasks')
        .update(draft.toFields(today: today, category: category, editing: true))
        .eq('id', taskId);
  }
}
