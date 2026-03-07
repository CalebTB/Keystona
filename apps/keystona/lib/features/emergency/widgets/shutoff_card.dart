import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/utility_shutoff.dart';

/// Card showing a single utility shutoff's setup status.
///
/// Tapping navigates to the shutoff detail screen ([AppRoutes.emergencyShutoffDetail]).
/// The [onTap] callback is provided by the parent screen.
class ShutoffCard extends StatelessWidget {
  const ShutoffCard({
    super.key,
    required this.utilityType,
    required this.shutoff,
    required this.onTap,
  });

  /// 'water', 'gas', or 'electrical'
  final String utilityType;

  /// The shutoff record, or null if not yet set up.
  final UtilityShutoff? shutoff;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isComplete = shutoff?.isComplete ?? false;
    final isSetUp = shutoff != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isComplete ? AppColors.healthGood : AppColors.border,
          ),
        ),
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            // Utility icon.
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconBg(isComplete),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(
                _icon,
                size: 22,
                color: _iconColor(isComplete),
              ),
            ),
            const SizedBox(width: AppSizes.md),

            // Label + description.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    utilityType.utilityLabel,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isSetUp) ...[
                    const SizedBox(height: 2),
                    Text(
                      shutoff!.locationDescription,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else ...[
                    const SizedBox(height: 2),
                    Text(
                      'Tap to set up',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm),

            // Status badge.
            _StatusBadge(isComplete: isComplete, isSetUp: isSetUp),
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

  IconData get _icon => switch (utilityType) {
        'water' => Icons.water_drop_outlined,
        'gas' => Icons.local_fire_department_outlined,
        'electrical' => Icons.electric_bolt_outlined,
        _ => Icons.settings_outlined,
      };

  Color _iconBg(bool complete) => complete
      ? AppColors.healthGood.withValues(alpha: 0.12)
      : AppColors.deepNavy.withValues(alpha: 0.08);

  Color _iconColor(bool complete) =>
      complete ? AppColors.healthGood : AppColors.deepNavy;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isComplete, required this.isSetUp});
  final bool isComplete;
  final bool isSetUp;

  @override
  Widget build(BuildContext context) {
    if (!isSetUp) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
        child: Text(
          'Not set up',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isComplete
            ? AppColors.healthGood.withValues(alpha: 0.12)
            : AppColors.healthFair.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        isComplete ? 'Complete' : 'Incomplete',
        style: AppTextStyles.labelSmall.copyWith(
          color: isComplete ? AppColors.healthGood : AppColors.healthFair,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
