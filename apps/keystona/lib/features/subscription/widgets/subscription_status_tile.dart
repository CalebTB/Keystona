import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
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
          horizontal: AuroraSpacing.screenPadH,
          vertical: AuroraSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: AuroraColors.paper,
          borderRadius: AuroraRadius.md,
          border: Border.all(color: AuroraColors.inkBorder),
        ),
        child: Row(
          children: [
            Icon(
              isPremium
                  ? CupertinoIcons.star_fill
                  : CupertinoIcons.star,
              color: isPremium
                  ? AuroraColors.yellow
                  : AuroraColors.inkSecondary,
              size: 20,
            ),
            const SizedBox(width: AuroraSpacing.screenPadH),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subscription',
                    style: AuroraType.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Keystona $tier',
                    style: AuroraType.bodySm.copyWith(
                      color: AuroraColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: AuroraColors.inkSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
