import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/supabase_service.dart';
import '../../maintenance/models/maintenance_task.dart';
import '../../maintenance/providers/maintenance_tasks_provider.dart';

/// Displays and manages maintenance tasks linked to a specific system or
/// appliance. Accessible from the Tasks quick-action cell on detail screens.
class ItemTasksScreen extends ConsumerStatefulWidget {
  const ItemTasksScreen({
    super.key,
    this.systemId,
    this.applianceId,
    required this.itemName,
  });

  final String? systemId;
  final String? applianceId;
  final String itemName;

  @override
  ConsumerState<ItemTasksScreen> createState() => _ItemTasksScreenState();
}

class _ItemTasksScreenState extends ConsumerState<ItemTasksScreen> {
  // ── Helpers ────────────────────────────────────────────────────────────────

  List<MaintenanceTask> _filterTasks(List<MaintenanceTask> all) {
    final linked = all.where((t) {
      if (widget.systemId != null && t.linkedSystemId == widget.systemId) {
        return true;
      }
      if (widget.applianceId != null &&
          t.linkedApplianceId == widget.applianceId) {
        return true;
      }
      return false;
    }).toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    linked.sort((a, b) {
      // Overdue first.
      final aOverdue = _isOverdue(a, today);
      final bOverdue = _isOverdue(b, today);
      if (aOverdue && !bOverdue) return -1;
      if (!aOverdue && bOverdue) return 1;
      return a.dueDate.compareTo(b.dueDate);
    });

    return linked;
  }

  bool _isOverdue(MaintenanceTask t, DateTime today) {
    if (t.status == TaskStatus.completed || t.status == TaskStatus.skipped) {
      return false;
    }
    return t.status == TaskStatus.overdue || t.dueDate.toLocal().isBefore(today);
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(MaintenanceTask task) async {
    HapticFeedback.lightImpact();
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    bool confirmed = false;

    if (isIOS) {
      final result = await showCupertinoDialog<bool>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Remove Task?'),
          content: const Text(
            'This task will be permanently removed.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop(false),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop(true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      confirmed = result ?? false;
    } else {
      final result = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Remove Task?'),
          content: const Text(
            'This task will be permanently removed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.error),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      confirmed = result ?? false;
    }

    if (!confirmed || !mounted) return;

    try {
      await SupabaseService.client
          .from('maintenance_tasks')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', task.id);
      if (!mounted) return;
      ref.invalidate(maintenanceTasksProvider);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't remove task. Try again."),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _addTask() {
    context.push(
      '/maintenance/create',
      extra: <String, dynamic>{
        if (widget.systemId != null) 'linked_system_id': widget.systemId,
        if (widget.applianceId != null)
          'linked_appliance_id': widget.applianceId,
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final tasksAsync = ref.watch(maintenanceTasksProvider);

    final tasks = tasksAsync.when(
      loading: () => null,
      error: (_, _) => <MaintenanceTask>[],
      data: _filterTasks,
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(
            widget.itemName,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: _buildBody(context, tasks, isIOS: true),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      appBar: AppBar(
        backgroundColor: AppColors.warmOffWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(widget.itemName, style: AppTextStyles.h3),
      ),
      floatingActionButton: tasks != null && tasks.isNotEmpty
          ? FloatingActionButton(
              onPressed: _addTask,
              backgroundColor: AppColors.deepNavy,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: _buildBody(context, tasks, isIOS: false),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<MaintenanceTask>? tasks, {
    required bool isIOS,
  }) {
    if (tasks == null) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }

    if (tasks.isEmpty) {
      return Stack(
        children: [
          _EmptyState(onAdd: _addTask),
          if (isIOS)
            Positioned(
              bottom: AppSizes.lg + MediaQuery.of(context).padding.bottom,
              right: AppSizes.md,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _addTask,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.deepNavy,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x331A2B4A),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return Stack(
      children: [
        ListView.builder(
          padding: EdgeInsets.fromLTRB(
            AppSizes.screenPadding,
            AppSizes.md,
            AppSizes.screenPadding,
            AppSizes.xxl + MediaQuery.of(context).padding.bottom,
          ),
          itemCount: tasks.length,
          itemBuilder: (context, index) => _ItemTaskRow(
            task: tasks[index],
            onDelete: () => _confirmDelete(tasks[index]),
            onEdit: () =>
                context.push('/maintenance/${tasks[index].id}'),
          ),
        ),
        if (isIOS)
          Positioned(
            bottom: AppSizes.lg + MediaQuery.of(context).padding.bottom,
            right: AppSizes.md,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _addTask,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.deepNavy,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x331A2B4A),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppPadding.screen,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.task_alt_outlined,
              size: AppSizes.iconXl,
              color: AppColors.gray400,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'No tasks yet',
              style: AppTextStyles.bodyMediumSemibold,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              'Tap + to add a task linked to this item.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Task row ───────────────────────────────────────────────────────────────────

class _ItemTaskRow extends StatelessWidget {
  const _ItemTaskRow({
    required this.task,
    required this.onDelete,
    required this.onEdit,
  });

  final MaintenanceTask task;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final accentColor = _accentColor(task, today);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.card,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent stripe
              Container(width: 4, color: accentColor),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        style: AppTextStyles.bodyMediumSemibold,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _StatusBadge(status: task.status),
                          if (task.recurrence != RecurrenceType.none) ...[
                            const SizedBox(width: 6),
                            _RecurrenceBadge(recurrence: task.recurrence),
                          ],
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM d').format(task.dueDate),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Right: action buttons
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _IconBtn(
                      icon: Icons.edit_outlined,
                      color: AppColors.textSecondary,
                      onTap: onEdit,
                    ),
                    _IconBtn(
                      icon: Icons.delete_outline,
                      color: AppColors.error,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onDelete();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _accentColor(MaintenanceTask task, DateTime today) {
  if (task.status == TaskStatus.completed ||
      task.status == TaskStatus.skipped) {
    return AppColors.olive;
  }
  if (task.status == TaskStatus.overdue ||
      task.dueDate.toLocal().isBefore(today)) {
    return AppColors.accent;
  }
  final sevenDays = today.add(const Duration(days: 7));
  if (task.dueDate.toLocal().isBefore(sevenDays)) {
    return AppColors.amber;
  }
  return AppColors.slate;
}

// ── Status badge ───────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      TaskStatus.overdue => (AppColors.accentDim, AppColors.accent, 'Overdue'),
      TaskStatus.due => (AppColors.amberDim, AppColors.amber, 'Due'),
      TaskStatus.scheduled =>
        (AppColors.warmFill, AppColors.textSecondary, 'Scheduled'),
      TaskStatus.completed =>
        (AppColors.oliveDim, AppColors.olive, 'Completed'),
      TaskStatus.skipped =>
        (AppColors.gray200, AppColors.gray500, 'Skipped'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radiusXs),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

// ── Recurrence badge ───────────────────────────────────────────────────────────

class _RecurrenceBadge extends StatelessWidget {
  const _RecurrenceBadge({required this.recurrence});
  final RecurrenceType recurrence;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.slateDim,
        borderRadius: BorderRadius.circular(AppSizes.radiusXs),
      ),
      child: Text(
        recurrence.label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.slate,
        ),
      ),
    );
  }
}

// ── Icon button ────────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}
