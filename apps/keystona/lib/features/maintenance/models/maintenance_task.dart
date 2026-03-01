import 'package:freezed_annotation/freezed_annotation.dart';

part 'maintenance_task.freezed.dart';
part 'maintenance_task.g.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

/// Maps exactly to Postgres `task_status` enum.
@JsonEnum(valueField: 'value')
enum TaskStatus {
  scheduled('scheduled'),
  due('due'),
  overdue('overdue'),
  completed('completed'),
  skipped('skipped');

  const TaskStatus(this.value);
  final String value;
}

/// Maps exactly to Postgres `task_priority` enum.
@JsonEnum(valueField: 'value')
enum TaskPriority {
  low('low'),
  medium('medium'),
  high('high'),
  critical('critical');

  const TaskPriority(this.value);
  final String value;

  /// Higher number = higher priority. Used for priority-descending sort.
  int get sortOrder => switch (this) {
        TaskPriority.critical => 3,
        TaskPriority.high => 2,
        TaskPriority.medium => 1,
        TaskPriority.low => 0,
      };
}

/// Maps exactly to Postgres `task_difficulty` enum.
@JsonEnum(valueField: 'value')
enum TaskDifficulty {
  easy('easy'),
  moderate('moderate'),
  involved('involved'),
  professional('professional');

  const TaskDifficulty(this.value);
  final String value;
}

/// Maps exactly to Postgres `diy_or_pro` enum.
@JsonEnum(valueField: 'value')
enum DiyOrPro {
  diy('diy'),
  either('either'),
  professional('professional');

  const DiyOrPro(this.value);
  final String value;
}

/// Maps exactly to Postgres `recurrence_type` enum.
@JsonEnum(valueField: 'value')
enum RecurrenceType {
  none('none'),
  weekly('weekly'),
  biweekly('biweekly'),
  monthly('monthly'),
  quarterly('quarterly'),
  biannual('biannual'),
  annual('annual');

  const RecurrenceType(this.value);
  final String value;

  /// Human-readable label for display in UI.
  String get label => switch (this) {
        RecurrenceType.none => 'One-time',
        RecurrenceType.weekly => 'Weekly',
        RecurrenceType.biweekly => 'Every 2 weeks',
        RecurrenceType.monthly => 'Monthly',
        RecurrenceType.quarterly => 'Quarterly',
        RecurrenceType.biannual => 'Twice a year',
        RecurrenceType.annual => 'Annually',
      };
}

/// Maps exactly to Postgres `task_origin` enum.
@JsonEnum(valueField: 'value')
enum TaskOrigin {
  systemGenerated('system_generated'),
  climateTriggered('climate_triggered'),
  seasonal('seasonal'),
  custom('custom'),
  oneTime('one_time');

  const TaskOrigin(this.value);
  final String value;
}

// ── Model ─────────────────────────────────────────────────────────────────────

/// A maintenance task in the homeowner's Maintenance Calendar.
///
/// Fields are annotated with the issue that uses them downstream so agents
/// building dependent issues know which fields are already available.
@freezed
abstract class MaintenanceTask with _$MaintenanceTask {
  const factory MaintenanceTask({
    required String id,
    required String propertyId,
    required String userId,

    // ── Source ────────────────────────────────────────────────────────────────

    /// Template this was generated from. [#33] Add Task form pre-fill.
    String? templateId,

    /// How this task was created. [#31] card badge for system-generated tasks.
    @Default(TaskOrigin.custom) TaskOrigin taskOrigin,

    // ── Task info ─────────────────────────────────────────────────────────────

    /// Display name of the task. [#31] card, [#34] search.
    required String name,

    /// Freeform description. [#32] detail screen, [#33] form.
    String? description,

    /// Step-by-step instructions. [#32] detail screen.
    String? instructions,

    /// Category string (e.g. "HVAC", "Plumbing"). [#31] card, [#33] filter.
    required String category,

    // ── Scheduling ────────────────────────────────────────────────────────────

    /// Due date — date only (no time component). [#31] card badge + sections.
    required DateTime dueDate,

    /// Recurrence pattern. [#32] detail screen, [#33] form.
    @Default(RecurrenceType.none) RecurrenceType recurrence,

    /// Season tag (e.g. "spring"). [#33] form, [#34] filter.
    String? season,

    /// Whether this task is climate-adjusted. [#32] detail badge.
    @Default(false) bool climateAdjusted,

    // ── Status ────────────────────────────────────────────────────────────────

    /// Current status. [#31] card badge + section grouping, [#32] complete CTA.
    @Default(TaskStatus.scheduled) TaskStatus status,

    // ── Task details ─────────────────────────────────────────────────────────

    /// How hard the task is. [#32] detail screen badge.
    @Default(TaskDifficulty.easy) TaskDifficulty difficulty,

    /// DIY vs professional. [#32] detail screen badge, [#33] form.
    @Default(DiyOrPro.diy) DiyOrPro diyOrPro,

    /// Priority level. [#31] card visual priority indicator.
    @Default(TaskPriority.medium) TaskPriority priority,

    /// Estimated time in minutes. [#31] card, [#32] detail screen.
    int? estimatedMinutes,

    // ── Linked entities ───────────────────────────────────────────────────────

    /// Foreign key to linked system. [#31] card chip, [#32] tappable link.
    String? linkedSystemId,

    /// Foreign key to linked appliance. [#32] tappable link.
    String? linkedApplianceId,

    // ── Audit ─────────────────────────────────────────────────────────────────

    /// Timestamp of row creation. [#31] sort fallback.
    required DateTime createdAt,

    /// Timestamp of last update.
    required DateTime updatedAt,

    // ── Joined fields (not DB columns) ────────────────────────────────────────

    /// Name of the linked system from nested select. [#31] card chip.
    String? linkedSystemName,
  }) = _MaintenanceTask;

  factory MaintenanceTask.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceTaskFromJson(json);
}
