import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/theme/aurora_colors.dart';
import 'package:keystona/core/theme/aurora_radius.dart';
import 'package:keystona/features/home_profile/widgets/shared/dashed_action_button.dart';
import 'package:keystona/features/home_profile/widgets/shared/dashed_suggestion_chip.dart';
import 'package:keystona/features/home_profile/widgets/shared/scan_field_box.dart';

import '../support/home_widget_harness.dart';

const _boundary = Key('boundary');

Future<ui.Image> capture(WidgetTester t) async {
  final render = t.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
  late ui.Image image;
  await t.runAsync(() async => image = await render.toImage());
  return image;
}

Future<Color> pixel(WidgetTester t, ui.Image image, int x, int y) async {
  late ByteData data;
  await t.runAsync(() async => data = (await image.toByteData())!);
  final i = (y * image.width + x) * 4;
  return Color.fromARGB(
    data.getUint8(i + 3),
    data.getUint8(i),
    data.getUint8(i + 1),
    data.getUint8(i + 2),
  );
}

Widget field({required bool fromScan}) => Align(
  alignment: Alignment.topLeft,
  child: RepaintBoundary(
    key: _boundary,
    child: ScanFieldBox(
      fromScan: fromScan,
      child: const ColoredBox(
        color: Colors.white,
        child: SizedBox(width: 200, height: 50),
      ),
    ),
  ),
);

void main() {
  testWidgetResponsive(
    'DashedActionButton',
    () => DashedActionButton(
      icon: Icons.add,
      label: 'Log a repair or service with a very long label to wrap',
      onTap: () {},
    ),
  );
  testWidgetResponsive(
    'DashedSuggestionChip wrap',
    () => Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final l in ['Plumbing', 'Windows', 'Sump pump', 'Insulation', 'Siding', 'Garage door'])
          DashedSuggestionChip(label: l, onTap: () {}),
      ],
    ),
  );
  testWidgetResponsive(
    'ScanFieldBox',
    () => const ScanFieldBox(
      fromScan: true,
      child: TextField(decoration: InputDecoration(border: OutlineInputBorder())),
    ),
  );

  testWidgets('dashed action button is full width, centered, 48+ tall, tappable', (
    t,
  ) async {
    var taps = 0;
    await pumpPhone(
      t,
      DashedActionButton(
        icon: Icons.add,
        label: 'Log a repair or service',
        onTap: () => taps++,
      ),
    );
    final r = t.getRect(find.byType(DashedActionButton));
    expect(r.left, kPad);
    expect(r.right, contentRight);
    expect(r.height, greaterThanOrEqualTo(48));
    expect(t.getCenter(find.text('Log a repair or service')).dx,
        closeTo(r.center.dx + 11, 14));
    await t.tap(find.text('Log a repair or service'));
    expect(taps, 1);
  });

  testWidgets('suggestion chips wrap onto rows and stay 44 tall', (t) async {
    final tapped = <String>[];
    await pumpPhone(
      t,
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final l in ['Plumbing', 'Windows', 'Sump pump', 'Insulation', 'Siding'])
            DashedSuggestionChip(label: l, onTap: () => tapped.add(l)),
        ],
      ),
    );
    final tops = {
      for (final c in find.byType(DashedSuggestionChip).evaluate())
        t.getTopLeft(find.byWidget(c.widget)).dy,
    };
    expect(tops.length, greaterThan(1));
    for (final c in find.byType(DashedSuggestionChip).evaluate()) {
      final r = t.getRect(find.byWidget(c.widget));
      expect(r.right, lessThanOrEqualTo(contentRight + 0.5));
      expect(r.height, greaterThanOrEqualTo(36));
    }
    await t.tap(find.text('Windows'));
    expect(tapped, ['Windows']);
  });

  testWidgets('the dashed outline paints dashes along the top edge', (t) async {
    await pumpPhone(
      t,
      Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: _boundary,
          child: const SizedBox(
            width: 200,
            height: 60,
            child: DashedActionButtonProbe(),
          ),
        ),
      ),
    );
    final image = await capture(t);
    var painted = 0;
    var gaps = 0;
    for (var x = 20; x < 180; x++) {
      final c = await pixel(t, image, x, 0);
      if (c.a > 0) {
        painted++;
      } else {
        gaps++;
      }
    }
    expect(painted, greaterThan(0));
    expect(gaps, greaterThan(0));
  });

  group('ScanFieldBox', () {
    testWidgets('paints cobalt on the left edge, not in the middle', (t) async {
      await pumpPhone(t, field(fromScan: true), padded: false);
      final image = await capture(t);
      expect(await pixel(t, image, 1, 25), AuroraColors.cobalt);
      expect(await pixel(t, image, 2, 25), AuroraColors.cobalt);
      expect(await pixel(t, image, 6, 25), Colors.white);
      expect(await pixel(t, image, 100, 25), Colors.white);
      expect(await pixel(t, image, 198, 25), Colors.white);
    });

    testWidgets('the edge follows the corner radius', (t) async {
      await pumpPhone(t, field(fromScan: true), padded: false);
      final image = await capture(t);
      // The very corner pixel is outside the rounded corner: not cobalt.
      expect(await pixel(t, image, 0, 0), isNot(AuroraColors.cobalt));
      expect(AuroraRadius.md.topLeft.x, greaterThan(0));
    });

    testWidgets('paints nothing once the value is edited', (t) async {
      await pumpPhone(t, field(fromScan: false), padded: false);
      final image = await capture(t);
      expect(await pixel(t, image, 1, 25), Colors.white);
    });
  });
}

/// A bare dashed box to probe the painter.
class DashedActionButtonProbe extends StatelessWidget {
  const DashedActionButtonProbe({super.key});

  @override
  Widget build(BuildContext context) => const DashedActionButton(
    icon: Icons.add,
    label: 'x',
    onTap: null,
  );
}
