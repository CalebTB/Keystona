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
import 'package:keystona/features/subscription/providers/subscription_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/responsive_harness.dart';
import '../upload/upload_test_support.dart';
import 'renewal_support.dart';

const DocumentUploadScreen _renewScreen = DocumentUploadScreen(
  renewDocumentId: 'old-1',
);

final DateTime _newEnd = DateTime(2027, 10, 13);

Future<ProviderContainer> _open(
  WidgetTester tester, {
  required List<Override> overrides,
  Widget screen = _renewScreen,
  Size size = const Size(390, 1800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = routerFor(screen);
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
  return ProviderScope.containerOf(tester.element(find.byType(Scaffold).last));
}

TextField _nameField(WidgetTester tester) => tester.widget<TextField>(
  find.byWidgetPredicate((w) => w is TextField && w.maxLines == 1).first,
);

void _pickFile(ProviderContainer c) =>
    c.read(documentUploadProvider.notifier).setPickedFile(
      file: File('/nonexistent/renewal.pdf'),
      mimeType: 'application/pdf',
      sizeBytes: 10,
      name: 'renewal.pdf',
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('responsive', () {
    for (final viewport in activeViewports) {
      for (final scale in scalesFor(viewport)) {
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
      final width = tester.view.physicalSize.width;

      expect(banner.top, greaterThan(header.bottom));
      expect(file.dy, greaterThan(banner.bottom));
      expect(banner.left, greaterThan(0));
      expect(banner.left, lessThan(width * 0.1));
      expect(width - banner.right, closeTo(banner.left, 0.5));
      final line = tester.getRect(
        find.text(DocsCopy.renewing('Homeowners insurance policy')),
      );
      expect(banner.contains(line.topLeft), isTrue);
      expect(banner.contains(line.bottomRight), isTrue);
      expect(tester.getRect(find.byIcon(Icons.autorenew)).right, lessThan(line.left));
      // The replace-the-file line sits under the renewing line.
      final replaces = tester.getRect(find.text(DocsCopy.renewalReplacesFile));
      expect(replaces.top, greaterThanOrEqualTo(line.bottom - 1));
      expect(replaces.left, closeTo(line.left, 0.5));
    });

    testWidgets('Save stays on the right of the header, Cancel on the left', (
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

  group('renewal form', () {
    testWidgets('pre-fills everything including notes; the end date is empty', (
      tester,
    ) async {
      final renewals = FakeRenewalRepository();
      final c = await _open(
        tester,
        overrides: renewalOverrides(renewals: renewals),
      );

      expect(renewals.loads, ['old-1']);
      expect(find.text('Renewing Homeowners insurance policy'), findsOneWidget);
      expect(find.text(DocsCopy.renewalReplacesFile), findsOneWidget);
      expect(_nameField(tester).controller!.text, kInsurance.name);
      expect(find.text('Insurance'), findsWidgets);
      expect(find.text('policy'), findsOneWidget);
      expect(find.text('2025'), findsOneWidget);
      expect(find.text('Furnace'), findsOneWidget);
      expect(find.text('Paper copy is in the blue folder.'), findsOneWidget);

      final state = c.read(documentUploadProvider);
      expect(state.notes, kInsurance.notes);
      expect(state.expirationDate, isNull);
      expect(state.expires, isTrue);
      expect(find.text('MM/DD/YYYY'), findsOneWidget);
      expect(
        find.text(DocsCopy.renewalDateHelp.toUpperCase()),
        findsOneWidget,
      );
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('the header shows no count and no limit message', (
      tester,
    ) async {
      await _open(tester, overrides: renewalOverrides());
      expect(find.textContaining('FREE PLAN'), findsNothing);
      expect(find.textContaining(' OF 25'), findsNothing);
    });

    testWidgets('a plain add still shows where it puts the user', (
      tester,
    ) async {
      await _open(
        tester,
        screen: const DocumentUploadScreen(),
        overrides: renewalOverrides(),
      );
      expect(find.text('11 OF 25 · FREE PLAN'), findsOneWidget);
    });

    testWidgets('shows an error with retry when the document cannot load', (
      tester,
    ) async {
      final renewals = FakeRenewalRepository(failLoads: 1);
      await _open(tester, overrides: renewalOverrides(renewals: renewals));
      expect(find.text(DocsCopy.renewalLoadError), findsOneWidget);
      expect(find.byType(UploadRenewalBanner), findsNothing);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byType(ErrorView), findsNothing);
      expect(find.byType(UploadRenewalBanner), findsOneWidget);
      expect(renewals.loads.length, 2);
    });

    testWidgets('an ordinary add shows no banner', (tester) async {
      await _open(
        tester,
        screen: const DocumentUploadScreen(),
        overrides: renewalOverrides(),
      );
      expect(find.byType(UploadRenewalBanner), findsNothing);
    });

    testWidgets('the expires switch cannot be turned off in a renewal', (
      tester,
    ) async {
      final c = await _open(tester, overrides: renewalOverrides());
      c.read(documentUploadProvider.notifier).setExpires(false);
      await tester.pump();
      expect(c.read(documentUploadProvider).expires, isTrue);
      expect(
        tester.widget<AuroraToggleRow>(find.byType(AuroraToggleRow)).value,
        isTrue,
      );
    });
  });

  group('required fields', () {
    test('a new file is required to save', () {
      final c = renewalContainer(withFile: false);
      c.read(documentUploadProvider.notifier).setExpirationDate(_newEnd);
      expect(c.read(documentUploadProvider).canSave, isFalse);
      _pickFile(c);
      expect(c.read(documentUploadProvider).canSave, isTrue);
    });

    test('the new end date is required to save', () {
      final c = renewalContainer();
      expect(c.read(documentUploadProvider).canSave, isFalse);
      c.read(documentUploadProvider.notifier).setExpirationDate(_newEnd);
      expect(c.read(documentUploadProvider).canSave, isTrue);
    });

    test('picking a file keeps the carried-over fields, notes and name', () {
      final c = renewalContainer();
      final s = c.read(documentUploadProvider);
      expect(s.name, kInsurance.name);
      expect(s.categoryId, 'c-insurance');
      expect(s.tags, ['policy', '2025']);
      expect(s.notes, kInsurance.notes);
      expect(s.link?.id, 'sys-1');

      c.read(documentUploadProvider.notifier).removeFile();
      final after = c.read(documentUploadProvider);
      expect(after.hasFile, isFalse);
      expect(after.renewal?.id, 'old-1');
      expect(after.notes, kInsurance.notes);
    });

    test('smart scan fills the date but never the carried-over details', () async {
      final c = renewalContainer();
      await c.read(documentUploadProvider.notifier).applyScanResult(fullResult());
      final s = c.read(documentUploadProvider);
      expect(s.expirationDate, DateTime(2031, 3, 15));
      expect(s.name, kInsurance.name);
      expect(s.categoryId, 'c-insurance');
      expect(s.link?.id, 'sys-1');
    });
  });

  group('saving', () {
    test('updates the SAME document and creates no new one', () async {
      final renewals = FakeRenewalRepository();
      final uploads = FakeUploadRepository();
      final c = renewalContainer(renewals: renewals, uploads: uploads);
      final notifier = c.read(documentUploadProvider.notifier)
        ..setExpirationDate(_newEnd);
      notifier.setNotes('Renewed through Oct 2027');

      await notifier.submit();

      expect(uploads.calls, 0, reason: 'no insert');
      expect(renewals.renewed, hasLength(1));
      final call = renewals.renewed.single;
      expect(call.request.documentId, 'old-1');
      expect(call.file.path, '/nonexistent/renewal.pdf');
      expect(call.request.mimeType, 'application/pdf');
      expect(call.request.name, kInsurance.name);
      expect(call.request.categoryId, 'c-insurance');
      expect(call.request.tags, ['policy', '2025']);
      expect(call.request.linkedSystemId, 'sys-1');
      expect(call.request.notes, 'Renewed through Oct 2027');
      expect(call.request.expirationDate, _newEnd);

      final s = c.read(documentUploadProvider);
      expect(s.phase, UploadPhase.success);
      expect(s.savedDocumentId, 'old-1');
    });

    test('a renewal at the free limit succeeds', () async {
      final renewals = FakeRenewalRepository();
      final uploads = FakeUploadRepository()..used = kFreeDocumentLimit;
      final c = renewalContainer(renewals: renewals, uploads: uploads);
      final notifier = c.read(documentUploadProvider.notifier)
        ..setExpirationDate(_newEnd);

      await notifier.submit();

      expect(c.read(documentUploadProvider).phase, UploadPhase.success);
      expect(c.read(documentUploadProvider).failure, isNull);
      expect(renewals.renewed, hasLength(1));
    });

    test('a plain add at the free limit is still blocked', () async {
      final uploads = FakeUploadRepository()..used = kFreeDocumentLimit;
      final c = ProviderContainer(overrides: renewalOverrides(uploads: uploads));
      addTearDown(c.dispose);
      c.read(documentUploadProvider.notifier)
        ..setPickedFile(
          file: File('/nonexistent/a.pdf'),
          mimeType: 'application/pdf',
          sizeBytes: 10,
          name: 'a',
        )
        ..useDefaultCategory(kCategories);
      await c.read(documentUploadProvider.notifier).submit();
      expect(c.read(documentUploadProvider).failure, UploadFailure.limitReached);
      expect(uploads.enforced, isTrue);
    });

    test('a failed renewal keeps the form so Save can be tried again', () async {
      final renewals = FakeRenewalRepository(renewError: Exception('offline'));
      final c = renewalContainer(renewals: renewals);
      final notifier = c.read(documentUploadProvider.notifier)
        ..setExpirationDate(_newEnd);

      await notifier.submit();

      var s = c.read(documentUploadProvider);
      expect(s.failure, UploadFailure.generic);
      expect(s.phase, UploadPhase.editing);
      expect(s.hasFile, isTrue);
      expect(s.expirationDate, _newEnd);
      expect(s.notes, kInsurance.notes);
      expect(renewals.renewed, isEmpty);

      renewals.renewError = null;
      notifier.clearFailure();
      await notifier.submit();
      s = c.read(documentUploadProvider);
      expect(s.phase, UploadPhase.success);
      expect(renewals.renewed, hasLength(1));
    });

    testWidgets('the screen goes to the SAME document and says it renewed', (
      tester,
    ) async {
      final renewals = FakeRenewalRepository();
      final c = await _open(
        tester,
        overrides: renewalOverrides(renewals: renewals),
      );
      _pickFile(c);
      c.read(documentUploadProvider.notifier).setExpirationDate(_newEnd);
      await tester.pump();

      await tester.tap(find.byType(SaveButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('detail old-1'), findsOneWidget);
      expect(find.text(DocsCopy.renewalSaved), findsOneWidget);
      expect(renewals.renewed.single.request.documentId, 'old-1');
    });

    testWidgets('a failed save shows the upload-failed message', (tester) async {
      final renewals = FakeRenewalRepository(renewError: Exception('offline'));
      final c = await _open(
        tester,
        overrides: renewalOverrides(renewals: renewals),
      );
      _pickFile(c);
      c.read(documentUploadProvider.notifier).setExpirationDate(_newEnd);
      await tester.pump();

      await tester.tap(find.byType(SaveButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Upload failed'), findsOneWidget);
      expect(find.byType(UploadRenewalBanner), findsOneWidget);
      expect(find.text('detail old-1'), findsNothing);
    });

    testWidgets('Cancel leaves the document untouched', (tester) async {
      final renewals = FakeRenewalRepository();
      await _open(tester, overrides: renewalOverrides(renewals: renewals));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
      expect(renewals.renewed, isEmpty);
    });
  });

  group('closing a renewal does not leak into the next add', () {
    testWidgets('cancel, then a new document opens blank', (tester) async {
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('HOME'))),
          GoRoute(path: '/renew', builder: (_, _) => _renewScreen),
          GoRoute(
            path: '/add',
            builder: (_, _) => const DocumentUploadScreen(),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: renewalOverrides(),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      final c = ProviderScope.containerOf(tester.element(find.text('HOME')));

      router.push('/renew');
      await tester.pumpAndSettle();
      expect(find.byType(UploadRenewalBanner), findsOneWidget);
      expect(c.read(documentUploadProvider).isRenewal, isTrue);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(c.read(documentUploadProvider).isRenewal, isFalse);

      router.push('/add');
      await tester.pumpAndSettle();
      expect(find.byType(UploadRenewalBanner), findsNothing);
      expect(c.read(documentUploadProvider).isRenewal, isFalse);
      expect(c.read(documentUploadProvider).name, isEmpty);
    });

    testWidgets('saving a renewal then adding a document opens blank', (
      tester,
    ) async {
      final c = await _open(tester, overrides: renewalOverrides());
      _pickFile(c);
      c.read(documentUploadProvider.notifier).setExpirationDate(_newEnd);
      await tester.pump();
      await tester.tap(find.byType(SaveButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final after = c.read(documentUploadProvider);
      expect(after.isRenewal, isFalse);
      expect(after.name, isEmpty);
      expect(after.hasFile, isFalse);
    });
  });

  testWidgets('the router location carries the document id', (tester) async {
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
