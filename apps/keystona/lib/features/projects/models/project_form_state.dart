import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_form_state.freezed.dart';

/// Ephemeral state for the create/edit project form.
///
/// No `.g.dart` — never serialized to/from JSON.
/// Assembled from [Project] in edit mode; starts with defaults in create mode.
@freezed
abstract class ProjectFormState with _$ProjectFormState {
  const factory ProjectFormState({
    @Default('') String name,
    @Default('') String description,
    @Default('kitchen_remodel') String projectType,
    @Default('planning') String status,
    @Default('diy') String workType,
    double? estimatedBudget,
    DateTime? plannedStartDate,
    DateTime? plannedEndDate,
    String? coverPhotoPath,
    @Default(false) bool saving,
  }) = _ProjectFormState;
}
