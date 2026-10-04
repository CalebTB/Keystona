import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/aurora/aurora.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../../services/providers/service_providers.dart';

/// Settings screen for managing the user's Keystona subscription.
///
/// Shows the current tier, offers an upgrade CTA for free users,
/// and provides restore-purchases and manage-subscription actions.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final tier = isPremium ? 'Pro' : 'Free';

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Subscription'),
      ),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () async => ref.invalidate(isPremiumProvider),
          ),
          SliverSafeArea(
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AuroraSpacing.screenPadH),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AuroraSpacing.space7),

                    // ── Current plan card ─────────────────────────────────────
                    _TierCard(tier: tier, isPremium: isPremium),

                    const SizedBox(height: AuroraSpacing.space9),

                    // ── Upgrade CTA — coral PrimaryButton (purchase action) ──
                    if (!isPremium) ...[
                      PrimaryButton(
                        label: 'Upgrade to Pro',
                        onPressed: () => context.push(AppRoutes.settingsPaywall),
                        expand: true,
                      ),
                      const SizedBox(height: AuroraSpacing.space5),
                    ],

                    // ── Section eyebrow ────────────────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AuroraColors.inkBorderStrong,
                            borderRadius:
                                BorderRadius.all(Radius.circular(2)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'MANAGE',
                          style: AuroraType.label.copyWith(
                            color: AuroraColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AuroraSpacing.space5),

                    // ── Action tiles ───────────────────────────────────────────
                    _ActionTile(
                      icon: Icons.refresh_rounded,
                      label: 'Restore Purchases',
                      onTap: () => _restore(context),
                    ),

                    const SizedBox(height: AuroraSpacing.space3),

                    _ActionTile(
                      icon: Icons.manage_accounts_rounded,
                      label: 'Manage Subscription',
                      onTap: () => RevenueCatUI.presentCustomerCenter(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _restore(BuildContext context) async {
    try {
      await Purchases.restorePurchases();
      if (context.mounted) {
        SnackbarService.showSuccess(context, 'Purchases restored.');
      }
    } catch (_) {
      if (context.mounted) {
        SnackbarService.showError(context, 'Could not restore purchases.');
      }
    }
  }
}

// ─── Tier card ────────────────────────────────────────────────────────────────

/// Current plan card:
/// - Premium: butter bg, cobalt left border indicator.
/// - Free: paper bg, standard inkBorder.
class _TierCard extends StatelessWidget {
  const _TierCard({required this.tier, required this.isPremium});

  final String tier;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AuroraSpacing.space7),
      decoration: BoxDecoration(
        color: isPremium ? AuroraColors.butter : AuroraColors.paper,
        borderRadius: AuroraRadius.xl,
        border: Border(
          left: BorderSide(
            color: isPremium ? AuroraColors.cobalt : AuroraColors.inkBorder,
            width: isPremium ? 3 : 1,
          ),
          top: BorderSide(color: AuroraColors.inkBorder),
          right: BorderSide(color: AuroraColors.inkBorder),
          bottom: BorderSide(color: AuroraColors.inkBorder),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPremium ? AuroraColors.cobaltDim : AuroraColors.butter,
              borderRadius: AuroraRadius.sm,
            ),
            child: Icon(
              isPremium ? Icons.star_rounded : Icons.star_border_rounded,
              color: isPremium ? AuroraColors.cobalt : AuroraColors.inkSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: AuroraSpacing.space7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keystona $tier',
                  style: AuroraType.h3,
                ),
                const SizedBox(height: 2),
                Text(
                  isPremium
                      ? 'Full access to all features'
                      : 'Limited features',
                  style: AuroraType.bodySm.copyWith(
                    color: AuroraColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isPremium)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AuroraSpacing.space3,
                vertical: AuroraSpacing.space1,
              ),
              decoration: BoxDecoration(
                color: AuroraColors.cobaltDim,
                borderRadius: AuroraRadius.xs,
              ),
              child: Text(
                'ACTIVE',
                style: AuroraType.labelSm.copyWith(
                  color: AuroraColors.cobalt,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Action tile ──────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AuroraSpacing.space5,
          horizontal: AuroraSpacing.space7,
        ),
        decoration: BoxDecoration(
          color: AuroraColors.paper,
          borderRadius: AuroraRadius.lg,
          border: Border.all(color: AuroraColors.inkBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AuroraColors.inkSecondary),
            const SizedBox(width: AuroraSpacing.space5),
            Expanded(
              child: Text(label, style: AuroraType.body),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AuroraColors.inkTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
