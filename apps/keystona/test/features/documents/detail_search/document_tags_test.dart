import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/documents/models/document_edit.dart';
import 'package:keystona/features/documents/models/document_tags.dart';
import 'package:keystona/features/documents/screens/document_detail_screen.dart';
import 'package:keystona/features/documents/services/document_upload_repository.dart';
import 'package:keystona/features/documents/widgets/edit_metadata_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'detail_search_support.dart';

const _screen = DocumentDetailScreen(documentId: 'doc-1');

DocumentUploadRequest _request(List<String> tags) => DocumentUploadRequest(
      file: File('/nonexistent/x.pdf'),
      mimeType: 'application/pdf',
      name: ' Warranty ',
      categoryId: 'c-war',
      pageCount: 2,
      tags: tags,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('tag rules', () {
    test('clean drops #, commas and padding', () {
      expect(DocumentTags.clean('  ##furnace, '), 'furnace');
    });

    test('adding refuses blanks, repeats, long tags and a full list', () {
      List<String>? add(List<String> c, String t) =>
          DocumentTags.adding(c, t, max: 2, maxLength: 5);
      expect(add(const [], 'a'), ['a']);
      expect(add(const ['a'], '  '), isNull);
      expect(add(const ['a'], 'A'), isNull);
      expect(add(const [], 'toolong'), isNull);
      expect(add(const ['a', 'b'], 'c'), isNull);
    });

    test('fromRow reads the column, falling back to old metadata only when empty', () {
      expect(DocumentTags.fromRow(['a', ' '], ['old']), ['a']);
      expect(DocumentTags.fromRow(const [], ['old', '#x']), ['old', 'x']);
      expect(DocumentTags.fromRow(null, null), isEmpty);
      expect(DocumentTags.fromRow(null, 'not a list'), isEmpty);
    });
  });

  group('writes', () {
    test('upload writes the tags column and no metadata tags', () {
      final row = SupabaseDocumentUploadRepository.insertRow(
        _request(['furnace', '2021 install']),
        userId: 'u-1',
        propertyId: 'p-1',
        path: 'u-1/p-1/x.pdf',
        fileSizeBytes: 10,
      );
      expect(row['tags'], ['furnace', '2021 install']);
      expect(row.containsKey('metadata'), isFalse);
      expect(row['name'], 'Warranty');
    });

    test('an upload with no tags writes an empty array, never null', () {
      final row = SupabaseDocumentUploadRepository.insertRow(
        _request(const []),
        userId: 'u-1',
        propertyId: 'p-1',
        path: 'x',
        fileSizeBytes: 1,
      );
      expect(row['tags'], isEmpty);
    });

    test('an edit sends the full tag list', () {
      const edit = DocumentEdit(name: 'n', categoryId: 'c', tags: ['a', 'b']);
      expect(edit.toChanges()['tags'], ['a', 'b']);
    });
  });

  group('detail and edit', () {
    testWidgets('detail shows tags from the column as chips', (tester) async {
      final docs = DocumentsStore(
        fixtureDocument(tags: ['furnace', '2021 install']),
      );
      await openScreen(tester, _screen, detailOverrides(documents: docs));
      await tester.pump();

      expect(find.text('#furnace'), findsOneWidget);
      expect(find.text('#2021 install'), findsOneWidget);
    });

    testWidgets('an old row with metadata tags still shows them', (tester) async {
      final docs = DocumentsStore(
        fixtureDocument(metadata: {'tags': ['legacy']}),
      );
      await openScreen(tester, _screen, detailOverrides(documents: docs));
      await tester.pump();

      expect(find.text('#legacy'), findsOneWidget);
    });

    testWidgets('the edit sheet starts with the tags and saves new ones', (
      tester,
    ) async {
      final docs = DocumentsStore(fixtureDocument(tags: ['furnace']));
      await openScreen(tester, _screen, detailOverrides(documents: docs));
      await tester.pump();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Tags sit under Notes and above Save.
      Finder inSheet(String text) => find.descendant(
        of: find.byType(EditMetadataSheet),
        matching: find.text(text),
      );
      final notes = tester.getRect(inSheet('NOTES'));
      final tags = tester.getRect(inSheet('TAGS'));
      final save = tester.getRect(inSheet('Save'));
      expect(tags.top, greaterThan(notes.bottom));
      expect(save.top, greaterThan(tags.bottom));
      expect(find.text('furnace'), findsWidgets);

      final field = find.widgetWithText(TextField, '').last;
      await tester.enterText(field, '2021 install');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(docs.updates.single['tags'], ['furnace', '2021 install']);
      expect(find.text('#2021 install'), findsOneWidget);
    });

    testWidgets('removing every tag in the sheet saves an empty list', (
      tester,
    ) async {
      final docs = DocumentsStore(fixtureDocument(tags: ['furnace']));
      await openScreen(tester, _screen, detailOverrides(documents: docs));
      await tester.pump();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Remove tag furnace'));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(docs.updates.single['tags'], isEmpty);
      expect(find.text('#furnace'), findsNothing);
    });
  });
}
