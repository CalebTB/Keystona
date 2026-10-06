import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/subscription/models/premium_access.dart';
import '../../features/subscription/providers/subscription_provider.dart';
import '../auth_service.dart';
import '../connectivity_service.dart';
import '../storage_service.dart';

/// Provider for the [ConnectivityService] singleton.
final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

/// Stream provider that emits `true` when online, `false` when offline.
///
/// Use this in widgets instead of [connectivityServiceProvider] to get
/// reactive rebuilds on connectivity changes.
///
/// ```dart
/// final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;
/// ```
final isOnlineProvider = StreamProvider<bool>(
  (ref) => ref.watch(connectivityServiceProvider).isOnlineStream,
);

/// Provider for the [AuthService] singleton.
///
/// Inject via `ref.read(authServiceProvider)` in event handlers.
final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(),
);

/// Provider for the [StorageService] singleton.
///
/// Inject via `ref.read(storageServiceProvider)` in event handlers.
final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);

/// Whether the current user has premium access. Gates all 8 premium features.
///
/// Decision logic lives in [PremiumAccess.resolve], which is pure and fully
/// tested — see `test/features/premium_access_test.dart`. This provider only
/// collects the inputs.
///
/// It previously read `profiles.subscription_tier == 'premium'` alone, on the
/// documented assumption that a RevenueCat webhook kept that column in sync.
/// No such webhook exists, so nothing ever wrote the column and the gate was
/// permanently false: a paying user got the "Pro" label on the subscription
/// screen and a locked app everywhere else. RevenueCat's entitlements are now
/// the primary signal, with the server tier as a fallback.
final isPremiumProvider = Provider<bool>((ref) {
  final customerInfo = ref.watch(customerInfoStreamProvider);
  final trial = ref.watch(trialStatusProvider).value;

  return PremiumAccess.resolve(
    // null, not an empty set, while RevenueCat is still loading or errored —
    // the resolver treats "unknown" differently from "definitively not
    // subscribed", which is what stops a cold start locking out a subscriber.
    activeEntitlementIds: customerInfo.hasValue
        ? customerInfo.value!.entitlements.active.keys.toSet()
        : null,
    serverTier: trial?.subscriptionTier,
    trialEndsAt: trial?.trialEndsAt,
    now: DateTime.now(),
  ).isPremium;
});
