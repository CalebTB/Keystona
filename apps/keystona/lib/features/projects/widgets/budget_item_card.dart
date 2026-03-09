import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/project_budget_item.dart';

/// Single budget line item row.
class BudgetItemCard extends StatelessWidget {
  const BudgetItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final ProjectBudgetItem item;
  final VoidCallback onTap;

  String _fmt(double v) => '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final hasActual = item.actualCost > 0;
    final isOver = hasActual && item.actualCost > item.estimatedCost;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.cardMinHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Paid indicator dot.
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isPaid ? AppColors.success : AppColors.gray300,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AppTextStyles.bodyMediumSemibold),
                  Text(
                    item.category.budgetCategoryLabel,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hasActual)
                  Text(
                    _fmt(item.actualCost),
                    style: AppTextStyles.bodyMediumSemibold.copyWith(
                      color: isOver ? AppColors.error : AppColors.textPrimary,
                    ),
                  )
                else
                  Text(
                    _fmt(item.estimatedCost),
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                Text(
                  hasActual ? 'est. ${_fmt(item.estimatedCost)}' : 'estimated',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(width: AppSizes.xs),
            const Icon(Icons.chevron_right, color: AppColors.gray400, size: 18),
          ],
        ),
      ),
    );
  }
}
