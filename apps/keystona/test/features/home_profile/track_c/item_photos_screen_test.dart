import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keystona/core/widgets/empty_state.dart';
import 'package:keystona/features/home_profile/models/item_photo_type.dart';
import 'package:keystona/features/home_profile/models/item_ref.dart';
import 'package:keystona/features/home_profile/providers/item_photos_provider.dart';
import 'package:keystona/features/home_profile/screens/item_photos_screen.dart';
import 'package:keystona/features/home_profile/widgets/item_photos/item_photo_viewer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../maintenance/form_reminders/form_reminders_support.dart'
    show testResponsiveLoaded;
import 'c_support.dart';

const ItemPhotosScreen washer = ItemPhotosScreen(item: ItemRef.appliance('wa'));

FakeItemPhotosRepository three() => FakeItemPhotosRepository([
  aPhoto('p1', type: 'unit'),
  aPhoto('p2', type: 'label'),
  aPhoto('p3', type: 'filter', caption: 'Filter slot'),
]);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows the first photo large, thumbnails, the plan limit and tips', (
    tester,
  ) async {
    await openScreen(tester, washer, overrides: cOverrides(photos: three()));
    expect(find.text('WASHER · HALDEN HW45-FL2'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);
    expect(find.text('1 OF 3'), findsOneWidget);
    expect(find.text('The unit'), findsOneWidget);
    expect(find.text('3 of 4 photos on Free'), findsOneWidget);
    expect(find.text('PREMIUM KEEPS EVERY PHOTO'), findsOneWidget);
    expect(find.text('GOOD PHOTOS TO HAVE'), findsOneWidget);
    expect(find.text('The shutoff valve or plug nearby'), findsOneWidget);
    // Three of the four tips are ticked: label, unit and filter exist.
    expect(find.byIcon(Icons.check), findsNWidgets(3));
  });

  testWidgets('"1 OF 3" sits at the right edge and Add at the limit card\'s', (
    tester,
  ) async {
    await openScreen(tester, washer, overrides: cOverrides(photos: three()));
    expect(tester.getTopRight(find.text('1 OF 3')).dx, greaterThan(390 - 40));
    expect(tester.getTopRight(find.text('Add')).dx, greaterThan(390 - 60));
    expect(tester.getTopLeft(find.text('3 of 4 photos on Free')).dx, lessThan(60));
  });

  testWidgets('choosing a thumbnail changes the big photo, its tag and caption', (
    tester,
  ) async {
    await openScreen(tester, washer, overrides: cOverrides(photos: three()));
    // Thumbnails carry the tags; the second is the label.
    await tester.tap(find.text('LABEL').last);
    await settle(tester);
    expect(find.text('2 OF 3'), findsOneWidget);
    expect(find.text('Rating label'), findsOneWidget);
    await tester.tap(find.text('FILTER').last);
    await settle(tester);
    expect(find.text('3 OF 3'), findsOneWidget);
    expect(find.text('Filter slot'), findsOneWidget);
  });

  testWidgets('swiping moves to the next photo and wraps around', (tester) async {
    await openScreen(tester, washer, overrides: cOverrides(photos: three()));
    await tester.fling(find.text('The unit'), const Offset(-300, 0), 1000);
    await settle(tester);
    // A swipe over the caption is outside the viewer: nothing changes.
    expect(find.text('1 OF 3'), findsOneWidget);
    final viewer = find.byType(ItemPhotoViewer);
    await tester.fling(viewer, const Offset(-300, 0), 1000);
    await settle(tester);
    expect(find.text('2 OF 3'), findsOneWidget);
    await tester.fling(viewer, const Offset(300, 0), 1000);
    await tester.fling(viewer, const Offset(300, 0), 1000);
    await settle(tester);
    expect(find.text('3 OF 3'), findsOneWidget);
  });

  testWidgets('a free item at the limit gets the upgrade sheet, not the picker', (
    tester,
  ) async {
    final photos = FakeItemPhotosRepository([
      for (var i = 0; i < 4; i++) aPhoto('p$i'),
    ]);
    await openScreen(tester, washer, overrides: cOverrides(photos: photos));
    expect(find.text('4 of 4 photos on Free'), findsOneWidget);
    await tester.tap(find.text('Add'));
    await settle(tester);
    expect(find.text('Keep every photo'), findsOneWidget);
    expect(photos.addedTypes, isEmpty);
  });

  testWidgets('premium shows a plain count', (tester) async {
    final photos = FakeItemPhotosRepository([
      for (var i = 0; i < 5; i++) aPhoto('p$i'),
    ]);
    await openScreen(tester, washer, overrides: cOverrides(photos: photos, premium: true));
    expect(find.text('5 photos'), findsOneWidget);
    expect(find.textContaining('on Free'), findsNothing);
  });

  testWidgets('no photos shows the empty state with an Add button', (tester) async {
    await openScreen(tester, washer, overrides: cOverrides());
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('No photos yet'), findsOneWidget);
  });

  testWidgets('a long press offers Remove, confirms, and deletes the photo', (
    tester,
  ) async {
    final photos = three();
    await openScreen(tester, washer, overrides: cOverrides(photos: photos));
    await tester.longPress(find.byType(ItemPhotoViewer));
    await settle(tester);
    await tester.tap(find.text('Remove photo'));
    await settle(tester);
    await tester.tap(find.text('Remove'));
    await settle(tester);
    expect(photos.deleted, ['p1']);
    expect(find.text('1 OF 2'), findsOneWidget);
  });

  testWidgets('a system item reads the same, named after the system', (tester) async {
    final photos = FakeItemPhotosRepository([aPhoto('s1', applianceId: null, systemId: 'fu', type: 'label')]);
    await openScreen(
      tester,
      const ItemPhotosScreen(item: ItemRef.system('fu')),
      overrides: cOverrides(photos: photos),
    );
    expect(find.text('FURNACE · NORTHLINE NF95-080B'), findsOneWidget);
    expect(find.text('Rating label'), findsOneWidget);
    expect(find.text('The whole unit with space around it'), findsOneWidget);
  });

  group('the photos provider', () {
    test('adding appends the photo; a failed delete puts it back', () async {
      final repo = three();
      final container = ProviderContainer(
        overrides: cOverrides(photos: repo),
      );
      addTearDown(container.dispose);
      const item = ItemRef.appliance('wa');
      container.listen(itemPhotosProvider(item), (_, _) {});
      await container.read(itemPhotosProvider(item).future);
      final notifier = container.read(itemPhotosProvider(item).notifier);

      final photo = await notifier.add(XFile('x.jpg'), ItemPhotoType.repair);
      expect(container.read(itemPhotosProvider(item)).value!.count, 4);
      expect(repo.addedTypes, [ItemPhotoType.repair]);

      repo.deleteError = StateError('offline');
      await expectLater(notifier.remove(photo), throwsStateError);
      expect(container.read(itemPhotosProvider(item)).value!.count, 4);
    });
  });

  testResponsiveLoaded(
    'item photos hold up',
    () => washer,
    overrides: () => cOverrides(photos: three()),
  );
}
