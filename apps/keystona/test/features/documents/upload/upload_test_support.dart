import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:keystona/features/documents/models/document.dart';
import 'package:keystona/features/documents/models/document_category.dart';
import 'package:keystona/features/documents/models/document_ocr.dart';
import 'package:keystona/features/documents/models/document_quota.dart';
import 'package:keystona/features/documents/models/document_scan.dart';
import 'package:keystona/features/subscription/providers/subscription_provider.dart' show DocumentLimitException;
import 'package:keystona/features/documents/providers/document_categories_provider.dart';
import 'package:keystona/features/documents/providers/document_upload_services_provider.dart';
import 'package:keystona/features/documents/providers/documents_provider.dart';
import 'package:keystona/features/documents/services/document_ocr_service.dart';
import 'package:keystona/features/documents/services/document_scanner.dart';
import 'package:keystona/features/documents/services/document_upload_repository.dart';
import 'package:keystona/features/documents/services/scan_document_builder.dart';
import 'package:keystona/services/providers/service_providers.dart';

DocumentCategory category(
  String id,
  String name, {
  bool system = true,
  int order = 0,
}) => DocumentCategory(
  id: id,
  name: name,
  icon: 'shield',
  color: '#2540D8',
  isSystem: system,
  sortOrder: order,
  createdAt: DateTime(2026),
);

final List<DocumentCategory> kCategories = [
  category('c-warranty', 'Warranty', order: 1),
  category('c-insurance', 'Insurance', order: 2),
  category('c-other', 'Other', order: 3),
  category('c-solar', 'Solar panels', system: false, order: 4),
];

const Map<String, int> kCounts = {'c-warranty': 9, 'c-insurance': 1};

/// Live documents the form shows against the free plan: the same as [kCounts].
const int kQuotaUsed = 10;

class FakeCategories extends DocumentCategoriesNotifier {
  FakeCategories({this.gate, this.fail = false});

  final Completer<void>? gate;
  final bool fail;

  @override
  Future<List<DocumentCategory>> build() async {
    if (gate != null) await gate!.future;
    if (fail) throw Exception('offline');
    return kCategories;
  }
}

/// Records what was saved and plays back progress, a failure or the limit.
class FakeUploadRepository implements DocumentUploadRepository {
  DocumentUploadRequest? last;
  bool? enforced;

  /// Live documents on the free plan; when set, the fake refuses an
  /// enforced upload at the limit, as the real repository does.
  int? used;
  Object? error;
  Completer<void>? gate;
  int calls = 0;

  @override
  Future<Document> upload(
    DocumentUploadRequest request, {
    required bool enforceFreeLimit,
    required void Function(double progress) onProgress,
  }) async {
    calls++;
    last = request;
    enforced = enforceFreeLimit;
    final counted = used;
    if (enforceFreeLimit && counted != null && DocumentQuota.isFull(counted)) {
      throw const DocumentLimitException();
    }
    onProgress(0.4);
    if (gate != null) await gate!.future;
    final e = error;
    if (e != null) throw e;
    onProgress(1);
    return Document(
      id: 'doc-1',
      propertyId: 'p',
      userId: 'u',
      name: request.name,
      categoryId: request.categoryId,
      filePath: 'u/p/doc-1.pdf',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }
}

class FakeScanner implements DocumentScanner {
  FakeScanner({this.fail = false});

  final bool fail;
  int captures = 0;
  final StreamController<ScanEdgeStatus> edges = StreamController.broadcast();

  @override
  bool get detectsEdges => false;

  @override
  Stream<ScanEdgeStatus> get edgeStatus => edges.stream;

  @override
  Widget? buildPreview(BuildContext context) => null;

  @override
  Future<File?> capturePage({required bool flash}) async {
    if (fail) throw Exception('camera');
    captures++;
    return File('/nonexistent/page-$captures.jpg');
  }
}

class FakeScanBuilder implements ScanDocumentBuilder {
  @override
  Future<ScanOutcome> build(List<File> pages, {required bool smart}) async =>
      ScanOutcome(
        file: File('/nonexistent/scan.pdf'),
        mimeType: pages.length > 1 ? 'application/pdf' : 'image/jpeg',
        sizeBytes: 1400000,
        pageCount: pages.length,
        previewFile: pages.first,
        smart: smart,
      );
}

/// A reader the test drives by hand.
class FakeOcr implements DocumentOcrService {
  FakeOcr({this.fail = false});

  final bool fail;
  int reads = 0;
  StreamController<OcrProgress>? controller;

  @override
  Stream<OcrProgress> read(List<File> pages) {
    reads++;
    if (fail) throw UnimplementedError('process-document-ocr');
    controller = StreamController<OcrProgress>();
    return controller!.stream;
  }

  void emit(int completed, OcrResult result) =>
      controller!.add(OcrProgress(completed: completed, result: result));
}

const OcrResult kFullResult = OcrResult(
  textSummary: 'Northline · Limited Warranty Certificate',
  name: 'Northline furnace warranty',
  categoryName: 'Warranty',
  expirationDate: null,
  link: OcrLink(
    id: 'sys-1',
    isAppliance: false,
    name: 'Furnace',
    summary: 'Your furnace — serial 2103A47719',
    matchedOn: 'model NF95-080B',
  ),
);

OcrResult fullResult() => OcrResult(
  textSummary: kFullResult.textSummary,
  name: kFullResult.name,
  categoryName: kFullResult.categoryName,
  expirationDate: DateTime(2031, 3, 15),
  expirationPage: 1,
  link: kFullResult.link,
);

/// Overrides every outside dependency of the add flow.
List<Override> uploadOverrides({
  bool premium = false,
  FakeUploadRepository? repo,
  FakeScanner? scanner,
  FakeOcr? ocr,
  Completer<void>? categoriesGate,
  bool categoriesFail = false,
  String? forwardingAddress,
  DocumentCategoriesNotifier Function()? categories,
  int quotaUsed = kQuotaUsed,
}) => [
  isPremiumProvider.overrideWithValue(premium),
  documentCategoriesProvider.overrideWith(
    categories ??
        () => FakeCategories(gate: categoriesGate, fail: categoriesFail),
  ),
  documentCategoryCountsProvider.overrideWith((ref) async => kCounts),
  documentQuotaCountProvider.overrideWith((ref) async => quotaUsed),
  documentUploadRepositoryProvider.overrideWithValue(
    repo ?? FakeUploadRepository(),
  ),
  documentScannerProvider.overrideWithValue(scanner ?? FakeScanner()),
  scanDocumentBuilderProvider.overrideWithValue(FakeScanBuilder()),
  documentOcrServiceProvider.overrideWithValue(ocr ?? FakeOcr()),
  documentForwardingAddressProvider.overrideWith(
    (ref) async => forwardingAddress ?? (throw StateError('none')),
  ),
];

Widget scopeWrap(List<Override> overrides, Widget app) =>
    ProviderScope(overrides: overrides, child: app);

/// Two-route router so screens that call `context.pop()` have somewhere to go.
GoRouter routerFor(Widget screen, {String home = 'HOME'}) => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => context.push('/screen'),
              child: Text(home),
            ),
          ),
        ),
      ),
    ),
    GoRoute(path: '/screen', builder: (_, _) => screen),
    GoRoute(
      path: '/documents/:documentId',
      builder: (_, state) =>
          Scaffold(body: Text('detail ${state.pathParameters['documentId']}')),
    ),
  ],
);
