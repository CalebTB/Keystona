import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../models/task_history.dart';
import '../shared/task_section_label.dart';
import 'task_history_entry.dart';
import 'task_history_skip_view.dart';

/// "Log": every completion and skip, newest first, on a timeline.
class TaskHistoryLogCard extends StatelessWidget {
  const TaskHistoryLogCard({super.key, required this.items});

  final List<TaskLogItem> items;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TaskSectionLabel(title: 'Log'),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        Container(
          padding: a.symmetric(
            horizontal: AuroraSpacing.space6,
            vertical: AuroraSpacing.space7,
          ),
          decoration: BoxDecoration(
            borderRadius: AuroraRadius.xl,
            border: Border.all(
              color: AuroraColors.inkBorder,
              width: AuroraBorders.regular,
            ),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++)
                switch (items[i]) {
                  CompletionLogItem(:final entry) => TaskHistoryEntryView(
                    key: ValueKey(entry.completion.id),
                    entry: entry,
                    isLast: i == items.length - 1,
                  ),
                  SkipLogItem(:final skip) => TaskHistorySkipView(
                    key: ValueKey(skip.id),
                    skip: skip,
                    isLast: i == items.length - 1,
                  ),
                },
            ],
          ),
        ),
      ],
    );
  }
}
