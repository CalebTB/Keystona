import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/home_profile/lifespan/appliance_lifespan.dart';
import 'package:keystona/features/home_profile/lifespan/lifespan_reading.dart';
import 'package:keystona/features/home_profile/models/appliance.dart';
import 'package:keystona/features/home_profile/models/appliance_care_tips.dart';
import 'package:keystona/features/home_profile/models/appliance_form_data.dart';
import 'package:keystona/features/home_profile/models/appliance_list.dart';
import 'package:keystona/features/home_profile/models/appliance_specs.dart';
import 'package:keystona/features/home_profile/models/appliance_warranty_check.dart';
import 'package:keystona/features/home_profile/models/form_date.dart';
import 'package:keystona/features/home_profile/models/item_completion.dart';
import 'package:keystona/features/home_profile/models/item_photo_type.dart';
import 'package:keystona/features/home_profile/models/item_ref.dart';
import 'package:keystona/features/home_profile/models/item_service_entry.dart';
import 'package:keystona/features/home_profile/models/item_tasks.dart';
import 'package:keystona/features/home_profile/widgets/appliance_detail/appliance_detail_mapper.dart';
import 'package:keystona/features/maintenance/models/maintenance_task.dart';

import 'c_support.dart';

void main() {
  final today = kToday;

  group('appliance lifespan', () {
    test('ages from the purchase date against the middle of the range', () {
      final washer = kitAppliances().firstWhere((a) => a.id == 'wa');
      final r = washer.lifespanReading(now: today);
      expect(r.ageLabel, '3 yrs');
      expect(r.lifeYears, 11);
      expect(r.replaceYear, 2034);
      expect(r.band, LifespanBand.plenty);
    });

    test('an override beats the scan range; no purchase date is unknown', () {
      final a = anAppliance('x', 'Fridge', purchaseDate: '2010-01-01', life: 13)
          .copyWith(lifespanOverride: 8);
      expect(a.lifespanReading(now: today).lifeYears, 8);
      final none = anAppliance('y', 'Oven', life: 15);
      expect(none.lifespanReading(now: today).percent, isNull);
      expect(none.lifespanReading(now: today).ageLabel, '');
    });

    test('type defaults: by name, then by category', () {
      expect(
        ApplianceLifespanDefaults.years('Main Dishwasher', ApplianceCategory.kitchen),
        10,
      );
      expect(
        ApplianceLifespanDefaults.years('Washer', ApplianceCategory.laundry),
        11,
      );
      expect(
        ApplianceLifespanDefaults.years('Gizmo', ApplianceCategory.cleaning),
        8,
      );
    });
  });

  group('ApplianceList', () {
    final all = kitAppliances();

    test('oldest first puts the most life used on top', () {
      final names = ApplianceList.shown(all, now: today).map((a) => a.name);
      expect(names.first, 'Dishwasher');
      expect(names.toList(), ['Dishwasher', 'Refrigerator', 'Range', 'Washer', 'Dryer']);
    });

    test('A-Z and the category filter', () {
      expect(
        ApplianceList.shown(all, sort: ApplianceSort.alphabetical, now: today)
            .map((a) => a.name),
        ['Dishwasher', 'Dryer', 'Range', 'Refrigerator', 'Washer'],
      );
      expect(
        ApplianceList.shown(all, category: ApplianceCategory.laundry, now: today)
            .map((a) => a.id),
        ['wa', 'dr'],
      );
    });

    test('an appliance with no purchase date sorts last', () {
      final list = ApplianceList.shown([
        anAppliance('n', 'Aaa', life: 10),
        ...all,
      ], now: today);
      expect(list.last.id, 'n');
    });

    test('chips list only categories in use, in enum order', () {
      expect(ApplianceList.categories(all), [
        ApplianceCategory.kitchen,
        ApplianceCategory.laundry,
      ]);
    });

    test('eyebrow counts tracked and past-life', () {
      expect(
        ApplianceList.eyebrow('1428 Elm Hollow', all, now: today),
        '1428 ELM HOLLOW · 5 TRACKED · 1 PAST ITS LIFE',
      );
      expect(
        ApplianceList.eyebrow(null, [all[1]], now: today),
        '1 TRACKED',
      );
    });
  });

  group('ApplianceSpecs', () {
    test('reads the scan notes', () {
      final s = ApplianceSpecs.fromScanNotes(
        'Capacity: 4.5 cu ft\nType: Front-load\nEnergy Star: Yes\nVoltage: 120 V',
      );
      expect(s.capacity, '4.5 cu ft');
      expect(s.type, 'Front-load');
      expect(s.energyStar, isTrue);
      expect(s.capacityNumber, '4.5');
      expect(ApplianceSpecs.fromScanNotes('Energy Star: No').energyStar, isFalse);
      expect(ApplianceSpecs.fromScanNotes(null).count, 0);
    });

    test('merging keeps unknown keys and drops emptied ones', () {
      const s = ApplianceSpecs(capacity: '5 cu ft', energyStar: false);
      final merged = s.mergeInto({
        'capacity': '4 cu ft',
        'energy_star': true,
        'custom': 'x',
        'type': 'Top-load',
      });
      expect(merged, {'capacity': '5 cu ft', 'custom': 'x'});
    });

    test('capacity input gets the unit only when it is a bare number', () {
      expect(ApplianceSpecs.capacityFromInput('4.5'), '4.5 cu ft');
      expect(ApplianceSpecs.capacityFromInput('4.5 cubic'), '4.5 cubic');
      expect(ApplianceSpecs.capacityFromInput(' '), isNull);
    });

    test('entries follow the kit order and Energy Star reads Certified', () {
      final s = ApplianceSpecs.fromJson({
        'capacity': '4.5 cu ft',
        'type': 'Front-load',
        'spin_speed': '1,300 RPM',
        'hookup': 'Hot + cold · 120 V',
        'energy_star': true,
      });
      expect(s.entries.map((e) => e.label), [
        'Capacity',
        'Type',
        'Spin speed',
        'Hookup',
        'Energy Star',
      ]);
      expect(s.entries.last.value, 'Certified');
    });
  });

  group('FormDate', () {
    test('reads real dates in common shapes, rejects the rest', () {
      expect(FormDate.parse('12/09/2023'), DateTime(2023, 12, 9));
      expect(FormDate.parse('12 9 2023'), DateTime(2023, 12, 9));
      expect(FormDate.parse('12092023'), DateTime(2023, 12, 9));
      expect(FormDate.parse('13/09/2023'), isNull);
      expect(FormDate.parse('02/30/2023'), isNull);
      expect(FormDate.parse('12/09/23'), isNull);
      expect(FormDate.isValidOrEmpty(''), isTrue);
      expect(FormDate.column(DateTime(2023, 1, 5)), '2023-01-05');
      expect(FormDate.format(DateTime(2023, 1, 5)), '01/05/2023');
    });
  });

  group('ApplianceFormData', () {
    test('only a name is needed', () {
      expect(const ApplianceFormData(category: ApplianceCategory.other, name: ' ').canSave, isFalse);
      expect(const ApplianceFormData(category: ApplianceCategory.other, name: 'Fridge').canSave, isTrue);
    });

    test('a new appliance writes the columns the table needs', () {
      const data = ApplianceFormData(
        category: ApplianceCategory.laundry,
        name: ' Washer ',
        brand: 'Halden',
        price: r'$1,299.50',
        purchaseDate: '12/09/2023',
        hasWarranty: true,
        warrantyProvider: 'Care',
        warrantyExpires: '12/09/2026',
        specs: ApplianceSpecs(capacity: '4.5 cu ft', energyStar: true),
      );
      final f = data.toFields(defaultLifespanYears: 11);
      expect(f['category'], 'laundry');
      expect(f['appliance_type'], 'laundry');
      expect(f['name'], 'Washer');
      expect(f['brand'], 'Halden');
      expect(f['model'], isNull);
      expect(f['purchase_price'], 1299.5);
      expect(f['purchase_date'], '2023-12-09');
      expect(f['warranty_expiration'], '2026-12-09');
      expect(f['warranty_provider'], 'Care');
      expect(f['specifications'], {'capacity': '4.5 cu ft', 'energy_star': true});
      expect(f['expected_lifespan_min'], 11);
      expect(f['expected_lifespan_max'], 11);
      expect(f.containsKey('lifespan_override'), isFalse);
      expect(f.containsKey('user_id'), isFalse); // the repository adds it
    });

    test('an edit clears what was emptied, keeps other specs and its life', () {
      final existing = anAppliance('wa', 'Washer', life: 11, specs: {'spin_speed': '1,300 RPM'});
      final f = const ApplianceFormData(
        category: ApplianceCategory.laundry,
        name: 'Washer',
        lifespan: '9',
      ).toFields(existing: existing, defaultLifespanYears: 99);
      expect(f['brand'], isNull);
      expect(f['warranty_provider'], isNull);
      expect(f['warranty_expiration'], isNull);
      expect(f['lifespan_override'], 9);
      expect(f.containsKey('expected_lifespan_min'), isFalse);
      expect((f['specifications'] as Map)['spin_speed'], '1,300 RPM');
    });
  });

  group('ApplianceWarrantyCheck', () {
    test('ends soon only while running and within 90 days', () {
      expect(ApplianceWarrantyCheck.endsSoon(DateTime(2026, 12, 9), today), isTrue);
      expect(ApplianceWarrantyCheck.daysLeft(DateTime(2026, 12, 9), today), 66);
      expect(ApplianceWarrantyCheck.endsSoon(DateTime(2027, 6, 1), today), isFalse);
      expect(ApplianceWarrantyCheck.endsSoon(DateTime(2026, 9, 1), today), isFalse);
      expect(ApplianceWarrantyCheck.endsSoon(null, today), isFalse);
    });

    test('the check is due a fortnight before, never in the past', () {
      expect(ApplianceWarrantyCheck.dueDate(DateTime(2026, 12, 9), today), DateTime(2026, 11, 25));
      expect(ApplianceWarrantyCheck.dueDate(DateTime(2026, 10, 8), today), today);
    });

    test('finds its own open task and carries every NOT NULL column', () {
      final wa = kitAppliances().firstWhere((a) => a.id == 'wa');
      final mine = washerTask('c', 'Check', due: DateTime(2026, 11, 25))
          .copyWith(tags: [ApplianceWarrantyCheck.tag]);
      final other = washerTask('o', 'Other', due: DateTime(2026, 11, 25));
      expect(ApplianceWarrantyCheck.existing([other, mine], 'wa')?.id, 'c');
      expect(ApplianceWarrantyCheck.existing([other], 'wa'), isNull);
      expect(ApplianceWarrantyCheck.existing([mine], 'dr'), isNull);
      final f = ApplianceWarrantyCheck.fields(wa, DateTime(2026, 11, 25));
      expect(f['user_id'], 'u1');
      expect(f['property_id'], 'p1');
      expect(f['linked_appliance_id'], 'wa');
      expect(f['due_date'], '2026-11-25');
      expect(f['task_origin'], 'one_time');
      expect(f['tags'], ['warranty-check']);
    });
  });

  group('ItemTasks', () {
    test('open tasks of the item, soonest first, not the finished ones', () {
      final tasks = [
        washerTask('b', 'B', due: day(11, 1)),
        washerTask('a', 'A', due: day(10, 19)),
        washerTask('d', 'D', due: day(10, 1)).copyWith(status: TaskStatus.completed),
        task('x', 'X', due: day(10, 2)).copyWith(linkedSystemId: 'wa'),
        washerTask('off', 'Off', due: day(10, 3)).copyWith(notificationsEnabled: false),
      ];
      expect(ItemTasks.open(tasks, const ItemRef.appliance('wa')).map((t) => t.id), ['a', 'b']);
      expect(ItemTasks.open(tasks, const ItemRef.system('wa')).map((t) => t.id), ['x']);
    });

    test('a card reads EVERY, who, time and cost', () {
      final t = washerTask(
        'f',
        'Service',
        due: day(10, 28),
        minutes: 60,
        who: DiyOrPro.professional,
        recurrence: RecurrenceType.annual,
      ).copyWith(estimatedCost: 129, season: 'fall');
      final c = ItemTasks.card(t, today);
      expect(c.every, 'EVERY FALL');
      expect(c.who, 'PRO');
      expect(c.pro, isTrue);
      expect(c.meta, '1 HR · ~\$129');
      expect(c.dateLabel, 'OCT 28');
    });

    test('the Done summary totals cost and times since the first year', () {
      final done = [
        ItemCompletion(id: '1', taskName: 'A', completedOn: DateTime(2026, 7, 6), doneBy: 'You', cost: 22),
        ItemCompletion(id: '2', taskName: 'B', completedOn: DateTime(2025, 10, 1), doneBy: 'Summit Heating & Air', cost: 129),
        ItemCompletion(id: '3', taskName: 'C', completedOn: DateTime(2026, 3, 30), doneBy: 'You'),
      ];
      final s = ItemTasks.summary(done)!;
      expect(s.spentLabel, '\$151');
      expect(s.caption, 'SPENT ON UPKEEP SINCE 2025 · 3 TIMES');
      expect(ItemTasks.summary(const []), isNull);
      expect(ItemTasks.doneMeta(done[0], today), 'JUL 6 · YOU');
      expect(ItemTasks.doneMeta(done[1], today), 'OCT 2025 · SUMMIT HEATING & AIR');
    });
  });

  group('photos', () {
    test('legacy photo types read as the nearest kit tag', () {
      expect(ItemPhotoType.fromValue('model_label'), ItemPhotoType.label);
      expect(ItemPhotoType.fromValue('overview'), ItemPhotoType.unit);
      expect(ItemPhotoType.fromValue('maintenance'), ItemPhotoType.filter);
      expect(ItemPhotoType.fromValue('condition'), ItemPhotoType.repair);
      expect(ItemPhotoType.fromValue('repair'), ItemPhotoType.repair);
      expect(ItemPhotoType.fromValue(null), ItemPhotoType.unit);
    });
  });

  group('ApplianceDetailMapper', () {
    final washer = kitAppliances().firstWhere((a) => a.id == 'wa');
    final hoses = ItemServiceEntry(
      id: 'h',
      item: const ItemRef.appliance('wa'),
      kind: ServiceKind.repair,
      serviceDate: DateTime(2025, 6, 10),
      title: 'Replaced the inlet hoses',
      provider: 'Did it myself',
      note: 'steel-braided',
      cost: 34,
    );

    test('history adds the purchase row and totals 883 dollars since 2023', () {
      final rows = ApplianceDetailMapper.history(washer, [hoses]);
      expect(rows.map((r) => r.title), ['Replaced the inlet hoses', 'Bought']);
      expect(rows.first.subtitle, 'Did it myself · steel-braided');
      expect(rows.last.hollow, isTrue);
      expect(rows.last.costLabel, '\$849');
      expect(ApplianceDetailMapper.historyTotal(washer, [hoses]), '\$883 since 2023');
    });

    test('a purchased log entry replaces the synthesized row', () {
      final bought = ItemServiceEntry(
        id: 'b',
        item: const ItemRef.appliance('wa'),
        kind: ServiceKind.purchased,
        serviceDate: DateTime(2023, 12, 9),
        title: 'Bought & installed',
        cost: 849,
      );
      final rows = ApplianceDetailMapper.history(washer, [hoses, bought]);
      expect(rows.length, 2);
      expect(rows.where((r) => r.title == 'Bought'), isEmpty);
    });

    test('purchase and identification cards only show what is known', () {
      final p = ApplianceDetailMapper.purchase(washer);
      expect(p.map((r) => r.label), ['Price', 'From', 'Bought', 'Warranty']);
      expect(p.last.value, 'Halden + Brightway Care · ends Dec 9, 2026');
      final bare = anAppliance('z', 'Bare');
      expect(ApplianceDetailMapper.purchase(bare), isEmpty);
      expect(ApplianceDetailMapper.identification(washer).where((r) => r.copyable).single.value, 'HL3390218K');
      expect(ApplianceDetailMapper.specifications(washer).length, 5);
    });
  });

  test('care tips follow the kind of appliance', () {
    final wa = kitAppliances().firstWhere((a) => a.id == 'wa');
    expect(ApplianceCareTips.forAppliance(wa), ApplianceCareTips.frontLoader);
    expect(
      ApplianceCareTips.forAppliance(anAppliance('d', 'Dishwasher')),
      contains('Dishwashers'),
    );
    expect(ApplianceCareTips.forAppliance(anAppliance('z', 'Gizmo')), ApplianceCareTips.general);
  });
}
