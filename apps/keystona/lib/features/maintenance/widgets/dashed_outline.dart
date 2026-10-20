import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_sizes.dart';
import '../../../core/theme/aurora_tasks_c.dart';

/// A dashed outline around [child] (the "Add a reminder" row and the Add a
/// task summary before the form is ready).
class DashedOutline extends StatelessWidget {
  const DashedOutline({
    super.key,
    required this.child,
    required this.radius,
    this.color = AuroraColors.inkBorderStrong,
  });

  final Widget child;
  final BorderRadius radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return CustomPaint(
      foregroundPainter: _DashedPainter(
        color: color,
        radius: radius,
        dash: a.of(AuroraTasksCSizes.dashLength),
        gap: a.of(AuroraTasksCSizes.dashGap),
      ),
      child: child,
    );
  }
}

class _DashedPainter extends CustomPainter {
  const _DashedPainter({
    required this.color,
    required this.radius,
    required this.dash,
    required this.gap,
  });

  final Color color;
  final BorderRadius radius;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = AuroraBorders.emphasis / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - AuroraBorders.emphasis,
      size.height - AuroraBorders.emphasis,
    );
    final path = Path()..addRRect(radius.toRRect(rect));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = AuroraBorders.emphasis;
    for (final PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.dash != dash ||
      old.gap != gap;
}
