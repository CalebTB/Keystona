import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/router/app_router.dart';
import 'package:keystona/core/widgets/aurora/aurora_button.dart';
import 'package:keystona/features/onboarding/models/onboarding_models.dart';
import 'package:keystona/features/onboarding/screens/trial_screen.dart';

import '../../support/responsive_harness.dart';
import 'onboarding_test_support.dart';

void main() {
  testResponsive(
    'OnbTrial',
    () => const TrialScreen(),
    wrap: OnbHarness().wrap,
  );

  testWidgets('shows the kit copy, prices and yearly fine print',
      (tester) async {
    await pumpFlow(tester, OnbHarness(), initial: AppRoutes.onboardingTrial);
    expect(find.text('Try everything free for a month.'), findsOneWidget);
    expect(find.text('★ PREMIUM · 30 DAYS FREE'), findsOneWidget);
    expect(find.text('3 OF 3'), findsOneWidget);
    expect(find.text('Scan your furnace label in 5 seconds'), findsOneWidget);
    expect(find.text('No limits'), findsOneWidget);
    expect(find.text('The Home History Report'), findsOneWidget);
    expect(find.text(r'$79.99'), findsOneWidget);
    expect(find.text(r'$9.99'), findsOneWidget);
    expect(find.text('SAVE 33%'), findsOneWidget);
    expect(find.text(r'$6.67 A MONTH'), findsOneWidget);
    expect(
      find.text(
        r'Free until Nov 4, then $79.99 a year. We remind you 3 days before. Cancel in the App Store any time.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('choosing Monthly changes the fine print and the plan started',
      (tester) async {
    final h = OnbHarness();
    await pumpFlow(tester, h, initial: AppRoutes.onboardingTrial);
    await tester.tap(find.text('Monthly'));
    await tester.pump();
    expect(
      find.text(
        r'Free until Nov 4, then $9.99 a month. We remind you 3 days before. Cancel in the App Store any time.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Start my free month'));
    await tester.pumpAndSettle();
    expect(h.trial.started, [OnbPlan.monthly]);
  });

  testWidgets('Start my free month starts the trial and opens the checklist',
      (tester) async {
    final h = OnbHarness();
    final router =
        await pumpFlow(tester, h, initial: AppRoutes.onboardingTrial);
    await tester.tap(find.text('Start my free month'));
    await tester.pumpAndSettle();
    expect(h.trial.started, [OnbPlan.yearly]);
    expect(h.repository.completed, 1);
    expect(h.store.saved?.trialStarted, isTrue);
    expect(h.store.saved?.stage, OnbStage.checklist);
    expect(locationOf(router), AppRoutes.onboardingChecklist);
  });

  testWidgets('Not now continues on Free without a trial', (tester) async {
    final h = OnbHarness();
    final router =
        await pumpFlow(tester, h, initial: AppRoutes.onboardingTrial);
    await tester.tap(find.text('Not now — start on Free'));
    await tester.pumpAndSettle();
    expect(h.trial.started, isEmpty);
    expect(h.repository.completed, 1);
    expect(h.store.saved?.trialStarted, isFalse);
    expect(locationOf(router), AppRoutes.onboardingChecklist);
  });

  testWidgets('a failed purchase shows an error and stays', (tester) async {
    final h = OnbHarness(trial: FakeTrialStarter()..fail = true);
    final router =
        await pumpFlow(tester, h, initial: AppRoutes.onboardingTrial);
    await tester.tap(find.text('Start my free month'));
    await tester.pumpAndSettle();
    expect(find.text('Could not start your free month. Please try again.'),
        findsOneWidget);
    expect(locationOf(router), AppRoutes.onboardingTrial);
    expect(
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('a failed status save warns but still continues',
      (tester) async {
    final h = OnbHarness(repository: FakeRepository()..failComplete = true);
    final router =
        await pumpFlow(tester, h, initial: AppRoutes.onboardingTrial);
    await tester.tap(find.text('Not now — start on Free'));
    await tester.pumpAndSettle();
    expect(locationOf(router), AppRoutes.onboardingChecklist);
  });

  testWidgets('both buttons are disabled while the trial starts',
      (tester) async {
    final gate = Completer<void>();
    final h = OnbHarness(trial: FakeTrialStarter()..gate = gate);
    await pumpFlow(tester, h, initial: AppRoutes.onboardingTrial);
    await tester.tap(find.text('Start my free month'));
    await tester.pump();
    expect(
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).loading,
      isTrue,
    );
    // A second tap while busy does nothing.
    await tester.tap(find.text('Not now — start on Free'));
    await tester.pump();
    gate.complete();
    await tester.pumpAndSettle();
    expect(h.trial.started, hasLength(1));
    expect(h.repository.completed, 1);
  });

  testWidgets('back goes to the property step', (tester) async {
    final router = await pumpFlow(
      tester,
      OnbHarness(),
      initial: AppRoutes.onboardingTrial,
    );
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(locationOf(router), AppRoutes.onboardingProperty);
  });
}
