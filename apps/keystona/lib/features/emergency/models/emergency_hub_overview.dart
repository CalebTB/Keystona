import 'emergency_contact.dart';
import 'insurance_policy.dart';
import 'utility_shutoff.dart';

/// Composite overview assembled by [EmergencyHubNotifier] from parallel queries.
///
/// Not persisted — never needs fromJson / toJson.
class EmergencyHubOverview {
  const EmergencyHubOverview({
    required this.shutoffs,
    required this.favoriteContacts,
    required this.totalContactCount,
    required this.policies,
    this.lastSyncedAt,
  });

  /// All utility shutoff records for this property (0–3 rows).
  final List<UtilityShutoff> shutoffs;

  /// Up to 3 favorite contacts shown as a preview on the hub screen.
  final List<EmergencyContact> favoriteContacts;

  /// Total contact count (favorites + non-favorites) for the "See all" badge.
  final int totalContactCount;

  /// All active insurance policies.
  final List<InsurancePolicy> policies;

  /// [#50] Set by the offline sync service after a successful sync.
  final DateTime? lastSyncedAt;

  /// Convenience: look up a shutoff by type ('water', 'gas', 'electrical').
  UtilityShutoff? shutoffFor(String type) =>
      shutoffs.where((s) => s.utilityType == type).firstOrNull;
}
