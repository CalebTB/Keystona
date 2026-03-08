import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';

/// Empty state for the Projects tab — Pattern B: Showcase.
///
/// Shows two ghosted example project cards (50% opacity, non-interactive)
/// and a CTA button. Copy matches Empty States Catalog §2.4 exactly.
class ProjectEmptyState extends StatelessWidget {
  const ProjectEmptyState({super.key, required this.onCreateProject});

  final VoidCallback onCreateProject;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppPadding.screen,
      child: Column(
        children: [
          const SizedBox(height: AppSizes.xl),
          Text(
            'Organize renovations with phases, budgets, and before/after photos',
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Track every project from planning to completion.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.xl),

          // ── Ghosted example cards ──────────────────────────────────────
          Opacity(
            opacity: 0.5,
            child: Column(
              children: [
                _ExampleProjectCard(
                  emoji: '🛁',
                  name: 'Bathroom Renovation',
                  phases: 'Planning → Demo → Build',
                  progressFraction: 0.62,
                  progressLabel: '62%',
                  budget: '\$12,500',
                  status: 'In Progress',
                ),
                const SizedBox(height: AppSizes.sm),
                _ExampleProjectCard(
                  emoji: '🪵',
                  name: 'Deck Build',
                  phases: 'Design → Permit → Build',
                  progressFraction: 0.28,
                  progressLabel: '28%',
                  budget: '\$8,200',
                  status: 'Planning',
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.xl),
          FilledButton(
            onPressed: onCreateProject,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.goldAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.xl,
                vertical: AppSizes.md,
              ),
            ),
            child: const Text('+ Start a Project'),
          ),
          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }
}

class _ExampleProjectCard extends StatelessWidget {
  const _ExampleProjectCard({
    required this.emoji,
    required this.name,
    required this.phases,
    required this.progressFraction,
    required this.progressLabel,
    required this.budget,
    required this.status,
  });

  final String emoji;
  final String name;
  final String phases;
  final double progressFraction;
  final String progressLabel;
  final String budget;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(name, style: AppTextStyles.bodyLargeSemibold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.deepNavy.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  status,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.deepNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            phases,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusFull),
                  child: LinearProgressIndicator(
                    value: progressFraction,
                    minHeight: 6,
                    backgroundColor: AppColors.gray200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.deepNavy),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Text(
                progressLabel,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Budget: $budget',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
