import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/maintenance_task.dart';
import '../models/task_completion.dart';
import '../models/task_detail.dart';
import 'maintenance_tasks_provider.dart';

part 'task_detail_provider.g.dart';

/// Manages the full detail state for a single maintenance task.
///
/// Keyed by [taskId] and auto-disposed when the detail screen is popped.
/// Fetches the task with nested system, appliance, completions, and template
/// data in a single Supabase query (no N+1).
///
/// Extension points for downstream issues:
/// - [completeTaskDetailed] — stub, implemented by issue #33
@riverpod
class TaskDetailNotifier extends _$TaskDetailNotifier {
  @override
  Future<TaskDetail> build(String taskId) => _fetchDetail(taskId);

  // ── Public interface ───────────────────────────────────────────────────────

  /// One-tap completion with today's date and auto-timestamps.
  ///
  /// Returns the created [TaskCompletion.id] so the caller can pass it to
  /// [undoQuickComplete] if the user taps "Undo" within the snackbar window.
  Future<String> quickCompleteTask() async {
    final detail = state.value;
    if (detail == null) throw StateError('Task not loaded');

    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');

    final today = DateTime.now().toIso8601String().split('T')[0];

    // Insert the completion record and capture its id for potential undo.
    final row = await SupabaseService.client
        .from('task_completions')
        .insert({
          'task_id': detail.task.id,
          'user_id': user.id,
          'property_id': detail.task.propertyId,
          'completed_date': today,
          'completed_by': 'diy',
        })
        .select('id')
        .single();

    final completionId = row['id'] as String;

    // Update task status to completed.
    await SupabaseService.client
        .from('maintenance_tasks')
        .update({'status': 'completed'})
        .eq('id', detail.task.id);

    // If recurring, ask the Edge Function to schedule the next occurrence.
    if (detail.task.recurrence != RecurrenceType.none) {
      await SupabaseService.client.functions.invoke(
        'schedule-next-task',
        body: {'task_id': detail.task.id},
      );
    }

    // Sync the list screen and re-fetch detail.
    ref.invalidate(maintenanceTasksProvider);
    ref.invalidateSelf();
    await future;

    return completionId;
  }

  /// Reverts a quick completion within the 5-second undo window.
  ///
  /// Deletes the [completionId] row and restores the task status based on
  /// whether the due date is past (overdue) or future (scheduled).
  Future<void> undoQuickComplete(String completionId) async {
    final detail = state.value;
    if (detail == null) return;

    await SupabaseService.client
        .from('task_completions')
        .delete()
        .eq('id', completionId);

    final now = DateTime.now().toLocal();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final restoredStatus =
        detail.task.dueDate.toLocal().isBefore(todayMidnight)
            ? 'overdue'
            : 'scheduled';

    await SupabaseService.client
        .from('maintenance_tasks')
        .update({'status': restoredStatus})
        .eq('id', detail.task.id);

    ref.invalidate(maintenanceTasksProvider);
    ref.invalidateSelf();
    await future;
  }

  /// Marks the task as skipped and records the user's [reason].
  Future<void> skipTask(String reason) async {
    final detail = state.value;
    if (detail == null) return;

    await SupabaseService.client
        .from('maintenance_tasks')
        .update({
          'status': 'skipped',
          if (reason.isNotEmpty) 'skip_reason': reason,
        })
        .eq('id', detail.task.id);

    // If recurring, schedule the next occurrence.
    if (detail.task.recurrence != RecurrenceType.none) {
      await SupabaseService.client.functions.invoke(
        'schedule-next-task',
        body: {'task_id': detail.task.id},
      );
    }

    ref.invalidate(maintenanceTasksProvider);
    ref.invalidateSelf();
    await future;
  }

  /// [#33] Opens the detailed completion form (photo, cost, contractor, notes).
  ///
  /// Agent building #33: implement this method. The [TaskCompletion] model is
  /// already defined — insert via `task_completions` with all form fields.
  Future<void> completeTaskDetailed(Map<String, dynamic> formData) async {
    throw UnimplementedError('completeTaskDetailed() implemented by issue #33');
  }

  // ── Private fetch ──────────────────────────────────────────────────────────

  Future<TaskDetail> _fetchDetail(String taskId) async {
    final row = await SupabaseService.client
        .from('maintenance_tasks')
        .select(
          '''
          id, property_id, user_id, template_id, task_origin, name,
          description, instructions, category, due_date, recurrence, season,
          climate_adjusted, status, difficulty, diy_or_pro, priority,
          estimated_minutes, tools_needed, supplies_needed,
          linked_system_id, linked_appliance_id, skip_reason,
          created_at, updated_at,
          system:systems(id, name),
          appliance:appliances(id, name),
          completions:task_completions(
            id, task_id, user_id, property_id, completed_date, completed_by,
            contractor_name, contractor_company, contractor_phone,
            service_cost, materials_cost, time_spent_minutes, notes,
            linked_document_ids, created_at
          ),
          template:maintenance_task_templates(instructions, tools_needed, supplies_needed)
          ''',
        )
        .eq('id', taskId)
        .single();

    return _parseDetail(row);
  }

  TaskDetail _parseDetail(Map<String, dynamic> row) {
    final systemRow = row['system'] as Map<String, dynamic>?;
    final applianceRow = row['appliance'] as Map<String, dynamic>?;
    final completionRows = (row['completions'] as List<dynamic>?) ?? [];
    final templateRow = row['template'] as Map<String, dynamic>?;

    // Strip nested objects so fromJson only sees flat columns.
    final cleaned = Map<String, dynamic>.from(row)
      ..remove('system')
      ..remove('appliance')
      ..remove('completions')
      ..remove('template');

    var task = MaintenanceTask.fromJson(cleaned).copyWith(
      linkedSystemName: systemRow?['name'] as String?,
      linkedApplianceName: applianceRow?['name'] as String?,
    );

    // Merge template values when the task itself has no data.
    if (templateRow != null) {
      if (task.instructions == null || task.instructions!.isEmpty) {
        task = task.copyWith(
          instructions: templateRow['instructions'] as String?,
        );
      }
      if (task.toolsNeeded.isEmpty && templateRow['tools_needed'] != null) {
        final tools = (templateRow['tools_needed'] as List<dynamic>)
            .whereType<String>()
            .toList();
        task = task.copyWith(toolsNeeded: tools);
      }
      if (task.suppliesNeeded.isEmpty &&
          templateRow['supplies_needed'] != null) {
        final supplies = (templateRow['supplies_needed'] as List<dynamic>)
            .whereType<String>()
            .toList();
        task = task.copyWith(suppliesNeeded: supplies);
      }
    }

    // Parse completions and sort chronologically descending.
    final completions = completionRows
        .map(
          (c) => TaskCompletion.fromJson(
            Map<String, dynamic>.from(c as Map),
          ),
        )
        .toList()
      ..sort((a, b) => b.completedDate.compareTo(a.completedDate));

    return TaskDetail(task: task, completions: completions);
  }
}
