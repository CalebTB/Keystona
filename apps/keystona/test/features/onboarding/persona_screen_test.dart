import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/router/app_router.dart';
import 'package:keystona/features/onboarding/models/onboarding_models.dart';
import 'package:keystona/features/onboarding/screens/persona_screen.dart';

import '../../support/responsive_harness.dart';
import 'onboarding_test_support.dart';

void main() {
  testResponsive(
    'OnbPersona',
    () => const OnbPersonaScreen(),
    wrap: OnbHarness().wrap,
  );

  testWidgets('shows copy, owner preselected, welcome name', (tester) async {
    final h = OnbHarness();
    await pumpFlow(tester, h, initial: AppRoutes.onboardingPersona);
    expect(find.text('WELCOME, CALEB'), findsOneWidget);
    expect(find.text('Which sounds like you?'), findsOneWidget);
    expect(find.text('I own a home'), findsOneWidget);
    expect(find.text('I’m shopping for one'), findsOneWidget);
    expect(find.text('1 OF 3'), findsOneWidget);
  });

  testWidgets('owner continues to property and records the stage',
      (tester) async {
    final h = OnbHarness();
    final router =
        await pumpFlow(tester, h, initial: AppRoutes.onboardingPersona);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(locationOf(router), AppRoutes.onboardingProperty);
    expect(h.store.saved?.stage, OnbStage.property);
    expect(h.store.saved?.persona, OnboardingPersona.owner);
  });

  testWidgets('shopping branch goes to the placeholder and keeps persona',
      (tester) async {
    final h = OnbHarness();
    final router =
        await pumpFlow(tester, h, initial: AppRoutes.onboardingPersona);
    await tester.tap(find.text('I’m shopping for one'));
    await tester.pump();
    expect(h.store.saved?.persona, OnboardingPersona.shopper);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(locationOf(router), AppRoutes.shopAdd);
  });

  testWidgets('Continue is disabled with no persona', (tester) async {
    final h = OnbHarness(
      store: FakeProgressStore(
        initial: const OnboardingProgress(persona: null),
      ),
    );
    final router =
        await pumpFlow(tester, h, initial: AppRoutes.onboardingPersona);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(locationOf(router), AppRoutes.onboardingPersona);
  });

  testWidgets('back from the first step goes to welcome', (tester) async {
    final h = OnbHarness();
    final router =
        await pumpFlow(tester, h, initial: AppRoutes.onboardingPersona);
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(locationOf(router), AppRoutes.onboarding);
  });

  testWidgets('loading skeleton then content', (tester) async {
    final gate = Completer<void>();
    final h = OnbHarness(store: FakeProgressStore(gate: gate));
    await pumpFlow(tester, h, initial: AppRoutes.onboardingPersona);
    expect(find.text('Which sounds like you?'), findsNothing);
    gate.complete();
    await tester.pump();
    await tester.pump();
    expect(find.text('Which sounds like you?'), findsOneWidget);
  });

  testWidgets('error shows retry and recovers', (tester) async {
    final h = OnbHarness(store: FakeProgressStore()..failLoads = 1);
    await pumpFlow(tester, h, initial: AppRoutes.onboardingPersona);
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Which sounds like you?'), findsOneWidget);
  });
}
