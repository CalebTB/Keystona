import '../../../services/supabase_service.dart';

/// How many live documents the user's property has: what the free plan's
/// limit counts.
abstract interface class DocumentQuotaRepository {
  /// Live documents for [propertyId].
  Future<int> usedFor(String propertyId);

  /// The same count for the signed-in user's property; 0 with no user or
  /// property yet.
  Future<int> used();
}

/// Supabase-backed [DocumentQuotaRepository]. Selects only `id`.
class SupabaseDocumentQuotaRepository implements DocumentQuotaRepository {
  const SupabaseDocumentQuotaRepository();

  @override
  Future<int> usedFor(String propertyId) async {
    final rows = await SupabaseService.client
        .from('documents')
        .select('id')
        .eq('property_id', propertyId)
        .isFilter('deleted_at', null);
    return rows.length;
  }

  @override
  Future<int> used() async {
    final client = SupabaseService.client;
    final user = client.auth.currentUser;
    if (user == null) return 0;
    final property = await client
        .from('properties')
        .select('id')
        .eq('user_id', user.id)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (property == null) return 0;
    return usedFor(property['id'] as String);
  }
}
