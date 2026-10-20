import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keystona/features/home_profile/models/scan_prefill.dart';
import 'package:keystona/features/home_profile/providers/scan_providers.dart';
import 'package:keystona/features/home_profile/screens/scan_flow_screen.dart';
import 'package:keystona/services/label_scanner_service.dart';

import '../../support/responsive_harness.dart';
import '../maintenance/tab/tasks_test_support.dart';
import 'support/fake_systems.dart';
import 'support/systems_harness.dart';

const read = LabelScanResult(
  brand: 'Northline',
  modelNumber: 'NF95-080B',
  serialNumber: '2103A47719',
  name: 'Furnace',
  manufactureDate: '2021-03',
  category: 'hvac',
);

Future<List<Visit>> open(
  WidgetTester tester, {
  ScanKind? kind,
  bool online = true,
  LabelReader? reader,
  PhotoSource? camera,
}) async {
  phoneSurface(tester);
  final visits = <Visit>[];
  await tester.pumpWidget(
    HomeRoutedApp(
      home: ScanFlowScreen(initialKind: kind),
      visits: visits,
      overrides: [
        ...homeOverrides(
          systems: FakeSystemsRepository(kitSystems()),
          online: online,
        ),
        photoSourceProvider.overrideWithValue(
          camera ?? (_) async => XFile('label.jpg'),
        ),
        labelReaderProvider.overrideWithValue(
          reader ?? (photo, {required isAppliance}) async => read,
        ),
      ],
    ),
  );
  await settle(tester);
  return visits;
}

void main() {
  testWidgets('asks what is being scanned, with the count of systems', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('What are you scanning?'), findsOneWidget);
    expect(find.text('A system'), findsOneWidget);
    expect(find.text('An appliance'), findsOneWidget);
    expect(find.text('5 IN YOUR HOME'), findsWidgets);
    expect(find.text('No label? Add it by hand'), findsOneWidget);
    // The panel sits at the bottom, like the kit's sheet.
    expect(tester.getBottomLeft(find.text('No label? Add it by hand')).dy,
        greaterThan(700));
  });

  testWidgets('choosing a system shows its label view', (tester) async {
    await open(tester);
    await tester.tap(find.text('A system'));
    await settle(tester);
    expect(find.text('Scan a system label'), findsOneWidget);
    expect(find.text('Fit the rating plate inside the frame'), findsOneWidget);
    await tester.tap(find.text('Appliance'));
    await settle(tester);
    expect(find.text('Scan an appliance label'), findsOneWidget);
    expect(
      find.text('Fit the model & serial sticker inside the frame'),
      findsOneWidget,
    );
  });

  testWidgets('a read label shows what was found and Review details opens the form filled', (
    tester,
  ) async {
    final visits = await open(tester, kind: ScanKind.system);
    await tester.tap(find.bySemanticsLabel('Take a photo of the label'));
    await settle(tester);
    expect(find.text('Label read · 6 details found'), findsOneWidget);
    expect(find.text('Review details →'), findsOneWidget);
    await tester.tap(find.text('Review details →'));
    await settle(tester);
    expect(visits.single.path, '/home/systems/add');
    final args = visits.single.extra as ItemFormArgs;
    expect(args.prefill?.kind, ScanKind.system);
    expect(args.prefill?.result.brand, 'Northline');
    expect(args.prefill?.photo.path, 'label.jpg');
  });

  testWidgets('an appliance scan opens the appliance form', (tester) async {
    final visits = await open(tester, kind: ScanKind.appliance);
    await tester.tap(find.bySemanticsLabel('Take a photo of the label'));
    await settle(tester);
    await tester.tap(find.text('Review details →'));
    await settle(tester);
    expect(visits.single.path, '/home/appliances/add');
  });

  testWidgets('an unreadable label says so and stays on the camera', (
    tester,
  ) async {
    await open(
      tester,
      kind: ScanKind.system,
      reader: (photo, {required isAppliance}) async => const LabelScanResult(),
    );
    await tester.tap(find.bySemanticsLabel('Take a photo of the label'));
    await settle(tester);
    expect(find.textContaining("Couldn't read any info"), findsWidgets);
    expect(find.text('Review details →'), findsNothing);
  });

  testWidgets('a failed read says so', (tester) async {
    await open(
      tester,
      kind: ScanKind.system,
      reader: (photo, {required isAppliance}) async => throw StateError('x'),
    );
    await tester.tap(find.bySemanticsLabel('Take a photo of the label'));
    await settle(tester);
    expect(find.textContaining('Something went wrong'), findsWidgets);
  });

  testWidgets('offline the shutter says so instead of opening the camera', (
    tester,
  ) async {
    var opened = false;
    await open(
      tester,
      kind: ScanKind.system,
      online: false,
      camera: (_) async {
        opened = true;
        return null;
      },
    );
    await tester.tap(find.bySemanticsLabel('Take a photo of the label'));
    await settle(tester);
    expect(opened, isFalse);
    expect(find.textContaining("You're offline"), findsOneWidget);
  });

  testWidgets('Type it in instead opens a blank form', (tester) async {
    final visits = await open(tester, kind: ScanKind.system);
    await tester.tap(find.text('Type it in instead'));
    await settle(tester);
    expect(visits.single.path, '/home/systems/add');
    expect(visits.single.extra, isNull);
  });

  testResponsive(
    'choose step does not overflow',
    () => const ScanFlowScreen(),
    wrap: (app) => ProviderScope(
      overrides: homeOverrides(systems: FakeSystemsRepository(kitSystems())),
      child: app,
    ),
  );

  testResponsive(
    'camera step does not overflow',
    () => const ScanFlowScreen(initialKind: ScanKind.system),
    wrap: (app) => ProviderScope(
      overrides: homeOverrides(systems: FakeSystemsRepository(kitSystems())),
      child: app,
    ),
  );
}
