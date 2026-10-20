import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_tasks_wire.dart';

/// Diagonal hatching that fills its parent: the mark of a skipped occurrence
/// on the every-time strip and its legend.
class TaskHatchFill extends StatelessWidget {
  const TaskHatchFill({super.key, this.color = AuroraColors.inkBorder});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HatchPainter(color),
      child: const SizedBox.expand(),
    );
  }
}

class _HatchPainter extends CustomPainter {
  const _HatchPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = AuroraTasksWire.hatchStroke;
    canvas.clipRect(Offset.zero & size);
    // 45 degree lines, from the bottom-left corner to the top-right.
    for (
      var x = -size.height;
      x < size.width;
      x += AuroraTasksWire.hatchSpacing
    ) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HatchPainter old) => old.color != color;
}
