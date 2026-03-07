import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/emergency_contact.dart';
import 'emergency_hub_provider.dart';

part 'contacts_list_provider.g.dart';

/// Loads ALL emergency contacts for the user's property — not just favorites.
///
/// Used by [ContactsListScreen] to show the full list with CRUD.
/// Mutations delegate to [EmergencyHubNotifier] then call [ref.invalidateSelf]
/// so the hub overview badge count stays in sync automatically.
@riverpod
class ContactsListNotifier extends _$ContactsListNotifier {
  @override
  Future<List<EmergencyContact>> build() => _fetchContacts();

  // ── Public interface ──────────────────────────────────────────────────────

  /// Pull-to-refresh: re-fetches from Supabase.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchContacts);
  }

  /// Adds a new contact. Returns the new contact's ID.
  Future<String> addContact(Map<String, dynamic> data) async {
    final newId =
        await ref.read(emergencyHubProvider.notifier).addContact(data);
    ref.invalidateSelf();
    await future;
    return newId;
  }

  /// Updates an existing contact by [id].
  Future<void> updateContact(String id, Map<String, dynamic> data) async {
    await ref
        .read(emergencyHubProvider.notifier)
        .updateContact(id, data);
    ref.invalidateSelf();
    await future;
  }

  /// Hard-deletes a contact by [id].
  Future<void> deleteContact(String id) async {
    await ref.read(emergencyHubProvider.notifier).deleteContact(id);
    ref.invalidateSelf();
    await future;
  }

  // ── Private fetch ─────────────────────────────────────────────────────────

  Future<List<EmergencyContact>> _fetchContacts() async {
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
        .from('emergency_contacts')
        .select(
          'id, property_id, user_id, name, company_name, category, '
          'phone_primary, phone_secondary, email, available_hours, '
          'is_24x7, is_favorite, notes, times_used, created_at, updated_at',
        )
        .eq('property_id', propertyRow['id'] as String)
        .order('is_favorite', ascending: false)
        .order('category')
        .order('name');

    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(EmergencyContact.fromJson)
        .toList();
  }
}
