import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/project_phase.dart';

/// Card displaying a single project phase.
///
/// Left-edge strip and background tint reflect the phase status at a glance.
/// Status badge is tappable via [onStatusTap] for quick status changes.
class PhaseCard extends StatelessWidget {
  const PhaseCard({
    super.key,
    required this.phase,
    required this.onTap,
    this.onStatusTap,
    this.onMoveUp,
    this.onMoveDown,
  });

  final ProjectPhase phase;
  final VoidCallback onTap;
  final VoidCallback? onStatusTap;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  static Color _stripColor(String s) => switch (s) {
        'planning'    => AppColors.gray400,
        'in_progress' => AppColors.slate,
        'on_hold'     => AppColors.amber,
        'completed'   => AppColors.olive,
        'cancelled'   => AppColors.gray300,
        _             => AppColors.gray300,
      };

  static Color _bgColor(String s) => switch (s) {
        'planning'    => AppColors.surface,
        'in_progress' => AppColors.slateDim,
        'on_hold'     => AppColors.amberDim,
        'completed'   => AppColors.oliveDim,
        'cancelled'   => AppColors.gray100,
        _             => AppColors.surface,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: AppSizes.cardMinHeight),
      decoration: BoxDecoration(
        color: _bgColor(phase.status),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd - 1),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Status strip ─────────────────────────────────────────
                  Container(
                    width: 4,
                    color: _stripColor(phase.status),
                  ),

                  // ── Card content ─────────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Reorder arrows
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

                          // Name + description + dates
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
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

                          // Status badge (tappable)
                          GestureDetector(
                            onTap: onStatusTap,
                            child: _StatusBadge(status: phase.status),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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

  static Color _badgeBg(String s) => switch (s) {
        'planning'    => AppColors.gray100,
        'in_progress' => AppColors.slateDim,
        'on_hold'     => AppColors.amberDim,
        'completed'   => AppColors.oliveDim,
        'cancelled'   => AppColors.errorLight,
        _             => AppColors.gray100,
      };

  static Color _badgeText(String s) => switch (s) {
        'planning'    => AppColors.textSecondary,
        'in_progress' => AppColors.slate,
        'on_hold'     => AppColors.amber,
        'completed'   => AppColors.olive,
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
        color: _badgeBg(status),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        status.phaseStatusLabel,
        style: AppTextStyles.labelSmall.copyWith(
          color: _badgeText(status),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
