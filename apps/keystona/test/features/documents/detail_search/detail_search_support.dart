import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:keystona/features/documents/models/document.dart';
import 'package:keystona/features/documents/models/document_category.dart';
import 'package:keystona/features/documents/models/document_search_hit.dart';
import 'package:keystona/features/documents/models/expiring_document.dart';
import 'package:keystona/features/documents/providers/document_categories_provider.dart';
import 'package:keystona/features/documents/providers/document_links_provider.dart';
import 'package:keystona/features/documents/providers/document_repositories_provider.dart';
import 'package:keystona/features/documents/providers/documents_provider.dart';
import 'package:keystona/features/documents/repositories/document_file_actions.dart';
import 'package:keystona/features/documents/repositories/document_files_repository.dart';
import 'package:keystona/features/documents/repositories/document_mutations_repository.dart';
import 'package:keystona/features/documents/repositories/document_search_repository.dart';
import 'package:keystona/features/documents/repositories/expiring_documents_repository.dart';
import 'package:keystona/services/providers/service_providers.dart';

/// A day from now, date-only, so expiry maths is stable at any hour.
DateTime daysFromNow(int days) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day + days);
}

DocumentCategory category(String id, String name, {String icon = 'shield'}) =>
    DocumentCategory(
      id: id,
      name: name,
      icon: icon,
      color: '#2540D8',
      isSystem: true,
      sortOrder: 0,
      createdAt: DateTime(2026),
    );

final List<DocumentCategory> kCategories = [
  category('c-ins', 'Insurance'),
  category('c-war', 'Warranties & manuals', icon: 'document'),
  category('c-own', 'Ownership', icon: 'home'),
];

const Map<String, int> kCounts = {'c-ins': 2, 'c-war': 4, 'c-own': 3};

Document fixtureDocument({
  String id = 'doc-1',
  String name = 'Northline furnace warranty',
  DateTime? expiration,
  String? notes,
  Map<String, dynamic> metadata = const {},
  List<String> tags = const [],
  String? mimeType = 'application/pdf',
  int? pageCount = 3,
  String ocrStatus = 'pending',
}) =>
    Document(
      id: id,
      propertyId: 'p-1',
      userId: 'u-1',
      name: name,
      categoryId: 'c-war',
      filePath: 'u-1/p-1/northline-warranty.pdf',
      fileSizeBytes: 1468006,
      mimeType: mimeType,
      pageCount: pageCount,
      metadata: metadata,
      tags: tags,
      expirationDate: expiration,
      notes: notes,
      ocrStatus: ocrStatus,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      category: kCategories[1],
    );

/// State behind [FakeDocuments]. Riverpod builds a fresh notifier each time
/// the provider is recreated, so the fake keeps its data here.
class DocumentsStore {
  DocumentsStore(this.document, {this.gate, this.failLoads = 0});

  Document document;
  final Completer<void>? gate;
  int failLoads;

  final List<Map<String, dynamic>> updates = [];
  final List<String> deleted = [];
  final List<String> restored = [];
  int getByIdCalls = 0;
  bool failUpdate = false;
  bool failDelete = false;
  bool failRestore = false;
}

/// Stands in for the list notifier the detail notifier delegates to.
class FakeDocuments extends DocumentsNotifier {
  FakeDocuments(this.store);

  final DocumentsStore store;

  @override
  Future<List<Document>> build() async => [store.document];

  @override
  Future<Document> getById(String id) async {
    store.getByIdCalls++;
    if (store.gate != null) await store.gate!.future;
    if (store.failLoads > 0) {
      store.failLoads--;
      throw Exception('offline');
    }
    return store.document;
  }

  @override
  Future<void> updateDocument(String id, Map<String, dynamic> changes) async {
    if (store.failUpdate) throw Exception('write failed');
    store.updates.add(changes);
    store.document = store.document.copyWith(
      name: changes['name'] as String? ?? store.document.name,
      notes: changes['notes'] as String?,
      tags: (changes['tags'] as List<dynamic>?)?.cast<String>() ??
          store.document.tags,
    );
  }
}

/// Stands in for the database functions behind delete and Undo, recording
/// each call in [DocumentsStore].
class FakeMutations implements DocumentMutationsRepository {
  FakeMutations(this.store);

  final DocumentsStore store;

  @override
  Future<void> softDelete(String documentId) async {
    if (store.failDelete) throw Exception('delete failed');
    store.deleted.add(documentId);
  }

  @override
  Future<void> restore(String documentId) async {
    if (store.failRestore) throw Exception('restore failed');
    store.restored.add(documentId);
  }
}

class FakeCategories extends DocumentCategoriesNotifier {
  @override
  Future<List<DocumentCategory>> build() async => kCategories;
}

class FakeLinks extends DocumentLinksNotifier {
  FakeLinks(this.entries);

  final List<DocumentLinkEntry> entries;

  @override
  Future<List<DocumentLinkEntry>> build(String documentId) async => entries;
}

class FakeFiles implements DocumentFilesRepository {
  @override
  Future<String?> signedUrl(String path) async => 'https://files.test/$path';

  @override
  Future<Uint8List> download(String path) async => Uint8List(0);
}

class FakeActions implements DocumentFileActions {
  final List<String> shared = [];
  final List<Uri> opened = [];

  @override
  Future<void> share({required String url, required String title}) async =>
      shared.add(url);

  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return true;
  }
}

class FakeSearchRepository implements DocumentSearchRepository {
  FakeSearchRepository({this.hits = const [], this.failures = 0});

  List<DocumentSearchHit> hits;
  int failures;
  final List<DocumentSearchQuery> queries = [];
  final List<bool> fullTextFlags = [];

  @override
  Future<List<DocumentSearchHit>> search(
    DocumentSearchQuery query, {
    required bool fullText,
  }) async {
    queries.add(query);
    fullTextFlags.add(fullText);
    if (failures > 0) {
      failures--;
      throw Exception('offline');
    }
    return hits.where((h) {
      final matchesText = query.text.isEmpty ||
          h.name.toLowerCase().contains(query.text.toLowerCase());
      return matchesText;
    }).toList();
  }
}

class FakeExpiringRepository implements ExpiringDocumentsRepository {
  FakeExpiringRepository(this.documents, {this.gate, this.failures = 0});

  final List<ExpiringDocument> documents;
  final Completer<void>? gate;
  int failures;

  @override
  Future<List<ExpiringDocument>> fetch() async {
    if (gate != null) await gate!.future;
    if (failures > 0) {
      failures--;
      throw Exception('offline');
    }
    return documents;
  }
}

DocumentSearchHit hit(
  String id,
  String name, {
  String category = 'Warranties',
  DateTime? expiration,
  String? snippet,
}) =>
    DocumentSearchHit(
      id: id,
      name: name,
      categoryName: category,
      addedAt: DateTime(DateTime.now().year, 1, 28),
      expirationDate: expiration,
      snippet: snippet,
    );

ExpiringDocument expiring(
  String id,
  String name,
  int days, {
  String category = 'Insurance',
  String? provider,
}) =>
    ExpiringDocument(
      id: id,
      name: name,
      categoryName: category,
      categoryIcon: 'shield',
      expirationDate: daysFromNow(days),
      provider: provider,
    );

List<Override> detailOverrides({
  required DocumentsStore documents,
  bool premium = false,
  Future<Map<String, int>> Function(Ref ref)? counts,
  List<DocumentLinkEntry> links = const [],
  FakeActions? actions,
  int quotaUsed = 9,
}) =>
    [
      documentsProvider.overrideWith(() => FakeDocuments(documents)),
      documentMutationsRepositoryProvider.overrideWithValue(
        FakeMutations(documents),
      ),
      documentCategoriesProvider.overrideWith(FakeCategories.new),
      documentCategoryCountsProvider.overrideWith(
        counts ?? (ref) async => kCounts,
      ),
      documentQuotaCountProvider.overrideWith((ref) async => quotaUsed),
      documentLinksProvider.overrideWith(() => FakeLinks(links)),
      documentFilesRepositoryProvider.overrideWithValue(FakeFiles()),
      documentFileActionsProvider.overrideWithValue(actions ?? FakeActions()),
      isPremiumProvider.overrideWithValue(premium),
    ];

List<Override> searchOverrides({
  required FakeSearchRepository repository,
  bool premium = false,
}) =>
    [
      documentSearchRepositoryProvider.overrideWithValue(repository),
      documentCategoriesProvider.overrideWith(FakeCategories.new),
      documentCategoryCountsProvider.overrideWith((ref) async => kCounts),
      documentQuotaCountProvider.overrideWith((ref) async => 9),
      isPremiumProvider.overrideWithValue(premium),
    ];

/// Failed providers stay failed (Riverpod would otherwise retry on a timer),
/// so error states are observable.
Duration? noRetry(int retryCount, Object error) => null;

Widget scopeWrap(List<Override> overrides, Widget app) =>
    ProviderScope(overrides: overrides, retry: noRetry, child: app);

/// Home screen with a button that pushes [screen], so `context.pop()` works.
GoRouter routerFor(Widget screen) => GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => context.push('/screen'),
                  child: const Text('HOME'),
                ),
              ),
            ),
          ),
        ),
        GoRoute(path: '/screen', builder: (_, _) => screen),
        GoRoute(
          path: '/documents/:documentId',
          builder: (_, state) => Scaffold(
            body: Text('detail ${state.pathParameters['documentId']}'),
          ),
        ),
      ],
    );

/// A phone-width viewport tall enough to show a whole screen without
/// scrolling, so tests can tap any control.
const Size kTallPhone = Size(390, 2600);

/// Pumps [screen] behind a home route (so it can pop) and opens it.
Future<void> openScreen(
  WidgetTester tester,
  Widget screen,
  List<Override> overrides,
) async {
  tester.view.physicalSize = kTallPhone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      retry: noRetry,
      child: MaterialApp.router(routerConfig: routerFor(screen)),
    ),
  );
  await tester.tap(find.text('HOME'));
  await tester.pump();
  // Let the page-push transition finish so controls sit at their final spot.
  await tester.pump(kPushTransition);
  await tester.pump();
}

/// Longer than the route push animation.
const Duration kPushTransition = Duration(milliseconds: 600);
