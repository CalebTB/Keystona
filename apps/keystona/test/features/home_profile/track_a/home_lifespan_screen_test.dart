import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/router/app_router.dart';
import 'package:keystona/features/home_profile/screens/home_lifespan_screen.dart';
import 'package:keystona/features/home_profile/widgets/home_lifespan/lifespan_tabs.dart';

import '../../../support/responsive_harness.dart';
import 'router_support.dart';
import 'track_a_support.dart';

void main() {
  final width = kViewports[1].size.width;

  List<Override> overrides({FakeHomeItemsRepository? items}) => homeOverrides(
    FakePropertyRepository(sampleProperty()),
    items ?? FakeHomeItemsRepository(sampleItems()),
  );

  testScreenResponsive(
    'HomeLifespanScreen',
    () => const HomeLifespanScreen(),
    overrides,
  );

  Future<List<String>> pump(WidgetTester t, {List<Override>? use}) async {
    final visited = <String>[];
    await pumpRouter(
      t,
      stubRouter(const HomeLifespanScreen(), visited),
      use ?? overrides(),
    );
    return visited;
  }

  testWidgets('summary, tabs, timeline and the set-aside table', (t) async {
    await pump(t);
    expect(find.text('5 THINGS · SYSTEMS AND APPLIANCES'), findsOneWidget);
    expect(find.text('How long things last'), findsOneWidget);
    expect(find.text('due in the next 5 years'), findsOneWidget);
    expect(find.text('All 5'), findsOneWidget);
    expect(find.text('Systems'), findsOneWidget);
    expect(find.text('Appliances'), findsOneWidget);
    expect(find.text('PAST ITS LIFE · REPLACE ANY TIME'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    await t.ensureVisible(find.text('WHAT TO SET ASIDE'));
    expect(find.text('PREMIUM'), findsOneWidget);
    expect(find.textContaining('A MONTH COVERS ALL OF IT'), findsOneWidget);
  });

  testWidgets('rows run most worn first; costs sit at the right edge', (
    t,
  ) async {
    await pump(t);
    double dy(String name) => t.getTopLeft(find.text(name)).dy;
    expect(dy('Dishwasher'), lessThan(dy('Water heater')));
    expect(dy('Water heater'), lessThan(dy('Roof')));
    expect(dy('Roof'), lessThan(dy('Furnace')));
    expect(dy('Furnace'), lessThan(dy('Washer')));
    expect(t.getTopRight(find.text('~\$800')).dx, closeTo(width - 16, 1));
    expect(t.getTopLeft(find.text('Dishwasher')).dx, closeTo(16, 1));
    // The tabs fill the content width.
    expect(t.getSize(find.byType(LifespanTabs)).width, closeTo(width - 32, 1));
  });

  testWidgets('the Appliances tab shows appliances only and re-totals', (
    t,
  ) async {
    await pump(t);
    final all = t
        .widgetList<Text>(find.byType(Text))
        .map((w) => w.data)
        .whereType<String>()
        .firstWhere((s) => s.startsWith(r'$') && s.length > 3);
    await t.tap(find.text('Appliances'));
    await t.pumpAndSettle();
    expect(find.text('Furnace'), findsNothing);
    expect(find.text('Roof'), findsNothing);
    expect(find.text('Washer'), findsOneWidget);
    expect(find.text('Dishwasher'), findsOneWidget);
    final appliances = t
        .widgetList<Text>(find.byType(Text))
        .map((w) => w.data)
        .whereType<String>()
        .firstWhere((s) => s.startsWith(r'$') && s.length > 3);
    expect(appliances, isNot(all));
    await t.tap(find.text('Systems'));
    await t.pumpAndSettle();
    expect(find.text('Washer'), findsNothing);
    expect(find.text('Furnace'), findsOneWidget);
  });

  testWidgets('rows open the system or appliance', (t) async {
    var visited = await pump(t);
    await tapText(t, find.text('Furnace'));
    expect(visited, contains('/home/systems/s2'));
    visited = await pump(t);
    await tapText(t, find.text('Washer'));
    expect(visited, contains('/home/appliances/a2'));
  });

  testWidgets('nothing tracked: an empty state with a scan button', (t) async {
    final visited = await pump(
      t,
      use: overrides(items: FakeHomeItemsRepository([])),
    );
    expect(find.text('Nothing tracked yet'), findsOneWidget);
    await tapText(t, find.text('Scan a label to add one'));
    expect(visited, contains(AppRoutes.homeScan));
  });

  testWidgets('an item with no date or life still draws', (t) async {
    await pump(
      t,
      use: overrides(
        items: FakeHomeItemsRepository([item('x', 'Mystery', life: 0, age: 0)]),
      ),
    );
    expect(find.text('Mystery'), findsOneWidget);
    expect(find.text('EXPECTED LIFE UNKNOWN'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('a failed load can be retried', (t) async {
    final property = FakePropertyRepository(sampleProperty())
      ..fetchError = StateError('offline');
    await pump(
      t,
      use: homeOverrides(property, FakeHomeItemsRepository(sampleItems())),
    );
    expect(find.text('Try again'), findsOneWidget);
    property.fetchError = null;
    await t.tap(find.text('Try again'));
    await t.pumpAndSettle();
    expect(find.text('Dishwasher'), findsOneWidget);
  });
}
