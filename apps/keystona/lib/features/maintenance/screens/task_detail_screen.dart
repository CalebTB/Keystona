import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_motion.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_tasks_b.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/maintenance_task.dart';
import '../models/task_detail.dart';
import '../models/task_log_draft.dart';
import '../models/task_parent.dart';
import '../providers/task_deletion.dart';
import '../providers/task_detail_provider.dart';
import '../services/task_dates.dart';
import '../services/task_detail_view.dart';
import '../services/task_format.dart';
import '../tasks_copy.dart';
import '../widgets/actions/task_quick_done.dart';
import '../widgets/actions/task_skip_sheet.dart';
import '../widgets/detail/task_detail_actions.dart';
import '../widgets/detail/task_detail_body.dart';
import '../widgets/detail/task_detail_skeleton.dart';
import '../widgets/shared/task_log_undo.dart';
import '../widgets/shared/task_scroll_page.dart';
import '../widgets/shared/task_text_action.dart';
import '../widgets/shared/task_top_bar.dart';

/// Task detail: when it is due, Mark done / Not now, what it is for, how to
/// do it, what you need, its history and schedule.
///
/// Route: `/maintenance/:taskId`
class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  /// The due date the task had before it was marked done here. It makes
  /// "3 days early" and Undo possible right after.
  DateTime? _dueBeforeDone;
  bool _busy = false;

  TaskDetailNotifier get _notifier =>
      ref.read(taskDetailProvider(widget.taskId).notifier);

  String _route(String template) =>
      template.replaceFirst(':taskId', widget.taskId);

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.maintenance);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(taskDetailProvider(widget.taskId));
    await ref.read(taskDetailProvider(widget.taskId).future);
  }

  void _edit(MaintenanceTask task) =>
      context.push(_route(AppRoutes.maintenanceEditTask), extra: task);

  Future<void> _markDone(MaintenanceTask task) async {
    if (_busy) return;
    setState(() => _busy = true);
    final before = task.dueDate;
    try {
      await TaskQuickDone.run(context, ref, task);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    _dueBeforeDone = before;
    ref.invalidate(taskDetailProvider(widget.taskId));
  }

  Future<void> _notNow(MaintenanceTask task) async {
    final acted = await TaskSkipSheet.show(context, ref, task);
    if (acted && mounted) {
      ref.invalidate(taskDetailProvider(widget.taskId));
    }
  }

  Future<void> _undoDone(TaskDetail detail) async {
    final notifier = _notifier;
    final receipt = CompletionReceipt(
      completionId: detail.completions.first.id,
      originalDueDate: _dueBeforeDone,
    );
    _dueBeforeDone = null;
    try {
      await notifier.undoCompletion(receipt);
    } catch (_) {
      if (mounted) {
        SnackbarService.showError(context, "Couldn't undo. Try again.");
      }
    }
  }

  Future<void> _addDetails() async {
    final notifier = _notifier;
    final receipt = await context.push<CompletionReceipt>(
      _route(AppRoutes.maintenanceCompleteTask),
    );
    if (receipt == null || !mounted) return;
    final next = ref.read(taskDetailProvider(widget.taskId)).value?.task;
    TaskLogUndo.show(
      context,
      notifier: notifier,
      receipt: receipt,
      subtitle: next == null || next.recurrence == RecurrenceType.none
          ? null
          : 'Next one is due ${TaskFormat.dateShort(next.dueDate)}',
    );
    context.push(_route(AppRoutes.maintenanceTaskHistory));
  }

  void _openParent(TaskParent parent) {
    final path = switch (parent.kind) {
      TaskParentKind.system => AppRoutes.homeSystemDetail.replaceFirst(
        ':systemId',
        parent.id ?? '',
      ),
      TaskParentKind.appliance => AppRoutes.homeApplianceDetail.replaceFirst(
        ':applianceId',
        parent.id ?? '',
      ),
      TaskParentKind.area => null,
    };
    if (path != null && parent.id != null) context.push(path);
  }

  Future<void> _delete() async {
    final notifier = _notifier;
    final taskId = widget.taskId;
    // The screen is gone by the time Undo is tapped: keep what it needs.
    final container = ProviderScope.containerOf(context);
    final toast = Navigator.of(context, rootNavigator: true).context;
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete this task?',
      message: "It leaves your tasks and its history goes with it.",
      confirmLabel: 'Delete task',
      onConfirm: () {},
    );
    if (confirmed != true || !mounted) return;
    try {
      await notifier.deleteTask();
    } catch (_) {
      if (mounted) {
        SnackbarService.showError(
          context,
          "Couldn't delete the task. Try again.",
        );
      }
      return;
    }
    if (!mounted) return;
    _back();
    if (!toast.mounted) return;
    SnackbarService.showUndo(
      toast,
      message: 'Task deleted',
      duration: AuroraDurations.undoDelete,
      onUndo: () => _restore(container, toast, taskId),
    );
  }

  /// Undo for [_delete]: brings the task back and refreshes every list.
  static Future<void> _restore(
    ProviderContainer container,
    BuildContext toast,
    String taskId,
  ) async {
    try {
      await TaskDeletion.restore(container, taskId);
    } catch (_) {
      if (toast.mounted) SnackbarService.showError(toast, TasksCopy.saveError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(taskDetailProvider(widget.taskId));
    final detail = async.value;
    return Scaffold(
      backgroundColor: AuroraColors.paper,
      body: detail != null
          ? _content(detail)
          : async.hasError
          ? _error()
          : _loading(),
    );
  }

  Widget _loading() => TaskScrollPage(
    onRefresh: _refresh,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TaskTopBar(backLabel: 'Tasks', onBack: _back),
        SizedBox(height: context.aurora.of(AuroraSpacing.space7)),
        const TaskDetailSkeleton(),
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
          child: TaskTopBar(backLabel: 'Tasks', onBack: _back),
        ),
        Expanded(
          child: ErrorView(
            message: "Couldn't load this task.",
            onRetry: () => ref.invalidate(taskDetailProvider(widget.taskId)),
          ),
        ),
      ],
    ),
  );

  Widget _content(TaskDetail detail) {
    final today = TaskDates.dateOnly(DateTime.now());
    final view = TaskDetailView.of(
      detail,
      today: today,
      dueBeforeDone: _dueBeforeDone,
    );
    final parent = detail.parent;
    return TaskScrollPage(
      onRefresh: _refresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TaskTopBar(
            backLabel: 'Tasks',
            onBack: _back,
            trailing: TaskTextAction(
              label: 'Edit',
              onTap: () => _edit(detail.task),
            ),
          ),
          SizedBox(height: context.aurora.of(AuroraTasksB.headerAfterBar)),
          TaskDetailBody(
            detail: detail,
            view: view,
            today: today,
            busy: _busy,
            actions: TaskDetailActions(
              onMarkDone: () => _markDone(detail.task),
              onNotNow: () => _notNow(detail.task),
              onAddDetails: _addDetails,
              onUndo: () => _undoDone(detail),
              onOpenHistory: () =>
                  context.push(_route(AppRoutes.maintenanceTaskHistory)),
              onDelete: _delete,
              onEdit: () => _edit(detail.task),
              onOpenParent: parent == null || parent.id == null
                  ? null
                  : () => _openParent(parent),
            ),
          ),
        ],
      ),
    );
  }
}
