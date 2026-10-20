import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/home_profile/edit/home_edit_form.dart';
import 'package:keystona/features/home_profile/home_profile_format.dart';
import 'package:keystona/features/home_profile/lifespan/home_lifespan_data.dart';
import 'package:keystona/features/home_profile/lifespan/lifespan_forecast.dart';
import 'package:keystona/features/home_profile/lifespan/lifespan_reading.dart';
import 'package:keystona/features/home_profile/models/home_item.dart';
import 'package:keystona/features/home_profile/models/item_ref.dart';
import 'package:keystona/features/home_profile/models/property.dart';
import 'package:keystona/features/home_profile/repositories/home_item_mapper.dart';

import 'track_a_support.dart';

final DateTime now = DateTime(2026, 10, 20);

void main() {
  group('LifespanForecast', () {
    test('past-due items land in the first year, the rest by replace year', () {
      final f = LifespanForecast.of([
        item('1', 'Old', age: 14, life: 10, startYear: 2012, cost: 800),
        item('2', 'Soon', age: 8, life: 10, startYear: 2018, cost: 1000),
        item('3', 'Later', age: 1, life: 15, startYear: 2025, cost: 9000),
      ], now);
      expect(f.firstYear, 2027);
      expect(f.years.map((y) => y.year), [2027, 2028, 2029, 2030, 2031]);
      expect(f.years[0].names, ['Old']);
      expect(f.years[0].amount, 800);
      expect(f.years[1].names, ['Soon']);
      expect(f.total, 1800);
      expect(f.dueItems.map((i) => i.name), ['Old', 'Soon']);
    });

    test('replace year 2031 is in the window, 2032 is not', () {
      final f = LifespanForecast.of([
        item('1', 'In', startYear: 2021, life: 10, cost: 100),
        item('2', 'Out', startYear: 2022, life: 10, cost: 200),
      ], now);
      expect(f.dueItems.map((i) => i.name), ['In']);
      expect(f.years[4].amount, 100);
    });

    test('items with no life or no cost', () {
      final f = LifespanForecast.of([
        HomeItemFixtures.unknown(),
        item('2', 'Free', startYear: 2016, life: 12, cost: null),
      ], now);
      expect(f.dueItems.map((i) => i.name), ['Free']);
      expect(f.total, 0);
      expect(f.years[1].names, ['Free']);
      expect(f.peak, 1);
    });

    test('perMonth spreads the total over 60 months', () {
      final f = LifespanForecast.of([
        item('1', 'A', startYear: 2016, life: 12, cost: 4380),
      ], now);
      expect(f.perMonth, 73);
    });

    test('yearFor puts a past-due item in the first year', () {
      final old = item('1', 'Old', startYear: 2001, life: 10);
      expect(LifespanForecast.of([old], now).yearFor(old), 2027);
    });
  });

  group('HomeLifespanData', () {
    final data = HomeLifespanData.from(sampleItems(), now: now);

    test('sorts by percent of life used, highest first', () {
      expect(data.items.map((i) => i.name).take(3), [
        'Dishwasher',
        'Water heater',
        'Roof',
      ]);
    });

    test(
      'worst is the item most worn out, only when at end of life or past',
      () {
        expect(data.worst?.name, 'Dishwasher');
        final fine = HomeLifespanData.from([
          item('1', 'New', age: 1),
        ], now: now);
        expect(fine.worst, isNull);
      },
    );

    test('forKind filters, forecastFor follows the kind', () {
      expect(data.forKind(ItemKind.appliance).length, 2);
      expect(data.forKind(null).length, 5);
      expect(
        data.forecastFor(ItemKind.appliance).total,
        lessThan(data.forecastFor(null).total),
      );
    });

    test('agingSystems counts systems only', () {
      expect(data.agingSystems, 1);
    });
  });

  group('HomeItemMapper', () {
    test(
      'systems age from installation_date, appliances from purchase_date',
      () {
        final system = HomeItemMapper.system({
          'id': 's',
          'category': 'hvac',
          'name': 'Furnace',
          'model': 'NF95',
          'location': 'Basement',
          'installation_date': '2021-03-01',
          'expected_lifespan_min': 12,
          'expected_lifespan_max': 18,
          'lifespan_override': null,
          'estimated_replacement_cost': 5800,
        }, now);
        expect(system.ref, const ItemRef.system('s'));
        expect(system.subtitle, 'NF95 · Basement');
        expect(system.reading.lifeYears, 15);
        expect(system.reading.startYear, 2021);
        expect(system.cost, 5800.0);

        final appliance = HomeItemMapper.appliance({
          'id': 'a',
          'category': 'laundry',
          'name': 'Washer',
          'purchase_date': '2023-08-01',
          'expected_lifespan_min': null,
          'expected_lifespan_max': 11,
        }, now);
        expect(appliance.ref, const ItemRef.appliance('a'));
        expect(appliance.reading.startYear, 2023);
        expect(appliance.reading.lifeYears, 11);
        expect(appliance.subtitle, isNull);
      },
    );

    test('no date means no age, override beats min and max', () {
      final i = HomeItemMapper.system({
        'id': 's',
        'category': 'other',
        'name': 'X',
        'expected_lifespan_min': 10,
        'expected_lifespan_max': 20,
        'lifespan_override': 7,
      }, now);
      expect(i.reading.ageYears, isNull);
      expect(i.reading.lifeYears, 7);
    });
  });

  group('Property', () {
    test('a null property_type no longer crashes fromJson', () {
      final p = Property.fromJson({
        'id': 'p',
        'user_id': 'u',
        'address_line1': 'A',
        'city': 'C',
        'state': 'AL',
        'zip_code': '35758',
        'property_type': null,
        'has_basement': false,
        'bedrooms': 3,
        'bathrooms': 2,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      });
      expect(p.propertyType, isNull);
      expect(p.bathrooms, 2.0);
    });
  });

  group('HomeEditForm', () {
    late HomeEditForm form;
    setUp(() => form = HomeEditForm(sampleProperty(), now: now));
    tearDown(() => form.dispose());

    test('starts clean and cannot save', () {
      expect(form.dirty, isFalse);
      expect(form.canSave, isFalse);
      expect(form.lot.text, '0.31');
      expect(form.sqft.text, '2,140');
      expect(form.price.text, '318,000');
    });

    test('a change turns Save on, reverting it turns it off', () {
      form.city.text = 'Huntsville';
      expect(form.canSave, isTrue);
      form.city.text = 'Springfield';
      expect(form.canSave, isFalse);
    });

    test('year help follows the kit', () {
      form.year.text = '19x8';
      expect(form.yearHelp, 'FOUR DIGITS, LIKE 1998');
      expect(form.canSave, isFalse);
      form.year.text = '2030';
      expect(form.yearOk, isFalse);
      form.year.text = '1700';
      expect(form.yearOk, isFalse);
      form.year.text = '2001';
      expect(form.yearHelp, 'REMINDERS AND LIFESPANS WILL UPDATE');
      expect(form.canSave, isTrue);
      form.year.text = '1998';
      expect(form.yearHelp, isNull);
    });

    test('zip help and validity', () {
      expect(form.zipHelp, contains("CAN'T BE CHANGED"));
      form.zip.text = '90210';
      expect(form.zipHelp, contains('RECHECK THE ZONE'));
      form.zip.text = '9021';
      expect(form.canSave, isFalse);
    });

    test('street is required', () {
      form.street.text = '  ';
      expect(form.canSave, isFalse);
    });

    test('a new ZIP rechecks the climate zone on save', () {
      form
        ..zip.text = '90210'
        ..state.text = 'ca';
      final edits = form.toEdits();
      expect(edits.state, 'CA');
      expect(edits.climateZone, 3);
    });

    test('an unknown ZIP keeps the old zone', () {
      form.zip.text = '00000';
      form.state.text = 'ZZ';
      expect(form.toEdits().climateZone, 4);
    });

    test('an untouched ZIP keeps the zone without a lookup', () {
      form.city.text = 'Else';
      expect(form.toEdits().climateZone, 4);
    });

    test('lot: untouched keeps the stored square feet, typed converts', () {
      form.city.text = 'Else';
      expect(form.toEdits().lotSizeSqft, 13504);
      form.lot.text = '0.5';
      expect(form.toEdits().lotSizeSqft, 21780);
      form.lot.text = '';
      expect(form.toEdits().lotSizeSqft, isNull);
    });

    test('price and square feet are parsed from formatted text', () {
      form
        ..price.text = r'$320,500'
        ..sqft.text = '2,200';
      final edits = form.toEdits();
      expect(edits.purchasePrice, 320500);
      expect(edits.squareFeet, 2200);
    });

    test('steppers respect their ranges and start from null', () {
      form.stepBedrooms(1);
      expect(form.bedrooms, 5);
      for (var i = 0; i < 20; i++) {
        form.stepBedrooms(1);
      }
      expect(form.bedrooms, HomeEditForm.bedroomsMax);
      form.stepBathrooms(1);
      expect(form.bathrooms, 3);
      for (var i = 0; i < 20; i++) {
        form.stepBathrooms(-1);
      }
      expect(form.bathrooms, HomeEditForm.bathroomsMin);
      final bare = HomeEditForm(
        sampleProperty().copyWith(bedrooms: null),
        now: now,
      );
      addTearDown(bare.dispose);
      bare.stepBedrooms(-1);
      expect(bare.bedrooms, isNull);
      bare.stepBedrooms(1);
      expect(bare.bedrooms, HomeEditForm.bedroomsMin);
    });

    test(
      'choosing no garage clears the spaces, choosing one sets a default',
      () {
        form.setGarage(null);
        expect(form.garageSpaces, isNull);
        form.setGarage('detached');
        expect(form.garageSpaces, HomeEditForm.garageSpacesMin);
        final edits = form.toEdits();
        expect(edits.garageType, 'detached');
        expect(edits.toColumns()['garage_spaces'], 1);
      },
    );

    test('purchase date is written as YYYY-MM-DD, blanks as null', () {
      form.setPurchaseDate(DateTime(2020, 5));
      expect(form.toEdits().toColumns()['purchase_date'], '2020-05-01');
      form.setPurchaseDate(null);
      expect(form.toEdits().toColumns()['purchase_date'], isNull);
    });

    test('the cover photo column is only written with a new path', () {
      final edits = form.toEdits();
      expect(edits.toColumns().containsKey('exterior_photo_path'), isFalse);
      expect(
        edits.toColumns(photoPath: 'u/x.jpg')['exterior_photo_path'],
        'u/x.jpg',
      );
    });
  });

  group('HomeFormat', () {
    test('money and acres', () {
      expect(HomeFormat.money(1800), r'$1,800');
      expect(HomeFormat.moneyShort(2600), r'$2.6K');
      expect(HomeFormat.moneyShort(2000), r'$2K');
      expect(HomeFormat.acres(13504), '0.31');
      expect(HomeFormat.acres(43560), '1');
    });

    test('climate label uses the lookup only when it agrees with the zone', () {
      expect(
        HomeFormat.climateLabel(sampleProperty()),
        'Zone 4A · mixed-humid',
      );
      expect(
        HomeFormat.climateLabel(sampleProperty(zip: '90210', state: 'CA')),
        'Zone 4',
      );
    });
  });

  test('LifespanBand wiring: kit bands', () {
    final r = LifespanReading.ofAge(ageYears: 12, lifeYears: 12);
    expect(r.band, LifespanBand.endOfLife);
  });
}

abstract final class HomeItemFixtures {
  static HomeItem unknown() => item('u', 'Unknown', life: 0)..toString();
}
