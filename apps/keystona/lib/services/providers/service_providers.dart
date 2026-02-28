import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Whether the current user has an active Premium subscription.
///
/// Stub — always returns false until RevenueCat is wired in Phase 8.
/// Replace the body with a RevenueCat CustomerInfo stream at that point.
final isPremiumProvider = Provider<bool>((ref) => false);
