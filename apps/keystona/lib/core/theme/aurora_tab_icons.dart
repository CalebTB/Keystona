import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'aurora_sizes.dart';

/// The five tab-bar glyphs (Tabler outline, 24 unit view box, round caps).
///
/// Path data lives with the tokens because it is geometry, not layout. Stroke
/// width is [AuroraIconSizes.stroke] in view-box units, so it scales with the
/// glyph exactly like the kit's SVGs.
enum AuroraTabIcon { home, docs, tasks, projects, settings }

class AuroraTabIconPainter extends CustomPainter {
  const AuroraTabIconPainter({required this.icon, required this.color});

  final AuroraTabIcon icon;
  final Color color;

  static const double _viewBox = 24;
  static const Radius _r2 = Radius.circular(2);
  static const Radius _r1 = Radius.circular(1);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = AuroraIconSizes.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.scale(size.width / _viewBox, size.height / _viewBox);

    switch (icon) {
      case AuroraTabIcon.home:
        canvas
          ..drawPath(
            Path()
              ..moveTo(5, 12)
              ..lineTo(3, 12)
              ..lineTo(12, 3)
              ..lineTo(21, 12)
              ..lineTo(19, 12),
            paint,
          )
          ..drawPath(
            Path()
              ..moveTo(5, 12)
              ..lineTo(5, 19)
              ..arcToPoint(const Offset(7, 21), radius: _r2, clockwise: false)
              ..lineTo(17, 21)
              ..arcToPoint(const Offset(19, 19), radius: _r2, clockwise: false)
              ..lineTo(19, 12),
            paint,
          )
          ..drawPath(
            Path()
              ..moveTo(9, 21)
              ..lineTo(9, 15)
              ..arcToPoint(const Offset(11, 13), radius: _r2)
              ..lineTo(13, 13)
              ..arcToPoint(const Offset(15, 15), radius: _r2)
              ..lineTo(15, 21),
            paint,
          );
      case AuroraTabIcon.docs:
        canvas
          ..drawPath(
            Path()
              ..moveTo(14, 3)
              ..lineTo(14, 7)
              ..arcToPoint(const Offset(15, 8), radius: _r1, clockwise: false)
              ..lineTo(19, 8),
            paint,
          )
          ..drawPath(
            Path()
              ..moveTo(17, 21)
              ..lineTo(7, 21)
              ..arcToPoint(const Offset(5, 19), radius: _r2)
              ..lineTo(5, 5)
              ..arcToPoint(const Offset(7, 3), radius: _r2)
              ..lineTo(14, 3)
              ..lineTo(19, 8)
              ..lineTo(19, 19)
              ..arcToPoint(const Offset(17, 21), radius: _r2)
              ..close(),
            paint,
          );
      case AuroraTabIcon.tasks:
        canvas.drawPath(
          Path()
            ..moveTo(7, 12)
            ..lineTo(12, 17)
            ..lineTo(22, 7)
            ..moveTo(2, 12)
            ..lineTo(7, 17)
            ..moveTo(12, 12)
            ..lineTo(17, 7),
          paint,
        );
      case AuroraTabIcon.projects:
        canvas.drawPath(
          Path()
            ..addRect(const Rect.fromLTWH(4, 4, 6, 8))
            ..addRect(const Rect.fromLTWH(14, 4, 6, 4))
            ..addRect(const Rect.fromLTWH(4, 16, 6, 4))
            ..addRect(const Rect.fromLTWH(14, 12, 6, 8)),
          paint,
        );
      case AuroraTabIcon.settings:
        const center = Offset(12, 12);
        const outer = 9.5;
        const inner = 7.8;
        const teeth = 8;
        canvas.drawCircle(center, 3, paint);
        final gear = Path();
        for (var i = 0; i < teeth; i++) {
          final a0 = (i / teeth) * math.pi * 2 - math.pi / 2;
          final a1 = a0 + (0.35 / teeth) * math.pi * 2;
          final a2 = a0 + (0.65 / teeth) * math.pi * 2;
          final a3 = a0 + (1.0 / teeth) * math.pi * 2;
          if (i == 0) {
            gear.moveTo(
              center.dx + inner * math.cos(a0),
              center.dy + inner * math.sin(a0),
            );
          }
          gear
            ..lineTo(center.dx + outer * math.cos(a1),
                center.dy + outer * math.sin(a1))
            ..lineTo(center.dx + outer * math.cos(a2),
                center.dy + outer * math.sin(a2))
            ..lineTo(center.dx + inner * math.cos(a3),
                center.dy + inner * math.sin(a3));
        }
        canvas.drawPath(gear..close(), paint);
    }
  }

  @override
  bool shouldRepaint(AuroraTabIconPainter old) =>
      old.icon != icon || old.color != color;
}
