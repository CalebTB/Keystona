import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/documents/models/document.dart';
import 'package:keystona/features/documents/models/document_quota.dart';
import 'package:keystona/features/documents/providers/document_repositories_provider.dart';
import 'package:keystona/features/documents/providers/documents_provider.dart';
import 'package:keystona/features/documents/repositories/document_quota_repository.dart';
import 'package:keystona/features/subscription/providers/subscription_provider.dart';
import 'package:keystona/services/providers/service_providers.dart';

/// Answers every property with a canned count and records the asks.
class _FakeQuota implements DocumentQuotaRepository {
  _FakeQuota(this.count);

  final int count;
  final List<String> asked = [];

  @override
  Future<int> usedFor(String propertyId) async {
    asked.add(propertyId);
    return count;
  }

  @override
  Future<int> used() async => count;
}

/// Only [DocumentsNotifier.add] is under test, so the list build is canned.
class _Documents extends DocumentsNotifier {
  @override
  Future<List<Document>> build() async => [
    Document(
      id: 'doc-1',
      propertyId: 'p',
      userId: 'u',
      name: 'n',
      categoryId: 'c',
      filePath: 'u/p/doc-1.pdf',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
  ];
}

ProviderContainer _container(_FakeQuota quota, {bool premium = false}) {
  final c = ProviderContainer(
    overrides: [
      isPremiumProvider.overrideWithValue(premium),
      documentQuotaRepositoryProvider.overrideWithValue(quota),
      documentsProvider.overrideWith(_Documents.new),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('the vault is full at the free limit, never before', () {
    expect(DocumentQuota.isFull(kFreeDocumentLimit - 1), isFalse);
    expect(DocumentQuota.isFull(kFreeDocumentLimit), isTrue);
  });

  group('DocumentsNotifier.add', () {
    const row = {'property_id': 'p-1'};

    test('refuses an add at the limit', () async {
      final c = _container(_FakeQuota(kFreeDocumentLimit));
      await expectLater(
        c.read(documentsProvider.notifier).add(row),
        throwsA(isA<DocumentLimitException>()),
      );
    });

    test('allows an add below the limit', () async {
      final quota = _FakeQuota(kFreeDocumentLimit - 1);
      final c = _container(quota);
      final doc = await c.read(documentsProvider.notifier).add(row);
      expect(doc.id, 'doc-1');
      expect(quota.asked, ['p-1']);
    });

    test('premium is never counted', () async {
      final quota = _FakeQuota(kFreeDocumentLimit);
      final c = _container(quota, premium: true);
      await c.read(documentsProvider.notifier).add(row);
      expect(quota.asked, isEmpty);
    });
  });
}
