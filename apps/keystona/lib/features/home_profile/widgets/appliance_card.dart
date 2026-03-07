import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/appliance.dart';

abstract final class ApplianceCategoryIcons {
  static const Map<ApplianceCategory, IconData> _map = {
    ApplianceCategory.kitchen: Icons.kitchen,
    ApplianceCategory.laundry: Icons.local_laundry_service,
    ApplianceCategory.climate: Icons.ac_unit,
    ApplianceCategory.cleaning: Icons.cleaning_services,
    ApplianceCategory.outdoor: Icons.yard,
    ApplianceCategory.bathroom: Icons.bathtub,
    ApplianceCategory.other: Icons.devices_other,
  };

  static IconData forCategory(ApplianceCategory category) =>
      _map[category] ?? Icons.devices_other;
}

class ApplianceCard extends StatelessWidget {
  const ApplianceCard({super.key, required this.appliance});
  final Appliance appliance;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.push('${AppRoutes.homeAppliances}/${appliance.id}'),
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.cardMinHeight),
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.deepNavy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(
                ApplianceCategoryIcons.forCategory(appliance.category),
                size: 22,
                color: AppColors.deepNavy,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appliance.name,
                    style: AppTextStyles.bodyMediumSemibold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      _subtitle,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            _StatusBadge(status: appliance.status),
            const SizedBox(width: AppSizes.xs),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  String get _subtitle {
    final parts = <String>[
      if (appliance.brand != null) appliance.brand!,
      if (appliance.modelNumber != null) appliance.modelNumber!,
    ];
    return parts.join(' · ');
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final ItemStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.labelSmall.copyWith(color: _textColor),
      ),
    );
  }

  Color get _bgColor => switch (status) {
        ItemStatus.active => AppColors.successLight,
        ItemStatus.needsRepair => AppColors.warningLight,
        ItemStatus.replaced => AppColors.surfaceVariant,
        ItemStatus.removed => AppColors.gray100,
      };

  Color get _textColor => switch (status) {
        ItemStatus.active => AppColors.success,
        ItemStatus.needsRepair => AppColors.warning,
        ItemStatus.replaced => AppColors.textSecondary,
        ItemStatus.removed => AppColors.textSecondary,
      };
}
