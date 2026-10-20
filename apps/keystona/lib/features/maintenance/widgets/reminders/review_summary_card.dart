import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_c.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../reminders_copy.dart';

/// "12 of 14 on", "About 7 a month" and a bar showing the share that is on.
class ReviewSummaryCard extends StatelessWidget {
  const ReviewSummaryCard({
    super.key,
    required this.on,
    required this.all,
    required this.perMonth,
  });

  final int on;
  final int all;
  final int perMonth;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final share = all == 0 ? 0.0 : on / all;
    return Container(
      padding: a.all(AuroraSpacing.space6),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.xl,
        border: Border.all(
          color: AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text.rich(
                  TextSpan(
                    text: '$on',
                    style: AuroraTasksCType.summaryNumber,
                    children: [
                      TextSpan(
                        text: ' ${RemindersCopy.ofAllOn(all)}',
                        style: AuroraType.buttonSm.copyWith(
                          color: AuroraColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: a.of(AuroraSpacing.space3)),
              Flexible(
                child: Text(
                  RemindersCopy.perMonth(perMonth).toUpperCase(),
                  textAlign: TextAlign.end,
                  style: AuroraType.meta,
                ),
              ),
            ],
          ),
          SizedBox(height: a.of(AuroraSpacing.space3)),
          ExcludeSemantics(
            child: Container(
              height: a.of(AuroraTasksCSizes.progressHeight),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: AuroraRadius.bar,
                border: Border.all(
                  color: AuroraColors.inkTileBorder,
                  width: AuroraBorders.regular,
                ),
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: share,
                  heightFactor: 1,
                  child: const ColoredBox(color: AuroraColors.cobalt),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
