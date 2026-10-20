import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_home_a.dart';
import '../../../../core/theme/aurora_home_shared.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';

/// Eyebrow, title, the big five-year total and the footnote.
class LifespanSummary extends StatelessWidget {
  const LifespanSummary({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.total,
    required this.totalSub,
    required this.footnote,
  });

  final String eyebrow;
  final String title;
  final String total;
  final String totalSub;
  final String footnote;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow, style: AuroraType.label),
        SizedBox(height: a.of(AuroraSpacing.space2)),
        Semantics(
          header: true,
          child: Text(title, style: AuroraHomeType.itemTitle),
        ),
        SizedBox(height: a.of(AuroraSpacing.space7)),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: a.of(AuroraSpacing.space2),
          children: [
            Text(total, style: AuroraHomeAType.bigTotal),
            Text(totalSub, style: AuroraHomeAType.bigTotalSub),
          ],
        ),
        SizedBox(height: a.of(AuroraSpacing.space1)),
        Text(footnote, style: AuroraHomeAType.summaryBody),
      ],
    );
  }
}
