import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_completion.freezed.dart';
part 'task_completion.g.dart';

/// A single completion event for a maintenance task.
///
/// Maps to the `task_completions` table.
///
/// [#33] agents building the Completion Flow: create new rows using
/// `TaskDetailNotifier.completeTaskDetailed()`. The [linkedDocumentIds] field
/// is already wired here — the form just needs to populate it.
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

    /// [#33] Receipt / document IDs from Document Vault, linked at completion.
    @Default(<String>[]) List<String> linkedDocumentIds,

    // ── Audit ────────────────────────────────────────────────────────────────

    required DateTime createdAt,
  }) = _TaskCompletion;

  factory TaskCompletion.fromJson(Map<String, dynamic> json) =>
      _$TaskCompletionFromJson(json);
}
