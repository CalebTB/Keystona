import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_a.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../lifespan/timeline_axis.dart';

/// Draws one timeline bar: the track from start to end of life, the fill up to
/// today (or the end), a hatched over-run past the end, and the today tick.
class LifespanBarPainter extends CustomPainter {
  const LifespanBarPainter({
    required this.bar,
    required this.fill,
    required this.scale,
  });

  final TimelineBar bar;
  final Color fill;

  /// The responsive factor for token sizes.
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final thickness = AuroraHomeASizes.timelineBar * scale;
    final top = (size.height - thickness) / 2;
    final radius = Radius.circular(thickness / 2);
    final minWidth = thickness;

    Rect span(double fromX, double toX) {
      final left = fromX * size.width;
      final width = ((toX - fromX) * size.width).clamp(minWidth, size.width);
      return Rect.fromLTWH(left, top, width, thickness);
    }

    final track = span(bar.startX, bar.endX);
    canvas.drawRRect(
      RRect.fromRectAndRadius(track.deflate(AuroraBorders.regular / 2), radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AuroraBorders.regular
        ..color = AuroraColors.inkInputBorder,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(span(bar.startX, bar.usedEndX), radius),
      Paint()..color = fill,
    );
    if (bar.pastLife) _hatch(canvas, size, top, thickness);

    final tickX = bar.nowX * size.width;
    canvas.drawRect(
      Rect.fromLTWH(
        tickX - AuroraHomeASizes.timelineTick / 2,
        0,
        AuroraHomeASizes.timelineTick,
        size.height,
      ),
      Paint()..color = AuroraColors.ink,
    );
  }

  void _hatch(Canvas canvas, Size size, double top, double thickness) {
    final from = bar.endX * size.width;
    final to = bar.nowX * size.width;
    final stripe = AuroraHomeASizes.hatchStripe * scale;
    final gap = AuroraHomeASizes.hatchGap * scale;
    final paint = Paint()..color = AuroraHomeAColors.hatch;
    for (var x = from; x < to; x += stripe + gap) {
      final width = x + stripe > to ? to - x : stripe;
      canvas.drawRect(Rect.fromLTWH(x, top, width, thickness), paint);
    }
  }

  @override
  bool shouldRepaint(LifespanBarPainter old) =>
      old.bar != bar || old.fill != fill || old.scale != scale;
}
