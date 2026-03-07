import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/home_health_score.dart';
import '../providers/home_health_score_provider.dart';
import 'health_score_skeleton.dart';

/// Displays the maintenance-pillar health score on the Tasks tab header.
///
/// Layout:
///   [Circular arc gauge] [Score label + trend] [Stats row: completed/overdue/upcoming]
///
/// Color bands:
///   score 71–100 → [AppColors.healthGood]   (green)
///   score 40–70  → [AppColors.healthFair]   (amber)
///   score 0–39   → [AppColors.healthPoor]   (red)
class HealthScoreWidget extends ConsumerWidget {
  const HealthScoreWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(homeHealthScoreProvider);

    return scoreAsync.when(
      loading: () => const HealthScoreSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (score) => _ScoreCard(score: score),
    );
  }
}

// ── Score card ────────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score});
  final HomeHealthScore score;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.screenHorizontal.copyWith(
        top: AppSizes.sm,
        bottom: AppSizes.sm,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),
        child: Row(
          children: [
            // Circular gauge.
            _GaugePainter(score: score.score),
            const SizedBox(width: AppSizes.md),
            // Right side: trend + stats.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TrendRow(trend: score.trend),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    'Home Maintenance Score',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  _StatsRow(score: score),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Circular gauge ────────────────────────────────────────────────────────────

class _GaugePainter extends StatelessWidget {
  const _GaugePainter({required this.score});
  final int score;

  Color get _color {
    if (score > 70) return AppColors.healthGood;
    if (score >= 40) return AppColors.healthFair;
    return AppColors.healthPoor;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(
        painter: _ArcPainter(
          score: score,
          activeColor: _color,
          trackColor: AppColors.gray200,
        ),
        child: Center(
          child: Text(
            '$score',
            style: AppTextStyles.h3.copyWith(
              color: _color,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({
    required this.score,
    required this.activeColor,
    required this.trackColor,
  });

  final int score;
  final Color activeColor;
  final Color trackColor;

  // Gauge sweeps 270° starting from 135° (bottom-left), going clockwise.
  static const double _startAngle = 135 * math.pi / 180;
  static const double _sweepTotal = 270 * math.pi / 180;
  static const double _strokeWidth = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (_strokeWidth / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;

    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = activeColor;

    // Background arc.
    canvas.drawArc(rect, _startAngle, _sweepTotal, false, trackPaint);

    // Foreground arc — proportional to score.
    final activeSweep = _sweepTotal * (score.clamp(0, 100) / 100);
    if (activeSweep > 0) {
      canvas.drawArc(rect, _startAngle, activeSweep, false, activePaint);
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.score != score;
}

// ── Trend row ─────────────────────────────────────────────────────────────────

class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.trend});
  final String trend;

  ({IconData icon, Color color, String label}) get _meta => switch (trend) {
        'improving' => (
            icon: Icons.arrow_upward,
            color: AppColors.healthGood,
            label: 'Improving',
          ),
        'declining' => (
            icon: Icons.arrow_downward,
            color: AppColors.healthPoor,
            label: 'Declining',
          ),
        _ => (
            icon: Icons.arrow_forward,
            color: AppColors.textSecondary,
            label: 'Stable',
          ),
      };

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(meta.icon, size: 14, color: meta.color),
        const SizedBox(width: 3),
        Text(
          meta.label,
          style: AppTextStyles.labelSmall.copyWith(color: meta.color),
        ),
      ],
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.score});
  final HomeHealthScore score;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Stat(value: score.completed, label: 'Done', color: AppColors.healthGood),
        const SizedBox(width: AppSizes.md),
        _Stat(
          value: score.overdue,
          label: 'Overdue',
          color: score.overdue > 0 ? AppColors.healthPoor : AppColors.textSecondary,
        ),
        const SizedBox(width: AppSizes.md),
        _Stat(value: score.upcoming, label: 'Upcoming', color: AppColors.textSecondary),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: AppTextStyles.labelLarge.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
