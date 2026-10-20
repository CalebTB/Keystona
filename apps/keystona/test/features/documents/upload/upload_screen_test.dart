import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keystona/core/widgets/aurora/aurora_button.dart';
import 'package:keystona/core/widgets/aurora/aurora_pressable.dart';
import 'package:keystona/core/widgets/aurora/aurora_toggle_row.dart';
import 'package:keystona/features/documents/models/document_category.dart';
import 'package:keystona/features/documents/models/document_upload_state.dart';
import 'package:keystona/features/documents/providers/document_categories_provider.dart';
import 'package:keystona/features/documents/providers/document_upload_provider.dart';
import 'package:keystona/features/documents/screens/document_upload_screen.dart';
import 'package:keystona/features/subscription/providers/subscription_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/responsive_harness.dart';
import 'upload_test_support.dart';

/// Starts a screen test from a given upload state.
class _Seeded extends DocumentUploadNotifier {
  _Seeded(this.initial);

  final DocumentUploadState initial;

  @override
  DocumentUploadState build() => initial;
}

class _FlakyCategories extends DocumentCategoriesNotifier {
  static int failures = 0;

  @override
  Future<List<DocumentCategory>> build() async {
    if (failures > 0) {
      failures--;
      throw Exception('offline');
    }
    return kCategories;
  }
}

DocumentUploadState _pdf({String name = 'furnace'}) => DocumentUploadState(
  file: File('/nonexistent/furnace.pdf'),
  mimeType: 'application/pdf',
  fileSizeBytes: 1468006,
  fileLabel: 'furnace.pdf',
  name: name,
  categoryId: 'c-other',
  categoryName: 'Other',
);

DocumentUploadState _scanned() =>
    _pdf(name: 'Northline furnace warranty').copyWith(
      fileLabel: 'Scan · 3 pages',
      pageCount: 3,
      categoryId: 'c-warranty',
      categoryName: 'Warranty',
      expirationDate: DateTime(2031, 3, 15),
      expirationFoundOnPage: 1,
      expiresChoice: true,
      link: (
        id: 'sys-1',
        isAppliance: false,
        name: 'Furnace',
        detail: 'Matched model NF95-080B',
      ),
      tags: const ['furnace', '2021 install'],
      scanFilled: UploadField.values.toSet(),
      scanDetailCount: 4,
    );

List<Override> _seed(DocumentUploadState s, {List<Override> more = const []}) =>
    [
      ...uploadOverrides(),
      documentUploadProvider.overrideWith(() => _Seeded(s)),
      ...more,
    ];

Future<GoRouter> _pumpFlow(
  WidgetTester tester, {
  List<Override>? overrides,
  Size size = const Size(390, 1600),
  ProviderContainer? container,
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = routerFor(const DocumentUploadScreen());
  addTearDown(router.dispose);
  final app = MaterialApp.router(routerConfig: router);
  await tester.pumpWidget(
    container != null
        ? UncontrolledProviderScope(container: container, child: app)
        : ProviderScope(
            // Riverpod retries failed providers by default; show the error.
            retry: (_, _) => null,
            overrides: overrides ?? uploadOverrides(),
            child: app,
          ),
  );
  await tester.tap(find.text('HOME'));
  settle
      ? await tester.pumpAndSettle()
      : await tester.pump(const Duration(seconds: 1));
  return router;
}

/// A real notifier with a file already picked, like after the add-from sheet.
ProviderContainer _pickedContainer({
  FakeUploadRepository? repo,
  bool premium = false,
  String name = 'furnace',
}) {
  final c = ProviderContainer(
    overrides: uploadOverrides(premium: premium, repo: repo),
  );
  addTearDown(c.dispose);
  c
      .read(documentUploadProvider.notifier)
      .setPickedFile(
        file: File('/nonexistent/furnace.pdf'),
        mimeType: 'application/pdf',
        sizeBytes: 1468006,
        name: name,
      );
  return c;
}

Finder _pressable(String label) => find.byWidgetPredicate(
  (w) => w is AuroraPressable && w.semanticLabel == label,
);

Finder _removeTag(String tag) => _pressable('Remove tag $tag');

Finder get _save => find.byType(SaveButton);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('responsive states', () {
    testResponsive(
      'AddDocument, no file',
      () => const DocumentUploadScreen(),
      wrap: (app) => scopeWrap(uploadOverrides(), app),
    );
    testResponsive(
      'AddDocument, picked file',
      () => const DocumentUploadScreen(),
      wrap: (app) => scopeWrap(_seed(_pdf()), app),
    );
    testResponsive(
      'AddDocument, filled in by smart scan',
      () => const DocumentUploadScreen(),
      wrap: (app) => scopeWrap(_seed(_scanned()), app),
    );
    testResponsive(
      'AddDocument, saving',
      () => const DocumentUploadScreen(),
      wrap: (app) => scopeWrap(
        _seed(_scanned().copyWith(phase: UploadPhase.uploading, progress: 0.4)),
        app,
      ),
    );
    testResponsive(
      'AddDocument, loading categories',
      () => const DocumentUploadScreen(),
      wrap: (app) =>
          scopeWrap(uploadOverrides(categoriesGate: Completer<void>()), app),
    );
    testResponsive(
      'AddDocument, categories failed',
      () => const DocumentUploadScreen(),
      wrap: (app) => scopeWrap(uploadOverrides(categoriesFail: true), app),
    );
  });

  testWidgets('no file: Scan, Photos and Files, and Save is off', (
    tester,
  ) async {
    final repo = FakeUploadRepository();
    await _pumpFlow(tester, overrides: uploadOverrides(repo: repo));
    expect(find.text('New document.'), findsOneWidget);
    expect(find.text('FILE'), findsOneWidget);
    expect(find.text('11 OF 25 · FREE PLAN'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);
    expect(find.text('Files'), findsOneWidget);
    expect(
      find.text('PDF, JPG, PNG OR HEIC · UP TO 25 MB · SCAN READS IT FOR YOU'),
      findsOneWidget,
    );
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(repo.calls, 0);
  });

  testWidgets('picked file: the kit fields and copy', (tester) async {
    await _pumpFlow(tester, container: _pickedContainer());
    expect(find.text('furnace'), findsWidgets);
    expect(find.text('PDF · 1.4 MB · JUST NOW'), findsOneWidget);
    expect(find.textContaining('NAME'), findsOneWidget);
    expect(find.textContaining('CATEGORY'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('It expires'), findsOneWidget);
    expect(find.text("WE'LL REMIND YOU 30 DAYS BEFORE"), findsOneWidget);
    expect(find.text('DETAILS'), findsOneWidget);
    expect(find.text('OPTIONAL'), findsOneWidget);
    expect(find.text('LINKED TO'), findsOneWidget);
    expect(find.text('A system or appliance'), findsOneWidget);
    expect(
      find.text('ITS DETAIL PAGE WILL LIST THIS DOCUMENT'),
      findsOneWidget,
    );
    expect(find.text('TAGS'), findsOneWidget);
    expect(find.text('PRESS RETURN OR COMMA TO ADD · UP TO 8'), findsOneWidget);
    expect(find.text('NOTES'), findsOneWidget);
    expect(find.text('PRIVATE TO YOU · STORED ENCRYPTED'), findsOneWidget);
    expect(find.textContaining('Smart scan read'), findsNothing);
    expect(
      find.text('MM/DD/YYYY'),
      findsNothing,
      reason: 'Other does not expire',
    );
  });

  testWidgets('smart scan result: banner, edged fields, reminder line', (
    tester,
  ) async {
    await _pumpFlow(tester, overrides: _seed(_scanned()));
    expect(find.text('Scan · 3 pages'), findsOneWidget);
    expect(find.textContaining('Smart scan read 4 details.'), findsOneWidget);
    expect(find.text('Northline furnace warranty'), findsOneWidget);
    expect(find.text('Warranty'), findsOneWidget);
    expect(find.text('03/15/2031'), findsOneWidget);
    expect(
      find.text('REMINDER ON FEB 13, 2031 · FOUND ON PAGE 1'),
      findsOneWidget,
    );
    expect(find.text('Furnace'), findsOneWidget);
    expect(find.text('MATCHED MODEL NF95-080B'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
    expect(find.text('furnace'), findsOneWidget);
    expect(find.text('2021 install'), findsOneWidget);
  });

  testWidgets('clearing the name turns Save off', (tester) async {
    final repo = FakeUploadRepository();
    final c = _pickedContainer(repo: repo);
    await _pumpFlow(tester, container: c);
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump();
    expect(c.read(documentUploadProvider).canSave, isFalse);
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(repo.calls, 0);
  });

  testWidgets('a category that expires asks for a date before Save works', (
    tester,
  ) async {
    final c = _pickedContainer();
    await _pumpFlow(tester, container: c);
    await tester.tap(find.text('Other'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Warranty'));
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(c.read(documentUploadProvider).categoryName, 'Warranty');
    expect(find.textContaining('EXPIRES'), findsOneWidget);
    expect(find.text('MM/DD/YYYY'), findsOneWidget);
    expect(find.text('PICK THE DATE IT ENDS'), findsOneWidget);
    expect(c.read(documentUploadProvider).canSave, isFalse);

    await tester.tap(find.text('MM/DD/YYYY'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(c.read(documentUploadProvider).expirationDate, isNotNull);
    expect(c.read(documentUploadProvider).canSave, isTrue);
    expect(find.textContaining('REMINDER ON'), findsOneWidget);
  });

  testWidgets('switching It expires off drops the date field', (tester) async {
    final c = ProviderContainer(overrides: _seed(_scanned()));
    addTearDown(c.dispose);
    await _pumpFlow(tester, container: c);
    expect(find.textContaining('EXPIRES'), findsOneWidget);
    await tester.tap(find.byType(AuroraSwitch));
    await tester.pumpAndSettle();
    expect(find.textContaining('EXPIRES'), findsNothing);
    expect(c.read(documentUploadProvider).expirationDate, isNull);
  });

  testWidgets('tags add on comma and return, and remove with the x', (
    tester,
  ) async {
    final c = _pickedContainer();
    await _pumpFlow(tester, container: c);
    final input = find.widgetWithText(TextField, 'Add a tag');
    await tester.enterText(input, 'furnace,');
    await tester.pump();
    expect(_removeTag('furnace'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(1), '2021 install');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(c.read(documentUploadProvider).tags, ['furnace', '2021 install']);
    await tester.tap(_removeTag('furnace'));
    await tester.pump();
    expect(c.read(documentUploadProvider).tags, ['2021 install']);
  });

  testWidgets('removing the file goes back to Scan, Photos and Files', (
    tester,
  ) async {
    await _pumpFlow(tester, container: _pickedContainer());
    await tester.tap(_pressable('Remove file'));
    await tester.pumpAndSettle();
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);
    expect(find.text('Files'), findsOneWidget);
  });

  testWidgets('Cancel goes back and forgets the file', (tester) async {
    final c = _pickedContainer();
    await _pumpFlow(tester, container: c);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
    expect(c.read(documentUploadProvider).hasFile, isFalse);
  });

  testWidgets('Save uploads with progress, then opens the document', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repo = FakeUploadRepository()..gate = gate;
    final c = _pickedContainer(repo: repo);
    await _pumpFlow(tester, container: c);
    await tester.tap(_save);
    await tester.pump();
    await tester.pump();
    expect(repo.calls, 1);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      0.4,
    );
    // Cancel is off while the file is on its way.
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(find.text('New document.'), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('detail doc-1'), findsOneWidget);
    expect(repo.last?.name, 'furnace');
  });

  testWidgets('a failed upload keeps the form and Save tries again', (
    tester,
  ) async {
    final repo = FakeUploadRepository()..error = Exception('offline');
    final c = _pickedContainer(repo: repo);
    await _pumpFlow(tester, container: c);
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.text('Upload failed'), findsOneWidget);
    expect(find.text('New document.'), findsOneWidget);
    expect(find.text('PDF · 1.4 MB · JUST NOW'), findsOneWidget);
    repo.error = null;
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.text('detail doc-1'), findsOneWidget);
    expect(repo.calls, 2);
  });

  testWidgets('the header shows where this document puts the user', (
    tester,
  ) async {
    await _pumpFlow(tester, overrides: uploadOverrides(quotaUsed: 8));
    expect(find.text('9 OF 25 · FREE PLAN'), findsOneWidget);
  });

  testWidgets('a plain add at the limit still offers the upgrade', (
    tester,
  ) async {
    final repo = FakeUploadRepository()..used = kFreeDocumentLimit;
    await _pumpFlow(tester, container: _pickedContainer(repo: repo));
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(repo.enforced, isTrue);
    expect(find.text('Unlock Unlimited Documents'), findsOneWidget);
    expect(find.text('New document.'), findsOneWidget);
  });

  testWidgets('a full free plan offers the upgrade', (tester) async {
    final repo = FakeUploadRepository()..error = const DocumentLimitException();
    await _pumpFlow(tester, container: _pickedContainer(repo: repo));
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.text('Unlock Unlimited Documents'), findsOneWidget);
    expect(find.text('New document.'), findsOneWidget);
  });

  testWidgets('categories loading shows the skeleton, not the form', (
    tester,
  ) async {
    final gate = Completer<void>();
    await _pumpFlow(
      tester,
      overrides: uploadOverrides(categoriesGate: gate),
      settle: false,
    );
    expect(find.textContaining('NAME'), findsNothing);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Scan'), findsOneWidget);
  });

  testWidgets('categories error shows retry, and retry recovers', (
    tester,
  ) async {
    _FlakyCategories.failures = 1;
    await _pumpFlow(
      tester,
      overrides: uploadOverrides(categories: _FlakyCategories.new),
    );
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Scan'), findsOneWidget);
  });
}
