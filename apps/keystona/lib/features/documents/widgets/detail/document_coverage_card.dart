import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_c.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_card.dart';
import '../../models/coverage_info.dart';
import '../../models/document_format.dart';
import '../../models/docs_expiry.dart';
import '../../models/expiry_labels.dart';

/// How much of the coverage period is left, with the reminder date.
///
/// The bar is cobalt with more than 90 days left, amber inside 90, coral
/// inside 30 or once ended.
class DocumentCoverageCard extends StatelessWidget {
  const DocumentCoverageCard({super.key, required this.coverage});

  final CoverageInfo coverage;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final reminder = coverage.reminderDate();
    return AuroraCard(
      padding: a.all(AuroraSpacing.space7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(coverage.title, style: AuroraDocsCType.coverageTitle),
          SizedBox(height: a.of(AuroraSpacing.space5)),
          _UsageBar(
            fraction: coverage.usedFraction,
            color: _barColor(coverage.expiry),
          ),
          SizedBox(height: a.of(AuroraSpacing.space5)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(coverage.startLabel, style: AuroraType.meta)),
              SizedBox(width: a.of(AuroraSpacing.space3)),
              Flexible(
                child: Text(
                  ExpiryLabels.remaining(coverage.expiry.days),
                  textAlign: TextAlign.right,
                  style: AuroraType.meta,
                ),
              ),
            ],
          ),
          if (reminder != null) ...[
            SizedBox(height: a.of(AuroraSpacing.space5)),
            const Divider(
              height: AuroraBorders.hairline,
              thickness: AuroraBorders.hairline,
              color: AuroraColors.inkBorder,
            ),
            SizedBox(height: a.of(AuroraSpacing.space5)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: a.of(AuroraIconSizes.md),
                  color: AuroraColors.inkSubtle,
                ),
                SizedBox(width: a.of(AuroraSpacing.space4)),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: "We'll remind you on ",
                      children: [
                        TextSpan(
                          text: DocumentFormat.date(reminder),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    style: AuroraType.bodyLg.copyWith(color: AuroraColors.inkBody),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _barColor(DocsExpiry expiry) => switch (expiry.tone) {
        DocsExpiryTone.far => AuroraColors.cobalt,
        DocsExpiryTone.soon => AuroraColors.amber,
        DocsExpiryTone.urgent => AuroraColors.coral,
      };
}

class _UsageBar extends StatelessWidget {
  const _UsageBar({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final percent = (fraction * 100).round();
    return Semantics(
      label: '$percent percent of the coverage period used',
      child: ExcludeSemantics(
        child: Container(
          height: a.of(AuroraDocsCSizes.coverageBarHeight),
          decoration: BoxDecoration(
            borderRadius: AuroraRadius.bar,
            border: Border.all(
              color: AuroraColors.inkBorderStrong,
              width: AuroraBorders.regular,
            ),
          ),
          child: ClipRRect(
            borderRadius: AuroraRadius.bar,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fraction,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: AuroraRadius.bar,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
