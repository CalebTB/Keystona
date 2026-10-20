import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/home_profile/lifespan/lifespan_reading.dart';
import 'package:keystona/features/home_profile/models/item_ref.dart';
import 'package:keystona/features/home_profile/models/item_service_entry.dart';
import 'package:keystona/features/home_profile/models/system.dart';
import 'package:keystona/features/home_profile/models/system_document.dart';
import 'package:keystona/features/home_profile/models/system_reading.dart';
import 'package:keystona/features/home_profile/presenters/system_detail_view.dart';
import 'package:keystona/features/home_profile/systems_copy.dart';
import 'package:keystona/features/maintenance/models/maintenance_task.dart';

import '../maintenance/tab/tasks_test_support.dart';
import 'support/fake_systems.dart';

ItemServiceEntry entry(
  String id,
  DateTime date, {
  String title = 'Annual tune-up',
  double? cost,
  ServiceKind kind = ServiceKind.service,
  String? provider,
  bool warranty = false,
  String? doc,
}) => ItemServiceEntry(
  id: id,
  item: const ItemRef.system('fu'),
  kind: kind,
  serviceDate: date,
  title: title,
  cost: cost,
  provider: provider,
  underWarranty: warranty,
  documentId: doc,
);

void main() {
  final now = DateTime(2026, 10, 4);

  group('status chip', () {
    LifespanReading at(double age, int life) =>
        LifespanReading.ofAge(ageYears: age, lifeYears: life);

    test('words match the lifespan band', () {
      final s = aSystem('a');
      expect(SystemDetailView.chip(s, at(5, 15)).label, 'Healthy');
      expect(SystemDetailView.chip(s, at(12, 15)).label, 'Aging');
      expect(SystemDetailView.chip(s, at(14, 15)).label, 'At end of life');
      expect(SystemDetailView.chip(s, at(16, 15)).label, 'Past expected life');
      expect(SystemDetailView.chip(s, at(16, 15)).tone, SystemChipTone.overdue);
    });

    test('status beats the band', () {
      final s = aSystem('a', status: ItemStatus.needsRepair);
      expect(SystemDetailView.chip(s, at(1, 15)).label, 'Needs repair');
      final r = aSystem('a', status: ItemStatus.replaced);
      expect(SystemDetailView.chip(r, at(1, 15)).tone, SystemChipTone.muted);
    });
  });

  test('identification lists brand, model, serial (copyable) then specs', () {
    final s = aSystem(
      'a',
      specifications: {'fuel': 'Natural gas', 'filter': '16 × 25 × 1', 'cfm': 800},
    ).copyWith(serialNumber: '2103A47719');
    final rows = SystemDetailView.identification(s);
    expect(rows.map((r) => r.label), [
      'BRAND',
      'MODEL',
      'SERIAL',
      'FUEL',
      'FILTER',
      'CFM',
    ]);
    expect(rows[2].copyable, isTrue);
    expect(rows.where((r) => r.copyable).length, 1);
  });

  test('empty identification is empty (the card is hidden)', () {
    final s = aSystem('a', brand: null, model: null);
    expect(SystemDetailView.identification(s), isEmpty);
  });

  group('history', () {
    final s = aSystem('fu', installed: '2021-03-01', purchasePrice: 4850)
        .copyWith(installer: 'Summit Heating & Air');

    test('newest first, install row last and hollow, from the system', () {
      final rows = SystemDetailView.history(s, [
        entry('1', DateTime(2025, 10, 1), cost: 129, provider: 'Summit', doc: 'd'),
        entry('2', DateTime(2025, 2, 1), cost: 210, warranty: true),
      ]);
      expect(rows.map((r) => r.title), [
        'Annual tune-up',
        'Annual tune-up',
        'Installed',
      ]);
      expect(rows.first.dateLabel, 'OCT 2025');
      expect(rows.first.subtitle, 'Summit · receipt saved');
      expect(rows[1].subtitle, 'under warranty');
      expect(rows.last.hollow, isTrue);
      expect(rows.last.costLabel, r'$4,850');
      expect(rows.last.subtitle, 'Summit Heating & Air');
    });

    test('a logged installed entry replaces the derived one', () {
      final rows = SystemDetailView.history(s, [
        entry('1', DateTime(2021, 3, 1), kind: ServiceKind.installed, title: 'Installed'),
      ]);
      expect(rows.length, 1);
    });

    test('total spent and the year it started', () {
      final t = SystemDetailView.historyTotal(s, [
        entry('1', DateTime(2025, 10, 1), cost: 129),
        entry('2', DateTime(2025, 2, 1), cost: 210),
      ]);
      expect(t!.total, 5189);
      expect(t.sinceYear, 2021);
      expect(
        SystemDetailView.historyTotal(aSystem('x', installed: null), const []),
        isNull,
      );
    });
  });

  group('tasks', () {
    test('only this system\'s open, switched-on tasks, soonest first', () {
      final tasks = [
        task('a', 'Late', due: day(10, 28), system: 'x').copyWith(linkedSystemId: 'fu'),
        task('b', 'Soon', due: day(10, 7)).copyWith(linkedSystemId: 'fu'),
        task('c', 'Other', due: day(10, 5)).copyWith(linkedSystemId: 'zz'),
        task('d', 'Done', due: day(10, 1), status: TaskStatus.completed)
            .copyWith(linkedSystemId: 'fu'),
        task('e', 'Off', due: day(10, 2), enabled: false).copyWith(linkedSystemId: 'fu'),
      ];
      expect(SystemDetailView.openTasks(tasks, 'fu').map((t) => t.id), ['b', 'a']);
    });

    test('row shows category, minutes and cost, soon and PRO', () {
      final t = task('b', 'Replace HVAC air filter', due: day(10, 7), minutes: 15)
          .copyWith(estimatedCost: 25, diyOrPro: DiyOrPro.professional);
      final e = SystemDetailView.nextUp(t, kToday);
      expect(e.metaLine, r'HVAC · 15 MIN · $25');
      expect(e.dateLabel, 'OCT 7');
      expect(e.soon, isTrue);
      expect(e.isPro, isTrue);
    });
  });

  test('document meta: category, type, until the expiry', () {
    final d = SystemDetailView.document(
      SystemDocument(
        id: '1',
        name: 'Northline warranty',
        createdAt: DateTime(2021, 3),
        categoryName: 'Warranty',
        mimeType: 'application/pdf',
        expirationDate: DateTime(2031, 3, 9),
      ),
    );
    expect(d.meta, 'WARRANTY · PDF · UNTIL MAR 2031');
  });

  group('lifespan sentence', () {
    LifespanReading r(double age) =>
        LifespanReading.ofAge(ageYears: age, lifeYears: 15, startYear: 2021);

    test('years left in bold, cost and planning year', () {
      final p = SystemsCopy.lifespanBody(reading: r(5.5), cost: 5800, now: 2026);
      expect(p.before, 'About ');
      expect(p.bold, '9½ years left');
      expect(
        p.after,
        '. Replacing it typically runs about \$5,800 \u2014 we\'ll start '
        'planning with you around 2033.',
      );
    });

    test('inside the planning window it says it is time', () {
      final p = SystemsCopy.lifespanBody(reading: r(13), cost: null, now: 2034);
      expect(p.after, '. Time to start planning.');
    });

    test('past its life, and no date', () {
      expect(
        SystemsCopy.lifespanBody(reading: r(16), cost: null, now: 2026).before,
        'This is past its expected life.',
      );
      expect(
        SystemsCopy.lifespanBody(
          reading: LifespanReading.unknown,
          cost: null,
          now: 2026,
        ).before,
        SystemsCopy.lifespanNoDate,
      );
    });
  });

  test('system subtitle joins unit and place', () {
    expect(aSystem('a').subtitle, 'Northline NF95-080B · Basement utility room');
    expect(aSystem('a', brand: null, model: null, location: null).subtitle, isNull);
    expect(aSystem('a').reading(now: now).ageLabel, '5½ yrs');
  });
}
