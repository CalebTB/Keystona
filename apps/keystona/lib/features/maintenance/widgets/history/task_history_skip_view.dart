import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../models/task_skip.dart';
import '../../services/task_format.dart';
import '../dashed_outline.dart';
import '../shared/task_timeline_item.dart';
import 'task_history_date_amount.dart';

/// One skipped occurrence on the History timeline: a dashed dot, the date,
/// a dash where the cost would be, "SKIPPED" and the reason when there is one.
class TaskHistorySkipView extends StatelessWidget {
  const TaskHistorySkipView({
    super.key,
    required this.skip,
    required this.isLast,
  });

  final TaskSkip skip;
  final bool isLast;

  /// The word that names the entry.
  static const String label = 'Skipped';

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return TaskTimelineItem(
      dotSize: AuroraTasksB.dotHistory,
      dotTop: AuroraTasksB.dotTopHistory,
      isLast: isLast,
      dot: const DashedOutline(
        radius: AuroraRadius.full,
        color: AuroraColors.inkCheckBorder,
        child: SizedBox.expand(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TaskHistoryDateAmount(
            date: TaskFormat.dateShort(skip.skippedOn),
            amount: '—',
          ),
          SizedBox(height: a.of(AuroraSpacing.space1)),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: label.toUpperCase(),
                  style: AuroraTasksBType.timing.copyWith(
                    color: AuroraColors.inkSecondary,
                  ),
                ),
                if (skip.hasReason)
                  TextSpan(
                    text: ' · ${skip.reason}',
                    style: AuroraTasksBType.entryMeta,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
