import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/project.dart';

part 'project_detail_provider.g.dart';

const _kProjectColumns =
    'id, property_id, user_id, name, description, project_type, status, work_type, '
    'estimated_budget, actual_spent, planned_start_date, planned_end_date, '
    'actual_start_date, actual_end_date, cover_photo_path, '
    'phase_count, contractor_ids, created_at, updated_at, deleted_at';

/// Loads and caches a single project by [projectId].
///
/// Auto-disposed on pop — use [ref.invalidateSelf()] + [await future] after
/// any mutation to refresh detail data without leaving a stale state.
@riverpod
class ProjectDetailNotifier extends _$ProjectDetailNotifier {
  @override
  Future<Project> build(String projectId) => _fetch();

  /// Refetches the project from Supabase.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<Project> _fetch() async {
    final client = SupabaseService.client;

    final row = await client
        .from('projects')
        .select(_kProjectColumns)
        .eq('id', projectId)
        .isFilter('deleted_at', null)
        .single();

    final budgetRows = await client
        .from('project_budget_items')
        .select('actual_cost')
        .eq('project_id', projectId)
        .isFilter('deleted_at', null);

    final actualSpent = (budgetRows as List<dynamic>).fold<double>(
      0,
      (sum, r) =>
          sum + ((r['actual_cost'] as num?)?.toDouble() ?? 0),
    );

    return Project.fromJson(row).copyWith(actualSpent: actualSpent);
  }
}
