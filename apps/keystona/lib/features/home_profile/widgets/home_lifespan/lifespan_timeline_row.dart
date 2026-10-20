import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_a.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../home_lifespan_copy.dart';
import '../../lifespan/lifespan_reading.dart';
import '../../lifespan/timeline_axis.dart';
import '../../models/home_item.dart';
import '../shared/lifespan_colors.dart';
import 'lifespan_bar_painter.dart';

/// One item on the timeline: name, when to replace it, the bar, then how old
/// it is and what it costs. Taps to its detail screen.
class LifespanTimelineRow extends StatelessWidget {
  const LifespanTimelineRow({
    super.key,
    required this.item,
    required this.axis,
    required this.firstYear,
    required this.onTap,
  });

  final HomeItem item;
  final TimelineAxis axis;

  /// First year of the forecast: past-due items are budgeted there.
  final int firstYear;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final reading = item.reading;
    final bar = TimelineBar.forItem(item, axis);
    final cost = HomeLifespanCopy.cost(item);
    final endColor = reading.band == null || reading.band == LifespanBand.plenty
        ? AuroraColors.inkSecondary
        : reading.textColor;
    final meta = HomeLifespanCopy.meta(item, axis);
    return AuroraPressable(
      onTap: onTap,
      semanticLabel:
          '${item.name}. ${HomeLifespanCopy.endText(reading, firstYear)}',
      child: Padding(
        padding: a.symmetric(vertical: AuroraSpacing.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    item.name,
                    style: AuroraHomeAType.timelineName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: a.of(AuroraSpacing.space4)),
                Flexible(
                  child: Text(
                    HomeLifespanCopy.endText(reading, firstYear),
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AuroraHomeAType.timelineEnd.copyWith(color: endColor),
                  ),
                ),
              ],
            ),
            SizedBox(height: a.of(AuroraSpacing.space3)),
            SizedBox(
              height: a.of(AuroraHomeASizes.timelineHeight),
              child: bar == null
                  ? null
                  : ExcludeSemantics(
                      child: CustomPaint(
                        painter: LifespanBarPainter(
                          bar: bar,
                          fill: reading.barColor,
                          scale: a.factor,
                        ),
                      ),
                    ),
            ),
            SizedBox(height: a.of(AuroraSpacing.space3)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    meta,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AuroraHomeAType.timelineEnd.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (cost.isNotEmpty) ...[
                  SizedBox(width: a.of(AuroraSpacing.space4)),
                  Text(cost, style: AuroraHomeAType.timelineCost),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
