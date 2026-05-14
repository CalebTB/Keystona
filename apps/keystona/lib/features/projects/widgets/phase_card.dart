import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/project_phase.dart';

/// Card displaying a single project phase.
///
/// [leading] is typically a [ReorderableDragStartListener]-wrapped handle
/// icon supplied by the list screen so the card stays decoupled from
/// the reorderable list implementation.
class PhaseCard extends StatelessWidget {
  const PhaseCard({
    super.key,
    required this.phase,
    required this.onTap,
    this.onStatusTap,
    this.leading,
  });

  final ProjectPhase phase;
  final VoidCallback onTap;
  final VoidCallback? onStatusTap;

  /// Widget rendered on the left before the phase name.
  /// Pass a drag handle here from the parent list.
  final Widget? leading;

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
                          // Drag handle (or nothing)
                          if (leading != null) ...[
                            leading!,
                            const SizedBox(width: AppSizes.sm),
                          ],

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
                                  _DateInfo(phase: phase),
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

// ── Date info with overdue/due-soon detection ─────────────────────────────────

class _DateInfo extends StatelessWidget {
  const _DateInfo({required this.phase});
  final ProjectPhase phase;

  static String _fmt(DateTime d) =>
      '${d.month}/${d.day}/${d.year.toString().substring(2)}';

  @override
  Widget build(BuildContext context) {
    final start = phase.plannedStartDate;
    final end = phase.plannedEndDate;

    final dateText = (start != null && end != null)
        ? '${_fmt(start)} – ${_fmt(end)}'
        : start != null
            ? 'Starts ${_fmt(start)}'
            : end != null
                ? 'Ends ${_fmt(end)}'
                : '';
    if (dateText.isEmpty) return const SizedBox.shrink();

    final done = phase.status == 'completed' || phase.status == 'cancelled';
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);

    String? healthLabel;
    Color dateColor = AppColors.textSecondary;
    Color labelColor = AppColors.textSecondary;

    if (!done && end != null) {
      final endDay = DateTime(end.year, end.month, end.day);
      final diff = endDay.difference(todayMidnight).inDays;

      if (diff < 0) {
        final days = diff.abs();
        healthLabel = days == 1 ? '1 day overdue' : '$days days overdue';
        dateColor = AppColors.error;
        labelColor = AppColors.error;
      } else if (diff <= 7) {
        healthLabel = diff == 0
            ? 'Due today'
            : diff == 1
                ? 'Due tomorrow'
                : 'Due in $diff days';
        dateColor = AppColors.amber;
        labelColor = AppColors.amber;
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          dateText,
          style: AppTextStyles.caption.copyWith(color: dateColor),
        ),
        if (healthLabel != null) ...[
          const SizedBox(width: AppSizes.xs),
          Text(
            '· $healthLabel',
            style: AppTextStyles.caption.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
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
