// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'project.freezed.dart';
part 'project.g.dart';

/// A home improvement project.
///
/// Downstream fields annotated with their implementing issue:
///   - [actualSpent], [phaseCount] → #5.3/5.4
///   - [contractorIds] → #5.5
///   - [coverPhotoPath] → #5.6
@freezed
abstract class Project with _$Project {
  const factory Project({
    required String id,
    required String propertyId,
    required String userId,

    required String name,
    String? description,

    @JsonKey(name: 'project_type') required String projectType,
    required String status,

    // ── Budget ─────────────────────────────────────────────────────────────

    double? estimatedBudget,

    /// [#5.4] Actual amount spent — updated by Budget items.
    @Default(0.0) double actualSpent,

    // ── Dates ──────────────────────────────────────────────────────────────

    @JsonKey(name: 'planned_start_date') DateTime? plannedStartDate,
    @JsonKey(name: 'planned_end_date') DateTime? plannedEndDate,
    @JsonKey(name: 'actual_start_date') DateTime? actualStartDate,
    @JsonKey(name: 'actual_end_date') DateTime? actualEndDate,

    // ── Cover photo ────────────────────────────────────────────────────────

    /// [#5.6] Supabase Storage path for the cover photo.
    String? coverPhotoPath,

    // ── Downstream ─────────────────────────────────────────────────────────

    /// [#5.3] Denormalized phase count — updated by trigger.
    @Default(0) int phaseCount,

    /// [#5.5] Contractor IDs from the shared emergency_contacts pool.
    @Default([]) List<String> contractorIds,

    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);
}

/// Display label for [Project.status].
extension ProjectStatusLabel on String {
  String get statusLabel => switch (this) {
        'planning'    => 'Planning',
        'in_progress' => 'In Progress',
        'on_hold'     => 'On Hold',
        'completed'   => 'Completed',
        'cancelled'   => 'Cancelled',
        _             => 'Unknown',
      };
}

/// Display label for [Project.projectType].
extension ProjectTypeLabel on String {
  String get projectTypeLabel => switch (this) {
        'kitchen_remodel'  => 'Kitchen Remodel',
        'bathroom_remodel' => 'Bathroom Remodel',
        'deck_build'       => 'Deck Build',
        'addition'         => 'Addition',
        'roofing'          => 'Roofing',
        'flooring'         => 'Flooring',
        'painting'         => 'Painting',
        'landscaping'      => 'Landscaping',
        'hvac_replacement' => 'HVAC Replacement',
        _                  => 'Other',
      };
}

/// All project status options.
abstract final class ProjectStatuses {
  static const all = [
    (value: 'planning',    label: 'Planning'),
    (value: 'in_progress', label: 'In Progress'),
    (value: 'on_hold',     label: 'On Hold'),
    (value: 'completed',   label: 'Completed'),
    (value: 'cancelled',   label: 'Cancelled'),
  ];
}

/// All project type options.
abstract final class ProjectTypes {
  static const all = [
    (value: 'kitchen_remodel',  label: 'Kitchen Remodel'),
    (value: 'bathroom_remodel', label: 'Bathroom Remodel'),
    (value: 'deck_build',       label: 'Deck Build'),
    (value: 'addition',         label: 'Addition'),
    (value: 'roofing',          label: 'Roofing'),
    (value: 'flooring',         label: 'Flooring'),
    (value: 'painting',         label: 'Painting'),
    (value: 'landscaping',      label: 'Landscaping'),
    (value: 'hvac_replacement',  label: 'HVAC Replacement'),
    (value: 'other',            label: 'Other'),
  ];
}
