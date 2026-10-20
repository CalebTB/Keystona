import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/documents/widgets/upload/add_from_sheet_body.dart';
import 'package:keystona/features/documents/widgets/upload_source_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/responsive_harness.dart';
import 'upload_test_support.dart';

class _Host extends ConsumerWidget {
  const _Host({required this.onPicked});

  final VoidCallback onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () =>
            UploadSourceSheet.show(context, ref, onFilePicked: onPicked),
        child: const Text('open'),
      ),
    ),
  );
}

Future<void> _open(
  WidgetTester tester, {
  bool premium = false,
  String? address,
  VoidCallback? onPicked,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: uploadOverrides(premium: premium, forwardingAddress: address),
      child: MaterialApp(home: _Host(onPicked: onPicked ?? () {})),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testResponsive(
    'DocAddFrom body',
    () =>
        const Scaffold(body: SingleChildScrollView(child: AddFromSheetBody())),
    wrap: (app) => ProviderScope(
      overrides: uploadOverrides(
        forwardingAddress: 'caleb.elmhollow@docs.keystona.app',
      ),
      child: app,
    ),
  );

  testWidgets('shows the kit copy, the plan line and the forwarding card', (
    tester,
  ) async {
    await _open(tester, address: 'caleb.elmhollow@docs.keystona.app');
    expect(find.text('Add a document'), findsOneWidget);
    expect(find.text('10 OF 25 ON FREE'), findsOneWidget);
    expect(find.text('Take a photo'), findsOneWidget);
    expect(
      find.text('Snap a paper document · several pages is fine'),
      findsOneWidget,
    );
    expect(find.text('Choose from Photos'), findsOneWidget);
    expect(find.text('A picture you already took'), findsOneWidget);
    expect(find.text('Choose a file'), findsOneWidget);
    expect(
      find.text('PDFs from Files, iCloud or email downloads'),
      findsOneWidget,
    );
    expect(find.text('Smart scan'), findsOneWidget);
    expect(find.text('★ PREMIUM'), findsOneWidget);
    expect(find.text('Or forward an email'), findsOneWidget);
    expect(find.text('caleb.elmhollow@docs.keystona.app'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
  });

  testWidgets('premium has no plan line; no address hides the card', (
    tester,
  ) async {
    await _open(tester, premium: true);
    expect(find.textContaining('ON FREE'), findsNothing);
    expect(find.text('Or forward an email'), findsNothing);
  });

  testWidgets('Smart scan on the free plan offers the upgrade', (tester) async {
    var picked = false;
    await _open(tester, onPicked: () => picked = true);
    await tester.tap(find.text('Smart scan'));
    await tester.pumpAndSettle();
    expect(find.text('Unlock Smart scan'), findsOneWidget);
    expect(picked, isFalse);
  });

  testWidgets('Take a photo opens the camera in smart mode for premium', (
    tester,
  ) async {
    await _open(tester, premium: true);
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();
    expect(find.text('★ SMART SCAN · PAGE 1'), findsOneWidget);
  });

  testWidgets('Take a photo opens the camera in plain mode on the free plan', (
    tester,
  ) async {
    await _open(tester);
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();
    expect(find.text('PAGE 1'), findsOneWidget);
  });
}
