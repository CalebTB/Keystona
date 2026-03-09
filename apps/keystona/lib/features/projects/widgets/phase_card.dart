import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/project_phase.dart';

/// Card displaying a single project phase with status badge and
/// up/down reorder controls.
///
/// [onMoveUp] and [onMoveDown] are null when reordering is unavailable
/// (first or last item respectively).
class PhaseCard extends StatelessWidget {
  const PhaseCard({
    super.key,
    required this.phase,
    required this.onTap,
    this.onMoveUp,
    this.onMoveDown,
  });

  final ProjectPhase phase;
  final VoidCallback onTap;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.cardMinHeight),
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Reorder arrows column ────────────────────────────────────
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ReorderButton(
                  icon: Icons.keyboard_arrow_up,
                  onPressed: onMoveUp,
                ),
                _ReorderButton(
                  icon: Icons.keyboard_arrow_down,
                  onPressed: onMoveDown,
                ),
              ],
            ),
            const SizedBox(width: AppSizes.sm),

            // ── Name + description ───────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phase.name,
                    style: AppTextStyles.bodyMediumSemibold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (phase.description != null &&
                      phase.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      phase.description!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (phase.plannedStartDate != null ||
                      phase.plannedEndDate != null) ...[
                    const SizedBox(height: AppSizes.xs),
                    _DateRange(phase: phase),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm),

            // ── Status badge ─────────────────────────────────────────────
            _StatusBadge(status: phase.status),
          ],
        ),
      ),
    );
  }
}

// ── Reorder button ────────────────────────────────────────────────────────────

class _ReorderButton extends StatelessWidget {
  const _ReorderButton({required this.icon, this.onPressed});
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Icon(
        icon,
        size: 18,
        color: onPressed != null ? AppColors.gray600 : AppColors.gray200,
      ),
    );
  }
}

// ── Date range display ────────────────────────────────────────────────────────

class _DateRange extends StatelessWidget {
  const _DateRange({required this.phase});
  final ProjectPhase phase;

  static String _fmt(DateTime d) =>
      '${d.month}/${d.day}/${d.year.toString().substring(2)}';

  @override
  Widget build(BuildContext context) {
    final start = phase.plannedStartDate;
    final end = phase.plannedEndDate;
    final text = (start != null && end != null)
        ? '${_fmt(start)} – ${_fmt(end)}'
        : start != null
            ? 'Starts ${_fmt(start)}'
            : end != null
                ? 'Ends ${_fmt(end)}'
                : '';
    if (text.isEmpty) return const SizedBox.shrink();
    return Text(
      text,
      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  static Color _bgColor(String s) => switch (s) {
        'planning'    => AppColors.gray100,
        'in_progress' => AppColors.deepNavy.withValues(alpha: 0.12),
        'on_hold'     => const Color(0xFFFFF3E0),
        'completed'   => AppColors.successLight,
        'cancelled'   => const Color(0xFFFFEBEE),
        _             => AppColors.gray100,
      };

  static Color _textColor(String s) => switch (s) {
        'planning'    => AppColors.textSecondary,
        'in_progress' => AppColors.deepNavy,
        'on_hold'     => const Color(0xFFE65100),
        'completed'   => AppColors.success,
        'cancelled'   => AppColors.error,
        _             => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: _bgColor(status),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        status.phaseStatusLabel,
        style: AppTextStyles.labelSmall.copyWith(
          color: _textColor(status),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
