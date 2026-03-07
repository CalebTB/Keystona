import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/emergency_contact.dart';
import '../models/emergency_hub_overview.dart';
import '../models/insurance_policy.dart';
import '../models/utility_shutoff.dart';

part 'emergency_hub_provider.g.dart';

/// Loads the Emergency Hub overview: shutoff statuses + favorite contacts +
/// insurance policy summaries.
///
/// Auto-disposed when the Emergency Hub is not visible.
/// Downstream issues invalidate this provider after mutations:
///   - #45 (Utility Shutoff Setup) calls [ref.invalidateSelf()] after save
///   - #46 (Emergency Contacts) calls [ref.invalidateSelf()] after add/edit/delete
///   - #47 (Insurance Quick Reference) calls [ref.invalidateSelf()] after save
@riverpod
class EmergencyHubNotifier extends _$EmergencyHubNotifier {
  @override
  Future<EmergencyHubOverview> build() => _fetchOverview();

  /// Refetches from Supabase — used by pull-to-refresh.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchOverview);
  }

  // ── Stubs for downstream issues ───────────────────────────────────────────

  /// [#45] Returns the shutoff record for [utilityType] ('water'/'gas'/'electrical'),
  /// or null if not yet set up.
  Future<UtilityShutoff?> getShutoff(String utilityType) =>
      throw UnimplementedError('getShutoff() — implemented by #45 Utility Shutoff Setup');

  /// [#45] Creates or updates the shutoff record for a given utility type.
  Future<void> saveShutoff(Map<String, dynamic> data) =>
      throw UnimplementedError('saveShutoff() — implemented by #45 Utility Shutoff Setup');

  /// [#46] Adds a new emergency contact and refreshes the hub.
  Future<String> addContact(Map<String, dynamic> data) =>
      throw UnimplementedError('addContact() — implemented by #46 Emergency Contacts');

  /// [#46] Updates an existing contact by [id].
  Future<void> updateContact(String id, Map<String, dynamic> data) =>
      throw UnimplementedError('updateContact() — implemented by #46 Emergency Contacts');

  /// [#46] Soft-deletes a contact by [id].
  Future<void> deleteContact(String id) =>
      throw UnimplementedError('deleteContact() — implemented by #46 Emergency Contacts');

  /// [#46, #5.5] Returns all contacts suitable for a picker (projects contractor
  /// picker + emergency quick-dial). Returns sorted by favorite, then name.
  Future<List<EmergencyContact>> getContactsForPicker() =>
      throw UnimplementedError('getContactsForPicker() — implemented by #46 Emergency Contacts');

  /// [#47] Adds a new insurance policy and refreshes the hub.
  Future<void> addInsurance(Map<String, dynamic> data) =>
      throw UnimplementedError('addInsurance() — implemented by #47 Insurance Quick Reference');

  /// [#47] Updates an existing insurance policy by [id].
  Future<void> updateInsurance(String id, Map<String, dynamic> data) =>
      throw UnimplementedError('updateInsurance() — implemented by #47 Insurance Quick Reference');

  // ── Private fetch ─────────────────────────────────────────────────────────

  Future<EmergencyHubOverview> _fetchOverview() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Resolve the user's property ID first (reuse home profile pattern).
    final propertyRow = await SupabaseService.client
        .from('properties')
        .select('id')
        .eq('user_id', user.id)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (propertyRow == null) throw _NoPropertyException();

    final propertyId = propertyRow['id'] as String;

    // Fetch all three data sets in parallel.
    final results = await Future.wait([
      // 1. All utility shutoffs for this property.
      SupabaseService.client
          .from('utility_shutoffs')
          .select(
            'id, property_id, user_id, utility_type, location_description, '
            'is_complete, valve_type, turn_direction, gas_company_phone, '
            'main_breaker_location, main_breaker_amperage, circuit_directory, '
            'tools_required, special_instructions, created_at, updated_at',
          )
          .eq('property_id', propertyId)
          .order('utility_type'),

      // 2. Favorites contacts (up to 3 shown in preview).
      SupabaseService.client
          .from('emergency_contacts')
          .select(
            'id, property_id, user_id, name, company_name, category, '
            'phone_primary, phone_secondary, email, available_hours, '
            'is_24x7, is_favorite, notes, times_used, created_at, updated_at',
          )
          .eq('property_id', propertyId)
          .eq('is_favorite', true)
          .order('name')
          .limit(3),

      // 3. All contacts (for total count badge).
      SupabaseService.client
          .from('emergency_contacts')
          .select('id')
          .eq('property_id', propertyId),

      // 4. All active insurance policies.
      SupabaseService.client
          .from('insurance_info')
          .select(
            'id, property_id, user_id, policy_type, carrier, policy_number, '
            'coverage_amount, deductible, premium_annual, agent_name, '
            'agent_phone, agent_email, claims_phone, effective_date, '
            'expiration_date, linked_document_id, created_at, updated_at, deleted_at',
          )
          .eq('property_id', propertyId)
          .isFilter('deleted_at', null)
          .order('policy_type'),
    ]);

    final shutoffRows = results[0] as List<dynamic>;
    final favContactRows = results[1] as List<dynamic>;
    final allContactRows = results[2] as List<dynamic>;
    final policyRows = results[3] as List<dynamic>;

    return EmergencyHubOverview(
      shutoffs: shutoffRows
          .cast<Map<String, dynamic>>()
          .map(UtilityShutoff.fromJson)
          .toList(),
      favoriteContacts: favContactRows
          .cast<Map<String, dynamic>>()
          .map(EmergencyContact.fromJson)
          .toList(),
      totalContactCount: allContactRows.length,
      policies: policyRows
          .cast<Map<String, dynamic>>()
          .map(InsurancePolicy.fromJson)
          .toList(),
    );
  }
}

/// Thrown when the user has no property — shows empty state.
class _NoPropertyException implements Exception {
  const _NoPropertyException();
}

typedef NoEmergencyPropertyException = _NoPropertyException;
