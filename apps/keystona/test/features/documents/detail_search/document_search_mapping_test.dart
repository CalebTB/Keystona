import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/documents/models/document_search_hit.dart';
import 'package:keystona/features/documents/repositories/document_search_repository.dart';

import 'detail_search_support.dart';

/// A row shaped like `search_documents` returns it.
Map<String, dynamic> _row({
  String id = 'd1',
  String name = 'Northline furnace warranty',
  String? categoryId = 'c-war',
  String? snippet,
  Object? tags = const <dynamic>[],
  Object? expiration,
}) => {
  'id': id,
  'name': name,
  'category_id': categoryId,
  'document_type_id': null,
  'file_path': 'u/p/x.pdf',
  'thumbnail_path': null,
  'file_size_bytes': 1468006,
  'mime_type': 'application/pdf',
  'page_count': 3, // smallint arrives as an int
  'ocr_status': 'complete',
  'expiration_date': expiration,
  'linked_system_id': null,
  'linked_appliance_id': null,
  'notes': null,
  'tags': tags,
  'created_at': '2026-01-28T10:00:00.000000+00:00',
  'updated_at': '2026-01-28T10:00:00.000000+00:00',
  'snippet': snippet,
  'rank': 0.0607927, // ignored
};

const _names = {'c-war': 'Warranties & manuals', 'c-ins': 'Insurance'};

/// Search that records calls and either answers or throws.
class _Search implements DocumentSearchRepository {
  _Search({this.hits = const [], this.error});

  final List<DocumentSearchHit> hits;
  final Object? error;
  final List<bool> fullTextFlags = [];

  @override
  Future<List<DocumentSearchHit>> search(
    DocumentSearchQuery query, {
    required bool fullText,
  }) async {
    fullTextFlags.add(fullText);
    if (error != null) throw error!;
    return hits;
  }
}

void main() {
  group('search_documents rows', () {
    test('a name-only match has a null snippet', () {
      final hits = SupabaseFullTextSearchRepository.hitsFromRows([
        _row(),
      ], _names);
      expect(hits.single.snippet, isNull);
      expect(hits.single.categoryName, 'Warranties & manuals');
      expect(hits.single.addedAt, DateTime.parse('2026-01-28T10:00:00Z'));
    });

    test('an empty snippet is treated as none', () {
      final hits = SupabaseFullTextSearchRepository.hitsFromRows([
        _row(snippet: ''),
      ], _names);
      expect(hits.single.snippet, isNull);
    });

    test('a ** snippet is kept for highlighting', () {
      final hits = SupabaseFullTextSearchRepository.hitsFromRows([
        _row(snippet: 'covers the **heat exchanger** for 20 years'),
      ], _names);
      expect(hits.single.snippet, 'covers the **heat exchanger** for 20 years');
    });

    test('tags come through, cleaned, and a null array is empty', () {
      final hits = SupabaseFullTextSearchRepository.hitsFromRows([
        _row(tags: ['furnace', '2021 install']),
        _row(id: 'd2', tags: null),
      ], _names);
      expect(hits[0].tags, ['furnace', '2021 install']);
      expect(hits[1].tags, isEmpty);
    });

    test('page_count and rank are ignored and the function order is kept', () {
      final hits = SupabaseFullTextSearchRepository.hitsFromRows([
        _row(id: 'second-by-date', name: 'B'),
        _row(id: 'first-by-date', name: 'A'),
      ], _names);
      expect(hits.map((h) => h.id), ['second-by-date', 'first-by-date']);
    });

    test('the end date is read as a date', () {
      final hits = SupabaseFullTextSearchRepository.hitsFromRows([
        _row(expiration: '2031-03-15'),
      ], _names);
      expect(hits.single.expirationDate, DateTime(2031, 3, 15));
    });

    test('a category scope drops other categories; no scope keeps all', () {
      final rows = [_row(id: 'a'), _row(id: 'b', categoryId: 'c-ins')];
      expect(
        SupabaseFullTextSearchRepository.hitsFromRows(
          rows,
          _names,
          categoryId: 'c-ins',
        ).map((h) => h.id),
        ['b'],
      );
      expect(
        SupabaseFullTextSearchRepository.hitsFromRows(rows, _names).length,
        2,
      );
    });

    test('an uncategorised row has an empty category name', () {
      final hits = SupabaseFullTextSearchRepository.hitsFromRows([
        _row(categoryId: null),
      ], _names);
      expect(hits.single.categoryName, '');
    });

    test('no rows is no hits', () {
      expect(
        SupabaseFullTextSearchRepository.hitsFromRows(const [], _names),
        isEmpty,
      );
    });
  });

  group('full-text with fallback', () {
    const query = DocumentSearchQuery(text: 'roof');

    test('Premium text search answers from the full-text search', () async {
      final full = _Search(hits: [hit('f1', 'Roof warranty', snippet: '**roof**')]);
      final byName = _Search(hits: [hit('n1', 'Roof by name')]);
      final repo = FallbackDocumentSearchRepository(
        fullText: full,
        byName: byName,
      );

      final hits = await repo.search(query, fullText: true);

      expect(hits.single.id, 'f1');
      expect(byName.fullTextFlags, isEmpty);
    });

    test('a failing RPC falls back to name search', () async {
      final full = _Search(error: Exception('function does not exist'));
      final byName = _Search(hits: [hit('n1', 'Roof by name')]);
      final repo = FallbackDocumentSearchRepository(
        fullText: full,
        byName: byName,
      );

      final hits = await repo.search(query, fullText: true);

      expect(full.fullTextFlags, [true], reason: 'full text was tried first');
      expect(hits.single.id, 'n1');
      expect(byName.fullTextFlags, [false]);
    });

    test('if the fallback fails too, that error reaches the screen', () async {
      final repo = FallbackDocumentSearchRepository(
        fullText: _Search(error: Exception('rpc')),
        byName: _Search(error: Exception('offline')),
      );
      await expectLater(repo.search(query, fullText: true), throwsException);
    });

    test('free search never calls full text', () async {
      final full = _Search();
      final byName = _Search(hits: [hit('n1', 'Roof by name')]);
      final repo = FallbackDocumentSearchRepository(
        fullText: full,
        byName: byName,
      );

      await repo.search(query, fullText: false);

      expect(full.fullTextFlags, isEmpty);
      expect(byName.fullTextFlags, [false]);
    });

    test('Premium with only a category skips full text', () async {
      final full = _Search();
      final byName = _Search();
      final repo = FallbackDocumentSearchRepository(
        fullText: full,
        byName: byName,
      );

      await repo.search(
        const DocumentSearchQuery(categoryId: 'c-war'),
        fullText: true,
      );

      expect(full.fullTextFlags, isEmpty);
      expect(byName.fullTextFlags, [false]);
    });
  });
}
