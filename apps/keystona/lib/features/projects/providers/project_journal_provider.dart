import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/project_journal_note.dart';

part 'project_journal_provider.g.dart';

/// Columns fetched for journal notes — matches DB columns exactly.
const _kColumns =
    'id, project_id, phase_id, user_id, title, content, note_date, '
    'created_at, updated_at, deleted_at';

/// Loads and manages journal notes for a single project.
@riverpod
class ProjectJournalNotifier extends _$ProjectJournalNotifier {
  @override
  Future<List<ProjectJournalNote>> build(String projectId) => _fetch();

  /// Refetches from Supabase — used by pull-to-refresh.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// Creates a new journal note. Returns the new note's ID.
  Future<String> createNote(Map<String, dynamic> data) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final inserted = await SupabaseService.client
        .from('project_journal_notes')
        .insert({
          ...data,
          'project_id': projectId,
          'user_id': user.id,
        })
        .select('id')
        .single();

    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);

    return inserted['id'] as String;
  }

  /// Updates an existing note by [id].
  Future<void> updateNote(String id, Map<String, dynamic> data) async {
    await SupabaseService.client
        .from('project_journal_notes')
        .update(data)
        .eq('id', id);

    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// Soft-deletes a note by [id].
  Future<void> deleteNote(String id) async {
    await SupabaseService.client
        .from('project_journal_notes')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);

    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<List<ProjectJournalNote>> _fetch() async {
    final rows = await SupabaseService.client
        .from('project_journal_notes')
        .select(_kColumns)
        .eq('project_id', projectId)
        .isFilter('deleted_at', null)
        .order('note_date', ascending: false)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ProjectJournalNote.fromJson)
        .toList();
  }
}
