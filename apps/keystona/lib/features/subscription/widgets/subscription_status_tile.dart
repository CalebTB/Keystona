import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/providers/service_providers.dart';
import '../providers/subscription_provider.dart';

/// Compact subscription status row for use inside the Settings list.
///
/// Shows the current tier and navigates to [AppRoutes.settingsSubscription]
/// on tap. Automatically reflects purchase/cancel events via
/// [isPremiumProvider] and [subscriptionTierProvider].
class SubscriptionStatusTile extends ConsumerWidget {
  const SubscriptionStatusTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final tier = ref.watch(subscriptionTierProvider);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.settingsSubscription),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              isPremium
                  ? CupertinoIcons.star_fill
                  : CupertinoIcons.star,
              color: isPremium
                  ? AppColors.goldAccent
                  : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subscription',
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Keystona $tier',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
