import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/widgets/aurora/aurora_sheet.dart';
import '../../../core/widgets/error_view.dart';
import '../models/tasks_tab_data.dart';
import '../providers/just_done_provider.dart';
import '../providers/maintenance_tasks_provider.dart';
import '../providers/task_progress_provider.dart';
import '../providers/tasks_tab_provider.dart';
import '../tasks_copy.dart';
import '../widgets/tasks_tab/tasks_scroll_page.dart';
import '../widgets/tasks_tab/tasks_skeleton.dart';
import '../widgets/tasks_tab/tasks_tab_content.dart';

/// The Tasks tab (kit: Tasks, TasksCaughtUp): what is overdue, what is coming
/// this month, and a way into All tasks. Every row marks done, skips or opens
/// from one place; long-press opens the task menu.
class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  TaskGrouping _grouping = TaskGrouping.date;
  String _query = '';

  Future<void> _refresh() async {
    ref.read(justDoneProvider.notifier).set(null);
    ref.invalidate(taskProgressProvider);
    await ref.read(maintenanceTasksProvider.notifier).refresh();
  }

  Future<void> _pickGrouping() async {
    final choice = await AuroraSheet.actionSheet(
      context,
      title: TasksCopy.groupingTitle,
      actions: const [
        AuroraSheetAction(label: TasksCopy.byDate),
        AuroraSheetAction(label: TasksCopy.byArea),
      ],
    );
    if (choice == null || !mounted) return;
    setState(() => _grouping = TaskGrouping.values[choice]);
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(maintenanceTasksProvider);
    final data = ref.watch(
      tasksTabDataProvider(grouping: _grouping, query: _query),
    );
    final loaded = tasks.hasValue;

    return Scaffold(
      backgroundColor: AuroraColors.paper,
      body: TasksScrollPage(
        onRefresh: _refresh,
        fillRemaining: !loaded,
        child: loaded
            ? TasksTabContent(
                data: data,
                grouping: _grouping,
                onGrouping: _pickGrouping,
                onQuery: (query) => setState(() => _query = query),
                onAdd: () => context.push(AppRoutes.maintenanceCreate),
                onSeeAll: () => context.push(AppRoutes.maintenanceAll),
              )
            : tasks.hasError
            ? ErrorView(
                message: TasksCopy.loadError,
                onRetry: () => ref.invalidate(maintenanceTasksProvider),
              )
            : const TasksSkeleton(),
      ),
    );
  }
}
