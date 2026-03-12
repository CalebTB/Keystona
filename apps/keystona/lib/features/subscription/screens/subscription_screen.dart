import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../../services/providers/service_providers.dart';
import '../providers/subscription_provider.dart';

/// Settings screen for managing the user's Keystona subscription.
///
/// Shows the current tier, offers an upgrade CTA for free users,
/// and provides restore-purchases and manage-subscription actions.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final tier = ref.watch(subscriptionTierProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Subscription'),
      ),
      child: SafeArea(
        child: ListView(
          padding: AppPadding.screen,
          children: [
            const SizedBox(height: AppSizes.md),
            _TierCard(tier: tier, isPremium: isPremium),
            const SizedBox(height: AppSizes.lg),
            if (!isPremium) ...[
              _ActionButton(
                label: 'Upgrade to Pro',
                color: AppColors.deepNavy,
                onTap: () => context.push(AppRoutes.settingsPaywall),
              ),
              const SizedBox(height: AppSizes.sm),
            ],
            _ActionButton(
              label: 'Restore Purchases',
              color: AppColors.textSecondary,
              onTap: () => _restore(context),
            ),
            const SizedBox(height: AppSizes.sm),
            _ActionButton(
              label: 'Manage Subscription',
              color: AppColors.textSecondary,
              onTap: () => RevenueCatUI.presentCustomerCenter(),
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isPremium ? AppColors.deepNavy : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isPremium ? AppColors.goldAccent : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPremium ? Icons.star_rounded : Icons.star_border_rounded,
            color:
                isPremium ? AppColors.goldAccent : AppColors.textSecondary,
            size: 28,
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keystona $tier',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color:
                        isPremium ? AppColors.textInverse : AppColors.textPrimary,
                  ),
                ),
                Text(
                  isPremium
                      ? 'Full access to all features'
                      : 'Limited features',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isPremium
                        ? AppColors.textInverse.withValues(alpha: 0.7)
                        : AppColors.textSecondary,
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
          vertical: AppSizes.md,
          horizontal: AppSizes.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(color: color),
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
