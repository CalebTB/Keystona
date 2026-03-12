import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_service.dart';
import '../connectivity_service.dart';
import '../storage_service.dart';
import '../../features/subscription/providers/subscription_provider.dart';

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

/// Whether the current user has an active Keystona Pro entitlement.
///
/// Derives from [customerInfoStreamProvider] so any purchase, cancellation,
/// or restore is reflected immediately without a manual refresh.
final isPremiumProvider = Provider<bool>((ref) {
  final info = ref.watch(customerInfoStreamProvider);
  return info.value?.entitlements.active.containsKey('Keystona Pro') ?? false;
});
