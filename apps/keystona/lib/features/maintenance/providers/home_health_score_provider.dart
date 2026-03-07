import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/home_health_score.dart';

part 'home_health_score_provider.g.dart';

/// Loads the maintenance-pillar health score from the `get_home_health_score` RPC.
///
/// Auto-disposed when the Tasks tab is not visible.
/// Invalidated by [TaskDetailNotifier] after any task mutation (complete, skip,
/// quick-complete, undo) so the score stays in sync without a manual refresh.
@riverpod
class HomeHealthScoreNotifier extends _$HomeHealthScoreNotifier {
  @override
  Future<HomeHealthScore> build() => _fetchScore();

  /// Refetches the score from Supabase.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchScore);
  }

  Future<HomeHealthScore> _fetchScore() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return HomeHealthScore.empty();

    final propertyRow = await SupabaseService.client
        .from('properties')
        .select('id')
        .eq('user_id', user.id)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (propertyRow == null) return HomeHealthScore.empty();

    final propertyId = propertyRow['id'] as String;

    final result = await SupabaseService.client.rpc(
      'get_home_health_score',
      params: {'p_property_id': propertyId},
    );

    if (result == null) return HomeHealthScore.empty();
    return HomeHealthScore.fromRpc(result as Map<String, dynamic>);
  }
}
