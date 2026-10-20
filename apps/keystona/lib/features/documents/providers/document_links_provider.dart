import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import 'document_detail_provider.dart';

part 'document_links_provider.g.dart';

/// Which kind of thing a document is linked to.
enum DocumentLinkType { project, appliance, system }

/// One thing a document is linked to, in either direction.
class DocumentLinkEntry {
  const DocumentLinkEntry({
    required this.type,
    required this.label,
    required this.id,
  });

  final DocumentLinkType type;

  /// Display name of the linked item.
  final String label;

  /// Item id, used for navigation.
  final String id;
}

/// Everything a document is linked to: the system or appliance it points at,
/// plus the projects, appliances and systems that point at it.
///
/// Runs the lookups in parallel and returns one de-duplicated list. An empty
/// list means nothing is linked.
@riverpod
class DocumentLinksNotifier extends _$DocumentLinksNotifier {
  @override
  Future<List<DocumentLinkEntry>> build(String documentId) async {
    final document = await ref.read(documentDetailProvider(documentId).future);

    final results = await Future.wait([
      _linkedItem(
        table: 'systems',
        id: document.linkedSystemId,
        type: DocumentLinkType.system,
      ),
      _linkedItem(
        table: 'appliances',
        id: document.linkedApplianceId,
        type: DocumentLinkType.appliance,
      ),
      _projectLinks(documentId),
      _warrantyLinks('appliances', DocumentLinkType.appliance, documentId),
      _warrantyLinks('systems', DocumentLinkType.system, documentId),
    ]);

    final seen = <String>{};
    return [
      for (final list in results)
        for (final entry in list)
          if (seen.add('${entry.type.name}:${entry.id}')) entry,
    ];
  }

  Future<List<DocumentLinkEntry>> _linkedItem({
    required String table,
    required String? id,
    required DocumentLinkType type,
  }) async {
    if (id == null) return const [];
    final row = await SupabaseService.client
        .from(table)
        .select('id, name')
        .eq('id', id)
        .isFilter('deleted_at', null)
        .maybeSingle();
    return _entries([?row], type);
  }

  Future<List<DocumentLinkEntry>> _projectLinks(String documentId) async {
    final rows = await SupabaseService.client
        .from('project_documents')
        .select('project_id, projects(name)')
        .eq('document_id', documentId);
    return _entries([
      for (final row in rows)
        {
          'id': row['project_id'],
          'name': (row['projects'] as Map<String, dynamic>?)?['name'],
        },
    ], DocumentLinkType.project);
  }

  Future<List<DocumentLinkEntry>> _warrantyLinks(
    String table,
    DocumentLinkType type,
    String documentId,
  ) async {
    final rows = await SupabaseService.client
        .from(table)
        .select('id, name')
        .eq('linked_warranty_doc_id', documentId)
        .isFilter('deleted_at', null);
    return _entries(rows, type);
  }

  List<DocumentLinkEntry> _entries(
    List<Map<String, dynamic>> rows,
    DocumentLinkType type,
  ) {
    return [
      for (final row in rows)
        if (row['id'] is String &&
            row['name'] is String &&
            (row['name'] as String).isNotEmpty)
          DocumentLinkEntry(
            type: type,
            label: row['name'] as String,
            id: row['id'] as String,
          ),
    ];
  }
}
