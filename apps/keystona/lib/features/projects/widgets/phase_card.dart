import 'package:flutter/material.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/theme/aurora_spacing.dart';

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
        'planning'    => AuroraColors.inkTertiary,
        'in_progress' => AuroraColors.cobalt,
        'on_hold'     => AuroraColors.yellow,
        'completed'   => AuroraColors.lime,
        'cancelled'   => const Color(0xFFE0DFEA),
        _             => const Color(0xFFE0DFEA),
      };

  static Color _bgColor(String s) => switch (s) {
        'planning'    => AuroraColors.paper,
        'in_progress' => AuroraColors.cobaltDim,
        'on_hold'     => AuroraColors.yellowDim,
        'completed'   => AuroraColors.limeDim,
        'cancelled'   => AuroraColors.butter,
        _             => AuroraColors.paper,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72.0),
      decoration: BoxDecoration(
        color: _bgColor(phase.status),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AuroraColors.inkBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0 - 1),
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
                      padding: const EdgeInsets.all(AuroraSpacing.space7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Drag handle (or nothing)
                          if (leading != null) ...[
                            leading!,
                            const SizedBox(width: AuroraSpacing.space3),
                          ],

                          // Name + description + dates
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  phase.name,
                                  style: AuroraType.h3,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (phase.description != null &&
                                    phase.description!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    phase.description!,
                                    style: AuroraType.bodySm.copyWith(
                                      color: AuroraColors.inkSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (phase.plannedStartDate != null ||
                                    phase.plannedEndDate != null) ...[
                                  const SizedBox(height: AuroraSpacing.space1),
                                  _DateInfo(phase: phase),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: AuroraSpacing.space3),

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
    Color dateColor = AuroraColors.inkSecondary;
    Color labelColor = AuroraColors.inkSecondary;

    if (!done && end != null) {
      final endDay = DateTime(end.year, end.month, end.day);
      final diff = endDay.difference(todayMidnight).inDays;

      if (diff < 0) {
        final days = diff.abs();
        healthLabel = days == 1 ? '1 day overdue' : '$days days overdue';
        dateColor = AuroraColors.coral;
        labelColor = AuroraColors.coral;
      } else if (diff <= 7) {
        healthLabel = diff == 0
            ? 'Due today'
            : diff == 1
                ? 'Due tomorrow'
                : 'Due in $diff days';
        dateColor = AuroraColors.yellow;
        labelColor = AuroraColors.yellow;
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          dateText,
          style: AuroraType.bodySm.copyWith(color: dateColor),
        ),
        if (healthLabel != null) ...[
          const SizedBox(width: AuroraSpacing.space1),
          Text(
            '· $healthLabel',
            style: AuroraType.bodySm.copyWith(
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
        'planning'    => AuroraColors.butter,
        'in_progress' => AuroraColors.cobaltDim,
        'on_hold'     => AuroraColors.yellowDim,
        'completed'   => AuroraColors.limeDim,
        'cancelled'   => AuroraColors.coralDim,
        _             => AuroraColors.butter,
      };

  static Color _badgeText(String s) => switch (s) {
        'planning'    => AuroraColors.inkSecondary,
        'in_progress' => AuroraColors.cobalt,
        'on_hold'     => AuroraColors.yellow,
        'completed'   => AuroraColors.lime,
        'cancelled'   => AuroraColors.coral,
        _             => AuroraColors.inkSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.space3,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: _badgeBg(status),
        borderRadius: BorderRadius.circular(999.0),
      ),
      child: Text(
        status.phaseStatusLabel,
        style: AuroraType.label.copyWith(
          color: _badgeText(status),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
