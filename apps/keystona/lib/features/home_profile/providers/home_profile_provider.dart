import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/home_profile_overview.dart';
import '../models/property.dart';

part 'home_profile_provider.g.dart';

/// Loads the Home Profile overview: property details + systems/appliances counts.
///
/// Auto-disposed when the Home Profile tab is not active.
/// Invalidated by [SystemsNotifier] and [AppliancesNotifier] after any mutation
/// so the system/appliance counts stay in sync (wired in #43 / #44).
@riverpod
class HomeProfileNotifier extends _$HomeProfileNotifier {
  @override
  Future<HomeProfileOverview> build() {
    ref.keepAlive(); // don't re-fetch on every tab switch
    return _fetchOverview();
  }

  /// Refetches from Supabase — used by pull-to-refresh.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchOverview);
  }

  /// [Future] Edit property fields — implemented in the property edit flow.
  Future<void> updateProperty(Map<String, dynamic> data) async {
    throw UnimplementedError('updateProperty() — implement in property edit flow');
  }

  // ── Private fetch ───────────────────────────────────────────────────────────

  Future<HomeProfileOverview> _fetchOverview() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // 1. Fetch the property row for this user.
    final propertyRow = await SupabaseService.client
        .from('properties')
        .select(
          'id, user_id, address_line1, address_line2, city, state, zip_code, '
          'property_type, year_built, square_feet, bedrooms, bathrooms, '
          'climate_zone, exterior_photo_path, created_at, updated_at',
        )
        .eq('user_id', user.id)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (propertyRow == null) throw _NoPropertyException();

    final property = Property.fromJson(propertyRow);

    // 2. In parallel: fetch lightweight system rows + appliances count.
    final results = await Future.wait([
      SupabaseService.client
          .from('systems')
          .select(
            'id, installation_date, expected_lifespan_min, '
            'expected_lifespan_max, lifespan_override',
          )
          .eq('property_id', property.id)
          .eq('status', 'active')
          .isFilter('deleted_at', null),
      SupabaseService.client
          .from('appliances')
          .select('id')
          .eq('property_id', property.id)
          .eq('status', 'active')
          .isFilter('deleted_at', null),
    ]);

    final systemRows = results[0] as List<dynamic>;
    final applianceRows = results[1] as List<dynamic>;

    // 3. Classify nearing-end-of-life in Dart — matches #48 Lifespan Tracking
    //    threshold (lifespan_percentage ≥ 75 %).
    final nearingEndOfLife = systemRows
        .cast<Map<String, dynamic>>()
        .where(_isNearingEndOfLife)
        .length;

    return HomeProfileOverview(
      property: property,
      systemCount: systemRows.length,
      systemsNearingEndOfLife: nearingEndOfLife,
      applianceCount: applianceRows.length,
    );
  }

  /// Returns true when a system's lifespan percentage is ≥ 75 %.
  ///
  /// Uses the same formula as the `get_system_lifespan_overview` RPC so the
  /// overview count always agrees with the lifespan screen (#48).
  static bool _isNearingEndOfLife(Map<String, dynamic> row) {
    final installRaw = row['installation_date'] as String?;
    if (installRaw == null) return false;

    final minLifespan = row['expected_lifespan_min'] as int? ?? 0;
    final maxLifespan = row['expected_lifespan_max'] as int? ?? 0;
    final override = row['lifespan_override'] as int?;

    final avgLifespan =
        override?.toDouble() ?? ((minLifespan + maxLifespan) / 2.0);
    if (avgLifespan == 0) return false;

    final install = DateTime.parse(installRaw);
    final ageYears =
        DateTime.now().difference(install).inDays / 365.25;

    return (ageYears / avgLifespan) >= 0.75;
  }
}

/// Sentinel exception thrown when the user has no property row yet.
///
/// Caught in [HomeProfileScreen] to render [HomeProfileEmptyState] instead
/// of the generic error view.
class _NoPropertyException implements Exception {
  const _NoPropertyException();
}

/// Re-exported so the screen can `catch (_NoPropertyException)`.
// ignore: library_private_types_in_public_api
typedef NoPropertyException = _NoPropertyException;
