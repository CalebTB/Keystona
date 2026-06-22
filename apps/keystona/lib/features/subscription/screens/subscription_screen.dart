import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
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
                    _TierCard(tier: tier, isPremium: isPremium),
                    const SizedBox(height: AuroraSpacing.space9),
                    if (!isPremium) ...[
                      _ActionButton(
                        label: 'Upgrade to Pro',
                        color: AuroraColors.ink,
                        onTap: () => context.push(AppRoutes.settingsPaywall),
                      ),
                      const SizedBox(height: AuroraSpacing.space3),
                    ],
                    _ActionButton(
                      label: 'Restore Purchases',
                      color: AuroraColors.inkSecondary,
                      onTap: () => _restore(context),
                    ),
                    const SizedBox(height: AuroraSpacing.space3),
                    _ActionButton(
                      label: 'Manage Subscription',
                      color: AuroraColors.inkSecondary,
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

class _TierCard extends StatelessWidget {
  const _TierCard({required this.tier, required this.isPremium});

  final String tier;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AuroraSpacing.space7),
      decoration: BoxDecoration(
        color: isPremium ? AuroraColors.ink : AuroraColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPremium ? AuroraColors.yellow : AuroraColors.inkBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPremium ? Icons.star_rounded : Icons.star_border_rounded,
            color: isPremium ? AuroraColors.yellow : AuroraColors.inkSecondary,
            size: 28,
          ),
          const SizedBox(width: AuroraSpacing.space7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keystona $tier',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isPremium ? Colors.white : AuroraColors.ink,
                  ),
                ),
                Text(
                  isPremium ? 'Full access to all features' : 'Limited features',
                  style: AuroraType.bodySm.copyWith(
                    color: isPremium
                        ? Colors.white.withValues(alpha: 0.7)
                        : AuroraColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AuroraSpacing.space7,
          horizontal: AuroraSpacing.space7,
        ),
        decoration: BoxDecoration(
          color: AuroraColors.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AuroraColors.inkBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
