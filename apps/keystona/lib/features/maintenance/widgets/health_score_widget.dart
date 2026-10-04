import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_typography.dart';
import '../models/home_health_score.dart';
import '../providers/home_health_score_provider.dart';
import 'health_score_skeleton.dart';
import '../../../core/theme/aurora_radius.dart';

/// Displays the maintenance-pillar health score on the Tasks tab header.
///
/// Layout:
///   [Circular arc gauge] [Score label + trend] [Stats row: completed/overdue/upcoming]
///
/// Color bands:
///   score 71–100 → limeDeep (green)
///   score 40–70  → yellow (amber)
///   score 0–39   → coral (red)
class HealthScoreWidget extends ConsumerWidget {
  const HealthScoreWidget({super.key, this.compact = false});

  /// When true, renders only the inner Row (gauge + stats) without the
  /// surrounding card border and screen-horizontal padding — use when
  /// embedding inside an existing card container.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(homeHealthScoreProvider);

    return scoreAsync.when(
      loading: () => const HealthScoreSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (score) => _ScoreCard(score: score, compact: compact),
    );
  }
}

// ── Score card ────────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score, this.compact = false});
  final HomeHealthScore score;
  final bool compact;

  Widget _row() => Row(
        children: [
          _GaugePainter(score: score.score),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _TrendRow(trend: score.trend),
                const SizedBox(height: 4),
                Text(
                  'Home Maintenance Score',
                  style: AuroraType.label.copyWith(
                    color: AuroraColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                _StatsRow(score: score),
              ],
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: _row(),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AuroraColors.paper,
          borderRadius: AuroraRadius.md,
          border: Border.all(color: AuroraColors.inkBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: _row(),
      ),
    );
  }
}

// ── Circular gauge ────────────────────────────────────────────────────────────

class _GaugePainter extends StatelessWidget {
  const _GaugePainter({required this.score});
  final int score;

  Color get _color {
    if (score > 70) return AuroraColors.limeDeep;
    if (score >= 40) return AuroraColors.yellow;
    return AuroraColors.coral;
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
          trackColor: AuroraColors.butter,
        ),
        child: Center(
          child: Text(
            '$score',
            style: AuroraType.h3.copyWith(
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
            color: AuroraColors.limeDeep,
            label: 'Improving',
          ),
        'declining' => (
            icon: Icons.arrow_downward,
            color: AuroraColors.coral,
            label: 'Declining',
          ),
        _ => (
            icon: Icons.arrow_forward,
            color: AuroraColors.inkSecondary,
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
          style: AuroraType.labelSm.copyWith(color: meta.color),
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
        _Stat(value: score.completed, label: 'Done', color: AuroraColors.limeDeep),
        const SizedBox(width: 12),
        _Stat(
          value: score.overdue,
          label: 'Overdue',
          color: score.overdue > 0 ? AuroraColors.coral : AuroraColors.inkSecondary,
        ),
        const SizedBox(width: 12),
        _Stat(value: score.upcoming, label: 'Upcoming', color: AuroraColors.inkSecondary),
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
          style: AuroraType.bodySm.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AuroraType.labelSm.copyWith(
            color: AuroraColors.inkSecondary,
          ),
        ),
      ],
    );
  }
}
