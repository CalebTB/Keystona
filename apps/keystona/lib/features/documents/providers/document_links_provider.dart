import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';

part 'document_links_provider.g.dart';

/// A single entry representing a reverse link to this document from another
/// entity in the app.
class DocumentLinkEntry {
  const DocumentLinkEntry({
    required this.type,
    required this.label,
    required this.id,
    this.subtitle,
  });

  /// Entity type: `'project'` | `'appliance'` | `'system'`
  final String type;

  /// Display name of the linked entity.
  final String label;

  /// Entity ID used for navigation.
  final String id;

  /// Optional secondary label (e.g. project type).
  final String? subtitle;
}

/// Fetches all reverse links for a document — projects, appliances, and systems
/// that reference this document by ID.
///
/// Runs three queries in parallel and returns a combined flat list.
/// Returns an empty list when no links exist.
@riverpod
class DocumentLinksNotifier extends _$DocumentLinksNotifier {
  @override
  Future<List<DocumentLinkEntry>> build(String documentId) async {
    final results = await Future.wait([
      _fetchProjectLinks(documentId),
      _fetchApplianceLinks(documentId),
      _fetchSystemLinks(documentId),
    ]);

    return [
      ...results[0],
      ...results[1],
      ...results[2],
    ];
  }

  Future<List<DocumentLinkEntry>> _fetchProjectLinks(String documentId) async {
    final rows = await SupabaseService.client
        .from('project_documents')
        .select('project_id, projects(name)')
        .eq('document_id', documentId);

    return rows
        .map((row) {
          final projectId = row['project_id'] as String?;
          final projects = row['projects'] as Map<String, dynamic>?;
          final name = projects?['name'] as String?;
          if (projectId == null || name == null || name.isEmpty) return null;
          return DocumentLinkEntry(
            type: 'project',
            label: name,
            id: projectId,
          );
        })
        .whereType<DocumentLinkEntry>()
        .toList();
  }

  Future<List<DocumentLinkEntry>> _fetchApplianceLinks(
      String documentId) async {
    final rows = await SupabaseService.client
        .from('appliances')
        .select('id, name')
        .eq('linked_warranty_doc_id', documentId)
        .isFilter('deleted_at', null);

    return rows
        .map((row) {
          final id = row['id'] as String?;
          final name = row['name'] as String?;
          if (id == null || name == null || name.isEmpty) return null;
          return DocumentLinkEntry(
            type: 'appliance',
            label: name,
            id: id,
          );
        })
        .whereType<DocumentLinkEntry>()
        .toList();
  }

  Future<List<DocumentLinkEntry>> _fetchSystemLinks(String documentId) async {
    final rows = await SupabaseService.client
        .from('systems')
        .select('id, name')
        .eq('linked_warranty_doc_id', documentId)
        .isFilter('deleted_at', null);

    return rows
        .map((row) {
          final id = row['id'] as String?;
          final name = row['name'] as String?;
          if (id == null || name == null || name.isEmpty) return null;
          return DocumentLinkEntry(
            type: 'system',
            label: name,
            id: id,
          );
        })
        .whereType<DocumentLinkEntry>()
        .toList();
  }
}
