import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_c.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_chip.dart';
import '../../item_copy.dart';
import '../../models/item_tasks.dart';

/// The Done tab's total: what the upkeep cost and how many times, with the
/// lime "ON SCHEDULE" chip when nothing is overdue.
class ItemDoneSummaryCard extends StatelessWidget {
  const ItemDoneSummaryCard({
    super.key,
    required this.summary,
    required this.onSchedule,
  });

  final ItemDoneSummary summary;
  final bool onSchedule;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.xl,
        border: Border.all(
          color: AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Padding(
        padding: a.symmetric(
          horizontal: AuroraSpacing.space7,
          vertical: AuroraSpacing.space6,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(summary.spentLabel, style: AuroraHomeCType.doneTotal),
                  SizedBox(height: a.of(AuroraSpacing.space1)),
                  Text(summary.caption, style: AuroraType.meta),
                ],
              ),
            ),
            if (onSchedule) ...[
              SizedBox(width: a.of(AuroraSpacing.space4)),
              const StatusChip.done(label: ItemCopy.onSchedule),
            ],
          ],
        ),
      ),
    );
  }
}
