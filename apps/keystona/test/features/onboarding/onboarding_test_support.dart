import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keystona/core/router/app_router.dart';
import 'package:keystona/features/onboarding/models/onboarding_models.dart';
import 'package:keystona/features/onboarding/providers/onboarding_provider.dart';
import 'package:keystona/features/onboarding/screens/checklist_screen.dart';
import 'package:keystona/features/onboarding/screens/persona_screen.dart';
import 'package:keystona/features/onboarding/screens/property_setup_screen.dart';
import 'package:keystona/features/onboarding/screens/trial_screen.dart';
import 'package:keystona/features/onboarding/services/onboarding_services.dart';

/// In-memory progress store. [gate] holds `load` until completed.
class FakeProgressStore implements OnboardingProgressStore {
  FakeProgressStore({this.initial = const OnboardingProgress(), this.gate});

  OnboardingProgress initial;
  Completer<void>? gate;
  int failLoads = 0;
  OnboardingProgress? saved;

  @override
  Future<OnboardingProgress> load(String userId) async {
    if (gate != null) await gate!.future;
    if (failLoads > 0) {
      failLoads--;
      throw Exception('load failed');
    }
    return saved ?? initial;
  }

  @override
  Future<void> save(String userId, OnboardingProgress progress) async {
    saved = progress;
  }
}

class FakeRepository implements OnboardingRepository {
  FakeRepository({this.summary});

  OnbHomeSummary? summary;
  int summaryFailures = 0;
  bool failSave = false;
  bool failComplete = false;
  final List<OnbPropertyDraft> saves = [];
  int completed = 0;

  @override
  Future<void> saveProperty(OnbPropertyDraft draft) async {
    if (failSave) throw Exception('save failed');
    saves.add(draft);
  }

  @override
  Future<void> completeOnboarding() async {
    if (failComplete) throw Exception('complete failed');
    completed++;
  }

  @override
  Future<OnbHomeSummary?> loadHomeSummary() async {
    if (summaryFailures > 0) {
      summaryFailures--;
      throw Exception('summary failed');
    }
    return summary;
  }
}

class FakeTrialStarter implements TrialStarter {
  bool fail = false;
  Completer<void>? gate;
  final List<OnbPlan> started = [];

  @override
  Future<void> startTrial(OnbPlan plan) async {
    if (gate != null) await gate!.future;
    if (fail) throw Exception('purchase failed');
    started.add(plan);
  }
}

class FakeClimateSource implements ClimateSource {
  FakeClimateSource({this.failures = 0, this.result});

  int failures;
  ClimateProfile? result;
  int calls = 0;

  @override
  Future<ClimateProfile?> lookup({
    required String zip,
    required String state,
  }) async {
    calls++;
    if (failures > 0) {
      failures--;
      throw Exception('lookup failed');
    }
    return result;
  }
}

const OnbHomeSummary kHomeSummary = OnbHomeSummary(
  street: '1428 Elm Hollow Ln',
  kind: HomeKind.singleFamily,
  yearBuilt: 1998,
  squareFeet: 2140,
  climateZone: 4,
  climateMoisture: 'A',
);

/// Everything a screen test needs, with sensible defaults.
class OnbHarness {
  OnbHarness({
    FakeProgressStore? store,
    FakeRepository? repository,
    FakeTrialStarter? trial,
    this.climate,
  })  : store = store ?? FakeProgressStore(),
        repository = repository ?? FakeRepository(summary: kHomeSummary),
        trial = trial ?? FakeTrialStarter();

  final FakeProgressStore store;
  final FakeRepository repository;
  final FakeTrialStarter trial;
  final FakeClimateSource? climate;

  List<Override> get overrides => [
        onboardingProgressStoreProvider.overrideWithValue(store),
        onboardingRepositoryProvider.overrideWithValue(repository),
        trialStarterProvider.overrideWithValue(trial),
        if (climate != null) climateSourceProvider.overrideWithValue(climate!),
        onboardingUserIdProvider.overrideWithValue('u1'),
        onboardingFirstNameProvider.overrideWithValue('Caleb'),
        onboardingClockProvider.overrideWithValue(() => DateTime(2026, 10, 5)),
      ];

  /// Retries are off so a failing provider shows its error state at once.
  Widget wrap(Widget app) => ProviderScope(
        overrides: overrides,
        retry: (_, _) => null,
        child: app,
      );
}

/// Router with the real onboarding screens and stubs for every other target.
GoRouter buildTestRouter(String initial) {
  GoRoute stub(String path) => GoRoute(
        path: path,
        builder: (context, _) => Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('stub:$path'),
                TextButton(
                  onPressed: () => context.pop(true),
                  child: const Text('finish step'),
                ),
              ],
            ),
          ),
        ),
      );
  return GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: AppRoutes.onboardingPersona,
        builder: (_, _) => const OnbPersonaScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingProperty,
        builder: (_, _) => const PropertySetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingTrial,
        builder: (_, _) => const TrialScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingChecklist,
        builder: (_, _) => const OnbChecklistScreen(),
      ),
      stub(AppRoutes.onboarding),
      stub(AppRoutes.shopAdd),
      stub(AppRoutes.home),
      stub(AppRoutes.homeSystemsAdd),
      stub(AppRoutes.emergency),
      stub(AppRoutes.documentsUpload),
      stub(AppRoutes.settingsHousehold),
    ],
  );
}

/// Pumps the flow at [initial] on a phone-size surface.
Future<GoRouter> pumpFlow(
  WidgetTester tester,
  OnbHarness harness, {
  required String initial,
  Size size = const Size(390, 1400),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final router = buildTestRouter(initial);
  await tester.pumpWidget(
    harness.wrap(MaterialApp.router(routerConfig: router)),
  );
  await tester.pump();
  await tester.pump();
  return router;
}

String locationOf(GoRouter router) =>
    router.routerDelegate.currentConfiguration.last.matchedLocation;
