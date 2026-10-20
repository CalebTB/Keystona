import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/document_search_hit.dart';
import 'current_property.dart';

/// Data access for document search.
///
/// Screens and notifiers depend on this interface through
/// `documentSearchRepositoryProvider`, so tests swap in a fake.
abstract interface class DocumentSearchRepository {
  /// Documents matching [query], newest first.
  ///
  /// Free search matches document names and category names. With [fullText]
  /// (Premium) it also searches the text inside files and returns snippets.
  Future<List<DocumentSearchHit>> search(
    DocumentSearchQuery query, {
    required bool fullText,
  });
}

class SupabaseDocumentSearchRepository implements DocumentSearchRepository {
  SupabaseDocumentSearchRepository(this._client);

  final SupabaseClient _client;

  /// Most rows a search returns.
  static const int resultLimit = 25;

  static const String _columns =
      'id, name, category_id, created_at, expiration_date, '
      'category:document_categories(name)';

  @override
  Future<List<DocumentSearchHit>> search(
    DocumentSearchQuery query, {
    required bool fullText,
  }) async {
    final propertyId = await currentPropertyId(_client);
    if (propertyId == null) return const [];

    if (fullText && query.text.isNotEmpty) {
      try {
        return await _fullText(propertyId, query);
      } catch (_) {
        // The RPC is missing or failed: fall back to name search so the
        // screen still answers.
      }
    }
    return _byNameAndCategory(propertyId, query);
  }

  Future<List<DocumentSearchHit>> _byNameAndCategory(
    String propertyId,
    DocumentSearchQuery query,
  ) async {
    final text = query.text;

    PostgrestFilterBuilder<List<Map<String, dynamic>>> base() {
      var q = _client
          .from('documents')
          .select(_columns)
          .eq('property_id', propertyId)
          .isFilter('deleted_at', null);
      if (query.categoryId != null) q = q.eq('category_id', query.categoryId!);
      return q;
    }

    if (text.isEmpty) {
      final rows = await base()
          .order('created_at', ascending: false)
          .limit(resultLimit);
      return rows.map(_hit).toList();
    }

    final pattern = '%${_escapeLike(text)}%';
    final categoryRows = await _client
        .from('document_categories')
        .select('id')
        .ilike('name', pattern);
    final categoryIds = categoryRows.map((r) => r['id'] as String).toList();

    final results = await Future.wait([
      base()
          .ilike('name', pattern)
          .order('created_at', ascending: false)
          .limit(resultLimit),
      if (categoryIds.isNotEmpty)
        base()
            .inFilter('category_id', categoryIds)
            .order('created_at', ascending: false)
            .limit(resultLimit),
    ]);

    final byId = <String, DocumentSearchHit>{};
    for (final rows in results) {
      for (final row in rows) {
        byId.putIfAbsent(row['id'] as String, () => _hit(row));
      }
    }
    final merged = byId.values.toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return merged.take(resultLimit).toList();
  }

  Future<List<DocumentSearchHit>> _fullText(
    String propertyId,
    DocumentSearchQuery query,
  ) async {
    final rows = await _client.rpc<List<dynamic>>(
      'search_documents',
      params: {
        'p_property_id': propertyId,
        'p_query': query.text,
        'p_limit': resultLimit,
      },
    );
    final categories = await _client
        .from('document_categories')
        .select('id, name');
    final names = {
      for (final c in categories) c['id'] as String: c['name'] as String,
    };

    final hits = <DocumentSearchHit>[];
    for (final row in rows.cast<Map<String, dynamic>>()) {
      final categoryId = row['category_id'] as String?;
      if (query.categoryId != null && categoryId != query.categoryId) continue;
      final snippet = row['snippet'] as String?;
      hits.add(
        DocumentSearchHit(
          id: row['id'] as String,
          name: row['name'] as String,
          categoryName: names[categoryId] ?? '',
          addedAt: DateTime.parse(row['created_at'] as String),
          expirationDate: _date(row['expiration_date']),
          snippet: (snippet == null || snippet.isEmpty) ? null : snippet,
        ),
      );
    }
    return hits;
  }

  DocumentSearchHit _hit(Map<String, dynamic> row) {
    final category = row['category'] as Map<String, dynamic>?;
    return DocumentSearchHit(
      id: row['id'] as String,
      name: row['name'] as String,
      categoryName: (category?['name'] as String?) ?? '',
      addedAt: DateTime.parse(row['created_at'] as String),
      expirationDate: _date(row['expiration_date']),
    );
  }

  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.parse(value as String);

  /// Escapes LIKE wildcards so user text is matched literally.
  static String _escapeLike(String text) => text
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}
