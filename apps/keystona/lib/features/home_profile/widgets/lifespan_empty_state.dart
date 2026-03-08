import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';

/// Empty state for the Lifespan screen when the user has no systems.
///
/// Pattern A — Motivational (Combined).
/// Copy matches Empty States Catalog §3.3 exactly.
class LifespanEmptyState extends StatelessWidget {
  const LifespanEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppPadding.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 120px icon — Deep Navy.
            Icon(
              Icons.home_repair_service_outlined,
              size: 120,
              color: AppColors.deepNavy,
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              'Add your home\'s systems',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Systems are the major components of your home — HVAC, plumbing, '
              'electrical, roofing, and more. Adding them unlocks personalized '
              'maintenance tasks and lifespan tracking.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.xl),
            FilledButton(
              onPressed: () => context.push(AppRoutes.homeSystemsAdd),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.goldAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.xl,
                  vertical: AppSizes.md,
                ),
              ),
              child: const Text('+ Add First System'),
            ),
          ],
        ),
      ),
    );
  }
}
