import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keystona/core/router/app_router.dart';
import 'package:keystona/core/widgets/aurora/aurora_button.dart';
import 'package:keystona/core/widgets/aurora/aurora_chip.dart';
import 'package:keystona/features/documents/docs_copy.dart';
import 'package:keystona/features/documents/models/docs_tab_data.dart';
import 'package:keystona/features/documents/models/document_format.dart';
import 'package:keystona/features/documents/models/document_renewal.dart';
import 'package:keystona/features/documents/models/expiring_document.dart';
import 'package:keystona/features/documents/models/expiring_groups.dart';
import 'package:keystona/features/documents/providers/document_repositories_provider.dart';
import 'package:keystona/features/documents/providers/document_upload_provider.dart';
import 'package:keystona/features/documents/providers/expiring_documents_provider.dart';
import 'package:keystona/features/documents/repositories/expiring_documents_repository.dart';
import 'package:keystona/features/documents/screens/documents_expiring_screen.dart';
import 'package:keystona/features/documents/screens/documents_screen.dart';
import 'package:keystona/features/subscription/providers/subscription_provider.dart';
import 'package:keystona/features/documents/widgets/expiring/expiring_ended_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../detail_search/detail_search_support.dart' as detail;
import '../tab/docs_tab_test_support.dart';
import 'renewal_support.dart';

ExpiringDocument _exp(String id, String name, int days) => ExpiringDocument(
  id: id,
  name: name,
  categoryName: 'Insurance',
  categoryIcon: 'shield',
  expirationDate: detail.daysFromNow(days),
);

/// Routes the screen under test at `/` and records every upload location.
class _Harness extends StatelessWidget {
  _Harness({
    required Widget home,
    required List<Override> overrides,
    required this.visited,
  }) : _overrides = overrides,
       _router = GoRouter(
         routes: [
           GoRoute(path: '/', builder: (_, _) => home),
           GoRoute(
             path: AppRoutes.documentsUpload,
             builder: (_, state) {
               visited.add(state.uri.toString());
               return const Scaffold(body: Text('upload route'));
             },
           ),
         ],
       );

  final List<String> visited;
  final List<Override> _overrides;
  final GoRouter _router;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: _overrides,
    retry: (_, _) => null,
    child: MaterialApp.router(routerConfig: _router),
  );
}

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the route carries the document id in the renew query parameter', () {
    final uri = Uri.parse(
      DocumentRenewal.location(AppRoutes.documentsUpload, 'old 1'),
    );
    expect(uri.path, AppRoutes.documentsUpload);
    expect(uri.queryParameters, {DocumentRenewal.queryParam: 'old 1'});
  });

  group('Docs tab', () {
    testWidgets('Upload renewal opens the add flow for that document', (
      tester,
    ) async {
      _tall(tester);
      final visited = <String>[];
      await tester.pumpWidget(
        _Harness(
          home: const DocumentsScreen(),
          overrides: tabOverrides(FakeDocsTabRepository(populatedData())),
          visited: visited,
        ),
      );
      await _settle(tester);
      await tester.tap(find.text(DocsCopy.uploadRenewal));
      await _settle(tester);
      expect(visited, ['/documents/upload?renew=ins']);
    });

    testWidgets('the plus button still opens a blank add flow', (tester) async {
      _tall(tester);
      final visited = <String>[];
      await tester.pumpWidget(
        _Harness(
          home: const DocumentsScreen(),
          overrides: tabOverrides(FakeDocsTabRepository(populatedData())),
          visited: visited,
        ),
      );
      await _settle(tester);
      await tester.tap(find.bySemanticsLabel('Add a document'));
      await _settle(tester);
      expect(visited, ['/documents/upload']);
    });

    testWidgets('Upload renewal is never stopped by a full free vault', (
      tester,
    ) async {
      _tall(tester);
      final visited = <String>[];
      final data = populatedData();
      final full = DocsTabData(
        totalCount: kFreeDocumentLimit,
        recent: data.recent,
        expiring: data.expiring,
      );
      await tester.pumpWidget(
        _Harness(
          home: const DocumentsScreen(),
          overrides: tabOverrides(FakeDocsTabRepository(full)),
          visited: visited,
        ),
      );
      await _settle(tester);
      await tester.tap(find.text(DocsCopy.uploadRenewal));
      await _settle(tester);
      expect(visited, ['/documents/upload?renew=ins']);
      expect(find.text(DocsCopy.limitSheet.headline), findsNothing);
    });
  });

  group('Expiring', () {
    final list = [
      _exp('ins', 'Homeowners insurance policy', 8),
      _exp('wash', 'Halden washer warranty', 65),
      _exp('old1', 'Calder water heater warranty', -400),
    ];

    testWidgets('ended documents read as ended, with the ordinary text', (
      tester,
    ) async {
      _tall(tester);
      await tester.pumpWidget(
        _Harness(
          home: const DocumentsExpiringScreen(),
          overrides: [
            expiringDocumentsRepositoryProvider.overrideWithValue(
              detail.FakeExpiringRepository(list),
            ),
          ],
          visited: [],
        ),
      );
      await _settle(tester);
      expect(find.text('ALREADY ENDED · 1'), findsOneWidget);
      expect(
        find.text(DocsCopy.endedMeta(detail.daysFromNow(-400))),
        findsOneWidget,
      );
      expect(
        DocsCopy.endedMeta(detail.daysFromNow(-400)),
        'ENDED ${DocumentFormat.monthYearUpper(detail.daysFromNow(-400))}'
        ' · KEPT FOR YOUR RECORD',
      );
    });

    testWidgets('ended rows: name over meta on the left, chevron far right', (
      tester,
    ) async {
      _tall(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpiringEndedSection(documents: [list.last], onOpen: (_) {}),
          ),
        ),
      );
      final width = tester.view.physicalSize.width;
      final name = tester.getRect(find.text('Calder water heater warranty'));
      final meta = tester.getRect(find.textContaining('ENDED').last);
      final chevron = tester.getRect(find.byType(Icon));
      expect(meta.top, greaterThan(name.bottom - 1));
      expect(meta.left, closeTo(name.left, 0.5));
      expect(chevron.left, greaterThan(name.right));
      expect(width - chevron.right, lessThan(width * 0.1));
    });

    testWidgets('card: chip and date are right-aligned, name left', (
      tester,
    ) async {
      _tall(tester);
      await tester.pumpWidget(
        _Harness(
          home: const DocumentsExpiringScreen(),
          overrides: [
            expiringDocumentsRepositoryProvider.overrideWithValue(
              detail.FakeExpiringRepository([list.first]),
            ),
          ],
          visited: [],
        ),
      );
      await _settle(tester);
      final width = tester.view.physicalSize.width;
      final name = tester.getRect(find.text('Homeowners insurance policy'));
      final chip = tester.getRect(find.byType(StatusChip));
      final button = tester.getRect(find.byType(PrimaryButton));
      expect(chip.left, greaterThan(name.right));
      expect(chip.right, greaterThan(width * 0.8));
      expect(chip.right, lessThanOrEqualTo(button.right + 0.5));
      expect(button.top, greaterThan(chip.bottom));
      expect(button.left, lessThan(name.left));
    });

    testWidgets("Upload renewal passes the card's document id", (tester) async {
      _tall(tester);
      final visited = <String>[];
      await tester.pumpWidget(
        _Harness(
          home: const DocumentsExpiringScreen(),
          overrides: [
            expiringDocumentsRepositoryProvider.overrideWithValue(
              detail.FakeExpiringRepository(list),
            ),
          ],
          visited: visited,
        ),
      );
      await _settle(tester);
      await tester.tap(find.text(DocsCopy.uploadRenewal));
      await _settle(tester);
      expect(visited, ['/documents/upload?renew=ins']);
    });
  });

  group('after a renewal the document leaves "expiring"', () {
    test('its new end date moves it out of the 90-day groups', () async {
      var days = 8;
      final expiringFetches = <int>[];
      final renewals = FakeRenewalRepository(
        source: kInsurance,
        onRenew: (request) => days = 400,
      );
      final container = ProviderContainer(
        overrides: [
          ...renewalOverrides(renewals: renewals),
          expiringDocumentsRepositoryProvider.overrideWithValue(
            _MovingExpiring(() => [_exp('old-1', 'Policy', days)], expiringFetches),
          ),
        ],
      );
      addTearDown(container.dispose);

      var groups = ExpiringGroups.of(
        await container.read(expiringDocumentsProvider.future),
        ExpiringRange.days90,
      );
      expect(groups.upcoming.single.documents.single.id, 'old-1');

      final notifier = container.read(documentUploadProvider.notifier)
        ..applyRenewal(kInsurance)
        ..setPickedFile(
          file: File('/nonexistent/renewal.pdf'),
          mimeType: 'application/pdf',
          sizeBytes: 10,
          name: 'renewal.pdf',
        )
        ..setExpirationDate(detail.daysFromNow(400));
      await notifier.submit();

      // The list was invalidated and refetched without a pull-to-refresh.
      groups = ExpiringGroups.of(
        await container.read(expiringDocumentsProvider.future),
        ExpiringRange.days90,
      );
      expect(expiringFetches.length, 2);
      expect(groups.upcoming, isEmpty);
      expect(groups.ended, isEmpty);
      final all = ExpiringGroups.of(
        await container.read(expiringDocumentsProvider.future),
        ExpiringRange.all,
      );
      expect(all.upcoming.single.band, ExpiringBand.later);
    });
  });
}

class _MovingExpiring implements ExpiringDocumentsRepository {
  _MovingExpiring(this._docs, this._fetches);

  final List<ExpiringDocument> Function() _docs;
  final List<int> _fetches;

  @override
  Future<List<ExpiringDocument>> fetch() async {
    _fetches.add(_fetches.length);
    return _docs();
  }
}
