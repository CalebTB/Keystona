import 'dart:async';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscription_provider.g.dart';

/// Streams [CustomerInfo] updates from RevenueCat.
///
/// Immediately fetches the current state, then subscribes to push
/// updates so any purchase or cancellation is reflected in real-time.
@riverpod
Stream<CustomerInfo> customerInfoStream(Ref ref) {
  final controller = StreamController<CustomerInfo>();

  // Eagerly emit the current state so the first frame is not empty.
  Purchases.getCustomerInfo().then((info) {
    if (!controller.isClosed) controller.add(info);
  }).catchError((_) {}); // swallow — listener will catch updates

  void listener(CustomerInfo info) {
    if (!controller.isClosed) controller.add(info);
  }

  Purchases.addCustomerInfoUpdateListener(listener);

  ref.onDispose(() {
    Purchases.removeCustomerInfoUpdateListener(listener);
    controller.close();
  });

  return controller.stream;
}

/// Current active subscription tier label for display purposes.
///
/// Returns `'Pro'` when the `Keystona Pro` entitlement is active,
/// otherwise returns `'Free'`.
@riverpod
String subscriptionTier(Ref ref) {
  final info = ref.watch(customerInfoStreamProvider).value;
  if (info == null) return 'Free';
  if (info.entitlements.active.containsKey('Keystona Pro')) return 'Pro';
  return 'Free';
}
