import 'property.dart';

/// Composite view-model for the Home Profile overview screen.
///
/// Assembled in [HomeProfileNotifier._fetchOverview] — never persisted,
/// so no Freezed / JSON needed. Same pattern as [TaskDetail] from Phase 2.
class HomeProfileOverview {
  const HomeProfileOverview({
    required this.property,
    required this.systemCount,
    required this.systemsNearingEndOfLife,
    required this.applianceCount,
  });

  /// The user's property record.
  final Property property;

  /// Total active systems (status = 'active', not soft-deleted).
  ///
  /// Displayed as a badge on the Systems section row.
  final int systemCount;

  /// Systems with a lifespan percentage ≥ 75 % — i.e., healthy → aging or worse.
  ///
  /// [#41] Drives the "X items nearing end of life" amber warning row.
  /// [#48] Lifespan Tracking screen uses this same threshold — keep in sync.
  final int systemsNearingEndOfLife;

  /// Total active appliances.
  final int applianceCount;
}
