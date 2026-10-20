import '../models/completion_photo.dart';
import '../models/maintenance_task.dart';
import '../models/task_detail.dart';
import '../models/task_log_draft.dart';

/// Data access for the Task detail, Log and History screens. Screens and
/// notifiers depend on this interface through a provider, so tests swap in a
/// fake and nothing reaches Supabase.
abstract interface class TaskDetailRepository {
  /// The task with its parent, reminder lead time and completions (newest
  /// first). Throws when the task does not exist or was deleted.
  Future<TaskDetail> fetchDetail(String taskId);

  /// Photos for [completionIds], each with a signed URL, grouped by
  /// completion id.
  Future<Map<String, List<CompletionPhoto>>> completionPhotos(
    List<String> completionIds,
  );

  /// Inserts the completion for [task], uploads its photos, and returns the
  /// new row's id. [dueDate] is the occurrence it answered, null for a past
  /// entry that answered none.
  Future<String> insertCompletion({
    required MaintenanceTask task,
    required TaskLogDraft draft,
    DateTime? dueDate,
  });

  /// Moves the task to [status] and [dueDate] (a DATE, "YYYY-MM-DD").
  Future<void> updateSchedule(
    String taskId, {
    required TaskStatus status,
    required DateTime dueDate,
  });

  /// Removes one completion (and, by cascade, its photo rows).
  Future<void> deleteCompletion(String completionId);

  /// Soft-deletes the task (`soft_delete_task`).
  Future<void> deleteTask(String taskId);

  /// Brings a soft-deleted task back (`restore_task`).
  Future<void> restoreTask(String taskId);
}
