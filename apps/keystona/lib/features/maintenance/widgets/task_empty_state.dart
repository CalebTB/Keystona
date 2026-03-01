import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';

/// Empty state for the Maintenance Calendar — Pattern A (Motivational).
///
/// Shown when the user has no tasks at all (no systems added yet).
///
/// **Copy from Empty States Catalog §2.3:**
/// - Headline: "Stay ahead of home repairs"
/// - Subtitle: "We'll build a personalized maintenance plan based on your
///   home's systems and climate. Add your first system to get started."
/// - CTA: "+ Add a System" → navigates to Home Profile → Add System flow
class TaskEmptyState extends StatelessWidget {
  const TaskEmptyState({super.key, required this.onAddSystem});

  final VoidCallback onAddSystem;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppPadding.screen,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.handyman_outlined,
              size: 120,
              color: AppColors.deepNavy.withAlpha(180),
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              'Stay ahead of home repairs',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              "We'll build a personalized maintenance plan based on your "
              "home's systems and climate. Add your first system to get started.",
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
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
              onPressed: onAddSystem,
              icon: const Icon(Icons.add),
              label: const Text('Add a System'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Celebration empty state — shown when the user is all caught up.
///
/// **Copy from Empty States Catalog §2.3 (special state):**
/// - Headline: "All caught up! Nothing due right now"
/// - Subtitle: "Great work keeping your home in shape. We'll let you know
///   when something's coming up."
/// - CTA: None
class TaskCaughtUpState extends StatelessWidget {
  const TaskCaughtUpState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppPadding.screen,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 120,
              color: AppColors.success,
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              'All caught up! Nothing due right now',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              "Great work keeping your home in shape. We'll let you know "
              'when something\'s coming up.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the active filter returns no matching tasks.
class TaskFilterEmptyState extends StatelessWidget {
  const TaskFilterEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppPadding.screen,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 64,
              color: AppColors.gray400,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'No tasks match this filter',
              style: AppTextStyles.bodyMediumSemibold,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              'Try selecting a different filter.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
