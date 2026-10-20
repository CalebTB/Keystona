import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_c.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// Dashed card offering search inside documents, shown to free accounts.
/// Opens the upgrade sheet.
class SearchPremiumGate extends StatelessWidget {
  const SearchPremiumGate({super.key, required this.query, required this.onTap});

  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: 'Search inside your documents. Premium.',
      child: CustomPaint(
        painter: _DashedBorderPainter(
          dash: a.of(AuroraDocsCSizes.dashLength),
          gap: a.of(AuroraDocsCSizes.dashGap),
        ),
        child: Container(
          constraints: BoxConstraints(
            minHeight: a.minControl(AuroraDocsCSizes.gateMinHeight),
          ),
          padding: a.symmetric(
            horizontal: AuroraSpacing.space6,
            vertical: AuroraSpacing.space5,
          ),
          child: Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: a.of(AuroraIconSizes.xl),
                color: AuroraColors.inkSubtle,
              ),
              SizedBox(width: a.of(AuroraSpacing.space5)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Search inside your documents', style: AuroraType.buttonSm),
                    SizedBox(height: a.of(AuroraSpacing.space1)),
                    Text(
                      'Premium also finds “$query” in the text of your PDFs and photos.',
                      style: AuroraType.bodySm.copyWith(
                        color: AuroraColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: a.of(AuroraSpacing.space3)),
              Icon(
                CupertinoIcons.chevron_right,
                size: a.of(AuroraIconSizes.sm),
                color: AuroraColors.inkPlaceholder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dashed rounded-rectangle outline (Flutter has no dashed border).
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.dash, required this.gap});

  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AuroraColors.inkBorderStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = AuroraBorders.emphasis;
    final rrect = AuroraRadius.xl.toRRect(Offset.zero & size);
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.dash != dash || old.gap != gap;
}
