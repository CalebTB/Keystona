import 'dart:async';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';

part 'subscription_provider.g.dart';

// ── Custom exceptions ─────────────────────────────────────────────────────────

/// Thrown by [DocumentsNotifier.add] when a free-tier user has reached the
/// 25-document limit.
class DocumentLimitException implements Exception {
  const DocumentLimitException();
}

/// Thrown by [ProjectsNotifier.createProject] when a free-tier user has
/// reached the 2-project limit.
class ProjectLimitException implements Exception {
  const ProjectLimitException();
}

// ── Free-tier limits ──────────────────────────────────────────────────────────

/// Maximum number of documents for free-tier accounts.
const kFreeDocumentLimit = 25;

/// Maximum number of active projects for free-tier accounts.
const kFreeProjectLimit = 2;

// ── Trial status ──────────────────────────────────────────────────────────────

/// Trial and grace-period state for the current user, derived from the
/// `profiles` table.
class TrialStatus {
  const TrialStatus({
    this.trialEndsAt,
    required this.subscriptionTier,
  });

  final DateTime? trialEndsAt;
  final String subscriptionTier;

  /// True when the user is on an active premium trial.
  bool get isInTrial =>
      subscriptionTier == 'premium' &&
      trialEndsAt != null &&
      DateTime.now().isBefore(trialEndsAt!);

  /// True when the trial has ended but the 14-day grace period has not expired.
  bool get isInGracePeriod {
    if (trialEndsAt == null) return false;
    final now = DateTime.now();
    if (now.isBefore(trialEndsAt!)) return false;
    final gracePeriodEnd = trialEndsAt!.add(const Duration(days: 14));
    return now.isBefore(gracePeriodEnd);
  }

  /// Days remaining until the trial expires. Returns 0 when not in trial.
  int get daysRemainingInTrial {
    if (trialEndsAt == null) return 0;
    return trialEndsAt!.difference(DateTime.now()).inDays.clamp(0, 30);
  }

  /// Days until documents are archived (trial end + 14 days = day 44).
  int get daysUntilArchive {
    if (trialEndsAt == null) return 0;
    final archiveDate = trialEndsAt!.add(const Duration(days: 14));
    return archiveDate.difference(DateTime.now()).inDays.clamp(0, 44);
  }

  /// Show a trial-ending warning when 5 or fewer days remain.
  bool get shouldShowTrialBanner =>
      isInTrial && daysRemainingInTrial <= 5;

  /// Show a grace-period warning banner.
  bool get shouldShowGraceBanner => isInGracePeriod;
}

// ── Providers ─────────────────────────────────────────────────────────────────

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

/// Trial and grace-period status for the current user.
///
/// Reads `subscription_tier` and `trial_ends_at` from the `profiles` table.
/// Gracefully returns a free-tier [TrialStatus] when columns are missing or
/// the user is not authenticated.
@riverpod
Future<TrialStatus> trialStatus(Ref ref) async {
  final user = SupabaseService.client.auth.currentUser;
  if (user == null) return const TrialStatus(subscriptionTier: 'free');

  try {
    final row = await SupabaseService.client
        .from('profiles')
        .select('subscription_tier, trial_ends_at')
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) return const TrialStatus(subscriptionTier: 'free');

    return TrialStatus(
      subscriptionTier:
          row['subscription_tier'] as String? ?? 'free',
      trialEndsAt: row['trial_ends_at'] == null
          ? null
          : DateTime.parse(row['trial_ends_at'] as String),
    );
  } catch (_) {
    // Gracefully degrade when the column doesn't exist yet.
    return const TrialStatus(subscriptionTier: 'free');
  }
}
