import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/theme/aurora_colors.dart';
import 'package:keystona/features/home_profile/lifespan/lifespan_reading.dart';
import 'package:keystona/features/home_profile/widgets/shared/item_list_row.dart';
import 'package:keystona/features/home_profile/widgets/shared/item_row_group.dart';
import 'package:keystona/features/home_profile/widgets/shared/lifespan_bar.dart';

import '../support/home_widget_harness.dart';

LifespanReading read(double age, int life, {int? startYear}) =>
    LifespanReading.ofAge(ageYears: age, lifeYears: life, startYear: startYear);

Widget card(List<Widget> rows) => ItemRowGroup(children: rows);

ItemListRow furnace({VoidCallback? onTap, bool compact = false}) => ItemListRow(
  icon: Icons.local_fire_department_outlined,
  name: 'Furnace',
  subtitle: 'Northline NF95-080B · Basement utility room',
  reading: read(5.5, 15, startYear: 2021),
  taskCount: 5,
  onTap: onTap,
  compact: compact,
);

const longName =
    'Upstairs primary-bedroom ductless mini-split heat pump with a very long name';

void main() {
  testWidgetResponsive(
    'ItemListRow group',
    () => card([
      furnace(),
      ItemListRow(
        icon: Icons.water_drop_outlined,
        name: longName,
        subtitle: 'Calder 50-gal gas · Basement utility room behind the stairs',
        reading: read(12, 12, startYear: 2014),
        taskCount: 2,
      ),
      ItemListRow(
        icon: Icons.local_laundry_service_outlined,
        name: 'Washer',
        subtitle: 'Halden HW45-FL2 · Laundry room',
        reading: read(2.8, 11, startYear: 2023),
        warrantyNote: 'Warranty ends Dec 9',
        taskCount: 1,
      ),
      ItemListRow(
        icon: Icons.kitchen_outlined,
        name: 'Dishwasher',
        reading: read(11.5, 10),
        taskCount: 0,
      ),
      ItemListRow(
        icon: Icons.help_outline,
        name: 'Unknown age',
        reading: LifespanReading.unknown,
      ),
    ]),
  );

  testWidgetResponsive(
    'ItemListRow compact',
    () => card([
      furnace(compact: true),
      ItemListRow(
        icon: Icons.water_drop_outlined,
        name: longName,
        reading: read(28.5, 40),
        compact: true,
      ),
    ]),
  );

  group('regular row positions (390 wide)', () {
    testWidgets('trailing text sits at the right edge, labels at the left', (
      t,
    ) async {
      await pumpPhone(t, card([furnace()]));
      final row = t.getRect(find.byType(ItemListRow));
      final inset = 14.0; // space6
      expect(
        t.getTopRight(find.text('5 TASKS')).dx,
        closeTo(row.right - inset, 1),
      );
      expect(
        t.getTopRight(find.textContaining('5½ yrs')).dx,
        closeTo(row.right - inset, 1),
      );
      expect(
        t.getTopLeft(find.text('REPLACE ~2036')).dx,
        t.getTopLeft(find.text('Furnace')).dx,
      );
      // The icon tile is first, at the left inset.
      expect(t.getTopLeft(find.byIcon(Icons.local_fire_department_outlined)).dx,
          greaterThan(row.left + inset));
    });

    testWidgets('the bar spans from the name to the right inset', (t) async {
      await pumpPhone(t, card([furnace()]));
      final bar = t.getRect(find.byType(LifespanBar));
      final row = t.getRect(find.byType(ItemListRow));
      expect(bar.right, closeTo(row.right - 14, 1));
      expect(bar.left, t.getTopLeft(find.text('Furnace')).dx);
    });

    testWidgets('the fill matches the percent of life used', (t) async {
      await pumpPhone(t, card([furnace()]));
      final fill = t.getSize(
        find.descendant(
          of: find.byType(FractionallySizedBox),
          matching: find.byType(DecoratedBox),
        ).first,
      );
      final bar = t.getSize(find.byType(LifespanBar));
      expect(fill.width / bar.width, closeTo(5.5 / 15, 0.01));
    });

    testWidgets('status wins over a warranty note and uses the band color', (
      t,
    ) async {
      await pumpPhone(
        t,
        card([
          ItemListRow(
            icon: Icons.kitchen_outlined,
            name: 'Dishwasher',
            reading: read(11.5, 10, startYear: 2015),
            warrantyNote: 'Warranty ends Dec 9',
          ),
        ]),
      );
      final status = t.widget<Text>(find.text('PAST EXPECTED LIFE'));
      expect(status.style!.color, AuroraColors.coralDeep);
      expect(find.text('WARRANTY ENDS DEC 9'), findsNothing);
      expect(find.textContaining('REPLACE'), findsNothing);
    });

    testWidgets('a warranty note shows when there is no status', (t) async {
      await pumpPhone(
        t,
        card([
          ItemListRow(
            icon: Icons.local_laundry_service_outlined,
            name: 'Washer',
            reading: read(2.8, 11, startYear: 2023),
            warrantyNote: 'Warranty ends Dec 9',
            taskCount: 2,
          ),
        ]),
      );
      expect(find.text('WARRANTY ENDS DEC 9'), findsOneWidget);
      expect(find.text('2 TASKS'), findsOneWidget);
      expect(find.text('REPLACE ~2034'), findsNothing);
    });

    testWidgets('one task reads "1 TASK"; the count is hidden when null', (
      t,
    ) async {
      await pumpPhone(
        t,
        card([
          ItemListRow(
            icon: Icons.bolt,
            name: 'Panel',
            reading: read(1, 40),
            taskCount: 1,
          ),
          ItemListRow(icon: Icons.home, name: 'Roof', reading: read(1, 25)),
        ]),
      );
      expect(find.text('1 TASK'), findsOneWidget);
      expect(find.textContaining('TASKS'), findsNothing);
    });

    testWidgets('age shows "N mo" and "of ~N yrs"', (t) async {
      await pumpPhone(
        t,
        card([
          ItemListRow(
            icon: Icons.ac_unit,
            name: 'Central AC',
            reading: LifespanReading.ofAge(
              ageYears: 4 / 12,
              lifeYears: 15,
              startYear: 2026,
            ),
          ),
        ]),
      );
      expect(find.textContaining('4 mo'), findsOneWidget);
      expect(find.textContaining('of ~15 yrs'), findsOneWidget);
      expect(find.text('REPLACE ~2041'), findsOneWidget);
    });

    testWidgets('an unknown reading shows no age and an empty bar', (t) async {
      await pumpPhone(
        t,
        card([
          ItemListRow(
            icon: Icons.help_outline,
            name: 'Mystery',
            reading: LifespanReading.unknown,
          ),
        ]),
      );
      expect(find.textContaining('yrs'), findsNothing);
      expect(find.textContaining('REPLACE'), findsNothing);
    });

    testWidgets('a tall name wraps instead of overflowing', (t) async {
      await pumpPhone(
        t,
        card([
          ItemListRow(
            icon: Icons.ac_unit,
            name: longName,
            reading: read(5, 10),
            taskCount: 3,
          ),
        ]),
        textScale: 2,
      );
      expect(t.takeException(), isNull);
      final row = t.getRect(find.byType(ItemListRow));
      expect(t.getTopRight(find.text('3 TASKS')).dx, lessThanOrEqualTo(row.right));
    });

    testWidgets('tapping the row calls onTap', (t) async {
      var taps = 0;
      await pumpPhone(t, card([furnace(onTap: () => taps++)]));
      await t.tap(find.text('Furnace'));
      expect(taps, 1);
    });

    testWidgets('the row is at least 44 tall', (t) async {
      await pumpPhone(t, card([furnace()]));
      expect(t.getSize(find.byType(ItemListRow)).height, greaterThanOrEqualTo(44));
    });
  });

  group('compact row positions (390 wide)', () {
    testWidgets('chevron at the right edge, bar left of it, name at the left', (
      t,
    ) async {
      await pumpPhone(t, card([furnace(compact: true)]));
      final row = t.getRect(find.byType(ItemListRow));
      final chevron = t.getRect(find.byIcon(Icons.chevron_right));
      final bar = t.getRect(find.byType(LifespanBar));
      final icon = t.getRect(find.byIcon(Icons.local_fire_department_outlined));
      expect(chevron.right, closeTo(row.right - 14, 12));
      expect(bar.right, lessThanOrEqualTo(chevron.left));
      expect(bar.width, 64);
      expect(icon.left, closeTo(row.left + 14, 1));
      expect(t.getTopLeft(find.text('Furnace')).dx, greaterThan(icon.right));
      expect(find.textContaining('5½ YRS'), findsOneWidget);
      expect(t.getTopRight(find.textContaining('5½ YRS')).dx,
          lessThanOrEqualTo(bar.left));
    });

    testWidgets('the compact row has a 44 pt touch height', (t) async {
      await pumpPhone(t, card([furnace(compact: true)]));
      expect(t.getSize(find.byType(ItemListRow)).height, greaterThanOrEqualTo(44));
    });
  });
}
