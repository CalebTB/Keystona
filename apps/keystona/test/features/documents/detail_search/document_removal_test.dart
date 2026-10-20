import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/documents/models/docs_tab_data.dart';
import 'package:keystona/features/documents/models/document_search_hit.dart';
import 'package:keystona/features/documents/providers/docs_tab_provider.dart';
import 'package:keystona/features/documents/providers/document_detail_provider.dart';
import 'package:keystona/features/documents/providers/document_removal.dart';
import 'package:keystona/features/documents/providers/document_search_provider.dart';
import 'package:keystona/features/documents/providers/documents_provider.dart';
import 'package:keystona/features/documents/providers/expiring_documents_provider.dart';
import 'package:keystona/features/documents/repositories/document_mutations_repository.dart';

import 'detail_search_support.dart';

/// Counts how many times each list was (re)built.
class _Builds {
  int docsTab = 0;
  int expiring = 0;
  int search = 0;
  int counts = 0;
}

const _query = DocumentSearchQuery(text: 'roof');

ProviderContainer _container(DocumentsStore store, _Builds builds) {
  final c = ProviderContainer(
    retry: noRetry,
    overrides: [
      ...detailOverrides(
        documents: store,
        counts: (ref) async {
          builds.counts++;
          return kCounts;
        },
      ),
      docsTabProvider.overrideWith((ref) async {
        builds.docsTab++;
        return const DocsTabData();
      }),
      expiringDocumentsProvider.overrideWith((ref) async {
        builds.expiring++;
        return const [];
      }),
      documentSearchProvider(_query).overrideWith((ref) async {
        builds.search++;
        return const [];
      }),
    ],
  );
  addTearDown(c.dispose);
  // Keep the lists alive the way open screens would.
  c.listen(docsTabProvider, (_, _) {});
  c.listen(expiringDocumentsProvider, (_, _) {});
  c.listen(documentSearchProvider(_query), (_, _) {});
  c.listen(documentCategoryCountsProvider, (_, _) {});
  c.listen(documentsProvider, (_, _) {});
  return c;
}

Future<void> _settle(ProviderContainer c) async {
  await c.read(docsTabProvider.future);
  await c.read(expiringDocumentsProvider.future);
  await c.read(documentSearchProvider(_query).future);
  await c.read(documentCategoryCountsProvider.future);
  await c.read(documentsProvider.future);
}

void main() {
  group('database calls', () {
    test('delete and restore call the functions, never a plain update', () async {
      final calls = <(String, Map<String, dynamic>)>[];
      final repo = SupabaseDocumentMutationsRepository(
        (function, params) async => calls.add((function, params)),
      );

      await repo.softDelete('doc-1');
      await repo.restore('doc-1');

      expect(calls.map((c) => c.$1), ['soft_delete_document', 'restore_document']);
      expect(calls.every((c) => c.$2['p_document_id'] == 'doc-1'), isTrue);
      expect(calls.every((c) => c.$2.length == 1), isTrue);
    });

    test('a database error reaches the caller', () async {
      final repo = SupabaseDocumentMutationsRepository(
        (function, params) async => throw Exception('not yours'),
      );
      expect(() => repo.softDelete('doc-1'), throwsException);
      expect(() => repo.restore('doc-1'), throwsException);
    });
  });

  group('lists after a change', () {
    test('delete refetches every list but not the open detail', () async {
      final store = DocumentsStore(fixtureDocument());
      final builds = _Builds();
      final c = _container(store, builds);
      c.listen(documentDetailProvider('doc-1'), (_, _) {});
      await c.read(documentDetailProvider('doc-1').future);
      await _settle(c);
      final before = (
        builds.docsTab,
        builds.expiring,
        builds.search,
        builds.counts,
      );

      await deleteDocument(c, 'doc-1');
      await _settle(c);

      expect(store.deleted, ['doc-1']);
      expect(builds.docsTab, before.$1 + 1);
      expect(builds.expiring, before.$2 + 1);
      expect(builds.search, before.$3 + 1);
      expect(builds.counts, before.$4 + 1);
      expect(store.getByIdCalls, 1, reason: 'detail must not refetch a deleted row');
    });

    test('restore refetches every list and the detail', () async {
      final store = DocumentsStore(fixtureDocument());
      final builds = _Builds();
      final c = _container(store, builds);
      c.listen(documentDetailProvider('doc-1'), (_, _) {});
      await c.read(documentDetailProvider('doc-1').future);
      await _settle(c);
      final before = (
        builds.docsTab,
        builds.expiring,
        builds.search,
        builds.counts,
      );

      await restoreDocument(c, 'doc-1');
      await _settle(c);
      await c.read(documentDetailProvider('doc-1').future);

      expect(store.restored, ['doc-1']);
      expect(builds.docsTab, before.$1 + 1);
      expect(builds.expiring, before.$2 + 1);
      expect(builds.search, before.$3 + 1);
      expect(builds.counts, before.$4 + 1);
      expect(store.getByIdCalls, 2);
    });

    test('Undo works with no screen left, on the app container', () async {
      final store = DocumentsStore(fixtureDocument());
      final c = ProviderContainer(
        retry: noRetry,
        overrides: detailOverrides(documents: store),
      );
      addTearDown(c.dispose);

      // Nothing is listening: the detail notifier is already disposed.
      await deleteDocument(c, 'doc-1');
      await restoreDocument(c, 'doc-1');

      expect(store.deleted, ['doc-1']);
      expect(store.restored, ['doc-1']);
    });

    test('a failed delete leaves the lists alone and throws', () async {
      final store = DocumentsStore(fixtureDocument())..failDelete = true;
      final builds = _Builds();
      final c = _container(store, builds);
      await _settle(c);
      final tab = builds.docsTab;

      await expectLater(deleteDocument(c, 'doc-1'), throwsException);
      await _settle(c);

      expect(builds.docsTab, tab);
    });

    test('a failed restore throws', () async {
      final store = DocumentsStore(fixtureDocument())..failRestore = true;
      final c = _container(store, _Builds());
      await expectLater(restoreDocument(c, 'doc-1'), throwsException);
    });
  });
}
