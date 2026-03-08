import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/system_lifespan_entry.dart';

/// Card displaying lifespan data for a single system.
///
/// Layout:
///   - Name + health status chip (row)
///   - Color-coded progress bar (full width)
///   - Age label (left) + years-remaining label (right)
///   - Estimated replacement cost (if available)
class LifespanCard extends StatelessWidget {
  const LifespanCard({super.key, required this.entry});

  final SystemLifespanEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Name + health chip ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.name,
                  style: AppTextStyles.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              _HealthChip(entry: entry),
            ],
          ),
          const SizedBox(height: AppSizes.sm),

          // ── Progress bar ────────────────────────────────────────────────
          _LifespanBar(entry: entry),
          const SizedBox(height: AppSizes.xs),

          // ── Age / years remaining ───────────────────────────────────────
          Row(
            children: [
              Text(
                _ageLabel(entry),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (!entry.isUnknown)
                Text(
                  _yearsRemainingLabel(entry),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: entry.isEndOfLife
                        ? AppColors.error
                        : AppColors.textSecondary,
                  ),
                ),
            ],
          ),

          // ── Replacement cost ────────────────────────────────────────────
          if (entry.estimatedReplacementCost != null) ...[
            const SizedBox(height: AppSizes.xs),
            Text(
              'Est. replacement: \$${_formatCost(entry.estimatedReplacementCost!)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _ageLabel(SystemLifespanEntry e) {
    if (e.ageYears == null) return 'Unknown age';
    final years = e.ageYears!.toStringAsFixed(1);
    return '$years yrs old';
  }

  String _yearsRemainingLabel(SystemLifespanEntry e) {
    if (e.isEndOfLife) return 'Past expected lifespan';
    final min = e.yearsUntilReplacementMin;
    final max = e.yearsUntilReplacementMax;
    if (min == null || max == null) return '';
    if (min.round() == max.round()) {
      return '~${min.round()} yrs remaining';
    }
    return '${min.round()}–${max.round()} yrs remaining';
  }

  String _formatCost(double cost) {
    if (cost >= 1000) {
      return '${(cost / 1000).toStringAsFixed(1)}k';
    }
    return cost.toStringAsFixed(0);
  }
}

// ── Progress bar ─────────────────────────────────────────────────────────────

class _LifespanBar extends StatelessWidget {
  const _LifespanBar({required this.entry});

  final SystemLifespanEntry entry;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: LinearProgressIndicator(
        value: entry.isUnknown ? 0.0 : entry.barFraction,
        minHeight: 8,
        backgroundColor: AppColors.gray200,
        valueColor: AlwaysStoppedAnimation<Color>(
          entry.isUnknown ? AppColors.gray300 : entry.healthColor,
        ),
      ),
    );
  }
}

// ── Health chip ───────────────────────────────────────────────────────────────

class _HealthChip extends StatelessWidget {
  const _HealthChip({required this.entry});

  final SystemLifespanEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: entry.healthColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        entry.healthLabel,
        style: AppTextStyles.labelSmall.copyWith(color: entry.healthColor),
      ),
    );
  }
}
