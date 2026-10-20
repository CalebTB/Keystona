import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keystona/core/router/app_router.dart';
import 'package:keystona/core/widgets/aurora/aurora_text_field.dart';
import 'package:keystona/core/widgets/aurora/aurora_toggle_row.dart';
import 'package:keystona/features/home_profile/models/appliance.dart';
import 'package:keystona/features/home_profile/models/appliance_suggestion.dart';
import 'package:keystona/features/home_profile/models/item_photo_type.dart';
import 'package:keystona/features/home_profile/models/item_ref.dart';
import 'package:keystona/features/home_profile/models/scan_prefill.dart';
import 'package:keystona/features/home_profile/screens/appliance_form_screen.dart';
import 'package:keystona/features/home_profile/widgets/shared/scan_field_box.dart';
import 'package:keystona/services/label_scanner_service.dart';

import '../../maintenance/form_reminders/form_reminders_support.dart'
    show testResponsiveLoaded;
import 'c_support.dart';

ScanPrefill scan() => ScanPrefill(
  kind: ItemKind.appliance,
  photo: XFile('label.jpg'),
  result: const LabelScanResult(
    brand: 'Halden',
    modelNumber: 'HW45-FL2',
    serialNumber: 'HL3390218K',
    name: 'Washer',
    category: 'laundry',
    estimatedLifespanYears: 11,
    notes: 'Capacity: 4.5 cu ft\nType: Front-load\nEnergy Star: Yes',
  ),
);

int edges(WidgetTester tester) => tester
    .widgetList<ScanFieldBox>(find.byType(ScanFieldBox))
    .where((b) => b.fromScan)
    .length;

/// Types into the [AuroraTextField] with this label (as given to the field).
Future<void> type(WidgetTester tester, String label, String text) async {
  final field = find.byWidgetPredicate(
    (w) => w is AuroraTextField && w.label == label,
  );
  final input = find.descendant(of: field, matching: find.byType(TextField));
  await tester.ensureVisible(input);
  await tester.pump();
  await tester.enterText(input, text);
  await tester.pump();
}

Finder save(String label) => find.text(label);

void main() {
  group('add', () {
    testWidgets('starts empty: no banner, Save waits for a name, then saves', (
      tester,
    ) async {
      final repo = FakeAppliancesRepository(const []);
      final visits = await openScreen(
        tester,
        const ApplianceFormScreen(),
        size: const Size(390, 3000),
        overrides: cOverrides(appliances: repo),
      );
      expect(find.text('HOME PROFILE · NEW'), findsOneWidget);
      expect(find.text('Add an appliance.'), findsOneWidget);
      expect(find.textContaining('We read'), findsNothing);
      expect(find.text('REQUIRED * · EVERYTHING ELSE CAN WAIT'), findsOneWidget);

      await tester.tap(save('Save appliance'));
      await settle(tester);
      expect(repo.added, isEmpty);

      await type(tester, 'Name', 'Washer');
      await tester.tap(find.text('Other'));
      await settle(tester);
      await tester.tap(find.text('Laundry').last);
      await settle(tester);
      await tester.tap(save('Save appliance'));
      await settle(tester);
      final f = repo.added.single;
      expect(f['name'], 'Washer');
      expect(f['category'], 'laundry');
      expect(f['appliance_type'], 'laundry');
      expect(f['expected_lifespan_min'], 11);
      expect(f['expected_lifespan_max'], 11);
      expect(visits.single.path, '/home/appliances/new1');
    });

    testWidgets('a bad date stops the save and says why', (tester) async {
      final repo = FakeAppliancesRepository(const []);
      await openScreen(
        tester,
        const ApplianceFormScreen(),
        size: const Size(390, 3000),
        overrides: cOverrides(appliances: repo),
      );
      await type(tester, 'Name', 'Fridge');
      await type(tester, 'Purchase date', '13/45/2020');
      await tester.tap(save('Save appliance'));
      await settle(tester);
      expect(find.text('USE MONTH / DAY / YEAR'), findsOneWidget);
      expect(repo.added, isEmpty);
    });

    testWidgets('the warranty switch reveals provider, expiry and the Docs link', (
      tester,
    ) async {
      await openScreen(
        tester,
        const ApplianceFormScreen(),
        size: const Size(390, 3000),
        overrides: cOverrides(),
      );
      expect(find.text('PROVIDER'), findsNothing);
      await tester.tap(find.byType(AuroraSwitch));
      await settle(tester);
      expect(find.text('PROVIDER'), findsOneWidget);
      expect(find.text('EXPIRES'), findsOneWidget);
      expect(find.text('Link the warranty from Docs'), findsOneWidget);
    });

    testWidgets('specifications start closed; a laundry appliance offers the type', (
      tester,
    ) async {
      await openScreen(
        tester,
        const ApplianceFormScreen(),
        size: const Size(390, 3000),
        overrides: cOverrides(),
      );
      expect(find.text('CAPACITY'), findsNothing);
      await tester.tap(find.text('SPECIFICATIONS'));
      await settle(tester);
      expect(find.text('CAPACITY'), findsOneWidget);
      expect(find.text('Front-load'), findsNothing); // category is not laundry
      await tester.tap(find.text('Other').first);
      await settle(tester);
      await tester.tap(find.text('Laundry').last);
      await settle(tester);
      expect(find.text('Front-load'), findsOneWidget);
      expect(find.text('Top-load'), findsOneWidget);
      expect(find.text('Stackable'), findsOneWidget);
    });

    testWidgets('photos: four slots on the free plan, with the plan note', (
      tester,
    ) async {
      await openScreen(
        tester,
        const ApplianceFormScreen(),
        size: const Size(390, 3000),
        overrides: cOverrides(),
      );
      expect(find.text('FREE PLAN · 4 PHOTOS'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNWidgets(4));
    });

    testWidgets('a suggestion fills the name and category', (tester) async {
      await openScreen(
        tester,
        const ApplianceFormScreen(
          suggestion: ApplianceSuggestion('Microwave', ApplianceCategory.kitchen),
        ),
        size: const Size(390, 3000),
        overrides: cOverrides(),
      );
      expect(find.text('Microwave'), findsOneWidget);
      expect(find.text('Kitchen'), findsOneWidget);
    });
  });

  group('after a label scan', () {
    testWidgets('the banner, the blue edges and the label photo', (tester) async {
      await openScreen(
        tester,
        ApplianceFormScreen(prefill: scan()),
        size: const Size(390, 3000),
        overrides: cOverrides(),
      );
      expect(find.text('We read 8 fields from the label'), findsOneWidget);
      expect(find.text('Rescan'), findsOneWidget);
      expect(tester.getTopRight(find.text('Rescan')).dx, greaterThan(390 - 40));
      expect(find.text('Scan'), findsOneWidget); // the back link
      expect(find.text('Halden'), findsOneWidget);
      expect(find.text('HW45-FL2'), findsOneWidget);
      expect(find.text('Laundry'), findsOneWidget);
      expect(find.text('3 SCANNED'), findsOneWidget);
      expect(edges(tester), 3);
      expect(find.text('LABEL'), findsOneWidget);
      expect(find.textContaining('THE LABEL PHOTO IS SAVED FOR YOU'), findsOneWidget);
    });

    testWidgets('the edge disappears once a scanned value is edited', (tester) async {
      await openScreen(
        tester,
        ApplianceFormScreen(prefill: scan()),
        size: const Size(390, 3000),
        overrides: cOverrides(),
      );
      await type(tester, 'Brand', 'Other brand');
      expect(edges(tester), 2);
      await type(tester, 'Brand', 'Halden');
      expect(edges(tester), 3);
    });

    testWidgets('saving stores the label photo as the LABEL, specs from the notes, the scan\'s life', (
      tester,
    ) async {
      final repo = FakeAppliancesRepository(const []);
      final photos = FakeItemPhotosRepository();
      await openScreen(
        tester,
        ApplianceFormScreen(prefill: scan()),
        size: const Size(390, 3000),
        overrides: cOverrides(appliances: repo, photos: photos),
      );
      await tester.tap(save('Save appliance'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      final f = repo.added.single;
      expect(f['brand'], 'Halden');
      expect(f['model'], 'HW45-FL2');
      expect(f['serial_number'], 'HL3390218K');
      expect(f['specifications'], {
        'capacity': '4.5 cu ft',
        'type': 'Front-load',
        'energy_star': true,
      });
      expect(f['expected_lifespan_min'], 11);
      expect(photos.addedTypes, [ItemPhotoType.label]);
      expect(photos.addedFor.single, const ItemRef.appliance('new1'));
    });

    testWidgets('Rescan goes back to the scan for appliances', (tester) async {
      final visits = await openScreen(
        tester,
        ApplianceFormScreen(prefill: scan()),
        size: const Size(390, 3000),
        overrides: cOverrides(),
      );
      await tester.tap(find.text('Rescan'));
      await settle(tester);
      expect(visits.single.path, AppRoutes.homeScan);
      expect(visits.single.extra, ItemKind.appliance);
    });
  });

  group('edit', () {
    Appliance washer() => kitAppliances().firstWhere((a) => a.id == 'wa');

    testWidgets('no banner, "Edit Washer.", more details, and the values filled in', (
      tester,
    ) async {
      await openScreen(
        tester,
        ApplianceFormScreen(existing: washer()),
        size: const Size(390, 3400),
        overrides: cOverrides(),
      );
      expect(find.text('HOME PROFILE · EDIT'), findsOneWidget);
      expect(find.text('Edit Washer.'), findsOneWidget);
      expect(find.textContaining('We read'), findsNothing);
      expect(find.text('MORE DETAILS'), findsOneWidget);
      expect(find.text('Laundry room'), findsWidgets);
      expect(find.text('849'), findsOneWidget);
      expect(find.text('12/09/2023'), findsOneWidget);
      expect(find.text('Halden + Brightway Care'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);
      expect(find.text('Delete this appliance'), findsOneWidget);
      expect(find.text('PHOTOS'), findsNothing);
    });

    testWidgets('saving writes the changes and keeps the other specifications', (
      tester,
    ) async {
      final repo = FakeAppliancesRepository(kitAppliances());
      await openScreen(
        tester,
        ApplianceFormScreen(existing: washer()),
        size: const Size(390, 3400),
        overrides: cOverrides(appliances: repo),
      );
      await type(tester, 'Name', 'Main washer');
      await tester.tap(save('Save changes'));
      await settle(tester);
      final u = repo.updated.single;
      expect(u.id, 'wa');
      expect(u.fields['name'], 'Main washer');
      expect(u.fields['purchase_date'], '2023-12-09');
      expect(u.fields['purchase_price'], 849);
      expect((u.fields['specifications'] as Map)['spin_speed'], '1,300 RPM');
      expect(u.fields.containsKey('expected_lifespan_min'), isFalse);
    });

    testWidgets('delete asks first, uses the delete function, and offers Undo that restores', (
      tester,
    ) async {
      final repo = FakeAppliancesRepository(kitAppliances());
      await openScreen(
        tester,
        ApplianceFormScreen(existing: washer()),
        size: const Size(390, 3400),
        overrides: cOverrides(appliances: repo),
      );
      await tester.tap(find.text('Delete this appliance'));
      await settle(tester);
      expect(find.text('Delete this appliance?'), findsOneWidget);
      expect(repo.deleted, isEmpty);
      await tester.tap(find.text('Delete'));
      await settle(tester);
      expect(repo.deleted, ['wa']);
      expect(find.text('Deleted Washer'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect(repo.restored, ['wa']);
    });

    testWidgets('cancelling the delete changes nothing', (tester) async {
      final repo = FakeAppliancesRepository(kitAppliances());
      await openScreen(
        tester,
        ApplianceFormScreen(existing: washer()),
        size: const Size(390, 3400),
        overrides: cOverrides(appliances: repo),
      );
      await tester.tap(find.text('Delete this appliance'));
      await settle(tester);
      await tester.tap(find.text('Cancel').last);
      await settle(tester);
      expect(repo.deleted, isEmpty);
    });

    testWidgets('a failed save says so and stays on the form', (tester) async {
      final repo = FakeAppliancesRepository(kitAppliances())..writeError = StateError('x');
      await openScreen(
        tester,
        ApplianceFormScreen(existing: washer()),
        size: const Size(390, 3400),
        overrides: cOverrides(appliances: repo),
      );
      await tester.tap(save('Save changes'));
      await settle(tester);
      expect(find.text("Couldn't save that. Try again."), findsOneWidget);
      expect(find.text('Edit Washer.'), findsOneWidget);
    });
  });

  testResponsiveLoaded(
    'the add form holds up',
    () => const ApplianceFormScreen(),
    overrides: () => cOverrides(),
  );
  testResponsiveLoaded(
    'the scanned add form holds up',
    () => ApplianceFormScreen(prefill: scan()),
    overrides: () => cOverrides(),
  );
  testResponsiveLoaded(
    'the edit form holds up',
    () => ApplianceFormScreen(existing: kitAppliances().firstWhere((a) => a.id == 'wa')),
    overrides: () => cOverrides(),
  );
}
