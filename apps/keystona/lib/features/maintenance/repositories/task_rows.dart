import '../models/maintenance_task.dart';
import '../models/quick_completion.dart';
import '../models/task_log_draft.dart';
import '../models/task_schedule.dart';

/// Names of the database functions the task screens call.
abstract final class TaskRpc {
  /// Soft-deletes a task. A plain UPDATE of `deleted_at` is refused by RLS.
  static const String softDelete = 'soft_delete_task';

  /// Brings a soft-deleted task back (Undo).
  static const String restore = 'restore_task';

  /// The argument both functions take.
  static Map<String, dynamic> args(String taskId) => {'p_task_id': taskId};
}

/// Insert payloads for the rows the task screens write. Pure Dart, so what
/// reaches the database is unit-tested without a client.
abstract final class TaskRows {
  /// A `task_completions` row from the quick "it's done" sheet.
  static Map<String, dynamic> quickCompletion({
    required MaintenanceTask task,
    required QuickCompletion completion,
    required String userId,
  }) => {
    'task_id': task.id,
    'user_id': userId,
    'property_id': task.propertyId,
    'completed_date': TaskSchedule.dateColumn(completion.completedOn),
    'completed_by': completion.byPro ? 'contractor' : 'diy',
    if (completion.dueDate != null)
      'due_date': TaskSchedule.dateColumn(completion.dueDate!),
    if (completion.cost != null)
      (completion.byPro ? 'service_cost' : 'materials_cost'): completion.cost,
    if (completion.note != null && completion.note!.isNotEmpty)
      'notes': completion.note,
  };

  /// A `task_completions` row from the Log screen. [dueDate] is the
  /// occurrence it answered, or null for a past entry that answered none.
  static Map<String, dynamic> logCompletion({
    required MaintenanceTask task,
    required TaskLogDraft draft,
    required String userId,
    DateTime? dueDate,
  }) {
    final notes = draft.notes?.trim();
    final pro = draft.doer == TaskDoer.pro ? draft.pro : null;
    return {
      'task_id': task.id,
      'user_id': userId,
      'property_id': task.propertyId,
      'completed_date': TaskSchedule.dateColumn(draft.completedDate),
      'completed_by': draft.doer.value,
      'contractor_name': ?pro?.name,
      'contractor_company': ?pro?.company,
      'contractor_phone': ?pro?.phone,
      if (draft.laborCost > 0) 'service_cost': draft.laborCost,
      if (draft.partsCost > 0) 'materials_cost': draft.partsCost,
      'time_spent_minutes': ?draft.minutes,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (draft.receiptIds.isNotEmpty) 'linked_document_ids': draft.receiptIds,
      'findings': [for (final f in draft.findings) f.value],
      'log_to_item_history': draft.addToItemHistory,
      if (dueDate != null) 'due_date': TaskSchedule.dateColumn(dueDate),
    };
  }

  /// A `task_skips` row. [dueDate] is the occurrence skipped.
  static Map<String, dynamic> skip({
    required MaintenanceTask task,
    required String userId,
    required DateTime dueDate,
    required DateTime skippedOn,
    String? reason,
  }) {
    final trimmed = reason?.trim();
    return {
      'task_id': task.id,
      'property_id': task.propertyId,
      'user_id': userId,
      'skipped_on': TaskSchedule.dateColumn(skippedOn),
      'due_date': TaskSchedule.dateColumn(dueDate),
      'reason': trimmed == null || trimmed.isEmpty ? null : trimmed,
    };
  }
}
