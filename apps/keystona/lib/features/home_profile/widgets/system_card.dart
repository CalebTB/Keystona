import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/system.dart';

/// A 72px card representing a single home system in the grouped list.
///
/// Shows:
///   - Category icon in a tinted square
///   - System name (primary) and system type (secondary)
///   - Status chip on the right
///
/// Taps navigate to [AppRoutes.homeSystemDetail].
class SystemCard extends StatelessWidget {
  const SystemCard({super.key, required this.system});

  final HomeSystem system;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final path = AppRoutes.homeSystemDetail.replaceFirst(
          ':systemId',
          system.id,
        );
        context.push(path);
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.cardMinHeight),
        padding: AppPadding.card,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Category icon.
            _CategoryIcon(category: system.category),
            const SizedBox(width: AppSizes.md),

            // Name + type.
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    system.name,
                    style: AppTextStyles.bodyMediumSemibold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    system.systemType,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm),

            // Status chip.
            _StatusChip(status: system.status),
            const SizedBox(width: AppSizes.xs),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.category});

  final SystemCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.deepNavy.withAlpha(20),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Icon(
        _iconFor(category),
        size: 22,
        color: AppColors.deepNavy,
      ),
    );
  }

  IconData _iconFor(SystemCategory cat) => switch (cat) {
        SystemCategory.hvac => Icons.thermostat_outlined,
        SystemCategory.plumbing => Icons.water_drop_outlined,
        SystemCategory.electrical => Icons.electrical_services_outlined,
        SystemCategory.roofing => Icons.roofing_outlined,
        SystemCategory.foundation => Icons.foundation_outlined,
        SystemCategory.siding => Icons.home_outlined,
        SystemCategory.windowsDoors => Icons.door_front_door_outlined,
        SystemCategory.insulation => Icons.waves_outlined,
        SystemCategory.garage => Icons.garage_outlined,
        SystemCategory.other => Icons.build_outlined,
      };
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ItemStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ItemStatus.active => ('Active', AppColors.success),
      ItemStatus.needsRepair => ('Repair', AppColors.warning),
      ItemStatus.replaced => ('Replaced', AppColors.textSecondary),
      ItemStatus.removed => ('Removed', AppColors.textDisabled),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }
}
