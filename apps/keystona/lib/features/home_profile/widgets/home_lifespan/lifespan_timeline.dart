import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../home_lifespan_copy.dart';
import '../../lifespan/timeline_axis.dart';
import '../../models/home_item.dart';
import '../../models/item_ref.dart';
import 'lifespan_legend.dart';
import 'lifespan_tick_row.dart';
import 'lifespan_timeline_row.dart';

/// The tick row, one timeline row per item (hairlines between) and the
/// legend. Shows [HomeLifespanCopy.tabEmpty] when [items] is empty.
class LifespanTimeline extends StatelessWidget {
  const LifespanTimeline({
    super.key,
    required this.axis,
    required this.items,
    required this.firstYear,
    required this.onOpen,
  });

  final TimelineAxis axis;
  final List<HomeItem> items;
  final int firstYear;
  final ValueChanged<ItemRef> onOpen;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    if (items.isEmpty) {
      return Text(HomeLifespanCopy.tabEmpty, style: AuroraType.meta);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LifespanTickRow(axis: axis),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const Divider(
              height: AuroraBorders.hairline,
              thickness: AuroraBorders.hairline,
              color: AuroraColors.inkBorder,
            ),
          LifespanTimelineRow(
            key: ValueKey(items[i].ref),
            item: items[i],
            axis: axis,
            firstYear: firstYear,
            onTap: () => onOpen(items[i].ref),
          ),
        ],
        SizedBox(height: a.of(AuroraSpacing.space4)),
        const LifespanLegend(),
      ],
    );
  }
}
