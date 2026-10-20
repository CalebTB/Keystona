import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/router/app_router.dart';
import 'package:keystona/core/widgets/aurora/aurora_button.dart';
import 'package:keystona/core/widgets/aurora/aurora_toggle_row.dart';
import 'package:keystona/features/home_profile/providers/home_profile_provider.dart';
import 'package:keystona/features/home_profile/screens/home_edit_screen.dart';
import 'package:keystona/features/home_profile/widgets/home_edit/home_edit_body.dart';

import '../../../support/responsive_harness.dart';
import 'router_support.dart';
import 'track_a_support.dart';

void main() {
  final width = kViewports[1].size.width;

  List<Override> overrides(FakePropertyRepository property) =>
      homeOverrides(property, FakeHomeItemsRepository(sampleItems()));

  testScreenResponsive(
    'HomeEditScreen',
    () => const HomeEditScreen(),
    () => overrides(FakePropertyRepository(sampleProperty())),
  );
  testScreenResponsive(
    'HomeEditScreen with a bare property',
    () => const HomeEditScreen(),
    () => overrides(
      FakePropertyRepository(
        sampleProperty(type: null).copyWith(
          bedrooms: null,
          bathrooms: null,
          stories: null,
          garageType: null,
          garageSpaces: null,
          purchaseDate: null,
          purchasePrice: null,
          lotSizeSqft: null,
        ),
      ),
    ),
  );

  Future<List<String>> pump(
    WidgetTester tester,
    FakePropertyRepository property, {
    Future<File?> Function(BuildContext)? pickPhoto,
  }) async {
    final visited = <String>[];
    await pumpRouter(
      tester,
      stubRouter(
        pickPhoto == null
            ? const HomeEditScreen()
            : HomeEditScreen(pickPhoto: pickPhoto),
        visited,
      ),
      overrides(property),
    );
    return visited;
  }

  bool saveEnabled(WidgetTester t) =>
      t.widget<SaveButton>(find.byType(SaveButton)).onPressed != null;

  Finder field(String text) => find.widgetWithText(TextField, text);

  testWidgets('opens with the property filled in and Save off', (t) async {
    await pump(t, FakePropertyRepository(sampleProperty()));
    for (final text in [
      '1428 Elm Hollow Ln',
      'Springfield',
      'AL',
      '35758',
      '1998',
      '2,140',
      '0.31',
      '318,000',
    ]) {
      expect(field(text), findsOneWidget, reason: text);
    }
    expect(find.text('Zone 4A · mixed-humid'), findsOneWidget);
    expect(
      find.text("SET FROM YOUR ZIP · CAN'T BE CHANGED BY HAND"),
      findsOneWidget,
    );
    expect(find.text('Attached · 2 cars'), findsOneWidget);
    expect(find.text('Mar 2024'), findsOneWidget);
    expect(find.text('COVER'), findsOneWidget);
    expect(saveEnabled(t), isFalse);
  });

  testWidgets('top bar: Cancel left, title centered, Save right', (t) async {
    await pump(t, FakePropertyRepository(sampleProperty()));
    expect(t.getTopLeft(find.text('Cancel')).dx, lessThan(width / 4));
    expect(t.getCenter(find.text('Edit home')).dx, closeTo(width / 2, 4));
    expect(t.getTopRight(find.text('Save')).dx, greaterThan(width * 0.8));
  });

  testWidgets('changing the year turns Save on and shows the note', (t) async {
    await pump(t, FakePropertyRepository(sampleProperty()));
    await t.enterText(field('1998'), '2001');
    await t.pump();
    expect(saveEnabled(t), isTrue);
    expect(find.text('REMINDERS AND LIFESPANS WILL UPDATE'), findsOneWidget);
    await t.enterText(field('2001'), '20');
    await t.pump();
    expect(find.text('FOUR DIGITS, LIKE 1998'), findsOneWidget);
    expect(saveEnabled(t), isFalse);
  });

  testWidgets('Save writes the edits and goes back to the profile', (t) async {
    final repo = FakePropertyRepository(sampleProperty());
    final visited = await pump(t, repo);
    await t.enterText(field('Springfield'), 'Huntsville');
    await t.tap(find.text('Condo'));
    await t.pump();
    await t.ensureVisible(find.byIcon(Icons.add).first);
    await t.pump();
    await t.tap(find.byIcon(Icons.add).first); // bedrooms 4 -> 5
    await t.pump();
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(repo.saved, hasLength(1));
    final saved = repo.saved.single;
    expect(saved.city, 'Huntsville');
    expect(saved.propertyType, 'condo');
    expect(saved.bedrooms, 5);
    expect(saved.climateZone, 4);
    expect(saved.lotSizeSqft, 13504);
    expect(visited, contains(AppRoutes.homeProfile));
  });

  testWidgets('a new ZIP rechecks the zone when saved', (t) async {
    final repo = FakePropertyRepository(sampleProperty());
    await pump(t, repo);
    await t.enterText(field('35758'), '90210');
    await t.enterText(field('AL'), 'CA');
    await t.pump();
    expect(
      find.text("NEW ZIP · WE'LL RECHECK THE ZONE WHEN YOU SAVE"),
      findsOneWidget,
    );
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(repo.saved.single.climateZone, 3);
  });

  testWidgets('a failed save keeps the form and says so', (t) async {
    final repo = FakePropertyRepository(sampleProperty(), failSave: true);
    final visited = await pump(t, repo);
    await t.enterText(field('Springfield'), 'Huntsville');
    await t.pump();
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(find.text('Could not save. Please try again.'), findsOneWidget);
    expect(field('Huntsville'), findsOneWidget);
    expect(saveEnabled(t), isTrue);
    expect(visited, isEmpty);
  });

  testWidgets('Cancel leaves without a prompt and writes nothing', (t) async {
    final repo = FakePropertyRepository(sampleProperty());
    final visited = await pump(t, repo);
    await t.enterText(field('Springfield'), 'Huntsville');
    await t.pump();
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(visited, contains(AppRoutes.homeProfile));
    expect(repo.saved, isEmpty);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('garage: choose none, and the basement switch', (t) async {
    final repo = FakePropertyRepository(sampleProperty());
    await pump(t, repo);
    await t.ensureVisible(find.text('Attached · 2 cars'));
    await t.tap(find.text('Attached · 2 cars'));
    await t.pumpAndSettle();
    await t.tap(find.text('No garage').last);
    await t.pumpAndSettle();
    expect(find.text('GARAGE SPACES'), findsNothing);
    await t.ensureVisible(find.byType(AuroraToggleRow));
    await t.tap(find.byType(AuroraSwitch));
    await t.pump();
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    final saved = repo.saved.single;
    expect(saved.garageType, isNull);
    expect(saved.garageSpaces, isNull);
    expect(saved.hasBasement, isFalse);
  });

  testWidgets('a picked cover photo is part of the save', (t) async {
    final repo = FakePropertyRepository(sampleProperty());
    final file = File('/tmp/cover.jpg');
    await pump(t, repo, pickPhoto: (_) async => file);
    await t.tap(find.text('ADD'));
    await t.pumpAndSettle();
    expect(saveEnabled(t), isTrue);
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(repo.saved.single.newPhoto, file);
  });

  testWidgets('kind of home: four choices, two per row', (t) async {
    await pump(t, FakePropertyRepository(sampleProperty()));
    expect(
      t.getCenter(find.text('Single-family')).dy,
      closeTo(t.getCenter(find.text('Townhouse')).dy, 1),
    );
    expect(
      t.getTopLeft(find.text('Condo')).dy,
      greaterThan(t.getTopLeft(find.text('Single-family')).dy),
    );
    expect(
      t.getCenter(find.text('Condo')).dx,
      closeTo(t.getCenter(find.text('Single-family')).dx, 1),
    );
  });

  testWidgets('a refresh of the property while editing keeps what was typed', (
    t,
  ) async {
    await pump(t, FakePropertyRepository(sampleProperty()));
    await t.enterText(field('Springfield'), 'Huntsville');
    await t.pump();
    ProviderScope.containerOf(
      t.element(find.byType(HomeEditBody)),
    ).invalidate(homeProfileProvider);
    await t.pump();
    await t.pumpAndSettle();
    expect(field('Huntsville'), findsOneWidget);
    expect(saveEnabled(t), isTrue);
  });
}
