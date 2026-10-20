import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../systems_copy.dart';
import '../shared/dashed_action_button.dart';
import '../shared/item_history_timeline.dart';
import '../shared/item_timeline_row.dart';

/// The HISTORY body: the timeline (or the "No service history yet" note) and
/// the dashed "Log a repair or service" button.
class SystemHistoryBody extends StatelessWidget {
  const SystemHistoryBody({
    super.key,
    required this.rows,
    required this.onLog,
  });

  final List<ItemTimelineRow> rows;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rows.isEmpty)
          _Empty()
        else
          ItemHistoryTimeline(rows: rows),
        SizedBox(height: a.of(AuroraSpacing.space5)),
        DashedActionButton(
          icon: Icons.add,
          label: SystemsCopy.logTitle,
          onTap: onLog,
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
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
        padding: a.all(AuroraSpacing.space8),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: a.of(AuroraIconSizes.xl),
              color: AuroraColors.inkTertiary,
            ),
            SizedBox(height: a.of(AuroraSpacing.space3)),
            Text(SystemsCopy.historyEmptyTitle, style: AuroraType.h3),
            SizedBox(height: a.of(AuroraSpacing.space1)),
            Text(
              SystemsCopy.historyEmptyBody,
              textAlign: TextAlign.center,
              style: AuroraType.bodySm.copyWith(color: AuroraColors.inkSubtle),
            ),
          ],
        ),
      ),
    );
  }
}
