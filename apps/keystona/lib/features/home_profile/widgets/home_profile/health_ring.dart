import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_a.dart';
import '../../../../core/theme/aurora_scale.dart';

/// A score ring: a track and a coral arc swept to [score] out of
/// [maxScore], the number inside.
class HealthRing extends StatelessWidget {
  const HealthRing({super.key, required this.score});

  final int score;

  /// A full ring.
  static const int maxScore = 100;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final size = a.of(AuroraHomeASizes.ring);
    return Semantics(
      label: '$score of $maxScore',
      child: ExcludeSemantics(
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(
              fraction: (score / maxScore).clamp(0.0, 1.0),
              stroke: a.of(AuroraHomeASizes.ringStroke),
            ),
            child: Center(
              child: Text('$score', style: AuroraHomeAType.ringScore),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.fraction, required this.stroke});

  final double fraction;
  final double stroke;

  /// Where the arc starts: twelve o'clock.
  static const double _start = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      arc,
      0,
      math.pi * 2,
      false,
      paint..color = AuroraHomeAColors.ringTrack,
    );
    canvas.drawArc(
      arc,
      _start,
      math.pi * 2 * fraction,
      false,
      paint..color = AuroraColors.coral,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.stroke != stroke;
}
