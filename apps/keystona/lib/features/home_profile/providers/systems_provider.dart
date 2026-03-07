import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/system.dart';
import 'home_profile_provider.dart';

part 'systems_provider.g.dart';

/// Manages the list of home systems for the authenticated user's property.
///
/// Auto-disposed when the Systems screen is not active.
/// Invalidates [homeProfileProvider] after any mutation so the overview
/// system count stays in sync.
@riverpod
class SystemsNotifier extends _$SystemsNotifier {
  @override
  Future<List<HomeSystem>> build() => _fetchSystems();

  // ── Public interface ───────────────────────────────────────────────────────

  /// Refetches systems from Supabase — used by pull-to-refresh.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchSystems);
  }

  /// Inserts a new system row and triggers the `generate-maintenance-tasks`
  /// Edge Function to create initial maintenance tasks.
  ///
  /// The Edge Function call is NON-FATAL: if it fails the system is still
  /// added and the list is refreshed. The user can generate tasks later.
  Future<void> addSystem(Map<String, dynamic> data) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');

    final propertyRow = await SupabaseService.client
        .from('properties')
        .select('id')
        .eq('user_id', user.id)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (propertyRow == null) throw StateError('No property found');

    final propertyId = propertyRow['id'] as String;

    final row = await SupabaseService.client
        .from('systems')
        .insert({
          'property_id': propertyId,
          'user_id': user.id,
          ...data,
        })
        .select('id')
        .single();

    final systemId = row['id'] as String;

    // Trigger task generation — non-fatal.
    try {
      final session = SupabaseService.client.auth.currentSession;
      if (session != null) {
        await SupabaseService.client.functions.invoke(
          'generate-maintenance-tasks',
          body: {
            'property_id': propertyId,
            'system_id': systemId,
          },
          headers: {'Authorization': 'Bearer ${session.accessToken}'},
        );
      }
    } catch (_) {
      // Non-fatal: system added successfully, tasks generated later.
    }

    // Sync the overview count and re-fetch list.
    ref.invalidate(homeProfileProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchSystems);
  }

  /// Updates an existing system row.
  Future<void> updateSystem(String systemId, Map<String, dynamic> data) async {
    await SupabaseService.client
        .from('systems')
        .update(data)
        .eq('id', systemId);

    ref.invalidate(homeProfileProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchSystems);
  }

  /// Soft-deletes a system by setting `deleted_at`.
  ///
  /// The row is preserved in the database; RLS ensures it is never returned
  /// in subsequent queries.
  Future<void> deleteSystem(String systemId) async {
    await SupabaseService.client
        .from('systems')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', systemId);

    ref.invalidate(homeProfileProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchSystems);
  }

  // ── Private fetch ──────────────────────────────────────────────────────────

  Future<List<HomeSystem>> _fetchSystems() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');

    final propertyRow = await SupabaseService.client
        .from('properties')
        .select('id')
        .eq('user_id', user.id)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (propertyRow == null) return [];

    final rows = await SupabaseService.client
        .from('systems')
        .select(
          'id, property_id, user_id, category, system_type, name, status, '
          'brand, model, serial_number, installation_date, purchase_price, '
          'installer, location, expected_lifespan_min, expected_lifespan_max, '
          'lifespan_override, warranty_expiration, warranty_provider, '
          'estimated_replacement_cost, notes, created_at, updated_at',
        )
        .eq('property_id', propertyRow['id'] as String)
        .isFilter('deleted_at', null)
        .order('category')
        .order('name');

    return rows
        .map((r) => HomeSystem.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }
}
