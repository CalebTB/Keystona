import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/document_search_hit.dart';
import '../models/document_tags.dart';
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

/// Premium search with a safety net: when the full-text search fails, the
/// screen still answers with a name and category search.
class FallbackDocumentSearchRepository implements DocumentSearchRepository {
  const FallbackDocumentSearchRepository({
    required this.fullText,
    required this.byName,
  });

  /// Used when `fullText` is requested and there is text to search for.
  final DocumentSearchRepository fullText;

  /// Used for free search, category-only search and as the fallback.
  final DocumentSearchRepository byName;

  @override
  Future<List<DocumentSearchHit>> search(
    DocumentSearchQuery query, {
    required bool fullText,
  }) async {
    if (fullText && query.text.isNotEmpty) {
      try {
        return await this.fullText.search(query, fullText: true);
      } catch (error) {
        // Never log the query or the error message: both can hold user text.
        debugPrint(
          'Document full-text search failed (${error.runtimeType}); '
          'using name search.',
        );
      }
    }
    return byName.search(query, fullText: false);
  }
}

/// Free search: document names and category names, newest first.
class SupabaseNameSearchRepository implements DocumentSearchRepository {
  SupabaseNameSearchRepository(this._client);

  final SupabaseClient _client;

  /// Most rows a search returns.
  static const int resultLimit = 25;

  static const String _columns =
      'id, name, category_id, created_at, expiration_date, tags, '
      'category:document_categories(name)';

  @override
  Future<List<DocumentSearchHit>> search(
    DocumentSearchQuery query, {
    required bool fullText,
  }) async {
    final propertyId = await currentPropertyId(_client);
    if (propertyId == null) return const [];
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

  DocumentSearchHit _hit(Map<String, dynamic> row) {
    final category = row['category'] as Map<String, dynamic>?;
    return DocumentSearchHit(
      id: row['id'] as String,
      name: row['name'] as String,
      categoryName: (category?['name'] as String?) ?? '',
      addedAt: DateTime.parse(row['created_at'] as String),
      expirationDate: _parseDate(row['expiration_date']),
      tags: DocumentTags.fromRow(row['tags']),
    );
  }

  /// Escapes LIKE wildcards so user text is matched literally.
  static String _escapeLike(String text) => text
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

DateTime? _parseDate(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

/// Premium search: the `search_documents` function matches the text inside
/// files, notes and tags as well as names, and returns a snippet.
///
/// Row shape (extra columns such as `page_count` and `rank` are ignored):
/// `id, name, category_id, created_at, expiration_date, tags, snippet` where
/// `snippet` is null when only the name matched.
class SupabaseFullTextSearchRepository implements DocumentSearchRepository {
  SupabaseFullTextSearchRepository(this._client);

  final SupabaseClient _client;

  /// Most rows a search returns.
  static const int resultLimit = SupabaseNameSearchRepository.resultLimit;

  @override
  Future<List<DocumentSearchHit>> search(
    DocumentSearchQuery query, {
    required bool fullText,
  }) async {
    final propertyId = await currentPropertyId(_client);
    if (propertyId == null) return const [];

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
    return hitsFromRows(rows, names, categoryId: query.categoryId);
  }

  /// Maps `search_documents` rows to hits, keeping the function's order and
  /// dropping rows outside [categoryId] when one is given.
  static List<DocumentSearchHit> hitsFromRows(
    List<dynamic> rows,
    Map<String, String> categoryNames, {
    String? categoryId,
  }) {
    final hits = <DocumentSearchHit>[];
    for (final row in rows.cast<Map<String, dynamic>>()) {
      final rowCategory = row['category_id'] as String?;
      if (categoryId != null && rowCategory != categoryId) continue;
      final snippet = row['snippet'] as String?;
      hits.add(
        DocumentSearchHit(
          id: row['id'] as String,
          name: row['name'] as String,
          categoryName: categoryNames[rowCategory] ?? '',
          addedAt: DateTime.parse(row['created_at'] as String),
          expirationDate: _parseDate(row['expiration_date']),
          snippet: (snippet == null || snippet.isEmpty) ? null : snippet,
          tags: DocumentTags.fromRow(row['tags']),
        ),
      );
    }
    return hits;
  }
}
