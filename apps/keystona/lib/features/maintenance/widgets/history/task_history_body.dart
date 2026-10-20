import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../models/task_history.dart';
import '../../services/task_format.dart';
import '../detail/task_detail_header.dart';
import 'task_history_callout.dart';
import 'task_history_empty.dart';
import 'task_history_log_card.dart';
import 'task_history_stats.dart';
import 'task_history_strip.dart';

/// The History content below the top bar.
class TaskHistoryBody extends StatelessWidget {
  const TaskHistoryBody({super.key, required this.history});

  final TaskHistory history;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraTasksB.historyGap));
    final parent = history.parentName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TaskDetailHeader(
          eyebrow: parent == null ? 'History' : 'History · $parent',
          title: history.task.name,
        ),
        gap,
        if (history.isEmpty)
          const TaskHistoryEmpty()
        else ...[
          TaskHistoryStats(stats: _stats()),
          gap,
          TaskHistoryStrip(marks: history.marks),
          gap,
          TaskHistoryLogCard(items: history.items),
          gap,
          TaskHistoryCallout(
            text: parent == null
                ? 'This log goes into your Home History Report — proof the '
                      'task was looked after.'
                : 'This log goes into your Home History Report — proof the '
                      '${parent.toLowerCase()} was looked after.',
          ),
        ],
      ],
    );
  }

  List<TaskStat> _stats() {
    final year = history.firstYear;
    final count = history.count;
    return [
      TaskStat(
        value: '$count',
        caption: year == null
            ? (count == 1 ? 'Time' : 'Times')
            : '${count == 1 ? 'Time' : 'Times'} since $year',
      ),
      TaskStat(
        value: history.known == 0
            ? '—'
            : '${history.onTime} of ${history.known}',
        caption: 'On time',
        color: history.known == 0 ? AuroraColors.ink : AuroraColors.olive,
      ),
      TaskStat(
        value: TaskFormat.money(history.totalSpent),
        caption: 'Spent in all',
      ),
    ];
  }
}
