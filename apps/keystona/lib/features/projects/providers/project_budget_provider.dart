import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/project_budget_item.dart';
import 'project_detail_provider.dart';
import 'projects_provider.dart';

part 'project_budget_provider.g.dart';

const _kColumns =
    'id, project_id, user_id, name, category, estimated_cost, actual_cost, '
    'is_paid, vendor, receipt_document_id, phase_id, created_at, updated_at, '
    'deleted_at';

/// Manages budget line items for a single project.
@riverpod
class ProjectBudgetNotifier extends _$ProjectBudgetNotifier {
  @override
  Future<List<ProjectBudgetItem>> build(String projectId) => _fetch();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  /// Creates a new budget line item. Returns the new item's ID.
  Future<String> createItem(Map<String, dynamic> data) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final inserted = await SupabaseService.client
        .from('project_budget_items')
        .insert({
          ...data,
          'project_id': projectId,
          'user_id': user.id,
        })
        .select('id')
        .single();

    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
    ref.invalidate(projectDetailProvider(projectId));
    ref.invalidate(projectsProvider);

    return inserted['id'] as String;
  }

  /// Updates a budget line item by [id].
  Future<void> updateItem(String id, Map<String, dynamic> data) async {
    await SupabaseService.client
        .from('project_budget_items')
        .update(data)
        .eq('id', id);

    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
    ref.invalidate(projectDetailProvider(projectId));
    ref.invalidate(projectsProvider);
  }

  /// Soft-deletes a budget line item by [id].
  Future<void> deleteItem(String id) async {
    await SupabaseService.client
        .from('project_budget_items')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);

    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
    ref.invalidate(projectDetailProvider(projectId));
    ref.invalidate(projectsProvider);
  }

  // ── Private fetch ─────────────────────────────────────────────────────────

  Future<List<ProjectBudgetItem>> _fetch() async {
    final rows = await SupabaseService.client
        .from('project_budget_items')
        .select(_kColumns)
        .eq('project_id', projectId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: true);

    final items = (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ProjectBudgetItem.fromJson)
        .toList();

    // Sync actual_spent to the projects table so the list card stays current.
    final total = items.fold<double>(0, (s, i) => s + i.actualCost);
    try {
      await SupabaseService.client
          .from('projects')
          .update({'actual_spent': total}).eq('id', projectId);
      ref.invalidate(projectsProvider);
    } catch (_) {
      // Non-fatal.
    }

    return items;
  }
}

/// Computes the budget summary from the loaded items list.
/// Uses the project's [estimatedBudget] (set at creation) as the budget cap,
/// and sums [actualCost] across items for the spent figure.
@riverpod
Future<BudgetSummary> projectBudgetSummary(
    Ref ref, String projectId) async {
  final items = await ref.watch(projectBudgetProvider(projectId).future);
  final project =
      await ref.watch(projectDetailProvider(projectId).future);

  final actual = items.fold<double>(0, (s, i) => s + i.actualCost);
  final estimated = project.estimatedBudget ?? 0;
  return BudgetSummary(
    estimatedTotal: estimated,
    actualTotal: actual,
    remaining: estimated - actual,
    categoryBreakdown: [],
  );
}
