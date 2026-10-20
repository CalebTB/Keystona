import 'package:flutter/material.dart';
import 'package:keystona/core/widgets/aurora/aurora_toggle_row.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keystona/features/home_profile/models/scan_prefill.dart';
import 'package:keystona/features/home_profile/models/system_template.dart';
import 'package:keystona/features/home_profile/providers/scan_providers.dart';
import 'package:keystona/features/home_profile/screens/system_form_screen.dart';
import 'package:keystona/services/label_scanner_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../support/responsive_harness.dart';
import '../maintenance/tab/tasks_test_support.dart';
import 'support/fake_systems.dart';
import 'support/systems_harness.dart';

final scan = ScanPrefill(
  kind: ScanKind.system,
  photo: XFile('label.jpg'),
  result: const LabelScanResult(
    brand: 'Northline',
    modelNumber: 'NF95-080B',
    serialNumber: '2103A47719',
    name: 'Furnace',
    manufactureDate: '2021-03',
    category: 'hvac',
    estimatedLifespanYears: 15,
  ),
);

class Opened {
  Opened(this.visits, this.systems, this.photos);
  final List<Visit> visits;
  final FakeSystemsRepository systems;
  final FakeSystemPhotosRepository photos;
}

Future<Opened> open(
  WidgetTester tester,
  Widget screen, {
  FakeSystemsRepository? systems,
  bool online = true,
  bool premium = false,
}) async {
  tester.view.physicalSize = const Size(390, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = systems ?? FakeSystemsRepository(const []);
  final photos = FakeSystemPhotosRepository();
  final visits = <Visit>[];
  await tester.pumpWidget(
    HomeRoutedApp(
      home: screen,
      visits: visits,
      overrides: [
        ...homeOverrides(
          systems: repo,
          photos: photos,
          online: online,
          premium: premium,
        ),
        photoSourceProvider.overrideWithValue(
          (source) async => XFile('picked.jpg'),
        ),
      ],
    ),
  );
  await settle(tester);
  return Opened(visits, repo, photos);
}

Finder field(String label) => find.ancestor(
  of: find.textContaining(label, findRichText: true),
  matching: find.byType(Column),
);

void main() {
  testWidgets('a blank form: Add heading, no banner, Save waits for a name', (
    tester,
  ) async {
    final o = await open(tester, const SystemFormScreen());
    expect(find.text('Add a system.'), findsOneWidget);
    expect(find.text('HOME PROFILE · NEW'), findsOneWidget);
    expect(find.textContaining('fields from the label'), findsNothing);
    expect(find.text('Save system'), findsOneWidget);
    await tester.tap(find.text('Save system'));
    await settle(tester);
    expect(o.systems.created, isEmpty);
    // Cancel at the left, Save fills the rest at the right.
    expect(tester.getTopLeft(find.text('Cancel')).dx, lessThan(80));
    expect(tester.getTopRight(find.text('Save system')).dx, greaterThan(250));
  });

  testWidgets('typing a name saves a row and opens the new system', (
    tester,
  ) async {
    final o = await open(tester, const SystemFormScreen());
    await tester.enterText(find.byType(TextField).first, 'Main floor HVAC');
    await tester.pump();
    // Tasks stay on; the reminders step cannot reach a backend here and must
    // not stop the save.
    await tester.tap(find.text('Save system'));
    await settle(tester);
    expect(o.systems.created.single['name'], 'Main floor HVAC');
    expect(o.systems.created.single['category'], 'hvac');
    expect(o.visits.single.path, '/home/systems/new1');
  });

  testWidgets('a scan fills the fields and shows the banner', (tester) async {
    await open(tester, SystemFormScreen(prefill: scan));
    expect(find.text('We read 5 fields from the label'), findsOneWidget);
    expect(find.text('Rescan'), findsOneWidget);
    expect(find.text('Northline'), findsOneWidget);
    expect(find.text('2103A47719'), findsOneWidget);
    expect(find.text('Mar'), findsOneWidget);
    expect(find.text('2021'), findsOneWidget);
    expect(find.text('15 years'), findsOneWidget);
    expect(
      find.text('TYPICAL FOR HVAC · PLAN TO REPLACE AROUND 2036'),
      findsOneWidget,
    );
    // The label photo is the first photo, tagged LABEL.
    expect(find.text('LABEL'), findsOneWidget);
  });

  testWidgets('Save with a scan uploads the label photo as type label', (
    tester,
  ) async {
    final o = await open(tester, SystemFormScreen(prefill: scan));
    await tester.tap(find.byType(AuroraSwitch));
    await tester.pump();
    await tester.tap(find.text('Save system'));
    await settle(tester);
    expect(o.photos.uploads.single.type, 'label');
    expect(o.photos.uploads.single.systemId, 'new1');
    expect(o.systems.created.single['installation_date'], '2021-03-01');
  });

  testWidgets('a suggestion template opens with category and name filled', (
    tester,
  ) async {
    await open(
      tester,
      SystemFormScreen(template: SystemTemplates.all[2]),
    );
    expect(find.text('Sump pump'), findsOneWidget);
    expect(find.text('Plumbing'), findsOneWidget);
    expect(find.text('50 years'), findsOneWidget);
  });

  testWidgets('offline: the tasks switch will not turn on and says why', (
    tester,
  ) async {
    await open(tester, const SystemFormScreen(), online: false);
    await tester.tap(find.byType(AuroraSwitch));
    await tester.pump();
    expect(find.text('OFF · YOU CAN ADD TASKS YOURSELF'), findsOneWidget);
    await tester.tap(find.byType(AuroraSwitch));
    await settle(tester);
    expect(find.textContaining("You're offline"), findsOneWidget);
  });

  testWidgets('the free plan stops at 4 photos with the upgrade sheet', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await open(tester, SystemFormScreen(prefill: scan));
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.bySemanticsLabel('Add a photo').first);
      await settle(tester);
      await tester.tap(find.text('Take a photo'));
      await settle(tester);
    }
    await tester.tap(find.bySemanticsLabel('Add a photo').first);
    await settle(tester);
    expect(find.text('Keep every photo with Premium'), findsOneWidget);
  });

  group('edit mode', () {
    final furnace = aSystem('fu', installed: ago(years: 5)).copyWith(
      location: 'Basement utility room',
    );

    testWidgets('Edit heading, no scan banner or tasks switch, more details', (
      tester,
    ) async {
      await open(
        tester,
        SystemFormScreen(existingSystem: furnace),
        systems: FakeSystemsRepository([furnace]),
      );
      expect(find.text('Edit Furnace.'), findsOneWidget);
      expect(find.text('HOME PROFILE · EDIT'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);
      expect(find.text('Add its maintenance tasks'), findsNothing);
      expect(find.textContaining('fields from the label'), findsNothing);
      expect(find.text('MORE DETAILS'), findsOneWidget);
      expect(find.text('Basement utility room'), findsWidgets);
      expect(find.text('Delete this system'), findsOneWidget);
    });

    testWidgets('Delete confirms, uses the soft delete and offers Undo', (
      tester,
    ) async {
      final repo = FakeSystemsRepository([furnace]);
      final o = await open(
        tester,
        SystemFormScreen(existingSystem: furnace),
        systems: repo,
      );
      await tester.ensureVisible(find.text('Delete this system'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Delete this system'));
      await settle(tester);
      expect(find.text('Delete Furnace?'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await settle(tester);
      expect(repo.deleted, ['fu']);
      expect(find.text('System deleted.'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect(repo.restored, ['fu']);
      expect(o.visits.last.path, '/home/systems');
    });
  });

  testResponsive(
    'scanned form does not overflow',
    () => SystemFormScreen(prefill: scan),
    wrap: (app) => ProviderScope(
      overrides: homeOverrides(systems: FakeSystemsRepository(const [])),
      child: app,
    ),
  );

  testResponsive(
    'edit form does not overflow',
    () => SystemFormScreen(existingSystem: aSystem('fu')),
    wrap: (app) => ProviderScope(
      overrides: homeOverrides(
        systems: FakeSystemsRepository([aSystem('fu')]),
      ),
      child: app,
    ),
  );
}
