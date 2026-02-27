import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text_styles.dart';

/// Small colored pill label used to communicate status at a glance.
///
/// Commonly used for task status, document type, or project phase labels.
/// Background color carries the semantic meaning; choose from [AppColors]
/// status constants.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.textColor,
  });

  /// Text displayed inside the badge.
  final String label;

  /// Background color of the pill. Use semantic colors from [AppColors].
  final Color color;

  /// Text color. Defaults to white when null.
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: textColor ?? AppColors.textInverse,
        ),
      ),
    );
  }
}
