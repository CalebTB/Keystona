import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/project_phase.dart';
import 'project_detail_provider.dart';

part 'project_phases_provider.g.dart';

const _kColumns =
    'id, project_id, user_id, name, description, status, sort_order, '
    'planned_start_date, planned_end_date, actual_start_date, actual_end_date, '
    'created_at, updated_at, deleted_at';

/// Manages the phase list for a single project.
///
/// Keyed by [projectId] — generates `projectPhasesProvider(projectId)`.
@riverpod
class ProjectPhasesNotifier extends _$ProjectPhasesNotifier {
  @override
  Future<List<ProjectPhase>> build(String projectId) => _fetch();

  /// Refetches from Supabase — used by pull-to-refresh.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  /// Creates a new phase. Returns the new phase's ID.
  Future<String> createPhase(Map<String, dynamic> data) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final phases = state.value ?? [];
    final maxOrder = phases.isEmpty
        ? 0
        : phases.map((p) => p.sortOrder).reduce((a, b) => a > b ? a : b);

    final inserted = await SupabaseService.client
        .from('project_phases')
        .insert({
          ...data,
          'project_id': projectId,
          'user_id': user.id,
          'sort_order': maxOrder + 1,
        })
        .select('id')
        .single();

    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);

    // Refresh project detail so phase_count updates.
    ref.invalidate(projectDetailProvider(projectId));

    return inserted['id'] as String;
  }

  /// Updates a phase by [id].
  Future<void> updatePhase(String id, Map<String, dynamic> data) async {
    await SupabaseService.client
        .from('project_phases')
        .update(data)
        .eq('id', id);

    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// Soft-deletes a phase by [id].
  ///
  /// Budget items and journal notes keep their project link — only their
  /// [phase_id] is nullified (via ON DELETE SET NULL FK).
  Future<void> deletePhase(String id) async {
    await SupabaseService.client
        .from('project_phases')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);

    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);

    ref.invalidate(projectDetailProvider(projectId));
  }

  /// Reorders phases by updating sort_order for each phase in [orderedIds].
  Future<void> reorderPhases(List<String> orderedIds) async {
    // Optimistic update.
    final current = state.value;
    if (current == null) return;

    // Batch update each phase's sort_order.
    for (var i = 0; i < orderedIds.length; i++) {
      await SupabaseService.client
          .from('project_phases')
          .update({'sort_order': i})
          .eq('id', orderedIds[i]);
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// Fetches phase templates for [projectType] and batch-inserts them as
  /// phases for this project.
  ///
  /// Implements the [ProjectsNotifier.loadPhaseTemplates] stub from #51.
  Future<void> loadTemplatesAndCreate(String projectType) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final templates = await SupabaseService.client
        .from('project_phase_templates')
        .select('name, description, sort_order')
        .eq('project_type', projectType)
        .order('sort_order', ascending: true);

    if ((templates as List).isEmpty) return;

    final rows = templates
        .cast<Map<String, dynamic>>()
        .map((t) => {
              'project_id': projectId,
              'user_id': user.id,
              'name': t['name'] as String,
              'description': t['description'],
              'sort_order': t['sort_order'] as int,
            })
        .toList();

    await SupabaseService.client.from('project_phases').insert(rows);

    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);

    ref.invalidate(projectDetailProvider(projectId));
  }

  // ── Private fetch ─────────────────────────────────────────────────────────

  Future<List<ProjectPhase>> _fetch() async {
    final rows = await SupabaseService.client
        .from('project_phases')
        .select(_kColumns)
        .eq('project_id', projectId)
        .isFilter('deleted_at', null)
        .order('sort_order', ascending: true);

    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ProjectPhase.fromJson)
        .toList();
  }
}
