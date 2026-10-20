import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keystona/core/router/app_router.dart';
import 'package:keystona/features/auth/providers/auth_provider.dart';

String fill(String pattern) => pattern
    .replaceFirst(':systemId', 'sys-1')
    .replaceFirst(':applianceId', 'app-1');

void main() {
  late GoRouter router;

  setUp(() {
    final container = ProviderContainer(
      overrides: [isAuthenticatedProvider.overrideWithValue(true)],
    );
    addTearDown(container.dispose);
    router = container.read(routerProvider);
  });

  void expectResolves(String pattern, {Map<String, String> params = const {}}) {
    final match = router.configuration.findMatch(Uri.parse(fill(pattern)));
    expect(match.isError, isFalse, reason: pattern);
    expect(match.fullPath, pattern, reason: pattern);
    expect(match.pathParameters, params, reason: pattern);
  }

  test('the new Sprint 3 routes resolve', () {
    expectResolves(AppRoutes.homeProfile);
    expectResolves(AppRoutes.homeScan);
    expectResolves(
      AppRoutes.homeSystemPhotos,
      params: {'systemId': 'sys-1'},
    );
    expectResolves(
      AppRoutes.homeSystemReminders,
      params: {'systemId': 'sys-1'},
    );
    expectResolves(
      AppRoutes.homeAppliancePhotos,
      params: {'applianceId': 'app-1'},
    );
    expectResolves(
      AppRoutes.homeApplianceReminders,
      params: {'applianceId': 'app-1'},
    );
  });

  test('the path constants have the agreed values', () {
    expect(AppRoutes.homeProfile, '/home/profile');
    expect(AppRoutes.homeScan, '/home/scan');
    expect(AppRoutes.homeSystemPhotos, '/home/systems/:systemId/photos');
    expect(AppRoutes.homeAppliancePhotos, '/home/appliances/:applianceId/photos');
    expect(AppRoutes.homeSystemReminders, '/home/systems/:systemId/reminders');
    expect(
      AppRoutes.homeApplianceReminders,
      '/home/appliances/:applianceId/reminders',
    );
  });

  test('static routes are not swallowed by the :id routes', () {
    // /home/systems/add is a static route declared before /home/systems/:id.
    final add = router.configuration.findMatch(Uri.parse(AppRoutes.homeSystemsAdd));
    expect(add.fullPath, AppRoutes.homeSystemsAdd);
    final detail = router.configuration.findMatch(Uri.parse('/home/systems/abc'));
    expect(detail.fullPath, AppRoutes.homeSystemDetail);
  });

  test('existing item routes still resolve', () {
    expectResolves(AppRoutes.homeSystemTasks, params: {'systemId': 'sys-1'});
    expectResolves(AppRoutes.homeApplianceTasks, params: {'applianceId': 'app-1'});
    expectResolves(AppRoutes.homeLifespan);
    expectResolves(AppRoutes.homeEdit);
    expectResolves(AppRoutes.homeReminders);
  });

  test('no route path is declared twice', () {
    final paths = <String>[];
    void walk(List<RouteBase> routes, String parent) {
      for (final r in routes) {
        if (r is GoRoute) {
          final full = r.path.startsWith('/')
              ? r.path
              : '${parent == '/' ? '' : parent}/${r.path}';
          paths.add(full);
          walk(r.routes, full);
        } else {
          walk(r.routes, parent);
        }
      }
    }

    walk(router.configuration.routes, '/');
    final dupes = {
      for (final p in paths)
        if (paths.where((q) => q == p).length > 1) p,
    };
    expect(dupes, isEmpty);
  });
}
