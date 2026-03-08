import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/system_lifespan_entry.dart';

part 'lifespan_provider.g.dart';

/// Loads all systems for the current property via the
/// `get_system_lifespan_overview` RPC and returns them sorted by urgency
/// (End of Life → Aging → Healthy → Unknown).
///
/// Auto-disposed when the Lifespan screen is popped.
@riverpod
class LifespanNotifier extends _$LifespanNotifier {
  @override
  Future<List<SystemLifespanEntry>> build() => _fetch();

  /// Refetches from Supabase — used by pull-to-refresh.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<List<SystemLifespanEntry>> _fetch() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final propertyRow = await SupabaseService.client
        .from('properties')
        .select('id')
        .eq('user_id', user.id)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (propertyRow == null) return [];

    final propertyId = propertyRow['id'] as String;

    final rows = await SupabaseService.client
        .rpc('get_system_lifespan_overview', params: {'p_property_id': propertyId});

    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(SystemLifespanEntry.fromRpc)
        .toList();
  }
}
