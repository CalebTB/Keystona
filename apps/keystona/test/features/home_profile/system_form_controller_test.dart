import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keystona/features/home_profile/forms/system_form_controller.dart';
import 'package:keystona/features/home_profile/models/scan_prefill.dart';
import 'package:keystona/features/home_profile/models/system.dart';
import 'package:keystona/features/home_profile/models/system_template.dart';
import 'package:keystona/services/label_scanner_service.dart';

import 'support/fake_systems.dart';

ScanPrefill scanned({
  String? manufactureDate = '2021-03',
  int? estimatedYear,
  int? life = 15,
  int? cost,
}) => ScanPrefill(
  kind: ScanKind.system,
  photo: XFile('label.jpg'),
  result: LabelScanResult(
    brand: 'Northline',
    modelNumber: 'NF95-080B',
    serialNumber: '2103A47719',
    name: 'Furnace',
    manufactureDate: manufactureDate,
    estimatedYear: estimatedYear,
    category: 'hvac',
    estimatedLifespanYears: life,
    estimatedReplacementCostUsd: cost,
  ),
);

void main() {
  group('from a scan', () {
    test('fills the fields, counts them and marks them from scan', () {
      final f = SystemFormController(prefill: scanned());
      expect(f.name.text, 'Furnace');
      expect(f.brand.text, 'Northline');
      expect(f.month, 3);
      expect(f.year, 2021);
      expect(f.life, 15);
      expect(f.scan.count, 5);
      expect(f.brandFromScan(), isTrue);
      expect(f.yearFromScan(), isTrue);
      expect(f.labelPhoto?.photoType, 'label');
      expect(f.photos.length, 1);
      f.dispose();
    });

    test('the edge disappears once a value is edited', () {
      final f = SystemFormController(prefill: scanned());
      f.brand.text = 'Other';
      f.setYear(2020);
      expect(f.brandFromScan(), isFalse);
      expect(f.yearFromScan(), isFalse);
      expect(f.modelFromScan(), isTrue);
      f.dispose();
    });

    test('a bare manufacture year or an estimated year fills the year only', () {
      final a = SystemFormController(prefill: scanned(manufactureDate: '2019'));
      expect((a.month, a.year), (null, 2019));
      final b = SystemFormController(
        prefill: scanned(manufactureDate: null, estimatedYear: 2018),
      );
      expect(b.year, 2018);
      expect(b.scan.count, 4);
      a.dispose();
      b.dispose();
    });

    test('create row: install date, one life, scan cost; no override', () {
      final f = SystemFormController(prefill: scanned(cost: 5800));
      final row = f.toRow();
      expect(row['category'], 'hvac');
      expect(row['name'], 'Furnace');
      expect(row['model'], 'NF95-080B');
      expect(row['installation_date'], '2021-03-01');
      expect(row['expected_lifespan_min'], 15);
      expect(row['expected_lifespan_max'], 15);
      expect(row.containsKey('lifespan_override'), isFalse);
      expect(row['estimated_replacement_cost'], 5800);
      expect(row.containsKey('user_id'), isFalse);
      f.dispose();
    });
  });

  group('blank and template', () {
    test('a blank form starts at HVAC with its typical life and cannot save', () {
      final f = SystemFormController();
      expect(f.category, SystemCategory.hvac);
      expect(f.life, 15);
      expect(f.canSave, isFalse);
      f.name.text = '  Main floor HVAC ';
      expect(f.canSave, isTrue);
      expect(f.toRow()['name'], 'Main floor HVAC');
      f.dispose();
    });

    test('picking a category resets the lifespan until it is set by hand', () {
      final f = SystemFormController();
      f.setCategory(SystemCategory.plumbing);
      expect(f.life, 50);
      f.setLife(30);
      f.setCategory(SystemCategory.roofing);
      expect(f.life, 30);
      expect(f.toRow()['lifespan_override'], 30);
      f.dispose();
    });

    test('a suggestion chip fills category and name', () {
      final f = SystemFormController(
        template: SystemTemplates.all.firstWhere((t) => t.label == 'Garage door'),
      );
      expect(f.category, SystemCategory.garage);
      expect(f.name.text, 'Garage door');
      expect(f.life, 20);
      f.dispose();
    });

    test('year with no month saves as January; no year saves no date', () {
      final f = SystemFormController()..name.text = 'x';
      f.setYear(2015);
      expect(f.toRow()['installation_date'], '2015-01-01');
      f.setYear(null);
      expect(f.toRow().containsKey('installation_date'), isFalse);
      f.dispose();
    });

    test('help line names the replace year', () {
      final f = SystemFormController();
      expect(f.replaceYear, isNull);
      f.setYear(2021);
      expect(f.replaceYear, 2036);
      f.dispose();
    });
  });

  group('edit mode', () {
    test('starts from the system and writes every editable column', () {
      final s = aSystem(
        'fu',
        specifications: {'fuel': 'Natural gas', 'extra': 'keep'},
        purchasePrice: 4850,
      );
      final f = SystemFormController(existing: s);
      expect(f.isEditing, isTrue);
      expect(f.name.text, 'Furnace');
      expect(f.location.text, 'Basement utility room');
      expect(f.price.text, '4850');
      expect(f.fuel.text, 'Natural gas');
      f.output.text = '80,000 BTU';
      f.location.clear();
      final row = f.toRow();
      expect(row['location'], isNull);
      expect(row['purchase_price'], 4850);
      expect(row['specifications'], {
        'fuel': 'Natural gas',
        'extra': 'keep',
        'output': '80,000 BTU',
      });
      f.dispose();
    });

    test('an untouched install date keeps its day; lifespan is not rewritten', () {
      final s = aSystem('fu', installed: '2021-03-17');
      final f = SystemFormController(existing: s);
      final row = f.toRow();
      expect(row['installation_date'], '2021-03-17');
      expect(row.containsKey('lifespan_override'), isFalse);
      f.setMonth(4);
      expect(f.toRow()['installation_date'], '2021-04-01');
      f.dispose();
    });

    test('a price that is not a number blocks saving', () {
      final f = SystemFormController(existing: aSystem('fu'));
      f.price.text = 'abc';
      expect(f.priceInvalid, isTrue);
      f.price.text = '1,250.50';
      expect(f.priceInvalid, isFalse);
      expect(f.priceValue, 1250.5);
      f.dispose();
    });
  });
}
