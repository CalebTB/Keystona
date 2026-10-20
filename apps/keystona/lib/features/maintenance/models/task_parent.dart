/// What a task belongs to: a system, an appliance, or an area of the house
/// (Safety, Outside, Yard, ...). Every task has exactly one parent.
enum TaskParentKind { system, appliance, area }

/// Where an item sits in its expected life. Words always accompany the color.
enum TaskParentHealth { healthy, aging, endOfLife }

/// The "For" card on the task detail screen. Plain Dart: assembled from the
/// nested select, never persisted.
class TaskParent {
  const TaskParent({
    required this.kind,
    required this.name,
    this.id,
    this.model,
    this.location,
    this.health,
  });

  final TaskParentKind kind;

  /// Null for an area, which has no page of its own.
  final String? id;
  final String name;
  final String? model;
  final String? location;
  final TaskParentHealth? health;

  /// "NF95-080B · BASEMENT" source text, or null when neither is known.
  String? get detail {
    final parts = [
      if (model != null && model!.trim().isNotEmpty) model!.trim(),
      if (location != null && location!.trim().isNotEmpty) location!.trim(),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// Health from the install date and expected lifespan, using the same
  /// 75% / 100% thresholds as the lifespan screen. Null when not enough is
  /// known.
  static TaskParentHealth? healthOf({
    required DateTime? installed,
    required int? lifespanMin,
    required int? lifespanMax,
    required int? lifespanOverride,
    required DateTime now,
  }) {
    if (installed == null) return null;
    final double? lifespan = lifespanOverride != null
        ? lifespanOverride.toDouble()
        : (lifespanMin != null && lifespanMax != null)
        ? (lifespanMin + lifespanMax) / 2
        : (lifespanMin ?? lifespanMax)?.toDouble();
    if (lifespan == null || lifespan <= 0) return null;
    final ageYears = now.difference(installed).inDays / _daysPerYear;
    final used = ageYears / lifespan;
    if (used >= 1) return TaskParentHealth.endOfLife;
    if (used >= _agingFraction) return TaskParentHealth.aging;
    return TaskParentHealth.healthy;
  }

  /// Fraction of expected life at which an item counts as aging.
  static const double _agingFraction = 0.75;
  static const double _daysPerYear = 365.25;
}
