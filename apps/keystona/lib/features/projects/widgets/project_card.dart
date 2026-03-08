import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/project.dart';

/// Card displaying a single project in the list.
///
/// Shows: name, project type, status badge, budget summary, date range.
/// Cover photo support wired for #5.6 (no photo = gradient placeholder).
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover photo / placeholder ──────────────────────────────
            _CoverPhoto(coverPhotoPath: project.coverPhotoPath),

            // ── Card content ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + status chip.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          project.name,
                          style: AppTextStyles.bodyLargeSemibold,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      _StatusChip(status: project.status),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xs),
                  // Project type.
                  Text(
                    project.projectType.projectTypeLabel,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  // Budget row (only when budget is set).
                  if (project.estimatedBudget != null) ...[
                    const SizedBox(height: AppSizes.xs),
                    _BudgetRow(project: project),
                  ],
                  // Date range (only when dates are set).
                  if (project.plannedStartDate != null ||
                      project.plannedEndDate != null) ...[
                    const SizedBox(height: AppSizes.xs),
                    _DateRow(project: project),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cover photo ──────────────────────────────────────────────────────────────

class _CoverPhoto extends StatelessWidget {
  const _CoverPhoto({required this.coverPhotoPath});

  final String? coverPhotoPath;

  @override
  Widget build(BuildContext context) {
    // [#5.6] When cover_photo_path is set, load from Supabase Storage.
    // For now, show a Deep Navy gradient placeholder.
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.deepNavy,
            AppColors.deepNavy.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.construction_outlined,
          color: Colors.white38,
          size: AppSizes.iconXl,
        ),
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  Color get _chipColor => switch (status) {
        'in_progress' => AppColors.success,
        'on_hold'     => AppColors.warning,
        'completed'   => AppColors.deepNavy,
        'cancelled'   => AppColors.error,
        _             => AppColors.gray400,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: _chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        status.statusLabel,
        style: AppTextStyles.labelSmall.copyWith(color: _chipColor),
      ),
    );
  }
}

// ── Budget row ────────────────────────────────────────────────────────────────

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final estimated = project.estimatedBudget!;
    final spent = project.actualSpent;
    final pct = estimated > 0 ? (spent / estimated).clamp(0.0, 1.0) : 0.0;
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${fmt.format(spent)} of ${fmt.format(estimated)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '${(pct * 100).toStringAsFixed(0)}%',
              style: AppTextStyles.labelSmall.copyWith(
                color: pct >= 1.0 ? AppColors.error : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 5,
            backgroundColor: AppColors.gray200,
            valueColor: AlwaysStoppedAnimation<Color>(
              pct >= 1.0 ? AppColors.error : AppColors.deepNavy,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Date row ──────────────────────────────────────────────────────────────────

class _DateRow extends StatelessWidget {
  const _DateRow({required this.project});

  final Project project;

  static final _fmt = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final start = project.plannedStartDate;
    final end = project.plannedEndDate;

    String text;
    if (start != null && end != null) {
      text = '${_fmt.format(start)} – ${_fmt.format(end)}';
    } else if (start != null) {
      text = 'Starts ${_fmt.format(start)}';
    } else {
      text = 'Ends ${_fmt.format(end!)}';
    }

    return Row(
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: AppSizes.iconSm,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
