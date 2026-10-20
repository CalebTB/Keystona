import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../tasks_copy.dart';
import 'task_list_card.dart';

/// A titled card of task rows ("THIS WEEK · 1"). The first group on the tab
/// also carries the grouping control ("By date ⌄").
class TasksGroupSection extends StatelessWidget {
  const TasksGroupSection({
    super.key,
    required this.title,
    required this.rows,
    this.groupingLabel,
    this.onGrouping,
    this.overdue = false,
  });

  final String title;
  final List<Widget> rows;

  /// "By date": shown at the right of the title when [onGrouping] is set.
  final String? groupingLabel;
  final VoidCallback? onGrouping;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: overdue
                    ? AuroraType.sectionTitle.copyWith(
                        color: AuroraColors.coralDeep,
                      )
                    : AuroraType.label,
              ),
            ),
            if (onGrouping != null)
              AuroraPressable(
                onTap: onGrouping,
                semanticLabel: TasksCopy.groupingTitle,
                enforceTouchTarget: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      groupingLabel ?? '',
                      style: AuroraType.buttonSm.copyWith(
                        color: AuroraColors.inkSubtle,
                      ),
                    ),
                    SizedBox(width: a.of(AuroraSpacing.space1)),
                    Icon(
                      Icons.expand_more,
                      size: a.of(AuroraIconSizes.xs),
                      color: AuroraColors.inkSubtle,
                    ),
                  ],
                ),
              ),
          ],
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        TaskListCard(overdue: overdue, children: rows),
      ],
    );
  }
}
