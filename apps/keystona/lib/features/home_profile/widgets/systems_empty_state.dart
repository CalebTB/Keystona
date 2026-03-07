import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';

/// Empty state for the Systems list screen.
///
/// Pattern A — Motivational (Combined).
///
/// **Copy from Empty States Catalog §3.3:**
/// - Icon: simplified house with gear (120px, Deep Navy)
/// - Headline: "Add your home's systems"
/// - Subtitle: "Systems are the major components of your home — HVAC,
///   plumbing, electrical, roofing, and more. Adding them unlocks
///   personalized maintenance tasks and lifespan tracking."
/// - CTA: "+ Add First System" → opens system creation form
class SystemsEmptyState extends StatelessWidget {
  const SystemsEmptyState({super.key, required this.onAddSystem});

  /// Called when the user taps "+ Add First System".
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
              Icons.home_repair_service_outlined,
              size: 120,
              color: AppColors.deepNavy.withAlpha(180),
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              "Add your home's systems",
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Systems are the major components of your home — HVAC, '
              'plumbing, electrical, roofing, and more. Adding them unlocks '
              'personalized maintenance tasks and lifespan tracking.',
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
              label: const Text('Add First System'),
            ),
          ],
        ),
      ),
    );
  }
}
