import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A single row returned by the `get_system_lifespan_overview` RPC.
///
/// Uses a plain class with a [fromRpc] factory — no Freezed / JSON serialization
/// needed since this is assembled in-memory from a Supabase RPC call, not
/// stored in the app's persistent models.
class SystemLifespanEntry {
  const SystemLifespanEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.systemType,
    this.installationDate,
    this.ageYears,
    this.lifespanMin,
    this.lifespanMax,
    this.lifespanPercentage,
    required this.healthStatus,
    this.estimatedReplacementCost,
    this.yearsUntilReplacementMin,
    this.yearsUntilReplacementMax,
  });

  final String id;
  final String name;
  final String category;
  final String systemType;

  /// Null when the user hasn't provided an installation date.
  final DateTime? installationDate;

  /// Fractional years of age. Null when [installationDate] is null.
  final double? ageYears;

  final int? lifespanMin;
  final int? lifespanMax;

  /// 0–100+ percentage. Null when age is unknown.
  final double? lifespanPercentage;

  /// 'healthy' | 'aging' | 'end_of_life' | 'unknown'
  final String healthStatus;

  final double? estimatedReplacementCost;
  final double? yearsUntilReplacementMin;
  final double? yearsUntilReplacementMax;

  // ── Convenience getters ───────────────────────────────────────────────────

  bool get isUnknown => healthStatus == 'unknown';
  bool get isEndOfLife => healthStatus == 'end_of_life';
  bool get isAging => healthStatus == 'aging';
  bool get isHealthy => healthStatus == 'healthy';

  /// Progress bar fill fraction (0.0–1.0). Clamped to [0, 1] for the bar.
  double get barFraction =>
      lifespanPercentage == null ? 0.0 : (lifespanPercentage! / 100).clamp(0.0, 1.0);

  /// Color for the progress bar and health chip.
  Color get healthColor {
    switch (healthStatus) {
      case 'end_of_life':
        return AppColors.error;
      case 'aging':
        return AppColors.warning;
      case 'healthy':
        return AppColors.success;
      default:
        return AppColors.gray400;
    }
  }

  /// Human-readable health label.
  String get healthLabel {
    switch (healthStatus) {
      case 'end_of_life':
        return 'End of Life';
      case 'aging':
        return 'Aging';
      case 'healthy':
        return 'Healthy';
      default:
        return 'Unknown Age';
    }
  }

  factory SystemLifespanEntry.fromRpc(Map<String, dynamic> row) {
    return SystemLifespanEntry(
      id: row['id'] as String,
      name: row['name'] as String,
      category: row['category'] as String,
      systemType: row['system_type'] as String,
      installationDate: row['installation_date'] != null
          ? DateTime.tryParse(row['installation_date'] as String)
          : null,
      ageYears: (row['age_years'] as num?)?.toDouble(),
      lifespanMin: (row['lifespan_min'] as num?)?.toInt(),
      lifespanMax: (row['lifespan_max'] as num?)?.toInt(),
      lifespanPercentage: (row['lifespan_percentage'] as num?)?.toDouble(),
      healthStatus: row['health_status'] as String? ?? 'unknown',
      estimatedReplacementCost:
          (row['estimated_replacement_cost'] as num?)?.toDouble(),
      yearsUntilReplacementMin:
          (row['years_until_replacement_min'] as num?)?.toDouble(),
      yearsUntilReplacementMax:
          (row['years_until_replacement_max'] as num?)?.toDouble(),
    );
  }
}
