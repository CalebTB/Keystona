import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_tasks_b.dart';
import '../../../core/widgets/error_view.dart';
import '../models/task_log_draft.dart';
import '../providers/task_detail_provider.dart';
import '../providers/task_history_provider.dart';
import '../widgets/history/task_history_body.dart';
import '../widgets/history/task_history_log_pill.dart';
import '../widgets/history/task_history_skeleton.dart';
import '../widgets/shared/task_log_undo.dart';
import '../widgets/shared/task_scroll_page.dart';
import '../widgets/shared/task_top_bar.dart';

/// Task history: totals, an every-time strip and the log of every completion.
///
/// Route: `/maintenance/:taskId/history`
class TaskHistoryScreen extends ConsumerStatefulWidget {
  const TaskHistoryScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<TaskHistoryScreen> createState() => _TaskHistoryScreenState();
}

class _TaskHistoryScreenState extends ConsumerState<TaskHistoryScreen> {
  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.maintenance);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(taskDetailProvider(widget.taskId));
    await ref.read(taskHistoryProvider(widget.taskId).future);
  }

  Future<void> _logPastOne() async {
    final notifier = ref.read(taskDetailProvider(widget.taskId).notifier);
    final receipt = await context.push<CompletionReceipt>(
      AppRoutes.maintenanceCompleteTask.replaceFirst(':taskId', widget.taskId),
    );
    if (receipt == null || !mounted) return;
    TaskLogUndo.show(context, notifier: notifier, receipt: receipt);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(taskHistoryProvider(widget.taskId));
    final history = async.value;
    return Scaffold(
      backgroundColor: AuroraColors.paper,
      body: history != null
          ? _page(TaskHistoryBody(history: history), logPill: true)
          : async.hasError
          ? _error()
          : _page(const TaskHistorySkeleton()),
    );
  }

  Widget _page(Widget child, {bool logPill = false}) => TaskScrollPage(
    onRefresh: _refresh,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TaskTopBar(
          backLabel: 'Task',
          onBack: _back,
          trailing: logPill ? TaskHistoryLogPill(onTap: _logPastOne) : null,
        ),
        SizedBox(height: context.aurora.of(AuroraTasksB.headerAfterBar)),
        child,
      ],
    ),
  );

  Widget _error() => SafeArea(
    bottom: false,
    child: Column(
      children: [
        Padding(
          padding: context.aurora.symmetric(
            horizontal: AuroraSpacing.screenPadH,
            vertical: AuroraSpacing.screenPadTop,
          ),
          child: TaskTopBar(backLabel: 'Task', onBack: _back),
        ),
        Expanded(
          child: ErrorView(
            message: "Couldn't load this history.",
            onRetry: () => ref.invalidate(taskDetailProvider(widget.taskId)),
          ),
        ),
      ],
    ),
  );
}
