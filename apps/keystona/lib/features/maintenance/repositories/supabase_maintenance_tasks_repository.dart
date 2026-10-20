import '../../../services/supabase_service.dart';
import '../models/maintenance_task.dart';
import '../models/quick_completion.dart';
import '../models/task_progress.dart';
import '../models/task_schedule.dart';
import 'maintenance_tasks_repository.dart';
import 'task_columns.dart';
import 'task_rows.dart';

/// [MaintenanceTasksRepository] backed by Supabase. RLS is the auth layer;
/// every query starts from the user's property.
class SupabaseMaintenanceTasksRepository implements MaintenanceTasksRepository {
  const SupabaseMaintenanceTasksRepository();

  /// Length of the "done this week" window, today included.
  static const int _weekDays = 7;

  Future<String?> _propertyId() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return null;
    final row = await SupabaseService.client
        .from('properties')
        .select('id')
        .eq('user_id', user.id)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row?['id'] as String?;
  }

  @override
  Future<List<MaintenanceTask>> fetchTasks() async {
    final propertyId = await _propertyId();
    if (propertyId == null) return [];
    final rows = await SupabaseService.client
        .from('maintenance_tasks')
        .select('${TaskColumns.task}, systems(id, name)')
        .eq('property_id', propertyId)
        .isFilter('deleted_at', null)
        .order('due_date', ascending: true);
    return rows.map(_rowToTask).toList();
  }

  MaintenanceTask _rowToTask(Map<String, dynamic> row) {
    final system = row['systems'] as Map<String, dynamic>?;
    final cleaned = Map<String, dynamic>.from(row)..remove('systems');
    return MaintenanceTask.fromJson(
      cleaned,
    ).copyWith(linkedSystemName: system?['name'] as String?);
  }

  @override
  Future<TaskProgress> fetchProgress(DateTime today) async {
    final propertyId = await _propertyId();
    if (propertyId == null) return TaskProgress.none;
    final monthStart = DateTime(today.year, today.month);
    final weekStart = DateTime(
      today.year,
      today.month,
      today.day - _weekDays + 1,
    );
    final earliest = monthStart.isBefore(weekStart) ? monthStart : weekStart;
    final rows = await SupabaseService.client
        .from('task_completions')
        .select('completed_date')
        .eq('property_id', propertyId)
        .gte('completed_date', TaskSchedule.dateColumn(earliest));
    var month = 0;
    var week = 0;
    for (final row in rows) {
      final date = DateTime.tryParse(row['completed_date'] as String? ?? '');
      if (date == null) continue;
      if (!date.isBefore(monthStart)) month++;
      if (!date.isBefore(weekStart)) week++;
    }
    return TaskProgress(doneThisMonth: month, doneThisWeek: week);
  }

  @override
  Future<String> insertCompletion(
    MaintenanceTask task,
    QuickCompletion completion,
  ) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');
    final row = await SupabaseService.client
        .from('task_completions')
        .insert(
          TaskRows.quickCompletion(
            task: task,
            completion: completion,
            userId: user.id,
          ),
        )
        .select('id')
        .single();
    return row['id'] as String;
  }

  @override
  Future<void> deleteCompletion(String completionId) async {
    await SupabaseService.client
        .from('task_completions')
        .delete()
        .eq('id', completionId);
  }

  @override
  Future<String> insertSkip(
    MaintenanceTask task, {
    required DateTime dueDate,
    required DateTime skippedOn,
    String? reason,
  }) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');
    final row = await SupabaseService.client
        .from('task_skips')
        .insert(
          TaskRows.skip(
            task: task,
            userId: user.id,
            dueDate: dueDate,
            skippedOn: skippedOn,
            reason: reason,
          ),
        )
        .select('id')
        .single();
    return row['id'] as String;
  }

  @override
  Future<void> deleteSkip(String skipId) async {
    await SupabaseService.client.from('task_skips').delete().eq('id', skipId);
  }

  @override
  Future<void> updateTask(String taskId, Map<String, dynamic> fields) async {
    await SupabaseService.client
        .from('maintenance_tasks')
        .update(fields)
        .eq('id', taskId);
  }

  @override
  Future<void> insertTask(Map<String, dynamic> fields) async {
    await SupabaseService.client.from('maintenance_tasks').insert(fields);
  }
}
