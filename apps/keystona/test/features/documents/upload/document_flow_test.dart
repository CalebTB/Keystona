import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/documents/providers/document_flow.dart';
import 'package:keystona/features/documents/providers/document_upload_provider.dart';
import 'package:keystona/features/documents/providers/scan_reading_provider.dart';
import 'package:keystona/features/documents/screens/document_upload_screen.dart';
import 'package:keystona/features/documents/widgets/upload_source_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'upload_test_support.dart';

/// State kept alive by the add-document flow must never outlive the flow.
/// These cover both ends: it is cleared when a flow ends, and when a new one
/// begins (so an abandoned flow cannot leak into the next).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpHost(
    WidgetTester tester,
    Widget Function(BuildContext, WidgetRef) body,
  ) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: uploadOverrides(ocr: FakeOcr()),
        child: MaterialApp(
          home: Scaffold(body: Consumer(builder: (c, ref, _) => body(c, ref))),
        ),
      ),
    );
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

  testWidgets('DocumentFlow.reset clears the form and the scan reading', (
    tester,
  ) async {
    await pumpHost(
      tester,
      (_, ref) => TextButton(
        onPressed: () => DocumentFlow.reset(ref),
        child: const Text('reset'),
      ),
    );
    final container = containerOf(tester);
    container.read(documentUploadProvider.notifier).setName('Stale name');
    container.read(scanReadingProvider.notifier).start(const []);
    expect(container.read(documentUploadProvider).name, 'Stale name');
    expect(container.read(scanReadingProvider).status, ScanReadingStatus.reading);

    await tester.tap(find.text('reset'));
    await tester.pump();

    expect(container.read(documentUploadProvider).name, isEmpty);
    expect(container.read(scanReadingProvider).status, ScanReadingStatus.idle);
  });

  testWidgets('starting a new add clears whatever an earlier flow left', (
    tester,
  ) async {
    await pumpHost(
      tester,
      (context, ref) => TextButton(
        onPressed: () =>
            UploadSourceSheet.show(context, ref, onFilePicked: () {}),
        child: const Text('add'),
      ),
    );
    final container = containerOf(tester);
    // Left behind by a flow that ended in some way nobody anticipated.
    container.read(documentUploadProvider.notifier).setName('Left behind');
    container.read(scanReadingProvider.notifier).start(const []);

    await tester.tap(find.text('add'));
    await tester.pump();

    expect(container.read(documentUploadProvider).name, isEmpty);
    expect(container.read(scanReadingProvider).status, ScanReadingStatus.idle);
  });

  testWidgets('closing the form clears the form and the scan reading', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = routerFor(const DocumentUploadScreen());
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: uploadOverrides(ocr: FakeOcr()),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('HOME'));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DocumentUploadScreen)),
    );
    container.read(documentUploadProvider.notifier).setName('Typed by the user');
    container.read(scanReadingProvider.notifier).start(const []);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(container.read(documentUploadProvider).name, isEmpty);
    expect(container.read(scanReadingProvider).status, ScanReadingStatus.idle);
  });
}
