import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/theme/aurora_motion.dart';
import 'package:keystona/core/widgets/error_view.dart';
import 'package:keystona/features/documents/models/document_edit.dart';
import 'package:keystona/features/documents/providers/document_links_provider.dart';
import 'package:keystona/features/documents/screens/document_detail_screen.dart';
import 'package:keystona/features/documents/widgets/document_detail_skeleton.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/responsive_harness.dart';
import 'detail_search_support.dart';

DocumentDetailScreen _screen() => const DocumentDetailScreen(documentId: 'doc-1');

DocumentsStore _warranty({Completer<void>? gate}) => DocumentsStore(
      fixtureDocument(
        expiration: daysFromNow(2000),
        notes: 'Paper copy is in the blue folder.',
        ocrStatus: 'complete',
        metadata: const {
          'parts': '10 years',
          'serial': '2103A47719',
          'claim_provider': 'Northline',
          'claim_phone': '1-800-555-0142',
          'claim_page': 3,
        },
      ),
      gate: gate,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('responsive', () {
    testResponsive(
      'loaded detail',
      _screen,
      wrap: (app) => scopeWrap(
        detailOverrides(
          documents: _warranty(),
          links: const [
            DocumentLinkEntry(
              type: DocumentLinkType.system,
              label: 'Furnace',
              id: 's-1',
            ),
          ],
        ),
        app,
      ),
    );

    testResponsive(
      'detail skeleton',
      _screen,
      wrap: (app) => scopeWrap(
        detailOverrides(documents: _warranty(gate: Completer<void>())),
        app,
      ),
    );

    testResponsive(
      'detail without expiry or notes',
      _screen,
      wrap: (app) => scopeWrap(
        detailOverrides(documents: DocumentsStore(fixtureDocument())),
        app,
      ),
    );
  });

  testWidgets('shows a skeleton on the first frame', (tester) async {
    await openScreen(
      tester,
      _screen(),
      detailOverrides(documents: _warranty(gate: Completer<void>())),
    );
    expect(find.byType(DocumentDetailSkeleton), findsOneWidget);
  });

  testWidgets('shows every kit section for a warranty', (tester) async {
    await openScreen(
      tester,
      _screen(),
      detailOverrides(
        documents: _warranty(),
        links: const [
          DocumentLinkEntry(
            type: DocumentLinkType.system,
            label: 'Furnace',
            id: 's-1',
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('Northline furnace warranty'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('COVERAGE'), findsOneWidget);
    expect(find.textContaining('Covered until'), findsOneWidget);
    expect(find.textContaining("We'll remind you on"), findsOneWidget);
    expect(find.text('WHAT IT SAYS'), findsOneWidget);
    expect(find.text('READ BY SMART SCAN'), findsOneWidget);
    expect(find.text('2103A47719'), findsOneWidget);
    expect(find.text('Start a claim'), findsOneWidget);
    expect(find.text('NORTHLINE · 1-800-555-0142 · FROM PAGE 3'), findsOneWidget);
    expect(find.text('LINKED TO'), findsOneWidget);
    expect(find.text('Furnace'), findsOneWidget);
    expect(find.text('NOTES'), findsOneWidget);
    expect(find.text('FILE'), findsOneWidget);
    expect(find.text('northline-warranty.pdf'), findsOneWidget);
    expect(find.textContaining('of 25 used'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    expect(find.text('Replace file'), findsOneWidget);
    expect(find.text('Delete document'), findsOneWidget);
  });

  testWidgets('hides coverage and facts when the document has neither', (
    tester,
  ) async {
    await openScreen(
      tester,
      _screen(),
      detailOverrides(documents: DocumentsStore(fixtureDocument())),
    );
    await tester.pump();

    expect(find.text('COVERAGE'), findsNothing);
    expect(find.text('WHAT IT SAYS'), findsNothing);
    expect(find.text('LINKED TO'), findsNothing);
    expect(find.text('Add a note'), findsOneWidget);
  });

  testWidgets('shows an error with retry that reloads', (tester) async {
    final docs = DocumentsStore(fixtureDocument(), failLoads: 1);
    await openScreen(tester, _screen(), detailOverrides(documents: docs));
    await tester.pump();

    expect(find.byType(ErrorView), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('Northline furnace warranty'), findsOneWidget);
  });

  testWidgets('delete asks first, removes, then Undo restores', (tester) async {
    final docs = _warranty();
    await openScreen(tester, _screen(), detailOverrides(documents: docs));
    await tester.pump();

    final deleteButton = find.text('Delete document');
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Confirm dialog; nothing is deleted yet.
    expect(find.text('Delete this document?'), findsOneWidget);
    expect(docs.deleted, isEmpty);

    await tester.tap(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Delete document'),
      ),
    );
    await tester.pumpAndSettle();

    expect(docs.deleted, ['doc-1']);
    expect(find.text('Document deleted'), findsOneWidget);
    expect(find.text('HOME'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pump();

    expect(docs.restored, ['doc-1']);
  });

  testWidgets('the delete Undo stays ten seconds and says so', (tester) async {
    await openScreen(
      tester,
      _screen(),
      detailOverrides(documents: _warranty()),
    );
    await tester.pump();
    await tester.tap(find.text('Delete document'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Delete document'),
      ),
    );
    await tester.pumpAndSettle();

    final bar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(bar.duration, AuroraDurations.undoDelete);
    expect(bar.duration, isNot(AuroraDurations.undo));
    expect(find.text('Undo within 10 seconds.'), findsOneWidget);
    expect(find.textContaining('5 seconds'), findsNothing);
  });

  testWidgets('storage shows how many documents are used', (tester) async {
    await openScreen(
      tester,
      _screen(),
      detailOverrides(documents: _warranty(), quotaUsed: 7),
    );
    await tester.pump();
    expect(find.text('Encrypted · 7 of 25 used'), findsOneWidget);
  });

  testWidgets('cancelling the confirm dialog deletes nothing', (tester) async {
    final docs = _warranty();
    await openScreen(tester, _screen(), detailOverrides(documents: docs));
    await tester.pump();

    final deleteButton = find.text('Delete document');
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(docs.deleted, isEmpty);
    expect(find.text('Document deleted'), findsNothing);
  });

  testWidgets('edit saves optimistically and sends a date-only end date', (
    tester,
  ) async {
    final docs = _warranty();
    await openScreen(tester, _screen(), detailOverrides(documents: docs));
    await tester.pump();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Edit document'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Furnace warranty');
    final save = find.text('Save');
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(docs.updates, hasLength(1));
    expect(docs.updates.single['name'], 'Furnace warranty');
    expect(docs.updates.single['expiration_date'], matches(r'^\d{4}-\d{2}-\d{2}$'));
    expect(find.text('Furnace warranty'), findsOneWidget);
    expect(find.text('Edit document'), findsNothing);
  });

  testWidgets('a failed edit rolls back and keeps the sheet open', (tester) async {
    final docs = _warranty()..failUpdate = true;
    await openScreen(tester, _screen(), detailOverrides(documents: docs));
    await tester.pump();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Renamed');
    final save = find.text('Save');
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text("Couldn't save changes. Try again."), findsOneWidget);
    expect(find.text('Edit document'), findsOneWidget);
    expect(docs.updates, isEmpty);
  });

  testWidgets('an empty name is rejected before saving', (tester) async {
    final docs = _warranty();
    await openScreen(tester, _screen(), detailOverrides(documents: docs));
    await tester.pump();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '   ');
    final save = find.text('Save');
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text('THIS FIELD IS REQUIRED'), findsOneWidget);
    expect(docs.updates, isEmpty);
  });

  testWidgets('share and download use a signed URL', (tester) async {
    final actions = FakeActions();
    await openScreen(
      tester,
      _screen(),
      detailOverrides(documents: _warranty(), actions: actions),
    );
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Share'));
    await tester.pump();
    final download = find.text('Download');
    await tester.tap(download);
    await tester.pump();

    expect(actions.shared.single, startsWith('https://files.test/'));
    expect(actions.opened.single.toString(), startsWith('https://files.test/'));
  });

  testWidgets('Start a claim dials the claims line', (tester) async {
    final actions = FakeActions();
    await openScreen(
      tester,
      _screen(),
      detailOverrides(documents: _warranty(), actions: actions),
    );
    await tester.pump();

    final claim = find.text('Start a claim');
    await tester.tap(claim);
    await tester.pump();

    expect(actions.opened.single.scheme, 'tel');
    expect(actions.opened.single.path, '1-800-555-0142');
  });

  test('DocumentEdit sends DATE columns without a time', () {
    final changes = DocumentEdit(
      name: 'n',
      categoryId: 'c',
      expirationDate: DateTime(2031, 3, 15, 14, 30),
    ).toChanges();
    expect(changes['expiration_date'], '2031-03-15');
    expect(
      const DocumentEdit(name: 'n', categoryId: 'c').toChanges()['expiration_date'],
      isNull,
    );
  });
}
