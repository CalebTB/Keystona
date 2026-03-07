import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';

class AppliancesEmptyState extends StatelessWidget {
  const AppliancesEmptyState({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppPadding.screen,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.kitchen_outlined,
              size: 120,
              color: AppColors.deepNavy.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              'Add your appliances',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Track your refrigerator, washer, dishwasher, and other appliances to stay on top of warranties and maintenance.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.xl),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.deepNavy,
                foregroundColor: AppColors.textInverse,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: AppSizes.md,
                ),
              ),
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add First Appliance'),
            ),
          ],
        ),
      ),
    );
  }
}
