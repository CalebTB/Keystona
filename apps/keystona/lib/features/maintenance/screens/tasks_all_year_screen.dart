import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_tasks_a.dart';
import '../../../core/widgets/error_view.dart';
import '../providers/maintenance_tasks_provider.dart';
import '../providers/tasks_tab_provider.dart';
import '../tasks_copy.dart';
import '../widgets/tasks_tab/tasks_scroll_page.dart';
import '../widgets/year/tasks_year_content.dart';
import '../widgets/year/tasks_year_skeleton.dart';

/// All tasks (kit: TasksAllYear): every task over the next 12 months, one
/// month at a time under a year-at-a-glance chart.
class TasksAllYearScreen extends ConsumerStatefulWidget {
  const TasksAllYearScreen({super.key});

  @override
  ConsumerState<TasksAllYearScreen> createState() => _TasksAllYearScreenState();
}

class _TasksAllYearScreenState extends ConsumerState<TasksAllYearScreen> {
  int _selected = 0;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(maintenanceTasksProvider);
    final data = ref.watch(tasksYearDataProvider(query: _query));
    final loaded = tasks.hasValue;

    return Scaffold(
      backgroundColor: AuroraColors.paper,
      body: TasksScrollPage(
        topPadding: AuroraTasksA.pushedPageTop,
        onRefresh: ref.read(maintenanceTasksProvider.notifier).refresh,
        fillRemaining: !loaded,
        child: loaded
            ? TasksYearContent(
                data: data,
                selected: _selected.clamp(0, data.months.length - 1),
                onSelect: (index) => setState(() => _selected = index),
                onQuery: (query) => setState(() => _query = query),
              )
            : tasks.hasError
            ? ErrorView(
                message: TasksCopy.loadError,
                onRetry: () => ref.invalidate(maintenanceTasksProvider),
              )
            : const TasksYearSkeleton(),
      ),
    );
  }
}
