import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/project_document_link.dart';

part 'project_documents_provider.g.dart';

@riverpod
class ProjectDocumentsNotifier extends _$ProjectDocumentsNotifier {
  @override
  Future<List<ProjectDocumentLink>> build(String projectId) async {
    return _fetch();
  }

  Future<List<ProjectDocumentLink>> _fetch() async {
    final rows = await SupabaseService.client
        .from('project_documents')
        .select(
          'id, project_id, document_id, link_type, linked_by, created_at, '
          'documents(name, document_types(name))',
        )
        .eq('project_id', projectId)
        .order('created_at', ascending: false);

    return (rows as List).map((r) {
      final raw = r as Map<String, dynamic>;
      final doc = raw['documents'] as Map<String, dynamic>?;
      final docType = doc?['document_types'] as Map<String, dynamic>?;
      return ProjectDocumentLink(
        id: raw['id'] as String,
        projectId: raw['project_id'] as String,
        documentId: raw['document_id'] as String,
        linkType: raw['link_type'] as String,
        linkedBy: raw['linked_by'] as String,
        createdAt: DateTime.parse(raw['created_at'] as String),
        documentName: doc?['name'] as String? ?? 'Unknown',
        documentTypeName: docType?['name'] as String?,
      );
    }).toList();
  }

  Future<void> linkDocument({
    required String documentId,
    required String linkType,
  }) async {
    final client = SupabaseService.client;
    await client.from('project_documents').insert({
      'project_id': projectId,
      'document_id': documentId,
      'link_type': linkType,
      'linked_by': client.auth.currentUser!.id,
    });
    // NOTE: After merge-train lands #52, also invalidate projectDetailProvider(projectId) here.
    ref.invalidateSelf();
    await future;
  }

  Future<void> unlinkDocument(String linkId) async {
    await SupabaseService.client
        .from('project_documents')
        .delete()
        .eq('id', linkId);
    ref.invalidateSelf();
    await future;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Fetches all documents for the current property to power the picker.
@riverpod
Future<List<({String id, String name, String? typeName})>>
    propertyDocumentPickerList(Ref ref) async {
  final client = SupabaseService.client;
  final userId = client.auth.currentUser!.id;

  // Look up the user's property via the properties table.
  final propertyRow = await client
      .from('properties')
      .select('id')
      .eq('user_id', userId)
      .maybeSingle();
  if (propertyRow == null) return [];

  final propertyId = propertyRow['id'] as String;

  final rows = await client
      .from('documents')
      .select('id, name, document_types(name)')
      .eq('property_id', propertyId)
      .filter('deleted_at', 'is', null)
      .order('name', ascending: true);

  return (rows as List).map((r) {
    final raw = r as Map<String, dynamic>;
    final docType = raw['document_types'] as Map<String, dynamic>?;
    return (
      id: raw['id'] as String,
      name: raw['name'] as String,
      typeName: docType?['name'] as String?,
    );
  }).toList();
}
