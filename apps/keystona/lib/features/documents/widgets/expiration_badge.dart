import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';

/// Color-coded pill badge showing document expiration status.
///
/// Thresholds:
///   - Already expired or < 30 days → Red
///   - 30–90 days → Amber
///   - > 90 days or no expiration → Green
///
/// The [large] variant shows a full label (e.g. "Expires in 45 days") suitable
/// for the detail screen metadata section. The compact variant (default) shows
/// a short label (e.g. "45d" or "Expired") for list cards.
class ExpirationBadge extends StatelessWidget {
  const ExpirationBadge({
    super.key,
    required this.expirationDate,
    this.large = false,
  });

  final DateTime expirationDate;

  /// When true, renders a wider badge with a longer label for detail screens.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final daysRemaining = expirationDate.difference(DateTime.now()).inDays;

    final Color bgColor;
    final Color textColor;
    final String label;

    if (daysRemaining < 0) {
      bgColor = AppColors.errorLight;
      textColor = AppColors.error;
      label = large ? 'Expired' : 'Expired';
    } else if (daysRemaining < 30) {
      bgColor = AppColors.errorLight;
      textColor = AppColors.error;
      label = large ? 'Expires in ${daysRemaining}d' : '${daysRemaining}d';
    } else if (daysRemaining <= 90) {
      bgColor = AppColors.warningLight;
      textColor = AppColors.warning;
      label = large ? 'Expires in ${daysRemaining}d' : '${daysRemaining}d';
    } else {
      bgColor = AppColors.successLight;
      textColor = AppColors.success;
      label = large ? 'Expires in ${daysRemaining}d' : '${daysRemaining}d';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? AppSizes.md : AppSizes.sm,
        vertical: large ? AppSizes.xs : 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        label,
        style: (large ? AppTextStyles.labelMedium : AppTextStyles.labelSmall)
            .copyWith(color: textColor),
      ),
    );
  }
}
