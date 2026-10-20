import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_shared.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import 'item_timeline_row.dart';

/// The HISTORY card: a vertical rail of dated entries, newest first, with the
/// title, who did it and what it cost. Put the dashed "Log a repair or
/// service" button (`DashedActionButton`) under it.
class ItemHistoryTimeline extends StatelessWidget {
  const ItemHistoryTimeline({super.key, required this.rows});

  final List<ItemTimelineRow> rows;

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
          horizontal: AuroraSpacing.space6,
          vertical: AuroraSpacing.space7,
        ),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++)
              _Entry(row: rows[i], last: i == rows.length - 1),
          ],
        ),
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({required this.row, required this.last});

  final ItemTimelineRow row;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final dot = a.of(AuroraHomeSizes.timelineDot);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: dot,
            child: Column(
              children: [
                Container(
                  width: dot,
                  height: dot,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: row.hollow ? AuroraColors.paper : AuroraColors.ink,
                    border: Border.all(
                      color: AuroraColors.ink,
                      width: AuroraBorders.emphasis,
                    ),
                  ),
                ),
                if (!last)
                  Expanded(
                    child: SizedBox(
                      width: AuroraHomeSizes.timelineRail,
                      child: const ColoredBox(
                        color: AuroraColors.inkInputBorder,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: a.of(AuroraSpacing.space6)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: last ? 0 : a.of(AuroraSpacing.space8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.dateLabel.toUpperCase(),
                          style: AuroraType.label,
                        ),
                        SizedBox(height: a.of(AuroraSpacing.space1)),
                        Text(row.title, style: AuroraHomeType.entryTitle),
                        if (row.subtitle != null) ...[
                          SizedBox(height: a.of(AuroraSpacing.space1)),
                          Text(
                            row.subtitle!,
                            style: AuroraType.bodySm.copyWith(
                              color: AuroraColors.inkSubtle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (row.costLabel != null) ...[
                    SizedBox(width: a.of(AuroraSpacing.space3)),
                    Text(row.costLabel!, style: AuroraHomeType.entryTitle),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
