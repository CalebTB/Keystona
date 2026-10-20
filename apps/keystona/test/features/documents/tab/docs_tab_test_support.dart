import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keystona/core/router/app_router.dart';
import 'package:keystona/features/documents/models/deleted_category.dart';
import 'package:keystona/features/documents/models/docs_tab_data.dart';
import 'package:keystona/features/documents/models/document_category.dart';
import 'package:keystona/features/documents/providers/docs_tab_provider.dart';
import 'package:keystona/features/documents/providers/document_categories_provider.dart';
import 'package:keystona/features/documents/repositories/docs_tab_repository.dart';
import 'package:keystona/features/documents/repositories/document_categories_repository.dart';
import 'package:keystona/services/providers/service_providers.dart';

import '../../../support/responsive_harness.dart';

final DateTime _now = DateTime.now();

/// [days] calendar days from today at midday (a plain `add(Duration)` can
/// land on the previous date across a daylight-saving change).
DateTime inDays(int days) =>
    DateTime(_now.year, _now.month, _now.day + days, 12);

DocsTabItem item(
  String id,
  String name, {
  String? category = 'Maintenance',
  String? icon,
  int? expiresInDays,
  int addedDaysAgo = 3,
}) => DocsTabItem(
  id: id,
  name: name,
  createdAt: _now.subtract(Duration(days: addedDaysAgo)),
  categoryName: category,
  categoryIcon: icon,
  expirationDate: expiresInDays == null ? null : inDays(expiresInDays),
);

/// A vault with one urgent document, one soon, and a far one.
DocsTabData populatedData() {
  final urgent = item(
    'ins',
    'Homeowners insurance policy',
    category: 'Insurance',
    icon: 'shield',
    expiresInDays: 9,
    addedDaysAgo: 100,
  );
  final soon = item(
    'dish',
    'Bosch dishwasher warranty',
    category: 'Warranties',
    expiresInDays: 45,
  );
  final far = item(
    'roof',
    'Roof 20-year warranty',
    category: 'Warranties',
    expiresInDays: 3000,
  );
  return DocsTabData(
    totalCount: 12,
    recent: [item('dryer', 'Dryer vent service receipt'), far, soon, urgent],
    expiring: [urgent, soon, far],
    emptyCategoryNames: const ['Tax & financial'],
  );
}

/// Serves canned data, or waits on [gate], or fails.
class FakeDocsTabRepository implements DocsTabRepository {
  FakeDocsTabRepository(this.data, {this.gate});

  DocsTabData data;
  Completer<void>? gate;
  Object? failWith;
  int loads = 0;
  final List<String> reminders = [];

  @override
  Future<DocsTabData> load() async {
    loads++;
    if (gate != null) await gate!.future;
    if (failWith != null) throw failWith!;
    return data;
  }

  @override
  Future<void> scheduleRenewalReminder(String documentId) {
    reminders.add(documentId);
    throw UnimplementedError('scheduleRenewalReminder()');
  }
}

DocumentCategory category(
  String id,
  String name, {
  bool system = false,
  int sortOrder = 0,
  String icon = 'folder',
}) => DocumentCategory(
  id: id,
  name: name,
  icon: icon,
  color: '#071238',
  isSystem: system,
  sortOrder: sortOrder,
  createdAt: DateTime(2026),
  userId: system ? null : 'u1',
);

List<DocumentCategory> standardCategories() => [
  category('s1', 'Warranty', system: true, sortOrder: 1),
  category('s2', 'Manual', system: true, sortOrder: 2),
  category('s3', 'Receipt', system: true, sortOrder: 3),
  category('s9', 'Other', system: true, sortOrder: 10),
];

/// In-memory categories: nothing reaches Supabase.
class FakeCategoriesRepository implements DocumentCategoriesRepository {
  FakeCategoriesRepository(this.categories, {this.counts = const {}});

  List<DocumentCategory> categories;
  Map<String, int> counts;
  Completer<void>? gate;
  Object? failWith;
  final List<String> calls = [];

  @override
  Future<List<DocumentCategory>> fetchAll() async {
    if (gate != null) await gate!.future;
    if (failWith != null) throw failWith!;
    return [...categories];
  }

  @override
  Future<Map<String, int>> documentCounts() async => counts;

  @override
  Future<DocumentCategory> create({
    required String name,
    required String icon,
    required String color,
    required int sortOrder,
  }) async {
    calls.add('create:$name:$icon');
    return category('new-$name', name, sortOrder: sortOrder, icon: icon);
  }

  @override
  Future<void> update(
    String id, {
    required String name,
    required String icon,
    required String color,
  }) async {
    calls.add('update:$id:$name:$icon');
  }

  @override
  Future<DeletedCategory> delete(
    DocumentCategory category, {
    required String moveToId,
  }) async {
    calls.add('delete:${category.id}:$moveToId');
    return DeletedCategory(
      category: category,
      movedDocumentIds: const ['d1'],
      movedToCategoryId: moveToId,
    );
  }

  @override
  Future<void> restore(DeletedCategory deleted) async {
    calls.add('restore:${deleted.category.id}');
  }

  @override
  Future<void> reorder(Map<String, int> sortOrders) async {
    calls.add(
      'reorder:${sortOrders.entries.map((e) => '${e.key}=${e.value}').join(',')}',
    );
  }
}

/// Routes the screen under test at `/` and records where it navigates.
class RoutedApp extends StatelessWidget {
  RoutedApp({
    super.key,
    required Widget home,
    List<Override> overrides = const [],
    List<String>? visited,
  }) : _overrides = overrides,
       _router = GoRouter(
         routes: [
           GoRoute(path: '/', builder: (_, _) => home),
           for (final path in [
             AppRoutes.documentsUpload,
             AppRoutes.documentsSearch,
             AppRoutes.documentsExpiring,
             AppRoutes.documentsCategories,
             AppRoutes.documentDetail,
           ])
             GoRoute(
               path: path,
               builder: (context, state) {
                 visited?.add(state.uri.path);
                 return Scaffold(body: Text('route ${state.uri.path}'));
               },
             ),
         ],
       );

  final List<Override> _overrides;
  final GoRouter _router;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: _overrides,
    child: MaterialApp.router(routerConfig: _router),
  );
}

List<Override> tabOverrides(
  FakeDocsTabRepository repository, {
  bool premium = false,
}) => [
  docsTabRepositoryProvider.overrideWithValue(repository),
  isPremiumProvider.overrideWithValue(premium),
];

List<Override> categoryOverrides(
  FakeCategoriesRepository repository, {
  bool premium = true,
}) => [
  documentCategoriesRepositoryProvider.overrideWithValue(repository),
  isPremiumProvider.overrideWithValue(premium),
];

/// Like `testResponsive`, but lets async providers resolve before asserting
/// no layout exception, so loaded states are what gets measured.
void testResponsiveLoaded(
  String description,
  Widget Function() build, {
  required Widget Function(Widget app) wrap,
}) {
  for (final viewport in kViewports) {
    for (final scale in kTextScales) {
      testWidgets('$description @ ${viewport.name}, text x$scale', (
        tester,
      ) async {
        await pumpScreen(
          tester,
          build,
          viewport: viewport,
          textScale: scale,
          wrap: wrap,
        );
        await tester.pump();
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
