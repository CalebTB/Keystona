import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// An empty photo slot: a dashed outline with a plus. Fills the square its
/// parent gives it.
class TaskPhotoSlot extends StatelessWidget {
  const TaskPhotoSlot({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: 'Add a photo',
      child: CustomPaint(
        foregroundPainter: _DashedPainter(
          dash: a.of(AuroraTasksB.dashLength),
          gap: a.of(AuroraTasksB.dashGap),
        ),
        child: Center(
          child: ExcludeSemantics(
            child: Icon(
              Icons.add,
              size: a.of(AuroraTasksB.photoAddGlyph),
              color: AuroraColors.inkHelper,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedPainter extends CustomPainter {
  const _DashedPainter({required this.dash, required this.gap});

  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = AuroraBorders.emphasis / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - AuroraBorders.emphasis,
      size.height - AuroraBorders.emphasis,
    );
    final path = Path()..addRRect(AuroraRadius.md.toRRect(rect));
    final paint = Paint()
      ..color = AuroraColors.inkBorderStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = AuroraBorders.emphasis;
    for (final PathMetric metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) => old.dash != dash || old.gap != gap;
}
