import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keystona/core/widgets/aurora/aurora_button.dart';
import 'package:keystona/core/widgets/aurora/aurora_toggle_row.dart';
import 'package:keystona/core/widgets/error_view.dart';
import 'package:keystona/features/documents/docs_copy.dart';
import 'package:keystona/features/documents/models/document_upload_state.dart';
import 'package:keystona/features/documents/providers/document_upload_provider.dart';
import 'package:keystona/features/documents/screens/document_upload_screen.dart';
import 'package:keystona/features/documents/widgets/upload/upload_renewal_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/responsive_harness.dart';
import '../upload/upload_test_support.dart';
import 'renewal_support.dart';

const DocumentUploadScreen _renewScreen = DocumentUploadScreen(
  renewDocumentId: 'old-1',
);

Future<void> _open(
  WidgetTester tester, {
  required List<Override> overrides,
  Size size = const Size(390, 1800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = routerFor(_renewScreen);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: overrides,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.tap(find.text('HOME'));
  await tester.pumpAndSettle();
}

TextField _nameField(WidgetTester tester) => tester.widget<TextField>(
  find.byWidgetPredicate((w) => w is TextField && w.maxLines == 1).first,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('responsive', () {
    for (final viewport in kViewports) {
      for (final scale in kTextScales) {
        testWidgets('renewal form @ ${viewport.name}, text x$scale', (
          tester,
        ) async {
          await pumpScreen(
            tester,
            () => _renewScreen,
            viewport: viewport,
            textScale: scale,
            wrap: (app) => scopeWrap(renewalOverrides(), app),
          );
          await tester.pump();
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(find.byType(UploadRenewalBanner), findsOneWidget);
        });
      }
    }
  });

  group('positions', () {
    testWidgets('banner sits first under the header, full width, then FILE', (
      tester,
    ) async {
      await _open(tester, overrides: renewalOverrides());
      final banner = tester.getRect(find.byType(UploadRenewalBanner));
      final header = tester.getRect(find.text('New document.'));
      final file = tester.getTopLeft(find.text('FILE'));
      final screen = tester.view.physicalSize;

      expect(banner.top, greaterThan(header.bottom));
      expect(file.dy, greaterThan(banner.bottom));
      // Spans the content column: same side gutters, nothing floats mid-row.
      expect(banner.left, greaterThan(0));
      expect(banner.left, lessThan(screen.width * 0.1));
      expect(screen.width - banner.right, closeTo(banner.left, 0.5));
      // The renewing line is inside the banner, next to its icon.
      final line = tester.getRect(
        find.text(DocsCopy.renewing('Homeowners insurance policy')),
      );
      expect(banner.contains(line.topLeft), isTrue);
      expect(banner.contains(line.bottomRight), isTrue);
      final icon = tester.getRect(find.byIcon(Icons.autorenew));
      expect(icon.right, lessThan(line.left));
    });

    testWidgets('Save stays pinned to the right edge of the header', (
      tester,
    ) async {
      await _open(tester, overrides: renewalOverrides());
      final save = tester.getRect(find.byType(SaveButton));
      final cancel = tester.getRect(find.text('Cancel'));
      final width = tester.view.physicalSize.width;
      expect(save.right, greaterThan(width * 0.85));
      expect(cancel.left, lessThan(width * 0.15));
    });

    testWidgets('banner stays inside a 320 wide screen at text x2', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _open(
        tester,
        overrides: renewalOverrides(),
        size: const Size(320, 568),
      );
      final banner = tester.getRect(find.byType(UploadRenewalBanner));
      expect(banner.left, greaterThanOrEqualTo(0));
      expect(banner.right, lessThanOrEqualTo(320));
      expect(tester.takeException(), isNull);
    });
  });

  group('renewal mode', () {
    testWidgets('pre-fills from the old document; notes and date are empty', (
      tester,
    ) async {
      final renewals = FakeRenewalRepository();
      await _open(tester, overrides: renewalOverrides(renewals: renewals));

      expect(renewals.loads, ['old-1']);
      expect(
        find.text('Renewing Homeowners insurance policy'),
        findsOneWidget,
      );
      expect(find.text(DocsCopy.renewalKept), findsOneWidget);
      expect(_nameField(tester).controller!.text, kInsurance.name);
      expect(find.text('Insurance'), findsWidgets);
      expect(find.text('policy'), findsOneWidget);
      expect(find.text('2025'), findsOneWidget);
      expect(find.text('Furnace'), findsOneWidget);

      final state = ProviderScope.containerOf(
        tester.element(find.byType(UploadRenewalBanner)),
      ).read(documentUploadProvider);
      expect(state.notes, isEmpty);
      expect(state.expirationDate, isNull);
      expect(state.expiresChoice, isTrue);

      // "It expires" is on and the date is asked for, empty.
      expect(
        tester.widget<AuroraToggleRow>(find.byType(AuroraToggleRow)).value,
        isTrue,
      );
      expect(find.text('MM/DD/YYYY'), findsOneWidget);
      expect(
        find.text(DocsCopy.renewalDateHelp.toUpperCase()),
        findsOneWidget,
      );
      // Primary button keeps the kit label.
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows the skeleton, then an error with retry', (tester) async {
      final renewals = FakeRenewalRepository(failLoads: 1);
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = routerFor(_renewScreen);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: renewalOverrides(renewals: renewals),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.tap(find.text('HOME'));
      await tester.pumpAndSettle();
      expect(find.text(DocsCopy.renewalLoadError), findsOneWidget);
      expect(find.byType(UploadRenewalBanner), findsNothing);

      expect(find.byType(ErrorView), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byType(UploadRenewalBanner), findsOneWidget);
      expect(renewals.loads.length, 2);
    });

    testWidgets('an ordinary add shows no banner', (tester) async {
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = routerFor(const DocumentUploadScreen());
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: renewalOverrides(),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.tap(find.text('HOME'));
      await tester.pumpAndSettle();
      expect(find.byType(UploadRenewalBanner), findsNothing);
    });

    test('picking a file keeps the carried-over fields and the old name', () {
      final c = renewalContainer();
      final s = c.read(documentUploadProvider);
      expect(s.name, kInsurance.name);
      expect(s.categoryId, 'c-insurance');
      expect(s.tags, ['policy', '2025']);
      expect(s.link?.id, 'sys-1');
      expect(s.hasFile, isTrue);

      c.read(documentUploadProvider.notifier).removeFile();
      final after = c.read(documentUploadProvider);
      expect(after.hasFile, isFalse);
      expect(after.renewal?.id, 'old-1');
      expect(after.name, kInsurance.name);
      expect(after.expiresChoice, isTrue);
    });

    test('the new end date is required before Save is live', () {
      final c = renewalContainer();
      final notifier = c.read(documentUploadProvider.notifier);
      expect(c.read(documentUploadProvider).canSave, isFalse);
      notifier.setExpirationDate(DateTime(2027, 10, 13));
      expect(c.read(documentUploadProvider).canSave, isTrue);
      // Turning "It expires" off is still the user's call.
      notifier.setExpires(false);
      expect(c.read(documentUploadProvider).canSave, isTrue);
    });

    test('smart scan fills the date but never the carried-over details', () {
      final c = renewalContainer();
      final notifier = c.read(documentUploadProvider.notifier);
      return notifier.applyScanResult(fullResult()).then((_) {
        final s = c.read(documentUploadProvider);
        expect(s.expirationDate, DateTime(2031, 3, 15));
        expect(s.name, kInsurance.name);
        expect(s.categoryId, 'c-insurance');
        expect(s.link?.id, 'sys-1');
      });
    });
  });

  group('saving', () {
    test('saves the new document, then marks the old one replaced', () async {
      final renewals = FakeRenewalRepository();
      final uploads = FakeUploadRepository();
      final c = renewalContainer(renewals: renewals, uploads: uploads);
      final notifier = c.read(documentUploadProvider.notifier)
        ..setExpirationDate(DateTime(2027, 10, 13));

      await notifier.submit();

      final request = uploads.last!;
      expect(request.name, kInsurance.name);
      expect(request.categoryId, 'c-insurance');
      expect(request.tags, ['policy', '2025']);
      expect(request.linkedSystemId, 'sys-1');
      expect(request.expirationDate, DateTime(2027, 10, 13));
      expect(request.notes, isEmpty);

      expect(renewals.marks, hasLength(1));
      final mark = renewals.marks.single;
      expect(mark.documentId, 'old-1');
      expect(mark.replacedById, 'doc-1');
      final now = DateTime.now();
      expect(mark.on.year, now.year);
      expect(mark.on.month, now.month);
      expect(mark.on.day, now.day);

      final s = c.read(documentUploadProvider);
      expect(s.phase, UploadPhase.success);
      expect(s.renewalMarkFailed, isFalse);
    });

    test('an ordinary add never marks anything', () async {
      final renewals = FakeRenewalRepository();
      final c = ProviderContainer(
        overrides: renewalOverrides(renewals: renewals),
      );
      addTearDown(c.dispose);
      final notifier = c.read(documentUploadProvider.notifier)
        ..setPickedFile(
          file: File('/nonexistent/a.pdf'),
          mimeType: 'application/pdf',
          sizeBytes: 10,
          name: 'a',
        )
        ..useDefaultCategory(kCategories);
      await notifier.submit();
      expect(c.read(documentUploadProvider).phase, UploadPhase.success);
      expect(renewals.marks, isEmpty);
    });

    test('a failed mark does not lose the new document', () async {
      final renewals = FakeRenewalRepository(failMark: true);
      final uploads = FakeUploadRepository();
      final c = renewalContainer(renewals: renewals, uploads: uploads);
      final notifier = c.read(documentUploadProvider.notifier)
        ..setExpirationDate(DateTime(2027, 10, 13));

      await notifier.submit();

      final s = c.read(documentUploadProvider);
      expect(uploads.calls, 1);
      expect(s.phase, UploadPhase.success);
      expect(s.uploadedDocument?.id, 'doc-1');
      expect(s.renewalMarkFailed, isTrue);
      expect(s.failure, isNull);
    });

    test('a failed upload leaves the old document untouched', () async {
      final renewals = FakeRenewalRepository();
      final uploads = FakeUploadRepository()..error = Exception('offline');
      final c = renewalContainer(renewals: renewals, uploads: uploads);
      final notifier = c.read(documentUploadProvider.notifier)
        ..setExpirationDate(DateTime(2027, 10, 13));

      await notifier.submit();

      expect(c.read(documentUploadProvider).failure, UploadFailure.generic);
      expect(renewals.marks, isEmpty);
    });

    testWidgets('the screen warns, without blocking, when the mark failed', (
      tester,
    ) async {
      final renewals = FakeRenewalRepository(failMark: true);
      final overrides = renewalOverrides(renewals: renewals);
      final container = ProviderContainer(overrides: overrides);
      addTearDown(container.dispose);
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = routerFor(_renewScreen);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.tap(find.text('HOME'));
      await tester.pumpAndSettle();
      container.read(documentUploadProvider.notifier)
        ..setPickedFile(
          file: File('/nonexistent/renewal.pdf'),
          mimeType: 'application/pdf',
          sizeBytes: 10,
          name: 'renewal.pdf',
        )
        ..setExpirationDate(DateTime(2027, 10, 13));
      await tester.pump();

      await tester.tap(find.byType(SaveButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text(DocsCopy.renewalMarkFailed), findsOneWidget);
      expect(find.text('detail doc-1'), findsOneWidget);
    });

    testWidgets('Cancel leaves the old document untouched', (tester) async {
      final renewals = FakeRenewalRepository();
      final uploads = FakeUploadRepository();
      await _open(
        tester,
        overrides: renewalOverrides(renewals: renewals, uploads: uploads),
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
      expect(renewals.marks, isEmpty);
      expect(uploads.calls, 0);
    });
  });

  testWidgets('router location carries the document id', (tester) async {
    final seen = <Uri>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/documents/upload',
          builder: (_, state) {
            seen.add(state.uri);
            return DocumentUploadScreen(
              renewDocumentId: state.uri.queryParameters['renew'],
            );
          },
        ),
      ],
      initialLocation: '/documents/upload?renew=old-1',
    );
    addTearDown(router.dispose);
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final renewals = FakeRenewalRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: renewalOverrides(renewals: renewals),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(renewals.loads, ['old-1']);
    expect(find.byType(UploadRenewalBanner), findsOneWidget);
    expect(seen.single.queryParameters, {'renew': 'old-1'});
  });
}
