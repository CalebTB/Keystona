import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keystona/core/providers/provider_retry.dart';
import 'package:keystona/core/router/app_router.dart';

import '../../../support/responsive_harness.dart';

/// A router with [home] at '/', every other route a stub that shows its path.
/// [visited] collects the paths pushed.
GoRouter stubRouter(
  Widget home,
  List<String> visited, {
  List<String> routes = const [],
}) {
  final paths = {
    AppRoutes.homeEdit,
    AppRoutes.homeLifespan,
    AppRoutes.homeReminders,
    AppRoutes.homeSystems,
    AppRoutes.homeAppliances,
    AppRoutes.homeScan,
    AppRoutes.homeProfile,
    AppRoutes.homeSystemDetail,
    AppRoutes.homeApplianceDetail,
    AppRoutes.maintenance,
    ...routes,
  };
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      for (final path in paths)
        GoRoute(
          path: path,
          builder: (_, state) {
            visited.add(state.uri.path);
            return Scaffold(body: Text('stub ${state.uri.path}'));
          },
        ),
    ],
  );
}

/// Pumps [router] on [viewport] at [textScale] inside a ProviderScope.
Future<void> pumpRouter(
  WidgetTester tester,
  GoRouter router,
  List<Override> overrides, {
  TestViewport? viewport,
  double textScale = 1,
}) async {
  final size = (viewport ?? kViewports[1]).size;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: noAutomaticRetry,
      overrides: overrides,
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The same overrides as a `wrap` for [testResponsive].
Widget Function(Widget) scopeWrap(List<Override> overrides) =>
    (app) => ProviderScope(overrides: overrides, child: app);

/// [testResponsive] for a loaded screen: pumps until the providers settle, on
/// every active viewport and scale, and fails on any layout exception.
void testScreenResponsive(
  String description,
  Widget Function() home,
  List<Override> Function() overrides,
) {
  for (final viewport in activeViewports) {
    for (final scale in scalesFor(viewport)) {
      testWidgets('$description @ ${viewport.name}, text x$scale', (
        tester,
      ) async {
        await pumpRouter(
          tester,
          stubRouter(home(), []),
          overrides(),
          viewport: viewport,
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}

/// Scrolls [finder] into view and taps it.
Future<void> tapText(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}
