// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_phase.freezed.dart';
part 'project_phase.g.dart';

/// A single phase within a home improvement project.
@freezed
abstract class ProjectPhase with _$ProjectPhase {
  const factory ProjectPhase({
    required String id,
    required String projectId,
    required String userId,
    required String name,
    String? description,
    @Default('planning') String status,
    @Default(0) int sortOrder,
    @JsonKey(name: 'planned_start_date') DateTime? plannedStartDate,
    @JsonKey(name: 'planned_end_date') DateTime? plannedEndDate,
    @JsonKey(name: 'actual_start_date') DateTime? actualStartDate,
    @JsonKey(name: 'actual_end_date') DateTime? actualEndDate,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _ProjectPhase;

  factory ProjectPhase.fromJson(Map<String, dynamic> json) =>
      _$ProjectPhaseFromJson(json);
}

/// A phase template row from [project_phase_templates].
///
/// Not persisted as a Dart model — assembled from a Supabase query.
class PhaseTemplate {
  const PhaseTemplate({
    required this.id,
    required this.projectType,
    required this.name,
    this.description,
    required this.sortOrder,
  });

  final String id;
  final String projectType;
  final String name;
  final String? description;
  final int sortOrder;

  factory PhaseTemplate.fromMap(Map<String, dynamic> map) => PhaseTemplate(
        id: map['id'] as String,
        projectType: map['project_type'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        sortOrder: (map['sort_order'] as num).toInt(),
      );
}

/// Display label for a phase status value.
extension PhaseStatusLabel on String {
  String get phaseStatusLabel => switch (this) {
        'planning'    => 'Planning',
        'in_progress' => 'In Progress',
        'on_hold'     => 'On Hold',
        'completed'   => 'Completed',
        'cancelled'   => 'Cancelled',
        _             => 'Unknown',
      };
}

/// All valid phase status options.
abstract final class PhaseStatuses {
  static const all = [
    (value: 'planning',    label: 'Planning'),
    (value: 'in_progress', label: 'In Progress'),
    (value: 'on_hold',     label: 'On Hold'),
    (value: 'completed',   label: 'Completed'),
    (value: 'cancelled',   label: 'Cancelled'),
  ];
}
