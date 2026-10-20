import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/widgets/aurora/aurora_chip.dart';
import 'package:keystona/core/widgets/aurora/aurora_pressable.dart';
import 'package:keystona/features/home_profile/widgets/shared/item_filter_bar.dart';

import '../support/home_widget_harness.dart';

const options = [
  ItemFilterOption(value: 'all', label: 'All 5'),
  ItemFilterOption(value: 'hvac', label: 'Heating & cooling'),
  ItemFilterOption(value: 'water', label: 'Water'),
  ItemFilterOption(value: 'structure', label: 'Structure'),
  ItemFilterOption(value: 'electric', label: 'Electrical'),
];

Widget bar({
  String selected = 'all',
  ValueChanged<String>? onSelected,
  int sort = 0,
  ValueChanged<int>? onSort,
}) => ItemFilterBar<String>(
  options: options,
  selected: selected,
  onSelected: onSelected ?? (_) {},
  shownCount: 5,
  sortLabels: const ['Oldest first', 'A–Z'],
  sortIndex: sort,
  onSortChanged: onSort ?? (_) {},
);

void main() {
  // The bar is full width and pads itself.
  testWidgetResponsive('ItemFilterBar', bar, padded: false);

  testWidgets('chips start at the screen inset and scroll sideways', (t) async {
    await pumpPhone(t, bar(), padded: false);
    expect(t.getTopLeft(find.byType(FilterPill).first).dx, kPad);
    expect(find.byType(FilterPill), findsNWidgets(5));
    // The row is wider than the screen, so it scrolls.
    final scroll = t.state<ScrollableState>(find.byType(Scrollable).at(1));
    expect(scroll.position.maxScrollExtent, greaterThan(0));
    await t.drag(find.byType(SingleChildScrollView).at(1), const Offset(-200, 0));
    await t.pump();
    expect(t.getTopLeft(find.byType(FilterPill).first).dx, lessThan(kPad));
  });

  testWidgets('N SHOWN at the left, sort toggle ends at the right inset', (
    t,
  ) async {
    await pumpPhone(t, bar(), padded: false);
    expect(t.getTopLeft(find.text('5 SHOWN')).dx, kPad);
    final az = find.ancestor(
      of: find.text('A–Z'),
      matching: find.byType(AuroraPressable),
    );
    expect(t.getRect(az).right, closeTo(contentRight, 1));
    final oldest = find.ancestor(
      of: find.text('Oldest first'),
      matching: find.byType(AuroraPressable),
    );
    expect(t.getRect(oldest).right, lessThanOrEqualTo(t.getRect(az).left + 1));
    expect(t.getSize(az).height, greaterThanOrEqualTo(44));
  });

  testWidgets('the selected chip is the filled one', (t) async {
    await pumpPhone(t, bar(selected: 'water'), padded: false);
    final selected = t
        .widgetList<FilterPill>(find.byType(FilterPill))
        .where((p) => p.selected)
        .single;
    expect(selected.label, 'Water');
  });

  testWidgets('tapping a chip and a sort option calls back', (t) async {
    String? picked;
    int? sorted;
    await pumpPhone(
      t,
      bar(onSelected: (v) => picked = v, onSort: (i) => sorted = i),
      padded: false,
    );
    await t.ensureVisible(find.text('Water'));
    await t.pump();
    await t.tap(find.text('Water'));
    expect(picked, 'water');
    await t.tap(find.text('A–Z'));
    expect(sorted, 1);
  });

  testWidgets('at 2x text the sort toggle wraps instead of overflowing', (
    t,
  ) async {
    await pumpScreenAt320(t);
    expect(t.takeException(), isNull);
  });
}

Future<void> pumpScreenAt320(WidgetTester t) async {
  t.view.physicalSize = const Size(320, 568);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: Scaffold(body: SingleChildScrollView(child: bar())),
    ),
  );
  await t.pump();
}
