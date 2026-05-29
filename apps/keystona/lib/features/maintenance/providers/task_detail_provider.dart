import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';
import '../models/maintenance_task.dart';
import '../models/task_completion.dart';
import '../models/task_detail.dart';
import 'home_health_score_provider.dart';
import 'maintenance_tasks_provider.dart';

part 'task_detail_provider.g.dart';

/// Manages the full detail state for a single maintenance task.
///
/// Keyed by [taskId] and auto-disposed when the detail screen is popped.
/// Fetches the task with nested system, appliance, completions, and template
/// data in a single Supabase query (no N+1).
@riverpod
class TaskDetailNotifier extends _$TaskDetailNotifier {
  @override
  Future<TaskDetail> build(String taskId) => _fetchDetail(taskId);

  // ── Public interface ───────────────────────────────────────────────────────

  /// One-tap completion. For recurring tasks the due_date is rolled forward
  /// on the same row (no new task created) — all history stays centralised.
  ///
  /// Returns the completion ID and the original due_date so the caller can
  /// wire an undo snackbar that fully reverts both writes.
  Future<({String completionId, DateTime? originalDueDate})>
      quickCompleteTask() async {
    final detail = state.value;
    if (detail == null) throw StateError('Task not loaded');

    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');

    final now = DateTime.now();
    final todayStr = _dateStr(now);
    final isRecurring = detail.task.recurrence != RecurrenceType.none;
    final nextDate = isRecurring ? _nextDate(detail.task, base: now) : null;

    // Optimistic update — prepend the new completion and update the task.
    // Recurring: roll due_date forward, status = scheduled (task stays active).
    // One-off: status = completed.
    state = AsyncData(TaskDetail(
      task: isRecurring && nextDate != null
          ? detail.task.copyWith(
              status: TaskStatus.scheduled,
              dueDate: nextDate,
            )
          : detail.task.copyWith(status: TaskStatus.completed),
      completions: [
        TaskCompletion(
          id: 'optimistic_${now.millisecondsSinceEpoch}',
          taskId: detail.task.id,
          userId: user.id,
          propertyId: detail.task.propertyId,
          completedDate: now,
          completedBy: 'diy',
          createdAt: now,
        ),
        ...detail.completions,
      ],
    ));

    // 1. Insert completion record.
    final row = await SupabaseService.client
        .from('task_completions')
        .insert({
          'task_id': detail.task.id,
          'user_id': user.id,
          'property_id': detail.task.propertyId,
          'completed_date': todayStr,
          'completed_by': 'diy',
        })
        .select('id')
        .single();

    final completionId = row['id'] as String;

    // 2. Update the task row.
    if (isRecurring && nextDate != null) {
      await SupabaseService.client.from('maintenance_tasks').update({
        'due_date': _dateStr(nextDate),
        'status': 'scheduled',
      }).eq('id', detail.task.id);
    } else {
      await SupabaseService.client
          .from('maintenance_tasks')
          .update({'status': 'completed'})
          .eq('id', detail.task.id);
    }

    ref.invalidate(maintenanceTasksProvider);
    ref.invalidate(homeHealthScoreProvider);
    state = await AsyncValue.guard(() => _fetchDetail(taskId));

    return (
      completionId: completionId,
      originalDueDate: isRecurring ? detail.task.dueDate : null,
    );
  }

  /// Reverts a quick completion. Deletes the completion record and restores
  /// the task's original due_date (recurring) or status (one-off).
  Future<void> undoQuickComplete(
    String completionId, {
    DateTime? originalDueDate,
  }) async {
    final detail = state.value;
    if (detail == null) return;

    await SupabaseService.client
        .from('task_completions')
        .delete()
        .eq('id', completionId);

    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);

    if (originalDueDate != null) {
      // Recurring: restore original due_date and derive status from it.
      final restoredStatus =
          originalDueDate.toLocal().isBefore(today) ? 'overdue' : 'scheduled';
      await SupabaseService.client.from('maintenance_tasks').update({
        'status': restoredStatus,
        'due_date': _dateStr(originalDueDate),
      }).eq('id', detail.task.id);
    } else {
      // One-off: restore status (only if no other completions remain).
      final remaining =
          detail.completions.where((c) => c.id != completionId);
      if (remaining.isEmpty) {
        final restoredStatus =
            detail.task.dueDate.toLocal().isBefore(today)
                ? 'overdue'
                : 'scheduled';
        await SupabaseService.client
            .from('maintenance_tasks')
            .update({'status': restoredStatus})
            .eq('id', detail.task.id);
      }
    }

    ref.invalidate(maintenanceTasksProvider);
    ref.invalidate(homeHealthScoreProvider);
    ref.invalidateSelf();
    await future;
  }

  /// Skips this occurrence. For recurring tasks, rolls the due_date forward
  /// from the original due date (preserves the established schedule).
  Future<void> skipTask(String reason) async {
    final detail = state.value;
    if (detail == null) return;
    final isRecurring = detail.task.recurrence != RecurrenceType.none;

    if (isRecurring) {
      final nextDate = _nextDate(detail.task);
      await SupabaseService.client.from('maintenance_tasks').update({
        'status': 'scheduled',
        'due_date': _dateStr(nextDate),
        if (reason.isNotEmpty) 'skip_reason': reason,
      }).eq('id', detail.task.id);
    } else {
      await SupabaseService.client.from('maintenance_tasks').update({
        'status': 'skipped',
        if (reason.isNotEmpty) 'skip_reason': reason,
      }).eq('id', detail.task.id);
    }

    ref.invalidate(maintenanceTasksProvider);
    ref.invalidate(homeHealthScoreProvider);
    ref.invalidateSelf();
    await future;
  }

  /// Detailed completion with optional photos and receipt links.
  Future<String> completeTaskDetailed(
    Map<String, dynamic> formData,
    List<XFile> photos,
  ) async {
    final detail = state.value;
    if (detail == null) throw StateError('Task not loaded');

    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');

    // 1. Insert completion row.
    final row = await SupabaseService.client
        .from('task_completions')
        .insert({
          'task_id': detail.task.id,
          'user_id': user.id,
          'property_id': detail.task.propertyId,
          ...formData,
        })
        .select('id')
        .single();

    final completionId = row['id'] as String;

    // 2. Upload photos.
    if (photos.isNotEmpty) {
      final photoRows = <Map<String, dynamic>>[];
      for (final photo in photos) {
        final bytes = await photo.readAsBytes();
        final ext = photo.name.split('.').last.toLowerCase();
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${photo.name}';
        final path =
            '${user.id}/${detail.task.propertyId}/$completionId/$fileName';

        await SupabaseService.client.storage
            .from('completion-photos')
            .uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(contentType: _mimeType(ext)),
            );

        photoRows.add({
          'completion_id': completionId,
          'user_id': user.id,
          'file_path': path,
        });
      }
      await SupabaseService.client
          .from('completion_photos')
          .insert(photoRows);
    }

    // 3. Update task row — roll forward if recurring, complete if one-off.
    final isRecurring = detail.task.recurrence != RecurrenceType.none;
    if (isRecurring) {
      final base = formData['completed_date'] is String
          ? DateTime.tryParse(formData['completed_date'] as String) ??
              DateTime.now()
          : DateTime.now();
      final nextDate = _nextDate(detail.task, base: base);
      await SupabaseService.client.from('maintenance_tasks').update({
        'due_date': _dateStr(nextDate),
        'status': 'scheduled',
      }).eq('id', detail.task.id);
    } else {
      await SupabaseService.client
          .from('maintenance_tasks')
          .update({'status': 'completed'})
          .eq('id', detail.task.id);
    }

    ref.invalidate(maintenanceTasksProvider);
    ref.invalidate(homeHealthScoreProvider);
    ref.invalidateSelf();
    await future;

    return completionId;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static DateTime _nextDate(MaintenanceTask task, {DateTime? base}) {
    final b = (base ?? task.dueDate).toLocal();
    return switch (task.recurrence) {
      RecurrenceType.none => b,
      RecurrenceType.weekly => b.add(const Duration(days: 7)),
      RecurrenceType.biweekly => b.add(const Duration(days: 14)),
      RecurrenceType.monthly => DateTime(b.year, b.month + 1, b.day),
      RecurrenceType.quarterly => DateTime(b.year, b.month + 3, b.day),
      RecurrenceType.biannual => DateTime(b.year, b.month + 6, b.day),
      RecurrenceType.annual => DateTime(b.year + 1, b.month, b.day),
    };
  }

  static String _dateStr(DateTime dt) {
    final d = dt.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static String _mimeType(String ext) {
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'heic' => 'image/heic',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
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

    final cleaned = Map<String, dynamic>.from(row)
      ..remove('system')
      ..remove('appliance')
      ..remove('completions')
      ..remove('template');

    var task = MaintenanceTask.fromJson(cleaned).copyWith(
      linkedSystemName: systemRow?['name'] as String?,
      linkedApplianceName: applianceRow?['name'] as String?,
    );

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
