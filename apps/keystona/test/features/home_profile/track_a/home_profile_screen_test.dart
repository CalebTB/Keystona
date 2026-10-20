import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/router/app_router.dart';
import 'package:keystona/features/home_profile/screens/home_profile_screen.dart';

import '../../../support/responsive_harness.dart';
import 'router_support.dart';
import 'track_a_support.dart';

void main() {
  final width = kViewports[1].size.width;
  List<Override> overrides() => homeOverrides(
    FakePropertyRepository(sampleProperty()),
    FakeHomeItemsRepository(sampleItems()),
  );

  testScreenResponsive(
    'HomeProfileScreen',
    () => const HomeProfileScreen(),
    overrides,
  );
  testScreenResponsive(
    'HomeProfileScreen with nothing tracked',
    () => const HomeProfileScreen(),
    () => homeOverrides(
      FakePropertyRepository(sampleProperty(type: null)),
      FakeHomeItemsRepository([]),
    ),
  );

  Future<List<String>> pump(
    WidgetTester tester, {
    List<Override> Function()? use,
  }) async {
    final visited = <String>[];
    await pumpRouter(
      tester,
      stubRouter(
        const HomeProfileScreen(),
        visited,
        routes: [AppRoutes.onboardingProperty],
      ),
      (use ?? overrides)(),
    );
    return visited;
  }

  testWidgets('shows the property, the callout and every section', (t) async {
    await pump(t);
    expect(find.text('1428 Elm Hollow Ln'), findsOneWidget);
    expect(
      find.text(
        'SINGLE-FAMILY · BUILT 1998 · 2,140 SQ FT · 4 BD · 2.5 BA · ZONE 4A',
      ),
      findsOneWidget,
    );
    expect(find.text('YOUR HOME · OWNED SINCE MAR 2024'), findsOneWidget);
    expect(find.text('Dishwasher is past its expected life'), findsOneWidget);
    expect(find.textContaining('BUDGET ~\$800 FOR '), findsOneWidget);
    expect(find.text('HOME HEALTH · 78'), findsOneWidget);
    expect(find.text('SYSTEMS · 3'), findsOneWidget);
    expect(find.text('1 AGING'), findsOneWidget);
    expect(find.text('2 appliances'), findsOneWidget);
    expect(find.text('0 REMINDERS NOT TIED TO A SYSTEM'), findsOneWidget);
    expect(find.text('NEXT 5 YEARS'), findsOneWidget);
    for (final value in [
      'Mar 2024 · \$318,000',
      '0.31 acres',
      '2 + basement',
      'Attached · 2 cars',
      'Zone 4A · mixed-humid',
    ]) {
      expect(find.text(value), findsOneWidget, reason: value);
    }
  });

  testWidgets('key elements sit where the kit puts them', (t) async {
    await pump(t);
    // Edit at the right of the top bar, the address at the left edge.
    expect(t.getTopRight(find.text('Edit').first).dx, greaterThan(width * 0.8));
    expect(t.getTopLeft(find.text('1428 Elm Hollow Ln')).dx, closeTo(16, 1));
    // The callout spans the content width.
    final callout = find.ancestor(
      of: find.text('Dishwasher is past its expected life'),
      matching: find.byType(DecoratedBox),
    );
    expect(t.getSize(callout.last).width, closeTo(width - 32, 1));
    // Systems rows are listed most worn first (the water heater leads).
    await t.ensureVisible(find.text('Water heater'));
    expect(
      t.getTopLeft(find.text('Water heater')).dy,
      lessThan(t.getTopLeft(find.text('Roof')).dy),
    );
    expect(
      t.getTopLeft(find.text('Roof')).dy,
      lessThan(t.getTopLeft(find.text('Furnace')).dy),
    );
    // The two pills share the row.
    expect(
      t.getTopLeft(find.text('All systems')).dx,
      lessThan(t.getTopLeft(find.text('2 appliances')).dx),
    );
    // Property rows: label left, value right.
    await t.ensureVisible(find.text('BOUGHT'));
    expect(t.getTopLeft(find.text('BOUGHT')).dx, lessThan(width / 4));
    expect(
      t.getTopRight(find.text('Mar 2024 · \$318,000')).dx,
      closeTo(width - 16 - 14, 2),
    );
  });

  group('every tap goes somewhere', () {
    Future<void> expectTap(WidgetTester t, String text, String path) async {
      final visited = await pump(t);
      await tapText(t, find.text(text));
      expect(visited, contains(path));
    }

    testWidgets('Edit', (t) => expectTap(t, 'Edit', AppRoutes.homeEdit));
    testWidgets(
      'the callout opens the lifespan screen',
      (t) => expectTap(
        t,
        'Dishwasher is past its expected life',
        AppRoutes.homeLifespan,
      ),
    );
    testWidgets(
      'a system row opens that system',
      (t) => expectTap(t, 'Furnace', '/home/systems/s2'),
    );
    testWidgets(
      'All systems',
      (t) => expectTap(t, 'All systems', AppRoutes.homeSystems),
    );
    testWidgets(
      'appliances',
      (t) => expectTap(t, '2 appliances', AppRoutes.homeAppliances),
    );
    testWidgets(
      'Around the house opens the reminders',
      (t) => expectTap(t, 'Around the house', AppRoutes.homeReminders),
    );
    testWidgets(
      'How long things last',
      (t) => expectTap(t, 'How long things last', AppRoutes.homeLifespan),
    );
    testWidgets(
      'the upkeep tile opens Tasks',
      (t) => expectTap(t, 'UPKEEP', AppRoutes.maintenance),
    );
  });

  testWidgets('no systems: a scan button and an honest next-5-years card', (
    t,
  ) async {
    final visited = await pump(
      t,
      use: () => homeOverrides(
        FakePropertyRepository(sampleProperty()),
        FakeHomeItemsRepository([]),
      ),
    );
    expect(find.text('SYSTEMS · 0'), findsOneWidget);
    expect(find.text('Nothing due'), findsOneWidget);
    expect(find.text('Dishwasher is past its expected life'), findsNothing);
    await tapText(t, find.text('Scan a label to add one'));
    expect(visited, contains(AppRoutes.homeScan));
  });

  testWidgets('no property: set up your home', (t) async {
    final visited = await pump(
      t,
      use: () => homeOverrides(
        FakePropertyRepository(null),
        FakeHomeItemsRepository([]),
      ),
    );
    expect(find.text('No home yet'), findsOneWidget);
    await tapText(t, find.text('Set up your home'));
    expect(visited, contains(AppRoutes.onboardingProperty));
  });

  testWidgets('a failed load can be retried', (t) async {
    final property = FakePropertyRepository(sampleProperty())
      ..fetchError = StateError('offline');
    await pump(
      t,
      use: () => homeOverrides(property, FakeHomeItemsRepository([])),
    );
    expect(find.text('Try again'), findsOneWidget);
    property.fetchError = null;
    await t.tap(find.text('Try again'));
    await t.pumpAndSettle();
    expect(find.text('1428 Elm Hollow Ln'), findsOneWidget);
  });
}
