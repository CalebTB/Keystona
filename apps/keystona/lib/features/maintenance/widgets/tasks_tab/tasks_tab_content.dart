import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../models/tasks_tab_data.dart';
import '../../providers/just_done_provider.dart';
import '../../providers/maintenance_tasks_provider.dart';
import '../../tasks_copy.dart';
import '../actions/task_actions.dart';
import 'task_list_card.dart';
import 'task_row_tile.dart';
import 'tasks_caught_up_section.dart';
import 'tasks_done_banner.dart';
import 'tasks_header.dart';
import 'tasks_overdue_section.dart';
import 'tasks_search_field.dart';
import 'tasks_upcoming_section.dart';

/// The loaded Tasks tab: header and search, then either search results, the
/// caught-up view, or the overdue card with this month's grouped list.
class TasksTabContent extends ConsumerWidget {
  const TasksTabContent({
    super.key,
    required this.data,
    required this.grouping,
    required this.onGrouping,
    required this.onQuery,
    required this.onAdd,
    required this.onSeeAll,
  });

  final TasksTabData data;
  final TaskGrouping grouping;
  final VoidCallback onGrouping;
  final ValueChanged<String> onQuery;
  final VoidCallback onAdd;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.space8));
    final justDone = ref.watch(justDoneProvider);
    final showBanner = justDone != null && data.overdueCount == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TasksHeader(
          eyebrow: TasksCopy.eyebrow(
            data.today,
            data.monthDone,
            data.monthTotal,
          ),
          subtitle: data.caughtUp
              ? TasksCopy.caughtUpSubtitle(data.daysUntilNext)
              : TasksCopy.subtitle(
                  overdue: data.overdueCount,
                  dueToday: data.dueTodayCount,
                ),
          onAdd: onAdd,
        ),
        gap,
        TasksSearchField(onChanged: onQuery),
        gap,
        if (data.hasQuery)
          _Matches(data: data)
        else if (data.caughtUp)
          TasksCaughtUpSection(data: data, onSeeAll: onSeeAll)
        else ...[
          if (data.hero != null) ...[
            TasksOverdueSection(hero: data.hero!, others: data.moreOverdue),
            gap,
          ] else if (showBanner) ...[
            TasksDoneBanner(
              text: TasksCopy.nothingOverdue(justDone.previous.name),
              onUndo: () async {
                final notifier = ref.read(maintenanceTasksProvider.notifier);
                ref.read(justDoneProvider.notifier).set(null);
                await TaskActions.undo(notifier, justDone);
              },
            ),
            gap,
          ],
          TasksUpcomingSection(
            data: data,
            grouping: grouping,
            onGrouping: onGrouping,
            onSeeAll: onSeeAll,
          ),
        ],
      ],
    );
  }
}

/// Search results: every open task that matches, soonest first.
class _Matches extends StatelessWidget {
  const _Matches({required this.data});

  final TasksTabData data;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    if (data.matches.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: a.of(AuroraSpacing.space9)),
        child: Text(
          TasksCopy.noMatches,
          textAlign: TextAlign.center,
          style: AuroraType.body.copyWith(color: AuroraColors.inkSubtle),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(TasksCopy.matchesHeading, style: AuroraType.label),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        TaskListCard(
          children: [
            for (final task in data.matches)
              TaskRowTile(key: ValueKey(task.id), task: task),
          ],
        ),
      ],
    );
  }
}
