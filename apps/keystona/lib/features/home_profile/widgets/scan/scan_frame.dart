import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_b.dart';
import '../../../../core/theme/aurora_scale.dart';

/// The label frame: four corner brackets, lime once the label is read, and a
/// faint guide inside. Sized from the screen width, never a fixed size.
class ScanFrame extends StatelessWidget {
  const ScanFrame({super.key, required this.found});

  final bool found;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth * AuroraHomeBSizes.frameWidthFraction;
        return Center(
          child: SizedBox(
            width: width,
            child: AspectRatio(
              aspectRatio: AuroraHomeBSizes.frameAspect,
              child: CustomPaint(
                painter: _BracketPainter(
                  color: found ? AuroraColors.lime : AuroraColors.paper,
                  arm: a.of(AuroraHomeBSizes.bracketArm),
                  stroke: a.of(AuroraHomeBSizes.bracketStroke),
                  radius: a.of(AuroraHomeBSizes.bracketRadius),
                ),
                child: Padding(
                  padding: a.all(AuroraHomeBSizes.bracketArm),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: AuroraHomeBColors.cameraGuide),
                      borderRadius: BorderRadius.circular(
                        a.of(AuroraHomeBSizes.guideRadius),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BracketPainter extends CustomPainter {
  const _BracketPainter({
    required this.color,
    required this.arm,
    required this.stroke,
    required this.radius,
  });

  final Color color;
  final double arm;
  final double stroke;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;
    final r = radius;
    final path = Path()
      ..moveTo(0, arm)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..lineTo(arm, 0)
      ..moveTo(w - arm, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
      ..lineTo(w, arm)
      ..moveTo(w, h - arm)
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w - r, h), radius: Radius.circular(r))
      ..lineTo(w - arm, h)
      ..moveTo(arm, h)
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: Radius.circular(r))
      ..lineTo(0, h - arm);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BracketPainter old) =>
      old.color != color ||
      old.arm != arm ||
      old.stroke != stroke ||
      old.radius != radius;
}
