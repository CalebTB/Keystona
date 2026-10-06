import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/router/app_router.dart';
import 'package:keystona/features/onboarding/models/onboarding_models.dart';
import 'package:keystona/features/onboarding/screens/checklist_screen.dart';

import '../../support/responsive_harness.dart';
import 'onboarding_test_support.dart';

void main() {
  testResponsive(
    'OnbChecklist',
    () => const OnbChecklistScreen(),
    wrap: OnbHarness(
      store: FakeProgressStore(
        initial: const OnboardingProgress(
          stage: OnbStage.checklist,
          trialStarted: true,
          doneSteps: {ChecklistStep.scan},
        ),
      ),
    ).wrap,
  );

  testWidgets('shows the home card, trial chip and four steps',
      (tester) async {
    final h = OnbHarness(
      store: FakeProgressStore(
        initial: const OnboardingProgress(trialStarted: true),
      ),
    );
    await pumpFlow(tester, h, initial: AppRoutes.onboardingChecklist);
    expect(find.text('Your home is on Keystona.'), findsOneWidget);
    expect(find.text('1428 Elm Hollow Ln'), findsOneWidget);
    expect(
      find.text('SINGLE-FAMILY · BUILT 1998 · 2,140 SQ FT · ZONE 4A'),
      findsOneWidget,
    );
    expect(find.text('★ TRIAL'), findsOneWidget);
    expect(find.text('DO THESE FIRST'), findsOneWidget);
    expect(find.text('ABOUT 6 MIN'), findsOneWidget);
    for (final t in [
      'Scan your systems',
      'Find your shutoffs',
      'Add one document',
      'Invite your household',
    ]) {
      expect(find.text(t), findsOneWidget);
    }
    expect(find.text('Start with my systems'), findsOneWidget);
    expect(find.text('Go to my home first'), findsOneWidget);
  });

  testWidgets('no trial chip when the user stayed on Free', (tester) async {
    await pumpFlow(tester, OnbHarness(), initial: AppRoutes.onboardingChecklist);
    expect(find.text('★ TRIAL'), findsNothing);
  });

  testWidgets('primary button opens the first step', (tester) async {
    final router = await pumpFlow(
      tester,
      OnbHarness(),
      initial: AppRoutes.onboardingChecklist,
    );
    await tester.tap(find.text('Start with my systems'));
    await tester.pumpAndSettle();
    expect(locationOf(router), AppRoutes.homeSystemsAdd);
  });

  testWidgets('a step that pops true is marked done and persisted',
      (tester) async {
    final h = OnbHarness();
    await pumpFlow(tester, h, initial: AppRoutes.onboardingChecklist);
    await tester.tap(find.text('Find your shutoffs'));
    await tester.pumpAndSettle();
    expect(find.text('stub:${AppRoutes.emergency}'), findsOneWidget);
    await tester.tap(find.text('finish step'));
    await tester.pumpAndSettle();
    expect(h.store.saved?.doneSteps, {ChecklistStep.shutoffs});
    // The hero check plus one check for the finished step.
    expect(find.byIcon(Icons.check), findsNWidgets(2));
  });

  testWidgets('resume: done steps stay done and the button moves to the next',
      (tester) async {
    final h = OnbHarness(
      store: FakeProgressStore(
        initial: const OnboardingProgress(
          doneSteps: {ChecklistStep.scan},
        ),
      ),
    );
    final router =
        await pumpFlow(tester, h, initial: AppRoutes.onboardingChecklist);
    expect(find.byIcon(Icons.check), findsNWidgets(2));
    expect(find.text('Start with my systems'), findsNothing);
    await tester.tap(find.text('Continue setup'));
    await tester.pumpAndSettle();
    expect(locationOf(router), AppRoutes.emergency);
  });

  testWidgets('every step done offers Go to my home', (tester) async {
    final h = OnbHarness(
      store: FakeProgressStore(
        initial: OnboardingProgress(doneSteps: ChecklistStep.values.toSet()),
      ),
    );
    final router =
        await pumpFlow(tester, h, initial: AppRoutes.onboardingChecklist);
    await tester.tap(find.text('Go to my home'));
    await tester.pumpAndSettle();
    expect(locationOf(router), AppRoutes.home);
  });

  testWidgets('Go to my home first leaves the checklist', (tester) async {
    final router = await pumpFlow(
      tester,
      OnbHarness(),
      initial: AppRoutes.onboardingChecklist,
    );
    await tester.tap(find.text('Go to my home first'));
    await tester.pumpAndSettle();
    expect(locationOf(router), AppRoutes.home);
  });

  testWidgets('loading skeleton then content', (tester) async {
    final gate = Completer<void>();
    final h = OnbHarness(store: FakeProgressStore(gate: gate));
    await pumpFlow(tester, h, initial: AppRoutes.onboardingChecklist);
    expect(find.text('Scan your systems'), findsNothing);
    gate.complete();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.text('Scan your systems'), findsOneWidget);
  });

  testWidgets('error shows retry and recovers', (tester) async {
    final h = OnbHarness(repository: FakeRepository(summary: kHomeSummary)..summaryFailures = 1);
    await pumpFlow(tester, h, initial: AppRoutes.onboardingChecklist);
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.text('Scan your systems'), findsOneWidget);
  });

  testWidgets('no saved home hides the home card', (tester) async {
    final h = OnbHarness(repository: FakeRepository());
    await pumpFlow(tester, h, initial: AppRoutes.onboardingChecklist);
    expect(find.text('1428 Elm Hollow Ln'), findsNothing);
    expect(find.text('Scan your systems'), findsOneWidget);
  });
}
