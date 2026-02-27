import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text_styles.dart';

/// Premium upsell bottom sheet placeholder.
///
/// Shown when a user attempts to access a feature gated behind the
/// Keystona Premium subscription. This is a placeholder — pricing details
/// and the full feature list will be added in Phase 8 design polish.
class UpgradeSheet extends StatelessWidget {
  const UpgradeSheet({
    super.key,
    required this.feature,
  });

  /// Short description of the gated feature, e.g. "unlimited document storage".
  final String feature;

  /// Presents the upgrade sheet as a modal bottom sheet.
  static void show(BuildContext context, {required String feature}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      builder: (_) => UpgradeSheet(feature: feature),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.lg,
        AppSizes.md,
        AppSizes.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Upgrade to Premium',
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Unlock $feature and more with Keystona Premium.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.lg),
          FilledButton(
            onPressed: () {
              // RevenueCat paywall wired in Phase 8
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.goldAccent,
              minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
            ),
            child: Text(
              'Upgrade',
              style: AppTextStyles.button.copyWith(
                color: AppColors.textInverse,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Not Now',
              style: AppTextStyles.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
