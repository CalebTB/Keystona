import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/router/app_router.dart';
import 'package:keystona/core/widgets/aurora/aurora_button.dart';
import 'package:keystona/features/onboarding/models/onboarding_models.dart';
import 'package:keystona/features/onboarding/screens/property_setup_screen.dart';
import 'package:keystona/features/onboarding/services/climate_lookup.dart';

import '../../support/responsive_harness.dart';
import 'onboarding_test_support.dart';

const _typed = '1428 Elm Hollow Ln, Springfield, AL 35758';
const _debounce = Duration(milliseconds: 400);

Future<void> _typeAddress(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).first, text);
  await tester.pump(_debounce);
  await tester.pump();
}

Future<void> _pickAddress(WidgetTester tester) async {
  await _typeAddress(tester, _typed);
  await tester.tap(find.text('1428 Elm Hollow Ln'));
  await tester.pump();
}

bool _ctaEnabled(WidgetTester tester) =>
    tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed != null;

void main() {
  testResponsive(
    'OnbProperty',
    () => const PropertySetupScreen(),
    wrap: OnbHarness().wrap,
  );

  testWidgets('starts disabled with the kit copy', (tester) async {
    await pumpFlow(tester, OnbHarness(), initial: AppRoutes.onboardingProperty);
    expect(find.text('Tell us about your home.'), findsOneWidget);
    expect(find.text('2 OF 3'), findsOneWidget);
    expect(find.text('KIND OF HOME'), findsOneWidget);
    expect(find.text('Single-family'), findsOneWidget);
    expect(find.text('Manufactured'), findsOneWidget);
    expect(
      find.text('NOT SURE? A GUESS IS FINE — YOU CAN CHANGE IT LATER'),
      findsOneWidget,
    );
    expect(_ctaEnabled(tester), isFalse);
  });

  testWidgets('typing a full address shows a suggestion; picking enables',
      (tester) async {
    await pumpFlow(tester, OnbHarness(), initial: AppRoutes.onboardingProperty);
    await _typeAddress(tester, _typed);
    expect(find.text('SPRINGFIELD · 35758'), findsOneWidget);
    expect(_ctaEnabled(tester), isFalse);
    await tester.tap(find.text('1428 Elm Hollow Ln'));
    await tester.pump();
    expect(_ctaEnabled(tester), isTrue);
    expect(find.text('SPRINGFIELD · 35758'), findsOneWidget);
  });

  testWidgets('a bad year shows the note and disables Continue',
      (tester) async {
    await pumpFlow(tester, OnbHarness(), initial: AppRoutes.onboardingProperty);
    await _pickAddress(tester);
    await tester.enterText(find.byType(TextField).at(1), '19x8');
    await tester.pump();
    expect(
      find.text('THAT YEAR LOOKS OFF — 4 DIGITS, LIKE 1998'),
      findsOneWidget,
    );
    expect(_ctaEnabled(tester), isFalse);
    await tester.enterText(find.byType(TextField).at(1), '1998');
    await tester.pump();
    expect(_ctaEnabled(tester), isTrue);
  });

  testWidgets('kind of home selection changes', (tester) async {
    final h = OnbHarness();
    await pumpFlow(tester, h, initial: AppRoutes.onboardingProperty);
    await _pickAddress(tester);
    await tester.tap(find.text('Condo'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.text('Looks right'));
    await tester.pumpAndSettle();
    expect(h.repository.saves.single.kind, HomeKind.condo);
  });

  testWidgets('Continue opens the climate sheet; Looks right saves and moves on',
      (tester) async {
    final h = OnbHarness();
    final router =
        await pumpFlow(tester, h, initial: AppRoutes.onboardingProperty);
    await _pickAddress(tester);
    await tester.enterText(find.byType(TextField).at(1), '1998');
    await tester.enterText(find.byType(TextField).at(2), '2,140');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('FOUND FROM YOUR ZIP · 35758'), findsOneWidget);
    expect(find.text('Your home is in a mixed-humid climate.'), findsOneWidget);
    expect(find.text('Drain outdoor faucets'), findsOneWidget);
    expect(find.text('EVERY NOV'), findsOneWidget);
    expect(find.text('ZONE 4A'), findsOneWidget);

    await tester.tap(find.text('Looks right'));
    await tester.pumpAndSettle();
    final saved = h.repository.saves.single;
    expect(saved.address.zip, '35758');
    expect(saved.yearBuilt, 1998);
    expect(saved.squareFeet, 2140);
    expect(saved.climate?.zone, 4);
    expect(locationOf(router), AppRoutes.onboardingTrial);
    expect(h.store.saved?.stage, OnbStage.trial);
  });

  testWidgets('dismissing the climate sheet saves nothing', (tester) async {
    final h = OnbHarness();
    final router =
        await pumpFlow(tester, h, initial: AppRoutes.onboardingProperty);
    await _pickAddress(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tapAt(const Offset(195, 20));
    await tester.pumpAndSettle();
    expect(h.repository.saves, isEmpty);
    expect(locationOf(router), AppRoutes.onboardingProperty);
  });

  testWidgets('climate lookup error shows retry and recovers', (tester) async {
    final climate = FakeClimateSource(
      failures: 1,
      result: ClimateLookup.forZip('35758', 'AL'),
    );
    final h = OnbHarness(climate: climate);
    await pumpFlow(tester, h, initial: AppRoutes.onboardingProperty);
    await _pickAddress(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('We couldn’t find your climate'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Looks right'), findsOneWidget);
    expect(climate.calls, 2);
  });

  testWidgets('a ZIP with no climate data shows the not-found state',
      (tester) async {
    final h = OnbHarness(climate: FakeClimateSource());
    await pumpFlow(tester, h, initial: AppRoutes.onboardingProperty);
    await _pickAddress(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.textContaining('ZIP 35758'), findsOneWidget);
    expect(find.text('Looks right'), findsNothing);
  });

  testWidgets('a failed save shows an error and stays', (tester) async {
    final h = OnbHarness(repository: FakeRepository()..failSave = true);
    final router =
        await pumpFlow(tester, h, initial: AppRoutes.onboardingProperty);
    await _pickAddress(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.text('Looks right'));
    await tester.pumpAndSettle();
    expect(find.text('Could not save your home. Please try again.'),
        findsOneWidget);
    expect(locationOf(router), AppRoutes.onboardingProperty);
  });

  testWidgets('back goes to the persona step', (tester) async {
    final router = await pumpFlow(
      tester,
      OnbHarness(),
      initial: AppRoutes.onboardingProperty,
    );
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(locationOf(router), AppRoutes.onboardingPersona);
  });
}
