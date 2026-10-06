import 'package:flutter/material.dart';

import '../../../core/theme/aurora_auth.dart';

/// The Keystona mark: a keystone with a bar across it (kit SVG, 40 x 40).
///
/// Sized by [size] (a square edge), drawn at any scale.
class AuthLogoMark extends StatelessWidget {
  const AuthLogoMark({
    super.key,
    required this.size,
    required this.bodyColor,
    required this.barColor,
  });

  final double size;
  final Color bodyColor;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _LogoPainter(bodyColor: bodyColor, barColor: barColor),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter({required this.bodyColor, required this.barColor});

  final Color bodyColor;
  final Color barColor;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / AuroraLogoGeometry.viewBox;
    final body = Path()
      ..moveTo(AuroraLogoGeometry.topLeftX * k, AuroraLogoGeometry.topY * k)
      ..lineTo(AuroraLogoGeometry.topRightX * k, AuroraLogoGeometry.topY * k)
      ..lineTo(
        AuroraLogoGeometry.bottomRightX * k,
        AuroraLogoGeometry.bottomY * k,
      )
      ..lineTo(
        AuroraLogoGeometry.bottomLeftX * k,
        AuroraLogoGeometry.bottomY * k,
      )
      ..close();
    canvas.drawPath(body, Paint()..color = bodyColor);
    canvas.drawLine(
      Offset(AuroraLogoGeometry.barStartX * k, AuroraLogoGeometry.barY * k),
      Offset(AuroraLogoGeometry.barEndX * k, AuroraLogoGeometry.barY * k),
      Paint()
        ..color = barColor
        ..strokeWidth = AuroraLogoGeometry.barStroke * k
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.bodyColor != bodyColor || old.barColor != barColor;
}
