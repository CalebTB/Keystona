import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/documents/models/renewal_source.dart';
import 'package:keystona/features/documents/providers/document_renewal_provider.dart';
import 'package:keystona/features/documents/providers/document_upload_provider.dart';
import 'package:keystona/features/documents/services/document_renewal_repository.dart';
import 'package:keystona/features/documents/services/document_renewer.dart';

import '../upload/upload_test_support.dart';

/// The document being renewed in these tests.
const RenewalSource kInsurance = RenewalSource(
  id: 'old-1',
  name: 'Homeowners insurance policy',
  categoryId: 'c-insurance',
  categoryName: 'Insurance',
  notes: 'Paper copy is in the blue folder.',
  tags: ['policy', '2025'],
  link: (id: 'sys-1', isAppliance: false, name: 'Furnace', detail: null),
);

/// One call to [DocumentRenewalRepository.renew].
typedef RenewCall = ({DocumentRenewalRequest request, File file});

/// Serves a canned source and records each renewal. [onRenew] lets a test
/// change what other fakes serve once the document is renewed.
class FakeRenewalRepository implements DocumentRenewalRepository {
  FakeRenewalRepository({
    this.source = kInsurance,
    this.failLoads = 0,
    this.renewError,
    this.gate,
    this.onRenew,
  });

  RenewalSource source;
  int failLoads;
  Object? renewError;
  Completer<void>? gate;
  void Function(DocumentRenewalRequest request)? onRenew;

  final List<String> loads = [];
  final List<RenewCall> renewed = [];

  @override
  Future<RenewalSource> load(String documentId) async {
    loads.add(documentId);
    if (gate != null) await gate!.future;
    if (failLoads > 0) {
      failLoads--;
      throw Exception('offline');
    }
    return source;
  }

  @override
  Future<void> renew(
    DocumentRenewalRequest request,
    File file, {
    required void Function(double progress) onProgress,
  }) async {
    onProgress(0.4);
    final e = renewError;
    if (e != null) throw e;
    renewed.add((request: request, file: file));
    onRenew?.call(request);
    onProgress(1);
  }
}

/// A step the fake store was asked to take, in order.
typedef StoreStep = String;

/// Records every storage and database step, and can fail chosen ones.
class FakeRenewalStore implements DocumentRenewalStore {
  FakeRenewalStore({
    this.filePath = 'u-1/p-1/old.pdf',
    this.thumbnailPath = 'u-1/p-1/old-thumb.jpg',
    this.failPut = false,
    this.failUpdate = false,
    this.failRemoveOld = false,
    this.failRemoveNew = false,
  });

  final String filePath;
  final String? thumbnailPath;
  final bool failPut;
  final bool failUpdate;
  final bool failRemoveOld;
  final bool failRemoveNew;

  final List<StoreStep> steps = [];
  String? putPath;
  Map<String, dynamic>? updated;
  String? updatedId;
  List<List<String>> removed = [];

  @override
  Future<({String filePath, String? thumbnailPath})> currentFiles(
    String documentId,
  ) async {
    steps.add('read');
    return (filePath: filePath, thumbnailPath: thumbnailPath);
  }

  @override
  Future<void> putFile(String path, Uint8List bytes, String mimeType) async {
    steps.add('put');
    if (failPut) throw Exception('storage down');
    putPath = path;
  }

  @override
  Future<void> updateRow(String documentId, Map<String, dynamic> changes) async {
    steps.add('update');
    if (failUpdate) throw Exception('row rejected');
    updatedId = documentId;
    updated = changes;
  }

  @override
  Future<void> removeFiles(List<String> paths) async {
    final isOld = paths.contains(filePath);
    steps.add(isOld ? 'remove-old' : 'remove-new');
    if (isOld ? failRemoveOld : failRemoveNew) throw Exception('remove failed');
    removed.add(paths);
  }

  @override
  void requestOcr(String documentId) => steps.add('ocr');
}

List<Override> renewalOverrides({
  FakeRenewalRepository? renewals,
  FakeUploadRepository? uploads,
  bool premium = false,
}) => [
  ...uploadOverrides(premium: premium, repo: uploads),
  documentRenewalRepositoryProvider.overrideWithValue(
    renewals ?? FakeRenewalRepository(),
  ),
];

/// A container whose form is already in renewal mode, with a file picked
/// unless [withFile] is false.
ProviderContainer renewalContainer({
  FakeRenewalRepository? renewals,
  FakeUploadRepository? uploads,
  bool withFile = true,
}) {
  final c = ProviderContainer(
    overrides: renewalOverrides(renewals: renewals, uploads: uploads),
  );
  addTearDown(c.dispose);
  final notifier = c.read(documentUploadProvider.notifier)
    ..applyRenewal(renewals?.source ?? kInsurance);
  if (withFile) {
    notifier.setPickedFile(
      file: File('/nonexistent/renewal.pdf'),
      mimeType: 'application/pdf',
      sizeBytes: 1468006,
      name: 'renewal.pdf',
    );
  }
  return c;
}
