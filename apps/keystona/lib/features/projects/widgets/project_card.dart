import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/project.dart';

/// Card for a single project — board/list shared component.
///
/// Active projects: dark gradient hero + body.
/// Completed projects: simplified warm-fill hero, dashed olive border, faded.
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  final Project project;
  final VoidCallback onTap;

  static const Map<String, String> _emoji = {
    'kitchen_remodel':    '🍳',
    'bathroom_remodel':   '🛁',
    'deck_build':         '🪵',
    'addition':           '🏗️',
    'roofing':            '🏠',
    'flooring':           '🪟',
    'painting':           '🎨',
    'landscaping':        '🌿',
    'hvac_replacement':   '❄️',
    'plumbing':           '🔧',
    'electrical':         '⚡',
    'general_renovation': '🔨',
    'other':              '🏡',
  };

  static Color _statusColor(String status) => switch (status) {
        'in_progress' => AppColors.slate,
        'planning'    => AppColors.sand,
        'on_hold'     => AppColors.amber,
        'completed'   => AppColors.olive,
        'cancelled'   => AppColors.gray300,
        _             => AppColors.border,
      };

  @override
  Widget build(BuildContext context) {
    final isCompleted = project.status == 'completed';
    final emoji = _emoji[project.projectType] ?? '🏠';

    final isCancelled = project.status == 'cancelled';

    if (isCompleted || isCancelled) {
      final borderColor = isCompleted ? AppColors.olive : AppColors.gray300;
      return Opacity(
        opacity: isCompleted ? 0.72 : 0.55,
        child: GestureDetector(
          onTap: onTap,
          child: CustomPaint(
            foregroundPainter: _DashedBorderPainter(
              color: borderColor,
              radius: 12,
              strokeWidth: 1.5,
              dashLength: 5,
              gapLength: 4,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _CondensedRow(
                project: project,
                icon: isCompleted ? Icons.check : Icons.close,
                iconColor: isCompleted ? AppColors.olive : AppColors.gray500,
              ),
            ),
          ),
        ),
      );
    }

    final borderColor = _statusColor(project.status);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 3),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroSection(
                project: project,
                emoji: emoji,
              ),
              _CardBody(project: project),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dashed border painter ─────────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashLength),
          paint,
        );
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength;
}

// ── Hero ─────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.project, required this.emoji});

  final Project project;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deepNavy, Color(0xFF3D3028)],
        ),
      ),
      child: Stack(
        children: [
          // Emoji — top-right, 60% opacity
          Positioned(
            top: 10,
            right: 12,
            child: Opacity(
              opacity: 0.6,
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          // Project name — bottom-left, Fraunces bold
          Positioned(
            bottom: 12,
            left: 14,
            right: 54,
            child: Text(
              project.name,
              style: AppTextStyles.headlineMedium.copyWith(
                fontSize: 17,
                color: AppColors.textInverse,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Condensed row (completed + cancelled) ─────────────────────────────────────

class _CondensedRow extends StatelessWidget {
  const _CondensedRow({
    required this.project,
    required this.icon,
    required this.iconColor,
  });

  final Project project;
  final IconData icon;
  final Color iconColor;

  static String _compact(double v) {
    if (v >= 1000) {
      final k = v / 1000;
      return '\$${k % 1 == 0 ? k.toInt().toString() : k.toStringAsFixed(1)}k';
    }
    return '\$${NumberFormat('#,###').format(v.toInt())}';
  }

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (project.estimatedBudget != null) {
      parts.add(_compact(project.estimatedBudget!));
    }
    if (project.plannedEndDate != null) {
      parts.add(DateFormat("MMM ''yy").format(project.plannedEndDate!));
    }
    parts.add(project.workType.workTypeLabel);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  project.name,
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (parts.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    parts.join(' · '),
                    style: AppTextStyles.monoLabel.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card body ─────────────────────────────────────────────────────────────────

class _CardBody extends StatelessWidget {
  const _CardBody({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final hasPhases = project.phaseCount > 0;
    final hasBudget = project.estimatedBudget != null;
    final dotCount = math.min(project.phaseCount, 7);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPhases) ...[
            _PhaseDots(
              count: dotCount,
              currentPhaseIndex: project.currentPhaseIndex != null
                  ? math.min(project.currentPhaseIndex!, dotCount - 1)
                  : null,
              currentPhaseName: project.currentPhaseName,
            ),
            const SizedBox(height: 8),
          ],
          if (hasBudget) ...[
            _BudgetRow(project: project),
            const SizedBox(height: 10),
          ],
          _FooterRow(project: project),
        ],
      ),
    );
  }
}

// ── Phase dots ────────────────────────────────────────────────────────────────

enum _DotState { completed, active, upcoming }

class _PhaseDots extends StatelessWidget {
  const _PhaseDots({
    required this.count,
    this.currentPhaseIndex,
    this.currentPhaseName,
  });

  final int count;
  final int? currentPhaseIndex;
  final String? currentPhaseName;

  @override
  Widget build(BuildContext context) {
    final hasProgress = currentPhaseIndex != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (int i = 0; i < count; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    color: hasProgress && i <= currentPhaseIndex!
                        ? AppColors.oliveLight.withValues(alpha: 0.65)
                        : AppColors.gray200,
                  ),
                ),
              _PhaseDot(
                state: !hasProgress
                    ? _DotState.upcoming
                    : i < currentPhaseIndex!
                        ? _DotState.completed
                        : i == currentPhaseIndex!
                            ? _DotState.active
                            : _DotState.upcoming,
              ),
            ],
          ],
        ),
        if (hasProgress && currentPhaseName != null) ...[
          const SizedBox(height: 5),
          Text(
            'Phase ${currentPhaseIndex! + 1} of $count · $currentPhaseName',
            style: AppTextStyles.monoLabel.copyWith(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _PhaseDot extends StatelessWidget {
  const _PhaseDot({required this.state});

  final _DotState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      _DotState.completed => Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.oliveLight,
          ),
        ),
      _DotState.active => Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.45),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      _DotState.upcoming => Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gray300, width: 1.5),
          ),
        ),
    };
  }
}

// ── Budget row ────────────────────────────────────────────────────────────────

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.project});

  final Project project;

  static String _compact(double v) {
    if (v >= 1000) {
      final k = v / 1000;
      return '\$${k % 1 == 0 ? k.toInt().toString() : k.toStringAsFixed(1)}k';
    }
    return '\$${NumberFormat('#,###').format(v.toInt())}';
  }

  @override
  Widget build(BuildContext context) {
    final estimated = project.estimatedBudget!;
    final spent = project.actualSpent;
    final pct = estimated > 0 ? (spent / estimated).clamp(0.0, 1.0) : 0.0;
    final isOver = pct >= 1.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '\$${NumberFormat('#,###').format(spent.toInt())} / ${_compact(estimated)}',
          style: AppTextStyles.monoLabel.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: AppColors.gray200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOver ? AppColors.error : AppColors.olive,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Footer row ────────────────────────────────────────────────────────────────

class _FooterRow extends StatelessWidget {
  const _FooterRow({required this.project});

  final Project project;

  static String _dateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '';
    final mFmt = DateFormat('MMM');
    final yFmt = DateFormat("''yy");
    if (start != null && end != null) {
      if (start.year == end.year) {
        return '${mFmt.format(start)} – ${mFmt.format(end)} ${yFmt.format(end)}';
      }
      return '${mFmt.format(start)} ${yFmt.format(start)} – ${mFmt.format(end)} ${yFmt.format(end)}';
    }
    if (start != null) return 'From ${mFmt.format(start)} ${yFmt.format(start)}';
    return 'Until ${mFmt.format(end!)} ${yFmt.format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _dateRange(project.plannedStartDate, project.plannedEndDate);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _WorkTypePill(workType: project.workType),
        if (dateStr.isNotEmpty) ...[
          const Spacer(),
          Text(
            dateStr,
            style: AppTextStyles.monoLabel.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Work-type pill ────────────────────────────────────────────────────────────

class _WorkTypePill extends StatelessWidget {
  const _WorkTypePill({required this.workType});

  final String workType;

  Color get _color => switch (workType) {
        'diy'        => AppColors.olive,
        'contractor' => AppColors.slate,
        'mixed'      => AppColors.sand,
        _            => AppColors.gray400,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        workType.workTypeLabel.toUpperCase(),
        style: AppTextStyles.monoTiny.copyWith(
          color: color,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
