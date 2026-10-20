import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/documents/models/renewal_source.dart';
import 'package:keystona/features/documents/providers/document_renewal_provider.dart';
import 'package:keystona/features/documents/providers/document_upload_provider.dart';
import 'package:keystona/features/documents/services/document_renewal_repository.dart';

import '../upload/upload_test_support.dart';

/// The document being renewed in these tests.
const RenewalSource kInsurance = RenewalSource(
  id: 'old-1',
  name: 'Homeowners insurance policy',
  categoryId: 'c-insurance',
  categoryName: 'Insurance',
  tags: ['policy', '2025'],
  link: (id: 'sys-1', isAppliance: false, name: 'Furnace', detail: null),
);

/// One call to [DocumentRenewalRepository.markReplaced].
typedef MarkCall = ({String documentId, String replacedById, DateTime on});

/// Serves a canned source and records what gets marked replaced.
class FakeRenewalRepository implements DocumentRenewalRepository {
  FakeRenewalRepository({
    this.source = kInsurance,
    this.failLoads = 0,
    this.failMark = false,
    this.gate,
  });

  RenewalSource source;
  int failLoads;
  bool failMark;
  Completer<void>? gate;

  final List<String> loads = [];
  final List<MarkCall> marks = [];

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
  Future<void> markReplaced({
    required String documentId,
    required String replacedById,
    required DateTime on,
  }) async {
    if (failMark) throw Exception('write failed');
    marks.add((documentId: documentId, replacedById: replacedById, on: on));
  }
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

/// A container whose form is already in renewal mode with a file picked.
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
