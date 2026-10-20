import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/providers/service_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/onboarding_models.dart';
import '../services/onboarding_services.dart';

part 'onboarding_provider.g.dart';

// ─── Dependencies (overridden in tests) ──────────────────────────────────────

@Riverpod(keepAlive: true)
OnboardingProgressStore onboardingProgressStore(Ref ref) =>
    const PrefsOnboardingProgressStore();

@Riverpod(keepAlive: true)
OnboardingRepository onboardingRepository(Ref ref) =>
    const SupabaseOnboardingRepository();

@Riverpod(keepAlive: true)
AddressSource addressSource(Ref ref) => const ParsedAddressSource();

@Riverpod(keepAlive: true)
ClimateSource climateSource(Ref ref) => const LocalClimateSource();

@Riverpod(keepAlive: true)
TrialStarter trialStarter(Ref ref) => const MockTrialStarter();

/// Current time. Overridden in tests so dates are stable.
@Riverpod(keepAlive: true)
DateTime Function() onboardingClock(Ref ref) => DateTime.now;

/// Signed-in user id. Scopes the stored progress.
@Riverpod(keepAlive: true)
String onboardingUserId(Ref ref) {
  // Re-evaluates on sign-in and sign-out so progress never leaks across users.
  ref.watch(isAuthenticatedProvider);
  return ref.read(authServiceProvider).currentUser?.id ?? '';
}

/// First name for "WELCOME, CALEB", or null when the account has no name.
@Riverpod(keepAlive: true)
String? onboardingFirstName(Ref ref) {
  final full =
      ref.watch(authServiceProvider).currentUser?.userMetadata?['full_name'];
  if (full is! String || full.trim().isEmpty) return null;
  return full.trim().split(RegExp(r'\s+')).first;
}

// ─── Progress (persona, stage, trial, checklist) ─────────────────────────────

/// Persisted progress. Updates state first, then writes to the device.
@Riverpod(keepAlive: true)
class OnboardingProgressNotifier extends _$OnboardingProgressNotifier {
  @override
  Future<OnboardingProgress> build() {
    final userId = ref.watch(onboardingUserIdProvider);
    return ref.read(onboardingProgressStoreProvider).load(userId);
  }

  Future<void> setPersona(OnboardingPersona persona) =>
      _update((p) => p.copyWith(persona: persona));

  /// Records the furthest step reached. Never moves backwards.
  Future<void> reachStage(OnbStage stage) => _update(
        (p) => stage.index > p.stage.index ? p.copyWith(stage: stage) : p,
      );

  Future<void> setTrialStarted() => _update((p) => p.copyWith(trialStarted: true));

  Future<void> markStepDone(ChecklistStep step) =>
      _update((p) => p.copyWith(doneSteps: {...p.doneSteps, step}));

  Future<void> _update(OnboardingProgress Function(OnboardingProgress) f) async {
    final current = state.value ?? await future;
    final next = f(current);
    state = AsyncData(next);
    try {
      await ref
          .read(onboardingProgressStoreProvider)
          .save(ref.read(onboardingUserIdProvider), next);
    } catch (_) {
      // Progress is a convenience: the in-memory value stays correct and the
      // flow keeps working if the device write fails.
    }
  }
}

// ─── Property draft ──────────────────────────────────────────────────────────

/// What OnbProperty collected, kept for the rest of the flow.
@Riverpod(keepAlive: true)
class OnbPropertyDraftNotifier extends _$OnbPropertyDraftNotifier {
  @override
  OnbPropertyDraft? build() {
    // Kept alive across the onboarding screens, so it must belong to the
    // signed-in user: a sign-out / sign-in rebuilds it empty instead of
    // showing the previous account's address on the next account's checklist.
    ref.watch(onboardingUserIdProvider);
    return null;
  }

  void set(OnbPropertyDraft draft) => state = draft;
}

/// The home card on the checklist: the draft when present, else the saved row.
@riverpod
Future<OnbHomeSummary?> onbHomeSummary(Ref ref) async {
  final draft = ref.watch(onbPropertyDraftProvider);
  if (draft != null) {
    return OnbHomeSummary(
      street: draft.address.street,
      kind: draft.kind,
      yearBuilt: draft.yearBuilt,
      squareFeet: draft.squareFeet,
      climateZone: draft.climate?.zone,
      climateMoisture: draft.climate?.moisture,
    );
  }
  return ref.read(onboardingRepositoryProvider).loadHomeSummary();
}
