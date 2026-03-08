import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/project.dart';

part 'projects_provider.g.dart';

/// Loads and manages all projects for the current property.
///
/// Downstream stubs:
///   - [createProject] → implemented by #5.2 (Create & Edit Project)
///   - [updateProject] → implemented by #5.2
///   - [deleteProject] → implemented by #5.2
@riverpod
class ProjectsNotifier extends _$ProjectsNotifier {
  @override
  Future<List<Project>> build() => _fetch();

  /// Refetches from Supabase — used by pull-to-refresh.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  // ── Stubs for downstream issues ──────────────────────────────────────────

  /// [#5.2] Creates a new project. Returns the new project's ID.
  Future<String> createProject(Map<String, dynamic> data) async {
    throw UnimplementedError('createProject() — implemented by issue #5.2');
  }

  /// [#5.2] Updates an existing project by [id].
  Future<void> updateProject(String id, Map<String, dynamic> data) async {
    throw UnimplementedError('updateProject() — implemented by issue #5.2');
  }

  /// [#5.2] Soft-deletes a project by [id].
  Future<void> deleteProject(String id) async {
    throw UnimplementedError('deleteProject() — implemented by issue #5.2');
  }

  // ── Private fetch ─────────────────────────────────────────────────────────

  Future<List<Project>> _fetch() async {
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

    final rows = await SupabaseService.client
        .from('projects')
        .select(
          'id, property_id, user_id, name, description, project_type, status, '
          'estimated_budget, actual_spent, planned_start_date, planned_end_date, '
          'actual_start_date, actual_end_date, cover_photo_path, '
          'phase_count, contractor_ids, created_at, updated_at, deleted_at',
        )
        .eq('property_id', propertyRow['id'] as String)
        .isFilter('deleted_at', null)
        .order('updated_at', ascending: false);

    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Project.fromJson)
        .toList();
  }
}
