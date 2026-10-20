import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_home_shared.dart';
import '../../../../core/theme/aurora_scale.dart';

/// Draws a dashed outline over its child, following [borderRadius]. The
/// painter sits in front so nothing inside can cover the dashes.
class DashedBorder extends StatelessWidget {
  const DashedBorder({
    super.key,
    required this.child,
    required this.borderRadius,
    this.color = AuroraHomeColors.dashed,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return CustomPaint(
      foregroundPainter: _DashedPainter(
        color: color,
        radius: borderRadius,
        stroke: a.of(AuroraHomeSizes.dashedStroke),
        dash: a.of(AuroraHomeSizes.dashLength),
        gap: a.of(AuroraHomeSizes.dashGap),
      ),
      child: child,
    );
  }
}

class _DashedPainter extends CustomPainter {
  const _DashedPainter({
    required this.color,
    required this.radius,
    required this.stroke,
    required this.dash,
    required this.gap,
  });

  final Color color;
  final BorderRadius radius;
  final double stroke;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final path = Path()..addRRect(radius.toRRect(rect));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    for (final metric in path.computeMetrics()) {
      var at = 0.0;
      while (at < metric.length) {
        canvas.drawPath(metric.extractPath(at, at + dash), paint);
        at += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.stroke != stroke ||
      old.dash != dash ||
      old.gap != gap;
}
