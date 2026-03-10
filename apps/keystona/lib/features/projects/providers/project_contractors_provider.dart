import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/project_contractor.dart';

part 'project_contractors_provider.g.dart';

/// Manages contractors linked to a single project.
///
/// Contractors come from the shared `emergency_contacts` table (#46).
/// Join data (role, amounts, rating) lives in `project_contractors`.
@riverpod
class ProjectContractorsNotifier extends _$ProjectContractorsNotifier {
  @override
  Future<List<ProjectContractor>> build(String projectId) => _fetch();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  // ── Link / unlink ─────────────────────────────────────────────────────────

  /// Links an existing contact to this project. Returns the new join row ID.
  Future<String> linkContact(
      String contactId, Map<String, dynamic> data) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final inserted = await SupabaseService.client
        .from('project_contractors')
        .insert({
          ...data,
          'project_id': projectId,
          'contact_id': contactId,
          'user_id': user.id,
        })
        .select('id')
        .single();

    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);

    return inserted['id'] as String;
  }

  /// Creates a new contact in the shared pool AND links it to this project.
  Future<String> createAndLink(
    Map<String, dynamic> contactData,
    Map<String, dynamic> linkData,
  ) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Get property_id for the new contact.
    final propertyRow = await SupabaseService.client
        .from('properties')
        .select('id')
        .eq('user_id', user.id)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (propertyRow == null) throw Exception('No property found');

    // Create contact in shared pool.
    final contact = await SupabaseService.client
        .from('emergency_contacts')
        .insert({
          ...contactData,
          'user_id': user.id,
          'property_id': propertyRow['id'] as String,
        })
        .select('id')
        .single();

    final contactId = contact['id'] as String;

    // Link to project.
    return linkContact(contactId, linkData);
  }

  /// Updates project-specific contractor fields by join row [id].
  Future<void> updateContractor(String id, Map<String, dynamic> data) async {
    await SupabaseService.client
        .from('project_contractors')
        .update(data)
        .eq('id', id);

    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// Removes a contractor from the project (deletes join row only).
  Future<void> removeContractor(String id) async {
    await SupabaseService.client
        .from('project_contractors')
        .delete()
        .eq('id', id);

    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  // ── Private fetch ─────────────────────────────────────────────────────────

  Future<List<ProjectContractor>> _fetch() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final rows = await SupabaseService.client
        .from('project_contractors')
        .select(
          'id, project_id, contact_id, user_id, role, contract_amount, '
          'amount_paid, rating, review_notes, created_at, '
          'emergency_contacts(name, phone_primary, phone_secondary, email)',
        )
        .eq('project_id', projectId)
        .order('created_at', ascending: true);

    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_fromRow)
        .toList();
  }

  ProjectContractor _fromRow(Map<String, dynamic> row) {
    final contact =
        (row['emergency_contacts'] as Map<String, dynamic>?) ?? {};
    return ProjectContractor(
      id: row['id'] as String,
      projectId: row['project_id'] as String,
      contactId: row['contact_id'] as String,
      userId: row['user_id'] as String,
      contactName: contact['name'] as String? ?? 'Unknown',
      contactPhone: contact['phone_primary'] as String?,
      contactEmail: contact['email'] as String?,
      role: row['role'] as String?,
      contractAmount: (row['contract_amount'] as num?)?.toDouble(),
      amountPaid: (row['amount_paid'] as num?)?.toDouble(),
      rating: row['rating'] as int?,
      reviewNotes: row['review_notes'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
