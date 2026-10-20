import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:keystona/core/router/app_router.dart';
import 'package:keystona/features/home_profile/models/system.dart';
import 'package:keystona/features/home_profile/providers/item_service_log_provider.dart';

import '../../maintenance/tab/tasks_test_support.dart';
import 'fake_item_service_log_repository.dart';
import 'fake_systems.dart';

/// A DATE column value [years] years and [months] months before today, so the
/// ages in these tests never drift with the calendar.
String ago({int years = 0, int months = 0}) {
  final n = DateTime.now();
  final d = DateTime(n.year - years, n.month - months, 1);
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-01';
}

/// The kit's HomeSystems list: five systems, one at the end of its life.
List<HomeSystem> kitSystems() => [
  aSystem(
    'wh',
    name: 'Water heater',
    category: SystemCategory.plumbing,
    installed: ago(years: 11, months: 6),
    life: 12,
    brand: 'Calder',
    model: '50-gal gas',
    location: 'Basement',
  ),
  aSystem(
    'ep',
    name: 'Electrical panel',
    category: SystemCategory.electrical,
    installed: ago(years: 28, months: 6),
    life: 40,
    brand: 'Square D',
    model: '200 amp',
    location: 'Garage',
  ),
  aSystem(
    'rf',
    name: 'Roof',
    category: SystemCategory.roofing,
    installed: ago(years: 14),
    life: 25,
    brand: null,
    model: 'Architectural shingle',
    location: 'Whole house',
  ),
  aSystem('fu', installed: ago(years: 5, months: 6)),
  aSystem(
    'ac',
    name: 'Central AC',
    installed: ago(months: 4),
    brand: 'Ridgeway',
    model: 'RC3',
    location: 'Side yard',
  ),
];

/// Every override the Systems screens need, with the clock fixed at the kit's
/// Sunday and an empty (or given) task list.
List<Override> homeOverrides({
  required FakeSystemsRepository systems,
  FakeSystemPhotosRepository? photos,
  FakeSystemDocumentsRepository? documents,
  FakeItemServiceLogRepository? log,
  FakeMaintenanceTasksRepository? tasks,
  bool online = true,
  bool premium = false,
}) => [
  ...systemOverrides(
    systems: systems,
    photos: photos,
    documents: documents,
    online: online,
    premium: premium,
  ),
  itemServiceLogRepositoryProvider.overrideWithValue(
    log ?? FakeItemServiceLogRepository(),
  ),
  ...tasksOverrides(tasks ?? FakeMaintenanceTasksRepository(const [])),
];

/// Where a route was pushed, with its `extra`.
class Visit {
  const Visit(this.path, this.extra);

  final String path;
  final Object? extra;
}

/// Routes [home] at `/` and records every push to the Home profile routes.
class HomeRoutedApp extends StatelessWidget {
  HomeRoutedApp({
    super.key,
    required Widget home,
    required this.overrides,
    required this.visits,
  }) : _router = GoRouter(
         routes: [
           GoRoute(path: '/', builder: (_, _) => home),
           for (final path in [
             AppRoutes.homeScan,
             AppRoutes.homeSystemsAdd,
             AppRoutes.homeSystemDetail,
             AppRoutes.homeSystemTasks,
             AppRoutes.homeSystemPhotos,
             AppRoutes.homeProfile,
             AppRoutes.homeSystems,
             AppRoutes.homeAppliancesAdd,
             AppRoutes.maintenanceTaskDetail,
             AppRoutes.documentDetail,
           ])
             GoRoute(
               path: path,
               builder: (context, state) {
                 visits.add(Visit(state.uri.path, state.extra));
                 return Scaffold(body: Text('route ${state.uri.path}'));
               },
             ),
         ],
       );

  final List<Override> overrides;
  final List<Visit> visits;
  final GoRouter _router;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(routerConfig: _router),
  );
}

/// Wraps an app in a [ProviderScope] with the Systems fakes, for
/// `testResponsive`.
abstract final class ProviderScopeFor {
  static Widget wrap(Widget app, List<HomeSystem> systems) => ProviderScope(
    overrides: homeOverrides(systems: FakeSystemsRepository(systems)),
    child: app,
  );
}
