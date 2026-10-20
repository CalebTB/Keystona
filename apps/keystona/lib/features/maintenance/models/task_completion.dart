import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_completion.freezed.dart';
part 'task_completion.g.dart';

/// A single completion event for a maintenance task.
///
/// Maps to the `task_completions` table.
///
/// Created by `TaskDetailNotifier.logCompletion()` from the Log screen.
@freezed
abstract class TaskCompletion with _$TaskCompletion {
  const factory TaskCompletion({
    required String id,
    required String taskId,
    required String userId,
    required String propertyId,

    // ── Completion details ───────────────────────────────────────────────────

    /// DATE column — returned as "YYYY-MM-DD" string, parsed to DateTime.
    required DateTime completedDate,

    /// 'diy' or 'contractor'.
    @Default('diy') String completedBy,

    // ── Contractor info ──────────────────────────────────────────────────────
    String? contractorName,
    String? contractorCompany,
    String? contractorPhone,

    // ── Costs ────────────────────────────────────────────────────────────────
    double? serviceCost,
    double? materialsCost,

    // ── Details ──────────────────────────────────────────────────────────────
    int? timeSpentMinutes,
    String? notes,

    /// Receipt / document IDs from Document Vault, linked at completion.
    @Default(<String>[]) List<String> linkedDocumentIds,

    /// What was found, by the `TaskFinding.value`s (`findings`).
    @Default(<String>[]) List<String> findings,

    /// The Log screen's "Add to the item's history" switch
    /// (`log_to_item_history`).
    @Default(false) bool logToItemHistory,

    /// The due date this completion answered (`due_date`, a DATE). Null for
    /// rows logged before the column existed and for past entries that
    /// answered no open due date.
    DateTime? dueDate,

    // ── Audit ────────────────────────────────────────────────────────────────
    required DateTime createdAt,
  }) = _TaskCompletion;

  factory TaskCompletion.fromJson(Map<String, dynamic> json) =>
      _$TaskCompletionFromJson(json);
}
