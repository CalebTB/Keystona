import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_shared.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';

/// Wraps a form field and, while [fromScan] is true, paints the inset cobalt
/// edge on its left that says "this came from the label scan". The edge follows
/// the field's corner radius and sits over the field's own border.
///
/// Turn [fromScan] off as soon as the value differs from the scanned one.
class ScanFieldBox extends StatelessWidget {
  const ScanFieldBox({
    super.key,
    required this.child,
    required this.fromScan,
    this.borderRadius = AuroraRadius.md,
  });

  final Widget child;
  final bool fromScan;

  /// The field's corner radius (inputs use `AuroraRadius.md`).
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    if (!fromScan) return child;
    return CustomPaint(
      foregroundPainter: _EdgePainter(
        radius: borderRadius,
        edge: context.aurora.of(AuroraHomeSizes.scanEdge),
      ),
      child: child,
    );
  }
}

class _EdgePainter extends CustomPainter {
  const _EdgePainter({required this.radius, required this.edge});

  final BorderRadius radius;
  final double edge;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Path()..addRRect(radius.toRRect(Offset.zero & size));
    final inner = Path()
      ..addRRect(radius.toRRect(Offset(edge, 0) & size));
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, inner),
      Paint()..color = AuroraColors.cobalt,
    );
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      old.radius != radius || old.edge != edge;
}
