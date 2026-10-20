import '../../../services/supabase_service.dart';
import '../models/system_document.dart';
import 'system_documents_repository.dart';

/// [SystemDocumentsRepository] backed by Supabase.
class SupabaseSystemDocumentsRepository implements SystemDocumentsRepository {
  const SupabaseSystemDocumentsRepository();

  @override
  Future<List<SystemDocument>> forSystem(
    String systemId, {
    String? warrantyDocId,
  }) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');
    final property = await SupabaseService.client
        .from('properties')
        .select('id')
        .eq('user_id', user.id)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    final propertyId = property?['id'] as String?;
    if (propertyId == null) return const [];

    final match = warrantyDocId == null
        ? 'linked_system_id.eq.$systemId'
        : 'linked_system_id.eq.$systemId,id.eq.$warrantyDocId';
    final rows = await SupabaseService.client
        .from('documents')
        .select(
          'id, name, mime_type, expiration_date, created_at, '
          'category:document_categories(name)',
        )
        .eq('property_id', propertyId)
        .isFilter('deleted_at', null)
        .or(match)
        .order('created_at', ascending: false);
    return [
      for (final r in rows)
        SystemDocument(
          id: r['id'] as String,
          name: r['name'] as String,
          createdAt: DateTime.parse(r['created_at'] as String),
          categoryName: (r['category'] as Map?)?['name'] as String?,
          mimeType: r['mime_type'] as String?,
          expirationDate: r['expiration_date'] == null
              ? null
              : DateTime.tryParse(r['expiration_date'] as String),
        ),
    ];
  }
}
