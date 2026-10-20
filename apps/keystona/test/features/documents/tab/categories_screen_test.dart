import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/widgets/aurora/aurora_pressable.dart';
import 'package:keystona/features/documents/categories_copy.dart';
import 'package:keystona/features/documents/models/deleted_category.dart';
import 'package:keystona/features/documents/models/document_category.dart';
import 'package:keystona/features/documents/screens/document_categories_screen.dart';
import 'package:keystona/features/documents/widgets/categories/categories_skeleton.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/responsive_harness.dart';
import 'docs_tab_test_support.dart';

List<_Cat> _three() => [
  _Cat('c1', 'Solar panels', 1, 6, 'sun'),
  _Cat('c2', 'Pool & spa', 2, 4, 'droplet'),
  _Cat('c3', 'Vehicle & garage', 3, 2, 'car'),
];

class _Cat {
  _Cat(this.id, this.name, this.order, this.docs, this.icon);
  final String id;
  final String name;
  final int order;
  final int docs;
  final String icon;
}

FakeCategoriesRepository _repo({List<_Cat>? custom}) {
  final cats = custom ?? _three();
  return FakeCategoriesRepository(
    [
      ...standardCategories(),
      for (final c in cats)
        category(c.id, c.name, sortOrder: 20 + c.order, icon: c.icon),
    ],
    counts: {for (final c in cats) c.id: c.docs},
  );
}

Widget _app(FakeCategoriesRepository repo, {bool premium = true}) => RoutedApp(
  home: const DocumentCategoriesScreen(),
  overrides: categoryOverrides(repo, premium: premium),
);

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _load(
  WidgetTester tester,
  FakeCategoriesRepository repo, {
  bool premium = true,
}) async {
  _tall(tester);
  await tester.pumpWidget(_app(repo, premium: premium));
  await _settle(tester);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await _settle(tester);
}

/// [text] inside the category list (the Undo snackbar repeats the name).
Finder _inList(String text) => find.descendant(
  of: find.byType(ReorderableListView),
  matching: find.text(text),
);

/// Scrolls the page until [finder] can be tapped.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 30 && finder.hitTestable().evaluate().isEmpty; i++) {
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -150),
    );
    await tester.pump();
  }
}

bool _enabled(WidgetTester tester, String label) {
  final pressable = find
      .ancestor(of: find.text(label), matching: find.byType(AuroraPressable))
      .first;
  return tester.widget<AuroraPressable>(pressable).onTap != null;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Your categories states', () {
    testWidgets('skeleton on the first frame', (tester) async {
      final repo = _repo()..gate = Completer<void>();
      _tall(tester);
      await tester.pumpWidget(_app(repo));
      await tester.pump();
      expect(find.byType(CategoriesSkeleton), findsOneWidget);
      repo.gate!.complete();
      await _settle(tester);
      expect(find.byType(CategoriesSkeleton), findsNothing);
      expect(find.text('Your categories'), findsOneWidget);
    });

    testWidgets('shows the kit copy, rows and counts', (tester) async {
      await _load(tester, _repo());
      expect(find.text('DOCUMENT CATEGORIES'), findsOneWidget);
      expect(find.text('★ PREMIUM'), findsOneWidget);
      expect(find.text('Your categories'), findsOneWidget);
      expect(find.text(CategoriesCopy.intro), findsOneWidget);
      expect(find.text('YOURS · 3 OF 10'), findsOneWidget);
      expect(find.text('Solar panels'), findsOneWidget);
      expect(find.text('6 DOCUMENTS'), findsOneWidget);
      expect(find.text('2 DOCUMENTS'), findsOneWidget);
      expect(find.text('NEW CATEGORY'), findsOneWidget);
      expect(find.text('4 standard categories'), findsOneWidget);
      expect(find.text('Edit'), findsNWidgets(3));
    });

    testWidgets('no categories of your own yet', (tester) async {
      await _load(tester, _repo(custom: []));
      expect(find.text('YOURS · 0 OF 10'), findsOneWidget);
      expect(find.byType(ReorderableListView), findsNothing);
    });

    testWidgets('the standard categories open and name themselves', (
      tester,
    ) async {
      await _load(tester, _repo());
      expect(find.textContaining('can’t be renamed or removed'), findsNothing);
      await _tap(tester, find.text('4 standard categories'));
      expect(
        find.text(
          'Warranty · Manual · Receipt · Other. '
          'These can’t be renamed or removed.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('error shows retry and retry loads', (tester) async {
      final repo = _repo()..failWith = StateError('offline');
      await _load(tester, repo);
      expect(find.text(CategoriesCopy.loadError), findsOneWidget);
      repo.failWith = null;
      await _tap(tester, find.text('Try again'));
      expect(find.text('Your categories'), findsOneWidget);
    });
  });

  group('Add a category', () {
    testWidgets('Add stays off until a name is typed', (tester) async {
      await _load(tester, _repo());
      expect(_enabled(tester, 'Add'), isFalse);
      await tester.enterText(find.byType(TextField), 'Generator');
      await tester.pump();
      expect(_enabled(tester, 'Add'), isTrue);
    });

    testWidgets('creates the category with the chosen icon and clears', (
      tester,
    ) async {
      final repo = _repo();
      await _load(tester, repo);
      await tester.enterText(find.byType(TextField), '  Generator ');
      await tester.pump();
      await _tap(tester, find.bySemanticsLabel('Icon bolt'));
      await _tap(tester, find.text('Add'));
      expect(repo.calls, ['create:Generator:bolt']);
      expect(find.text('Generator'), findsOneWidget);
      expect(find.text('YOURS · 4 OF 10'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });

    testWidgets('free plan: Add opens the upgrade sheet instead', (
      tester,
    ) async {
      final repo = _repo();
      await _load(tester, repo, premium: false);
      await _tap(tester, find.text('Add'));
      expect(repo.calls, isEmpty);
      expect(find.text(CategoriesCopy.premiumSheet.headline), findsOneWidget);
    });

    testWidgets('ten of your own is the limit', (tester) async {
      final ten = [
        for (var i = 1; i <= 10; i++) _Cat('c$i', 'Cat $i', i, 0, 'folder'),
      ];
      await _load(tester, _repo(custom: ten));
      await tester.enterText(find.byType(TextField), 'One more');
      await tester.pump();
      expect(find.text('YOURS · 10 OF 10'), findsOneWidget);
      expect(_enabled(tester, 'Add'), isFalse);
    });
  });

  group('Delete a category', () {
    Future<void> openPanel(
      WidgetTester tester,
      FakeCategoriesRepository repo, [
      String name = 'Pool & spa',
    ]) async {
      await _load(tester, repo);
      await _tap(tester, find.bySemanticsLabel('Delete $name'));
    }

    testWidgets('asks where the documents go; nothing is deleted yet', (
      tester,
    ) async {
      final repo = _repo();
      await openPanel(tester, repo);
      expect(find.text('Delete “Pool & spa”?'), findsOneWidget);
      expect(
        find.text('Its 4 documents won’t be deleted. Move them to:'),
        findsOneWidget,
      );
      for (final name in ['Other', 'Manual', 'Receipt']) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text('Keep it'), findsOneWidget);
      expect(repo.calls, isEmpty);
    });

    testWidgets('Keep it closes the panel', (tester) async {
      await openPanel(tester, _repo());
      await _tap(tester, find.text('Keep it'));
      expect(find.text('Delete “Pool & spa”?'), findsNothing);
    });

    testWidgets('moves to Other by default, with Undo', (tester) async {
      final repo = _repo();
      await openPanel(tester, repo);
      await _tap(tester, find.text('Delete & move'));
      expect(repo.calls, ['delete:c2:s9']);
      expect(_inList('Pool & spa'), findsNothing);
      expect(find.text('YOURS · 2 OF 10'), findsOneWidget);
      expect(find.text(CategoriesCopy.deleted), findsOneWidget);

      await _tap(tester, find.text('Undo'));
      expect(repo.calls.last, 'restore:c2');
      expect(_inList('Pool & spa'), findsOneWidget);
    });

    testWidgets('moves to the chosen category', (tester) async {
      final repo = _repo();
      await openPanel(tester, repo);
      await _tap(tester, find.text('Manual'));
      await _tap(tester, find.text('Delete & move'));
      expect(repo.calls, ['delete:c2:s2']);
    });

    testWidgets('an empty category deletes without a move choice', (
      tester,
    ) async {
      final repo = _repo(custom: [_Cat('c1', 'Spare', 1, 0, 'folder')]);
      await openPanel(tester, repo, 'Spare');
      expect(find.text('It has no documents.'), findsOneWidget);
      expect(find.text('Manual'), findsNothing);
      await _tap(tester, find.text('Delete'));
      expect(repo.calls.single, startsWith('delete:c1:'));
    });

    testWidgets('a failed delete brings the row back', (tester) async {
      final repo = _repo();
      await openPanel(tester, repo);
      repo.failWith = null;
      final failing = _FailingDelete(repo);
      await tester.pumpWidget(_app(failing));
      await _settle(tester);
      await _tap(tester, find.bySemanticsLabel('Delete Pool & spa'));
      await _tap(tester, find.text('Delete & move'));
      expect(find.text('Pool & spa'), findsOneWidget);
      expect(find.text(CategoriesCopy.deleteFailed), findsOneWidget);
    });
  });

  group('Rename and reorder', () {
    testWidgets('Edit renames through the sheet', (tester) async {
      final repo = _repo();
      await _load(tester, repo);
      await _tap(tester, find.text('Edit').first);
      expect(find.text('Edit category'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'Solar array');
      await tester.pump();
      await _tap(tester, find.text('Save'));
      expect(repo.calls, ['update:c1:Solar array:sun']);
      expect(find.text('Solar array'), findsOneWidget);
      expect(find.text('Solar panels'), findsNothing);
    });

    testWidgets('an empty name is refused in the sheet', (tester) async {
      final repo = _repo();
      await _load(tester, repo);
      await _tap(tester, find.text('Edit').first);
      await tester.enterText(find.byType(TextField).last, '   ');
      await _tap(tester, find.text('Save'));
      expect(
        find.text(CategoriesCopy.nameRequired.toUpperCase()),
        findsOneWidget,
      );
      expect(repo.calls, isEmpty);
    });

    testWidgets('dragging a row saves the new order', (tester) async {
      final repo = _repo();
      await _load(tester, repo);
      tester
          .widget<ReorderableListView>(find.byType(ReorderableListView))
          .onReorder(0, 3);
      await _settle(tester);
      expect(repo.calls, ['reorder:c2=21,c3=22,c1=23']);
      final y = {
        for (final n in ['Solar panels', 'Pool & spa', 'Vehicle & garage'])
          n: tester.getTopLeft(find.text(n)).dy,
      };
      expect(y['Pool & spa']! < y['Vehicle & garage']!, isTrue);
      expect(y['Vehicle & garage']! < y['Solar panels']!, isTrue);
    });
  });

  group('Your categories responsive', () {
    testResponsiveLoaded(
      'populated',
      () => const DocumentCategoriesScreen(),
      wrap: (app) =>
          ProviderScope(overrides: categoryOverrides(_repo()), child: app),
    );
    testResponsiveLoaded(
      'empty',
      () => const DocumentCategoriesScreen(),
      wrap: (app) => ProviderScope(
        overrides: categoryOverrides(_repo(custom: [])),
        child: app,
      ),
    );
    testResponsiveLoaded(
      'error',
      () => const DocumentCategoriesScreen(),
      wrap: (app) => ProviderScope(
        overrides: categoryOverrides(_repo()..failWith = StateError('x')),
        child: app,
      ),
    );
    testResponsiveLoaded(
      'loading',
      () => const DocumentCategoriesScreen(),
      wrap: (app) => ProviderScope(
        overrides: categoryOverrides(_repo()..gate = Completer<void>()),
        child: app,
      ),
    );

    for (final viewport in kViewports) {
      for (final scale in kTextScales) {
        testWidgets('delete panel open @ ${viewport.name}, text x$scale', (
          tester,
        ) async {
          await pumpScreen(
            tester,
            () => const DocumentCategoriesScreen(),
            viewport: viewport,
            textScale: scale,
            wrap: (app) => ProviderScope(
              overrides: categoryOverrides(_repo()),
              child: app,
            ),
          );
          await _settle(tester);
          final delete = find.byIcon(Icons.delete_outline).at(1);
          await _scrollTo(tester, delete);
          await tester.tap(delete);
          await _settle(tester);
          await _scrollTo(tester, find.text('Delete & move'));
          expect(find.text('Delete & move'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}

/// Delegates to [FakeCategoriesRepository] but fails deletes.
class _FailingDelete extends FakeCategoriesRepository {
  _FailingDelete(FakeCategoriesRepository base)
    : super(base.categories, counts: base.counts);

  @override
  Future<DeletedCategory> delete(
    DocumentCategory category, {
    required String moveToId,
  }) => Future.error(StateError('nope'));
}
