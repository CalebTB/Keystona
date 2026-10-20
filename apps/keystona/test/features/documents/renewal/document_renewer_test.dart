import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/documents/services/document_renewer.dart';

import 'renewal_support.dart';

DocumentRenewalRequest _request({String? notes = '  new notes  '}) =>
    DocumentRenewalRequest(
      documentId: 'doc-9',
      mimeType: 'application/pdf',
      name: '  Homeowners policy  ',
      categoryId: 'c-insurance',
      pageCount: 3,
      tags: const ['policy'],
      expirationDate: DateTime(2027, 10, 13, 15, 30),
      notes: notes,
      linkedSystemId: 'sys-1',
    );

DocumentRenewer _renewer(FakeRenewalStore store) => DocumentRenewer(
  store,
  newPath: (old, mime) => '${old.substring(0, old.lastIndexOf('/') + 1)}new.pdf',
);

final Uint8List _bytes = Uint8List.fromList([1, 2, 3, 4]);

void main() {
  test('writes exactly these columns onto the same row', () async {
    final store = FakeRenewalStore();
    await _renewer(store).renew(_request(), _bytes, onProgress: (_) {});

    expect(store.updatedId, 'doc-9');
    expect(store.updated, {
      'name': 'Homeowners policy',
      'category_id': 'c-insurance',
      'file_path': 'u-1/p-1/new.pdf',
      'thumbnail_path': null,
      'file_size_bytes': 4,
      'mime_type': 'application/pdf',
      'page_count': 3,
      'ocr_text': null,
      'ocr_status': 'pending',
      'expiration_date': '2027-10-13',
      'expiration_reminded_90': false,
      'expiration_reminded_30': false,
      'expiration_reminded_7': false,
      'notes': 'new notes',
      'linked_system_id': 'sys-1',
      'linked_appliance_id': null,
      'tags': ['policy'],
    });
  });

  test('never touches identity: no id, created_at, owner or metadata', () {
    final changes = DocumentRenewer.changes(
      _request(),
      path: 'x.pdf',
      sizeBytes: 1,
    );
    for (final key in const [
      'id',
      'created_at',
      'property_id',
      'user_id',
      'metadata',
      'deleted_at',
    ]) {
      expect(changes.containsKey(key), isFalse, reason: key);
    }
  });

  test('empty notes are cleared, not saved as blank', () {
    final changes = DocumentRenewer.changes(
      _request(notes: '   '),
      path: 'x.pdf',
      sizeBytes: 1,
    );
    expect(changes['notes'], isNull);
  });

  test('stores the new file, updates the row, then deletes the old files', () async {
    final store = FakeRenewalStore();
    final progress = <double>[];
    await _renewer(store).renew(_request(), _bytes, onProgress: progress.add);

    expect(store.steps, ['read', 'put', 'update', 'ocr', 'remove-old']);
    expect(store.removed, [
      ['u-1/p-1/old.pdf', 'u-1/p-1/old-thumb.jpg'],
    ]);
    // The new object is a different path in the same folder; never an overwrite.
    expect(store.putPath, 'u-1/p-1/new.pdf');
    expect(store.putPath, isNot(store.filePath));
    expect(progress.last, 1);
  });

  test('a document with no thumbnail removes only the old file', () async {
    final store = FakeRenewalStore(thumbnailPath: null);
    await _renewer(store).renew(_request(), _bytes, onProgress: (_) {});
    expect(store.removed, [
      ['u-1/p-1/old.pdf'],
    ]);
  });

  test('a failed upload changes nothing', () async {
    final store = FakeRenewalStore(failPut: true);
    await expectLater(
      _renewer(store).renew(_request(), _bytes, onProgress: (_) {}),
      throwsException,
    );
    expect(store.steps, ['read', 'put']);
    expect(store.updated, isNull);
    expect(store.removed, isEmpty);
  });

  test('a failed update removes the new file and keeps the old one', () async {
    final store = FakeRenewalStore(failUpdate: true);
    await expectLater(
      _renewer(store).renew(_request(), _bytes, onProgress: (_) {}),
      throwsException,
    );
    expect(store.steps, ['read', 'put', 'update', 'remove-new']);
    expect(store.removed, [
      ['u-1/p-1/new.pdf'],
    ]);
  });

  test('a failed cleanup of the new file still reports the update error', () async {
    final store = FakeRenewalStore(failUpdate: true, failRemoveNew: true);
    await expectLater(
      _renewer(store).renew(_request(), _bytes, onProgress: (_) {}),
      throwsA(predicate((e) => e.toString().contains('row rejected'))),
    );
  });

  test('failing to delete the old file is silent', () async {
    final store = FakeRenewalStore(failRemoveOld: true);
    await _renewer(store).renew(_request(), _bytes, onProgress: (_) {});
    expect(store.updated, isNotNull);
    expect(store.steps, ['read', 'put', 'update', 'ocr', 'remove-old']);
  });
}
