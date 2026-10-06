/// Resolves whether the current user has premium access.
///
/// This exists as a pure function, separate from any provider, because the
/// previous arrangement shipped a bug that no amount of UI review would catch:
///
///   `isPremiumProvider` gated all 8 premium call sites on
///   `profiles.subscription_tier == 'premium'`, a column documented as "kept in
///   sync by the RevenueCat webhook". No such webhook exists — not in
///   `supabase/functions/`, not deployed. Nothing in the system could ever
///   write that value, so the gate was permanently false. A user could
///   complete a real purchase, RevenueCat would grant the entitlement, the
///   subscription screen would display "Pro", and every premium feature would
///   stay locked.
///
/// The fix is to gate on the source that actually knows: RevenueCat's
/// entitlements, which the SDK caches on-device and updates synchronously when
/// a purchase completes. The Supabase tier stays as a secondary signal so the
/// server can still grant access (comped accounts, family plans, a webhook if
/// one is added later) — but it is no longer the only thing consulted.
library;

/// The entitlement identifier configured in RevenueCat.
///
/// Must match the dashboard exactly; a typo here fails open to "not premium"
/// for every paying customer, which is why [PremiumAccess.resolve] is tested
/// against this constant rather than a literal.
const kProEntitlementId = 'Keystona Pro';

/// Server-side tiers that grant premium access.
///
/// `family` is included deliberately: it is a valid value of the
/// `subscription_tier` Postgres enum (`free | premium | family`) that the old
/// `== 'premium'` check silently treated as free, so a family subscriber was
/// downgraded by a string comparison.
const kPremiumTiers = {'premium', 'family'};

/// Why access was granted or denied. Surfaced for diagnostics — a user
/// reporting "I paid and it's locked" is answerable from this value alone.
enum PremiumSource {
  /// An active RevenueCat entitlement. The authoritative case.
  entitlement,

  /// Server-side tier (`premium` or `family`) with no active entitlement.
  /// Covers comped accounts and anything granted outside the store.
  serverTier,

  /// Inside an active trial window.
  trial,

  /// Trial ended, still inside the grace period before data is archived.
  gracePeriod,

  /// No signal granted access.
  none,
}

/// The outcome of a premium-access decision.
class PremiumAccess {
  const PremiumAccess._(this.isPremium, this.source);

  final bool isPremium;
  final PremiumSource source;

  /// Decides premium access from every available signal.
  ///
  /// [activeEntitlementIds] are the keys of `CustomerInfo.entitlements.active`.
  /// Pass `null` — not an empty set — when RevenueCat has not answered yet, so
  /// "still loading" is distinguishable from "definitively not subscribed".
  /// That distinction is the difference between briefly falling back to the
  /// server tier and wrongly locking out a paying user on a cold start.
  ///
  /// [serverTier] is `profiles.subscription_tier`, or null when unknown.
  /// [trialEndsAt] is `profiles.trial_ends_at`.
  /// [now] is injected so trial boundaries are testable.
  static PremiumAccess resolve({
    required Set<String>? activeEntitlementIds,
    required String? serverTier,
    required DateTime? trialEndsAt,
    required DateTime now,
    Duration gracePeriod = const Duration(days: 14),
  }) {
    // 1. RevenueCat wins when it has answered. It is the only signal that
    //    reflects a purchase the instant it completes, and it works offline
    //    from the SDK's cache.
    if (activeEntitlementIds != null &&
        activeEntitlementIds.contains(kProEntitlementId)) {
      return const PremiumAccess._(true, PremiumSource.entitlement);
    }

    // 2. A server-granted tier. Reached when RevenueCat is still loading, or
    //    when access was granted outside the store entirely.
    if (serverTier != null && kPremiumTiers.contains(serverTier)) {
      return const PremiumAccess._(true, PremiumSource.serverTier);
    }

    // 3. Trial and grace are evaluated from the date alone, NOT gated on the
    //    tier. The old code required `tier == 'premium'` before it would look
    //    at `trialEndsAt`, so a trial on a `free` row — which is what a signup
    //    trial actually looks like, since nothing writes the tier — never
    //    registered as a trial at all.
    if (trialEndsAt != null) {
      if (now.isBefore(trialEndsAt)) {
        return const PremiumAccess._(true, PremiumSource.trial);
      }
      if (now.isBefore(trialEndsAt.add(gracePeriod))) {
        return const PremiumAccess._(true, PremiumSource.gracePeriod);
      }
    }

    return const PremiumAccess._(false, PremiumSource.none);
  }
}
