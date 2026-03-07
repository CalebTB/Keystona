import 'package:freezed_annotation/freezed_annotation.dart';

part 'utility_shutoff.freezed.dart';
part 'utility_shutoff.g.dart';

/// A single utility shutoff record (water, gas, or electrical).
///
/// Used by [EmergencyHubScreen] to show completion status on each card.
/// Full detail + mutation implemented by [#45 Utility Shutoff Setup].
@freezed
abstract class UtilityShutoff with _$UtilityShutoff {
  const factory UtilityShutoff({
    required String id,
    required String propertyId,
    required String userId,

    /// One of: 'water', 'gas', 'electrical'
    required String utilityType,
    required String locationDescription,
    required bool isComplete,

    // ── Water-specific ───────────────────────────────────────────────────────
    String? valveType,
    String? turnDirection,

    // ── Gas-specific ─────────────────────────────────────────────────────────
    /// [#45] Gas company emergency phone number.
    String? gasCompanyPhone,

    // ── Electrical-specific ──────────────────────────────────────────────────
    /// [#45] Text description of main breaker panel location.
    String? mainBreakerLocation,
    /// [#45] Amperage rating of main breaker (e.g. 200).
    int? mainBreakerAmperage,
    /// [#45] Circuit directory: list of {breaker, label} maps.
    @Default([]) List<Map<String, dynamic>> circuitDirectory,

    // ── General ──────────────────────────────────────────────────────────────
    @Default([]) List<String> toolsRequired,
    String? specialInstructions,

    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UtilityShutoff;

  factory UtilityShutoff.fromJson(Map<String, dynamic> json) =>
      _$UtilityShutoffFromJson(json);
}

/// Display helpers for [UtilityShutoff.utilityType].
extension UtilityTypeLabel on String {
  String get utilityLabel => switch (this) {
        'water' => 'Water Shutoff',
        'gas' => 'Gas Shutoff',
        'electrical' => 'Electrical Panel',
        _ => this,
      };
}
