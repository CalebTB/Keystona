import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/project.dart';

/// Card for a single project — board/list shared component.
///
/// Hero: dark gradient with project emoji + name.
/// Body: phase scope dots, budget bar, work-type pill + date range.
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
        _             => AppColors.border,
      };

  @override
  Widget build(BuildContext context) {
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
                emoji: _emoji[project.projectType] ?? '🏠',
              ),
              _CardBody(project: project),
            ],
          ),
        ),
      ),
    );
  }
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

// ── Card body ─────────────────────────────────────────────────────────────────

class _CardBody extends StatelessWidget {
  const _CardBody({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final hasPhases = project.phaseCount > 0;
    final hasBudget = project.estimatedBudget != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPhases) ...[
            _PhaseDots(count: math.min(project.phaseCount, 7)),
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

class _PhaseDots extends StatelessWidget {
  const _PhaseDots({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < count; i++) ...[
          if (i > 0)
            Expanded(child: Container(height: 2, color: AppColors.gray200)),
          const _PhaseDot(),
        ],
      ],
    );
  }
}

class _PhaseDot extends StatelessWidget {
  const _PhaseDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gray300, width: 1.5),
      ),
    );
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
