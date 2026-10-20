import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keystona/core/router/app_router.dart';
import 'package:keystona/features/documents/widgets/upload/category_picker_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/responsive_harness.dart';
import 'upload_test_support.dart';

class _Host extends StatefulWidget {
  const _Host({required this.selected});

  final String? selected;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String result = 'none';

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        TextButton(
          onPressed: () async {
            final c = await CategoryPickerSheet.show(
              context,
              categories: kCategories,
              selectedId: widget.selected,
            );
            setState(() => result = c?.name ?? 'cancelled');
          },
          child: const Text('open'),
        ),
        Text('result: $result'),
      ],
    ),
  );
}

Future<void> _open(
  WidgetTester tester, {
  String? selected = 'c-warranty',
  bool premium = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: uploadOverrides(premium: premium),
      child: MaterialApp(home: _Host(selected: selected)),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Done closes only the sheet when the host is a nested tab navigator',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // The root navigator holds one page (the shell); the tab has its own
    // navigator. Popping the root navigator would assert "popped the last
    // page", which is what happened in the app.
    await tester.pumpWidget(
      ProviderScope(
        overrides: uploadOverrides(),
        child: MaterialApp(
          home: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => const _Host(selected: 'c-warranty'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('open'), findsOneWidget);
    expect(find.textContaining('result: '), findsOneWidget);
    expect(find.text('Done'), findsNothing);
  });

  testResponsive(
    'DocCategory sheet content',
    () => Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => CategoryPickerSheet.show(
              context,
              categories: kCategories,
              selectedId: 'c-warranty',
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
    wrap: (app) => scopeWrap(uploadOverrides(), app),
  );

  testWidgets('lists standard and your categories with counts', (tester) async {
    await _open(tester);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('STANDARD'), findsOneWidget);
    expect(find.text('YOURS'), findsOneWidget);
    expect(find.text('Manage'), findsOneWidget);
    expect(find.text('Warranty'), findsOneWidget);
    expect(find.text('9 DOCS'), findsOneWidget);
    expect(find.text('1 DOC'), findsOneWidget);
    expect(find.text('EMPTY'), findsNWidgets(2));
    expect(find.text('New category'), findsOneWidget);
    expect(find.text('★ PREMIUM'), findsOneWidget);
    final selected = tester.getSemantics(find.text('Warranty'));
    expect(selected, isNotNull);
  });

  testWidgets('choosing a row then Done returns it', (tester) async {
    await _open(tester);
    await tester.tap(find.text('Insurance'));
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('result: Insurance'), findsOneWidget);
  });

  testWidgets('Done without a change returns the current category', (
    tester,
  ) async {
    await _open(tester);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('result: Warranty'), findsOneWidget);
  });

  testWidgets('Cancel discards the choice', (tester) async {
    await _open(tester);
    await tester.tap(find.text('Insurance'));
    await tester.pump();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('result: cancelled'), findsOneWidget);
  });

  testWidgets('search narrows both groups', (tester) async {
    await _open(tester);
    await tester.enterText(find.byType(TextField), 'sol');
    await tester.pump();
    expect(find.text('Warranty'), findsNothing);
    expect(find.text('STANDARD'), findsNothing);
    expect(find.text('Solar panels'), findsOneWidget);
  });

  testWidgets('New category on the free plan offers the upgrade', (
    tester,
  ) async {
    await _open(tester);
    await tester.tap(find.text('New category'));
    await tester.pumpAndSettle();
    expect(find.text('Unlock your own categories'), findsOneWidget);
  });

  for (final label in ['Manage', 'New category']) {
    testWidgets('$label opens the categories screen (premium)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const _Host(selected: 'c-warranty'),
          ),
          GoRoute(
            path: AppRoutes.documentsCategories,
            builder: (_, _) => const Scaffold(body: Text('categories page')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: uploadOverrides(premium: true),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.text('categories page'), findsOneWidget);
    });
  }
}
