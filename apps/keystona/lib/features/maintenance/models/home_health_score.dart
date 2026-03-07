import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_health_score.freezed.dart';

/// Maintenance-pillar health score returned by the `get_home_health_score` RPC.
///
/// Phase 2 scope: maintenance pillar only (0–100).
/// Phase 3 dashboard will extend this to the full three-pillar composite.
@freezed
abstract class HomeHealthScore with _$HomeHealthScore {
  const factory HomeHealthScore({
    /// Overall maintenance score (0–100).
    required int score,

    /// 'improving' | 'stable' | 'declining' — 30-day vs prior 30-day comparison.
    required String trend,

    /// Tasks in the 12-month rolling window (excludes skipped).
    required int totalTasks,

    /// Tasks completed (on time + late) in the 12-month window.
    required int completed,

    /// Tasks currently overdue in the 12-month window.
    required int overdue,

    /// Tasks that are scheduled/due with a future due date.
    required int upcoming,
  }) = _HomeHealthScore;

  /// Default value used when the user has no property or the RPC returns null.
  factory HomeHealthScore.empty() => const HomeHealthScore(
        score: 100,
        trend: 'stable',
        totalTasks: 0,
        completed: 0,
        overdue: 0,
        upcoming: 0,
      );

  /// Parses the raw JSON map returned by the `get_home_health_score` RPC.
  factory HomeHealthScore.fromRpc(Map<String, dynamic> json) => HomeHealthScore(
        score: json['score'] as int? ?? 100,
        trend: json['trend'] as String? ?? 'stable',
        totalTasks: json['total_tasks'] as int? ?? 0,
        completed: json['completed'] as int? ?? 0,
        overdue: json['overdue'] as int? ?? 0,
        upcoming: json['upcoming'] as int? ?? 0,
      );
}
