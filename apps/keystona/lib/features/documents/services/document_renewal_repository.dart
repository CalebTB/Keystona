import '../../../services/supabase_service.dart';
import '../models/document_renewal.dart';
import '../models/document_tags.dart';
import '../models/document_upload_state.dart';
import '../models/renewal_source.dart';

/// Reads the document being renewed and marks it replaced once the new one is
/// saved.
abstract interface class DocumentRenewalRepository {
  /// What the new document starts from. Throws when the document is gone.
  Future<RenewalSource> load(String documentId);

  /// Records on [documentId] that [replacedById] replaced it on [on], keeping
  /// every other metadata key. The document itself is kept.
  Future<void> markReplaced({
    required String documentId,
    required String replacedById,
    required DateTime on,
  });
}

/// [DocumentRenewalRepository] backed by Supabase.
class SupabaseDocumentRenewalRepository implements DocumentRenewalRepository {
  const SupabaseDocumentRenewalRepository();

  @override
  Future<RenewalSource> load(String documentId) async {
    final client = SupabaseService.client;
    final row = await client
        .from('documents')
        .select(
          'id, name, category_id, metadata, tags, linked_system_id, '
          'linked_appliance_id, category:document_categories(name)',
        )
        .eq('id', documentId)
        .isFilter('deleted_at', null)
        .maybeSingle();
    if (row == null) throw StateError('Document not found');

    final metadata = (row['metadata'] as Map<String, dynamic>?) ?? const {};
    return RenewalSource(
      id: row['id'] as String,
      name: row['name'] as String,
      categoryId: row['category_id'] as String,
      categoryName:
          (row['category'] as Map<String, dynamic>?)?['name'] as String? ?? '',
      tags: DocumentTags.fromRow(
        row['tags'],
        metadata[DocumentTags.legacyMetadataKey],
      ),
      link: await _link(
        systemId: row['linked_system_id'] as String?,
        applianceId: row['linked_appliance_id'] as String?,
      ),
    );
  }

  Future<UploadLink?> _link({String? systemId, String? applianceId}) async {
    final appliance = applianceId != null;
    final id = appliance ? applianceId : systemId;
    if (id == null) return null;
    final row = await SupabaseService.client
        .from(appliance ? 'appliances' : 'systems')
        .select('id, name')
        .eq('id', id)
        .isFilter('deleted_at', null)
        .maybeSingle();
    final name = row?['name'];
    if (name is! String || name.isEmpty) return null;
    return (id: id, isAppliance: appliance, name: name, detail: null);
  }

  @override
  Future<void> markReplaced({
    required String documentId,
    required String replacedById,
    required DateTime on,
  }) async {
    final client = SupabaseService.client;
    final row = await client
        .from('documents')
        .select('metadata')
        .eq('id', documentId)
        .single();
    final merged = DocumentRenewal.withReplaced(
      row['metadata'] as Map<String, dynamic>?,
      on: on,
      by: replacedById,
    );
    await client
        .from('documents')
        .update({'metadata': merged})
        .eq('id', documentId);
  }
}
