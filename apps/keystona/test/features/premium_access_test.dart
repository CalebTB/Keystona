import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/subscription/models/premium_access.dart';
import 'package:keystona/features/subscription/providers/subscription_provider.dart';

/// Regression tests for the monetization gate.
///
/// The bug these exist to prevent: `isPremiumProvider` gated all 8 premium
/// call sites on `profiles.subscription_tier == 'premium'`, a column nothing
/// in the system ever wrote (the "RevenueCat webhook" it was documented as
/// depending on does not exist). The gate was permanently false, so a paying
/// user got nothing. It looked wired — it read a real column through a real
/// provider — which is exactly why only a test of the decision itself catches
/// it.
///
/// Both failure directions matter here and neither is cosmetic: denying a
/// paying customer is a refund and a bad review, granting a non-payer is
/// giving the product away.
void main() {
  final now = DateTime.utc(2026, 6, 15, 12);

  PremiumAccess resolve({
    Set<String>? entitlements,
    String? tier,
    DateTime? trialEndsAt,
  }) =>
      PremiumAccess.resolve(
        activeEntitlementIds: entitlements,
        serverTier: tier,
        trialEndsAt: trialEndsAt,
        now: now,
      );

  group('the bug that shipped', () {
    test('a paid entitlement grants access even though the tier says free', () {
      // The exact production state: purchase succeeded, RevenueCat granted the
      // entitlement, and profiles.subscription_tier is still its 'free'
      // default because nothing writes it. This MUST be premium.
      final access = resolve(
        entitlements: {kProEntitlementId},
        tier: 'free',
      );
      expect(access.isPremium, isTrue);
      expect(access.source, PremiumSource.entitlement);
    });

    test('a family subscriber is premium, not free', () {
      // 'family' is a real value of the subscription_tier enum. The old
      // `== 'premium'` comparison read it as free.
      final access = resolve(entitlements: const {}, tier: 'family');
      expect(access.isPremium, isTrue);
      expect(access.source, PremiumSource.serverTier);
    });

    test('a trial on a free-tier row still counts as a trial', () {
      // The old code required tier == 'premium' before it would even look at
      // trialEndsAt — but a signup trial sits on a 'free' row, so trials
      // never registered.
      final access = resolve(
        entitlements: const {},
        tier: 'free',
        trialEndsAt: now.add(const Duration(days: 3)),
      );
      expect(access.isPremium, isTrue);
      expect(access.source, PremiumSource.trial);
    });
  });

  group('entitlement is authoritative', () {
    test('an unrelated active entitlement does not grant Pro', () {
      final access = resolve(entitlements: {'Some Other Thing'}, tier: 'free');
      expect(access.isPremium, isFalse);
    });

    test('entitlement wins over a free tier', () {
      expect(resolve(entitlements: {kProEntitlementId}, tier: 'free').isPremium,
          isTrue);
    });

    test('an expired trial does not revoke an active entitlement', () {
      // Someone whose trial lapsed and who then paid.
      final access = resolve(
        entitlements: {kProEntitlementId},
        tier: 'free',
        trialEndsAt: now.subtract(const Duration(days: 400)),
      );
      expect(access.isPremium, isTrue);
      expect(access.source, PremiumSource.entitlement);
    });
  });

  group('null vs empty entitlements — loading is not "not subscribed"', () {
    test('null (still loading) falls back to the server tier', () {
      // Cold start before RevenueCat answers. A premium server tier must not
      // be ignored, or a paying user sees a locked app for a beat.
      final access = resolve(entitlements: null, tier: 'premium');
      expect(access.isPremium, isTrue);
      expect(access.source, PremiumSource.serverTier);
    });

    test('null with nothing else known denies — fails closed, not open', () {
      final access = resolve(entitlements: null, tier: null);
      expect(access.isPremium, isFalse);
      expect(access.source, PremiumSource.none);
    });

    test('empty set (definitively not subscribed) still honours the tier', () {
      // A comped account: no store purchase, access granted server-side.
      expect(resolve(entitlements: const {}, tier: 'premium').isPremium, isTrue);
    });
  });

  group('trial and grace boundaries', () {
    test('the instant a trial expires it is no longer a trial', () {
      final access = resolve(entitlements: const {}, trialEndsAt: now);
      expect(access.source, PremiumSource.gracePeriod,
          reason: 'expiry is exclusive — at exactly trialEndsAt the trial is over');
      expect(access.isPremium, isTrue, reason: 'grace still grants access');
    });

    test('inside the grace period access is retained', () {
      final access = resolve(
        entitlements: const {},
        trialEndsAt: now.subtract(const Duration(days: 13)),
      );
      expect(access.isPremium, isTrue);
      expect(access.source, PremiumSource.gracePeriod);
    });

    test('one day past grace, access is gone', () {
      final access = resolve(
        entitlements: const {},
        trialEndsAt: now.subtract(const Duration(days: 15)),
      );
      expect(access.isPremium, isFalse);
      expect(access.source, PremiumSource.none);
    });

    test('the grace boundary is exclusive at exactly +14 days', () {
      final access = resolve(
        entitlements: const {},
        trialEndsAt: now.subtract(const Duration(days: 14)),
      );
      expect(access.isPremium, isFalse,
          reason: 'at exactly trialEndsAt + grace, access has ended');
    });
  });

  group('denial — the product is not given away', () {
    test('free tier, no entitlement, no trial', () {
      final access = resolve(entitlements: const {}, tier: 'free');
      expect(access.isPremium, isFalse);
      expect(access.source, PremiumSource.none);
    });

    test('an unknown tier string does not grant access', () {
      // Guards against a new enum value being added server-side and silently
      // becoming premium.
      for (final tier in ['', 'FREE', 'Premium', 'pro', 'lifetime', 'trial']) {
        expect(resolve(entitlements: const {}, tier: tier).isPremium, isFalse,
            reason: 'tier "$tier" must not grant access');
      }
    });

    test('tier matching is case-sensitive and exact', () {
      expect(resolve(entitlements: const {}, tier: 'PREMIUM').isPremium, isFalse);
      expect(resolve(entitlements: const {}, tier: 'premium ').isPremium, isFalse);
    });

    test('the entitlement id must match exactly', () {
      for (final id in ['keystona pro', 'KeystonaPro', 'Keystona_Pro', 'Pro']) {
        expect(resolve(entitlements: {id}, tier: 'free').isPremium, isFalse,
            reason: 'entitlement "$id" must not match');
      }
    });
  });

  trialStatusTests();

  group('constants match the backend', () {
    test('the entitlement id is the one configured in RevenueCat', () {
      // Changing this breaks every paying customer, so pin it.
      expect(kProEntitlementId, 'Keystona Pro');
    });

    test('premium tiers cover exactly the non-free enum values', () {
      // Postgres enum subscription_tier is: free | premium | family.
      expect(kPremiumTiers, {'premium', 'family'});
      expect(kPremiumTiers.contains('free'), isFalse);
    });
  });
}

/// `TrialStatus` lives in the provider file and carries the banner logic.
/// Its getters had the same defect as the premium gate: `isInTrial` required
/// `subscriptionTier == 'premium'`, a value nothing writes, so the trial
/// banner could never render.
void trialStatusTests() {
  group('TrialStatus banner getters', () {
    test('a trial on a free-tier row shows the banner', () {
      final status = TrialStatus(
        subscriptionTier: 'free',
        trialEndsAt: DateTime.now().add(const Duration(days: 3)),
      );
      expect(status.isInTrial, isTrue);
      expect(status.shouldShowTrialBanner, isTrue,
          reason: '3 days left is inside the 5-day warning window');
    });

    test('no banner when the trial is comfortably far off', () {
      final status = TrialStatus(
        subscriptionTier: 'free',
        trialEndsAt: DateTime.now().add(const Duration(days: 20)),
      );
      expect(status.isInTrial, isTrue);
      expect(status.shouldShowTrialBanner, isFalse);
    });

    test('an expired trial is in grace, not in trial', () {
      final status = TrialStatus(
        subscriptionTier: 'free',
        trialEndsAt: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(status.isInTrial, isFalse);
      expect(status.isInGracePeriod, isTrue);
      expect(status.shouldShowGraceBanner, isTrue);
    });

    test('no trial date means no banners at all', () {
      const status = TrialStatus(subscriptionTier: 'free');
      expect(status.isInTrial, isFalse);
      expect(status.isInGracePeriod, isFalse);
      expect(status.shouldShowTrialBanner, isFalse);
      expect(status.shouldShowGraceBanner, isFalse);
    });
  });
}
