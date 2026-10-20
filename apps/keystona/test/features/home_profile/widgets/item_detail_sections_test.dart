import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/theme/aurora_home_shared.dart';
import 'package:keystona/core/widgets/aurora/aurora_chip.dart';
import 'package:keystona/core/widgets/aurora/aurora_pressable.dart';
import 'package:keystona/core/widgets/aurora/aurora_task_row.dart';
import 'package:keystona/features/home_profile/lifespan/lifespan_reading.dart';
import 'package:keystona/features/home_profile/widgets/shared/item_document_row.dart';
import 'package:keystona/features/home_profile/widgets/shared/item_documents_card.dart';
import 'package:keystona/features/home_profile/widgets/shared/item_hero.dart';
import 'package:keystona/features/home_profile/widgets/shared/item_history_timeline.dart';
import 'package:keystona/features/home_profile/widgets/shared/item_key_value.dart';
import 'package:keystona/features/home_profile/widgets/shared/item_key_value_card.dart';
import 'package:keystona/features/home_profile/widgets/shared/item_lifespan_card.dart';
import 'package:keystona/features/home_profile/widgets/shared/item_next_up_entry.dart';
import 'package:keystona/features/home_profile/widgets/shared/item_next_up_list.dart';
import 'package:keystona/features/home_profile/widgets/shared/item_photo_tile.dart';
import 'package:keystona/features/home_profile/widgets/shared/item_timeline_row.dart';
import 'package:keystona/features/home_profile/widgets/shared/mono_section_label.dart';

import '../support/home_widget_harness.dart';

final reading = LifespanReading.ofAge(
  ageYears: 5.5,
  lifeYears: 15,
  startYear: 2021,
);

Widget lifespanCard() => ItemLifespanCard(
  reading: reading,
  startLabel: 'Installed Mar 2021',
  body: const TextSpan(
    children: [
      TextSpan(text: 'About '),
      TextSpan(
        text: '9½ years left',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      TextSpan(
        text:
            '. A furnace this size runs about \$5,800–7,200 to replace and a very long sentence so it wraps.',
      ),
    ],
  ),
);

const tasks = [
  ItemNextUpEntry(
    id: 'filter',
    name: 'Replace HVAC air filter',
    metaLine: 'HVAC · 15 MIN · \$25',
    dateLabel: 'OCT 7',
    soon: true,
  ),
  ItemNextUpEntry(
    id: 'service',
    name: 'Service the furnace with a really long task name that wraps',
    metaLine: 'HVAC · FALL PREP',
    dateLabel: 'OCT 28',
    isPro: true,
  ),
];

const kv = [
  ItemKeyValue(label: 'Brand', value: 'Northline'),
  ItemKeyValue(label: 'Serial', value: '2103A47719', copyable: true),
  ItemKeyValue(label: 'Output', value: '80,000 BTU · 95% AFUE · a long extra detail'),
];

const history = [
  ItemTimelineRow(
    dateLabel: 'Oct 2025',
    title: 'Annual tune-up',
    subtitle: 'Summit Heating & Air · receipt saved',
    costLabel: r'$129',
  ),
  ItemTimelineRow(
    dateLabel: 'Mar 2021',
    title: 'Installed',
    subtitle: 'Summit Heating & Air',
    costLabel: r'$4,850',
    hollow: true,
  ),
];

const docs = [
  ItemDocumentRow(
    id: 'd1',
    title: 'Northline warranty',
    meta: 'Warranty · PDF · until Mar 2031',
  ),
  ItemDocumentRow(id: 'd2', title: 'Install invoice', meta: 'Receipt · Mar 2021'),
];

void main() {
  group('responsive', () {
    testWidgetResponsive(
      'ItemHero',
      () => ItemHero(
        eyebrow: 'HVAC · SYSTEM',
        statusChip: const StatusChip.done(label: '✓ Healthy'),
        title: 'Furnace with a long name that has to wrap at large text sizes',
        subtitle: 'Northline NF95-080B · Basement utility room',
        photoTag: 'Unit',
        photoBadge: '4 photos',
      ),
    );
    testWidgetResponsive('ItemLifespanCard', lifespanCard);
    testWidgetResponsive(
      'ItemNextUpList',
      () => ItemNextUpList(
        tasks: tasks,
        onTap: (_) {},
        onToggle: (_) {},
        allLabel: 'All 5 HVAC tasks',
        onAll: () {},
      ),
    );
    testWidgetResponsive('ItemKeyValueCard', () => const ItemKeyValueCard(rows: kv));
    testWidgetResponsive(
      'ItemHistoryTimeline',
      () => const ItemHistoryTimeline(rows: history),
    );
    testWidgetResponsive(
      'ItemDocumentsCard',
      () => ItemDocumentsCard(rows: docs, onTap: (_) {}),
    );
    testWidgetResponsive(
      'ItemPhotoTile',
      () => const ItemPhotoTile(
        tag: 'A rather long photo tag to ellipsize',
        badgeLabel: '4 photos on the free plan',
      ),
    );
    testWidgetResponsive(
      'MonoSectionLabel',
      () => const MonoSectionLabel(
        'History · 3 with a long title that wraps',
        trailing: r'$5,189 since 2021 and some more words',
      ),
    );
  });

  group('MonoSectionLabel', () {
    testWidgets('label at the left, trailing note at the right', (t) async {
      await pumpPhone(
        t,
        const MonoSectionLabel('History · 3', trailing: r'$5,189 since 2021'),
      );
      expect(find.text('HISTORY · 3'), findsOneWidget);
      expect(t.getTopLeft(find.text('HISTORY · 3')).dx, kPad);
      expect(t.getTopRight(find.text(r'$5,189 SINCE 2021')).dx, contentRight);
    });
  });

  group('ItemHero', () {
    testWidgets('texts at the left, photo spans the width at 16:10', (t) async {
      await pumpPhone(
        t,
        ItemHero(
          eyebrow: 'HVAC · SYSTEM',
          statusChip: const StatusChip.done(label: '✓ Healthy'),
          title: 'Furnace',
          subtitle: 'Northline NF95-080B',
          photoTag: 'Unit',
          photoBadge: '4 photos',
        ),
      );
      expect(t.getTopLeft(find.text('HVAC · SYSTEM')).dx, kPad);
      expect(t.getTopLeft(find.text('Furnace')).dx, kPad);
      final eyebrow = t.getRect(find.text('HVAC · SYSTEM'));
      final chip = t.getRect(find.byType(StatusChip));
      expect(chip.left, greaterThan(eyebrow.right));
      final photo = t.getRect(find.byType(ItemPhotoTile));
      expect(photo.left, kPad);
      expect(photo.right, contentRight);
      expect(
        photo.width / photo.height,
        closeTo(AuroraHomeSizes.heroAspect, 0.01),
      );
      expect(photo.top, greaterThan(t.getRect(find.text('Northline NF95-080B')).bottom));
    });

    testWidgets('photo badge is called back', (t) async {
      var taps = 0;
      await pumpPhone(
        t,
        ItemHero(
          eyebrow: 'HVAC',
          title: 'Furnace',
          photoBadge: '4 photos',
          onPhotoBadgeTap: () => taps++,
        ),
      );
      await t.tap(find.text('4 PHOTOS'));
      expect(taps, 1);
    });
  });

  group('ItemPhotoTile positions', () {
    testWidgets('tag bottom left, badge top right', (t) async {
      await pumpPhone(
        t,
        const ItemPhotoTile(tag: 'Unit', badgeLabel: '4 photos'),
      );
      final tile = t.getRect(find.byType(ItemPhotoTile));
      final tag = t.getRect(find.text('UNIT'));
      final badge = t.getRect(find.text('4 PHOTOS'));
      expect(tag.left, lessThan(tile.left + tile.width / 2));
      expect(tag.bottom, greaterThan(tile.center.dy));
      expect(badge.right, greaterThan(tile.center.dx));
      expect(badge.top, lessThan(tile.center.dy));
      expect(badge.right, lessThanOrEqualTo(tile.right));
    });

    testWidgets('grid tiles are square', (t) async {
      await pumpPhone(
        t,
        const ItemPhotoTile(
          tag: 'Label',
          aspectRatio: AuroraHomeSizes.tileAspect,
        ),
      );
      final r = t.getRect(find.byType(ItemPhotoTile));
      expect(r.width, closeTo(r.height, 0.5));
    });

    testWidgets('tap calls back and the image slot is shown', (t) async {
      var taps = 0;
      await pumpPhone(
        t,
        ItemPhotoTile(
          tag: 'Unit',
          image: const ColoredBox(color: Colors.red, key: Key('img')),
          onTap: () => taps++,
        ),
      );
      expect(find.byKey(const Key('img')), findsOneWidget);
      await t.tap(find.byType(ItemPhotoTile));
      expect(taps, 1);
    });
  });

  group('ItemLifespanCard positions', () {
    testWidgets('age at the left, expected life at the right', (t) async {
      await pumpPhone(t, lifespanCard());
      final card = t.getRect(find.byType(ItemLifespanCard));
      expect(find.textContaining('5½ yrs'), findsOneWidget);
      expect(find.text('OF ~15 YRS EXPECTED'), findsOneWidget);
      expect(
        t.getTopLeft(find.textContaining('5½ yrs')).dx,
        closeTo(card.left + 14 + 1, 3),
      );
      expect(
        t.getTopRight(find.text('OF ~15 YRS EXPECTED')).dx,
        closeTo(card.right - 14 - 1, 3),
      );
      expect(t.getTopLeft(find.text('INSTALLED MAR 2021')).dx,
          closeTo(card.left + 14 + 1, 3));
      expect(
        t.getTopRight(find.text('REPLACE AROUND 2036')).dx,
        closeTo(card.right - 14 - 1, 3),
      );
    });

    testWidgets('the body sentence sits under the bar', (t) async {
      await pumpPhone(t, lifespanCard());
      final text = t.getRect(find.textContaining('9½ years left', findRichText: true));
      final labels = t.getRect(find.text('INSTALLED MAR 2021'));
      expect(text.top, greaterThan(labels.bottom));
    });

    testWidgets('no age shows a dash and no expected life', (t) async {
      await pumpPhone(t, ItemLifespanCard(reading: LifespanReading.unknown));
      expect(find.textContaining('—'), findsOneWidget);
      expect(find.textContaining('EXPECTED'), findsNothing);
    });
  });

  group('ItemNextUpList', () {
    testWidgets('names at the left, dates at the right, PRO in the meta', (
      t,
    ) async {
      await pumpPhone(
        t,
        ItemNextUpList(tasks: tasks, onTap: (_) {}, onToggle: (_) {}),
      );
      expect(find.text('OCT 7'), findsOneWidget);
      expect(find.text('OCT 28'), findsOneWidget);
      expect(find.textContaining('FALL PREP · PRO'), findsOneWidget);
      expect(t.getTopRight(find.text('OCT 7')).dx, lessThan(contentRight));
      expect(t.getTopRight(find.text('OCT 7')).dx, greaterThan(contentRight - 30));
      expect(
        t.getTopLeft(find.text('Replace HVAC air filter')).dx,
        greaterThan(t.getTopLeft(find.byType(ItemNextUpList)).dx),
      );
    });

    testWidgets('row, check circle and the All pill call back', (t) async {
      final tapped = <String>[];
      final toggled = <String>[];
      var all = 0;
      await pumpPhone(
        t,
        ItemNextUpList(
          tasks: tasks,
          onTap: tapped.add,
          onToggle: toggled.add,
          allLabel: 'All 5 HVAC tasks',
          onAll: () => all++,
        ),
      );
      await t.tap(find.text('Replace HVAC air filter'));
      expect(tapped, ['filter']);
      await t.tap(
        find.descendant(
          of: find.byType(AuroraTaskRow).first,
          matching: find.byType(AuroraPressable),
        ).last,
      );
      expect(toggled, ['filter']);
      await t.ensureVisible(find.text('All 5 HVAC tasks'));
      await t.tap(find.text('All 5 HVAC tasks'));
      expect(all, 1);
    });

    testWidgets('a done task reads DONE and the All pill is full width', (
      t,
    ) async {
      await pumpPhone(
        t,
        ItemNextUpList(
          tasks: const [
            ItemNextUpEntry(
              id: 'a',
              name: 'Replace HVAC air filter',
              metaLine: 'HVAC',
              dateLabel: 'Done',
              done: true,
            ),
          ],
          onTap: (_) {},
          allLabel: 'All 5 HVAC tasks',
          onAll: () {},
        ),
      );
      expect(find.text('DONE'), findsOneWidget);
      final pill = t.getRect(find.ancestor(
        of: find.text('All 5 HVAC tasks'),
        matching: find.byType(Container),
      ).first);
      expect(pill.left, kPad);
      expect(pill.right, contentRight);
    });
  });

  group('ItemKeyValueCard', () {
    testWidgets('labels at the left, values at the right', (t) async {
      await pumpPhone(t, const ItemKeyValueCard(rows: kv));
      final card = t.getRect(find.byType(ItemKeyValueCard));
      expect(t.getTopLeft(find.text('BRAND')).dx, closeTo(card.left + 14 + 1, 3));
      expect(
        t.getTopRight(find.text('Northline')).dx,
        closeTo(card.right - 14 - 1, 3),
      );
      // Label and value share a row; the value is to the right of the label.
      expect(
        t.getTopLeft(find.text('Northline')).dx,
        greaterThan(t.getTopRight(find.text('BRAND')).dx),
      );
    });

    testWidgets('copy icon: copies, reads COPIED, then flips back', (t) async {
      final copied = <String>[];
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpPhone(t, const ItemKeyValueCard(rows: kv));
      final icon = find.byIcon(Icons.content_copy_outlined);
      final card = t.getRect(find.byType(ItemKeyValueCard));
      expect(t.getRect(icon).right, lessThanOrEqualTo(card.right));
      expect(find.byIcon(Icons.content_copy_outlined), findsOneWidget);

      await t.tap(icon);
      await t.pump();
      expect(copied, ['2103A47719']);
      expect(find.text('COPIED'), findsOneWidget);
      expect(find.byIcon(Icons.content_copy_outlined), findsNothing);

      await t.pump(AuroraHomeDurations.copied + const Duration(milliseconds: 50));
      expect(find.text('COPIED'), findsNothing);
      expect(find.byIcon(Icons.content_copy_outlined), findsOneWidget);
    });

    testWidgets('the copy target is at least 44 square', (t) async {
      await pumpPhone(t, const ItemKeyValueCard(rows: kv));
      final target = t.getSize(find.ancestor(
        of: find.byIcon(Icons.content_copy_outlined),
        matching: find.byType(ConstrainedBox),
      ).first);
      expect(target.width, greaterThanOrEqualTo(44));
      expect(target.height, greaterThanOrEqualTo(44));
    });
  });

  group('ItemHistoryTimeline', () {
    testWidgets('dot at the left, cost at the right, newest above oldest', (
      t,
    ) async {
      await pumpPhone(t, const ItemHistoryTimeline(rows: history));
      final card = t.getRect(find.byType(ItemHistoryTimeline));
      expect(t.getTopRight(find.text(r'$129')).dx, closeTo(card.right - 14 - 1, 3));
      expect(t.getTopRight(find.text(r'$4,850')).dx, closeTo(card.right - 14 - 1, 3));
      expect(t.getTopLeft(find.text('OCT 2025')).dx, greaterThan(card.left + 14));
      expect(
        t.getTopLeft(find.text('Annual tune-up')).dy,
        lessThan(t.getTopLeft(find.text('Installed')).dy),
      );
      // The title column lines up under its date.
      expect(
        t.getTopLeft(find.text('Annual tune-up')).dx,
        t.getTopLeft(find.text('OCT 2025')).dx,
      );
    });

    testWidgets('a hollow dot for the first entry, filled for the rest', (
      t,
    ) async {
      await pumpPhone(t, const ItemHistoryTimeline(rows: history));
      final dots = t
          .widgetList<Container>(find.byType(Container))
          .where((c) {
            final d = c.decoration;
            return d is BoxDecoration && d.shape == BoxShape.circle;
          })
          .toList();
      expect(dots.length, 2);
      expect((dots.first.decoration! as BoxDecoration).color,
          isNot((dots.last.decoration! as BoxDecoration).color));
    });
  });

  group('ItemDocumentsCard', () {
    testWidgets('chevron at the right edge; tap passes the id', (t) async {
      final tapped = <String>[];
      await pumpPhone(t, ItemDocumentsCard(rows: docs, onTap: tapped.add));
      final card = t.getRect(find.byType(ItemDocumentsCard));
      final chevrons = find.byIcon(Icons.chevron_right);
      expect(chevrons, findsNWidgets(2));
      expect(t.getRect(chevrons.first).right, closeTo(card.right - 14, 4));
      expect(find.text('WARRANTY · PDF · UNTIL MAR 2031'), findsOneWidget);
      await t.tap(find.text('Install invoice'));
      expect(tapped, ['d2']);
    });
  });
}
