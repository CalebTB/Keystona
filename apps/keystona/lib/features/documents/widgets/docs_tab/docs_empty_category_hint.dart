import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_a.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// A dashed row inviting the first document of an empty category
/// ("Nothing in Financial yet").
class DocsEmptyCategoryHint extends StatelessWidget {
  const DocsEmptyCategoryHint({
    super.key,
    required this.title,
    required this.hint,
    required this.onTap,
  });

  final String title;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: title,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AuroraColors.inkBorderStrong,
          radius: AuroraRadius.xl,
          dash: a.of(AuroraDocsA.dashLength),
          gap: a.of(AuroraDocsA.dashGap),
        ),
        child: Container(
          constraints: BoxConstraints(
            minHeight: a.minControl(AuroraSizes.actionRow),
          ),
          padding: a.symmetric(
            horizontal: AuroraSpacing.space6,
            vertical: AuroraSpacing.space5,
          ),
          child: Row(
            children: [
              Icon(
                Icons.add,
                size: a.of(AuroraIconSizes.lg),
                color: AuroraColors.inkSubtle,
              ),
              SizedBox(width: a.of(AuroraSpacing.space5)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: AuroraType.rowTitle),
                    SizedBox(height: a.of(AuroraDocsA.hairlineGap)),
                    Text(
                      hint,
                      style: AuroraType.bodySm.copyWith(
                        color: AuroraColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
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
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.dash != dash ||
      old.gap != gap;
}
