import 'system.dart';

/// A system worth tracking, offered as a dashed chip under the list. Tapping
/// one opens Add system with [category], [name] and [systemType] filled in.
class SystemTemplate {
  const SystemTemplate({
    required this.label,
    required this.category,
    required this.systemType,
    this.builtBefore,
  });

  /// The chip text and the suggested name: "Sump pump".
  final String label;
  final SystemCategory category;

  /// The `system_type` stored with it.
  final String systemType;

  /// Offered only to homes built before this year. Null: every home.
  final int? builtBefore;

  /// Whether [systems] already include this one (same type, or a name that
  /// says it).
  bool isTrackedIn(Iterable<HomeSystem> systems) => systems.any(
    (s) =>
        s.systemType == systemType ||
        s.name.toLowerCase().contains(label.toLowerCase()),
  );
}

/// What a typical home has and people forget. Static: no backend source.
abstract final class SystemTemplates {
  static const List<SystemTemplate> all = [
    SystemTemplate(
      label: 'Plumbing',
      category: SystemCategory.plumbing,
      systemType: 'plumbing_supply',
    ),
    SystemTemplate(
      label: 'Windows',
      category: SystemCategory.windowsDoors,
      systemType: 'windows',
    ),
    SystemTemplate(
      label: 'Sump pump',
      category: SystemCategory.plumbing,
      systemType: 'sump_pump',
    ),
    SystemTemplate(
      label: 'Insulation',
      category: SystemCategory.insulation,
      systemType: 'insulation',
    ),
    SystemTemplate(
      label: 'Siding',
      category: SystemCategory.siding,
      systemType: 'siding',
    ),
    SystemTemplate(
      label: 'Garage door',
      category: SystemCategory.garage,
      systemType: 'garage_door',
    ),
    SystemTemplate(
      label: 'Chimney',
      category: SystemCategory.other,
      systemType: 'chimney',
      builtBefore: 1990,
    ),
    SystemTemplate(
      label: 'Gutters',
      category: SystemCategory.other,
      systemType: 'gutters',
    ),
  ];

  /// The chips for a home built in [yearBuilt] (null: unknown), minus what
  /// [tracked] already has, at most [limit].
  static List<SystemTemplate> suggestionsFor({
    required int? yearBuilt,
    required Iterable<HomeSystem> tracked,
    required int limit,
  }) => [
    for (final t in all)
      if ((t.builtBefore == null ||
              (yearBuilt != null && yearBuilt < t.builtBefore!)) &&
          !t.isTrackedIn(tracked))
        t,
  ].take(limit).toList();
}

/// Per-category starting points for Add system.
abstract final class SystemDefaults {
  /// Typical life in years when the category is chosen (middle of the
  /// NAHB-style ranges).
  static int lifespanYears(SystemCategory category) => switch (category) {
    SystemCategory.hvac => 15,
    SystemCategory.plumbing => 50,
    SystemCategory.electrical => 40,
    SystemCategory.roofing => 25,
    SystemCategory.foundation => 50,
    SystemCategory.siding => 30,
    SystemCategory.windowsDoors => 25,
    SystemCategory.insulation => 30,
    SystemCategory.garage => 20,
    SystemCategory.other => 15,
  };

  /// What the "Add its maintenance tasks" switch promises for [category].
  static String tasksMeta(SystemCategory category) => switch (category) {
    SystemCategory.hvac => 'FILTER CHANGES · ANNUAL TUNE-UP · 3 TASKS',
    SystemCategory.plumbing => 'LEAK CHECKS · SHUTOFF TEST · 2 TASKS',
    SystemCategory.roofing => 'SPRING & FALL INSPECTION · 2 TASKS',
    _ => 'ROUTINE CHECKS FOR THIS SYSTEM',
  };
}
