import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../models/maintenance_task.dart';
import '../models/task_completion.dart';
import '../models/task_detail.dart';
import '../providers/task_detail_provider.dart';
import '../widgets/task_detail_skeleton.dart';

/// Full Task Detail screen.
///
/// Route: `/maintenance/:taskId`
///
/// Adaptive layout:
/// - iOS: [CupertinoPageScaffold] with [CupertinoNavigationBar]
/// - Android: [Scaffold] with [AppBar]
///
/// Displays all task fields, completion history, and action buttons
/// (Quick Complete, Detailed Complete [stub for #33], Skip).
class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return isIOS
        ? _IOSDetailLayout(taskId: taskId)
        : _AndroidDetailLayout(taskId: taskId);
  }
}

// ── iOS layout ────────────────────────────────────────────────────────────────

class _IOSDetailLayout extends ConsumerWidget {
  const _IOSDetailLayout({required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(taskDetailProvider(taskId));

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        previousPageTitle: 'Tasks',
        middle: detailState.maybeWhen(
          data: (d) => Text(
            d.task.name,
            overflow: TextOverflow.ellipsis,
          ),
          orElse: () => const Text('Task'),
        ),
        // Edit button — wired by issue #34.
        trailing: detailState.maybeWhen(
          data: (_) => CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: null, // TODO(#34): navigate to edit screen
            child: const Text('Edit'),
          ),
          orElse: () => null,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: _DetailStateBody(taskId: taskId, detailState: detailState),
      ),
    );
  }
}

// ── Android layout ────────────────────────────────────────────────────────────

class _AndroidDetailLayout extends ConsumerWidget {
  const _AndroidDetailLayout({required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(taskDetailProvider(taskId));

    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      appBar: AppBar(
        title: detailState.maybeWhen(
          data: (d) => Text(d.task.name, style: AppTextStyles.h3),
          orElse: () => Text('Task', style: AppTextStyles.h3),
        ),
        backgroundColor: AppColors.warmOffWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          // Edit button — wired by issue #34.
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: null, // TODO(#34): navigate to edit screen
          ),
        ],
      ),
      body: _DetailStateBody(taskId: taskId, detailState: detailState),
    );
  }
}

// ── State switcher ────────────────────────────────────────────────────────────

class _DetailStateBody extends ConsumerWidget {
  const _DetailStateBody({
    required this.taskId,
    required this.detailState,
  });

  final String taskId;
  final AsyncValue<TaskDetail> detailState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return detailState.when(
      loading: () => const TaskDetailSkeleton(),
      error: (e, _) => ErrorView(
        message: "Couldn't load task.",
        onRetry: () => ref.invalidate(taskDetailProvider(taskId)),
      ),
      data: (detail) => _DetailContent(taskId: taskId, detail: detail),
    );
  }
}

// ── Main content ──────────────────────────────────────────────────────────────

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.taskId, required this.detail});

  final String taskId;
  final TaskDetail detail;

  @override
  Widget build(BuildContext context) {
    final task = detail.task;
    final isDone = task.status == TaskStatus.completed ||
        task.status == TaskStatus.skipped;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: AppPadding.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSizes.sm),

                // ── Status / Priority / Difficulty badges ───────────────────
                _BadgeRow(task: task),
                const SizedBox(height: AppSizes.lg),

                // ── Scheduling metadata ─────────────────────────────────────
                _MetaRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Due',
                  value: DateFormat('MMMM d, y').format(task.dueDate.toLocal()),
                ),
                if (task.recurrence != RecurrenceType.none) ...[
                  const SizedBox(height: AppSizes.sm),
                  _MetaRow(
                    icon: Icons.repeat,
                    label: 'Recurrence',
                    value: task.recurrence.label,
                  ),
                ],
                if (task.estimatedMinutes != null) ...[
                  const SizedBox(height: AppSizes.sm),
                  _MetaRow(
                    icon: Icons.schedule_outlined,
                    label: 'Estimated',
                    value: _formatMinutes(task.estimatedMinutes!),
                  ),
                ],
                if (task.climateAdjusted) ...[
                  const SizedBox(height: AppSizes.sm),
                  _MetaRow(
                    icon: Icons.thermostat_outlined,
                    label: 'Climate',
                    value: 'Adjusted for your climate zone',
                  ),
                ],

                // ── Skip reason ────────────────────────────────────────────
                if (task.status == TaskStatus.skipped &&
                    task.skipReason != null &&
                    task.skipReason!.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.sm),
                  _MetaRow(
                    icon: Icons.skip_next_outlined,
                    label: 'Skipped',
                    value: task.skipReason!,
                    valueColor: AppColors.textSecondary,
                  ),
                ],

                const SizedBox(height: AppSizes.lg),
                const _SectionDivider(),
                const SizedBox(height: AppSizes.lg),

                // ── DIY vs Pro chip ─────────────────────────────────────────
                _DiyProChip(diyOrPro: task.diyOrPro),
                const SizedBox(height: AppSizes.lg),

                // ── Linked system / appliance ───────────────────────────────
                if (task.linkedSystemId != null) ...[
                  _LinkedEntityChip(
                    icon: Icons.home_repair_service_outlined,
                    label: task.linkedSystemName ?? 'Linked System',
                    onTap: () {
                      final path = AppRoutes.homeSystemDetail.replaceFirst(
                        ':systemId',
                        task.linkedSystemId!,
                      );
                      context.push(path);
                    },
                  ),
                  const SizedBox(height: AppSizes.sm),
                ],
                if (task.linkedApplianceId != null) ...[
                  _LinkedEntityChip(
                    icon: Icons.kitchen_outlined,
                    label: task.linkedApplianceName ?? 'Linked Appliance',
                    onTap: () {
                      final path = AppRoutes.homeApplianceDetail.replaceFirst(
                        ':applianceId',
                        task.linkedApplianceId!,
                      );
                      context.push(path);
                    },
                  ),
                  const SizedBox(height: AppSizes.sm),
                ],
                if (task.linkedSystemId != null ||
                    task.linkedApplianceId != null) ...[
                  const SizedBox(height: AppSizes.sm),
                  const _SectionDivider(),
                  const SizedBox(height: AppSizes.lg),
                ],

                // ── Description ─────────────────────────────────────────────
                if (task.description != null &&
                    task.description!.isNotEmpty) ...[
                  _SectionHeader(title: 'Description'),
                  const SizedBox(height: AppSizes.sm),
                  Text(task.description!, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: AppSizes.lg),
                  const _SectionDivider(),
                  const SizedBox(height: AppSizes.lg),
                ],

                // ── Instructions ─────────────────────────────────────────────
                if (task.instructions != null &&
                    task.instructions!.isNotEmpty) ...[
                  _SectionHeader(
                    title: task.taskOrigin == TaskOrigin.systemGenerated ||
                            task.taskOrigin == TaskOrigin.climateTriggered ||
                            task.taskOrigin == TaskOrigin.seasonal
                        ? 'How To Do It'
                        : 'Instructions',
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(task.instructions!, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: AppSizes.lg),
                  const _SectionDivider(),
                  const SizedBox(height: AppSizes.lg),
                ],

                // ── Tools needed ────────────────────────────────────────────
                if (task.toolsNeeded.isNotEmpty) ...[
                  _SectionHeader(title: 'Tools Needed'),
                  const SizedBox(height: AppSizes.sm),
                  _BulletList(items: task.toolsNeeded),
                  const SizedBox(height: AppSizes.lg),
                ],

                // ── Supplies needed ─────────────────────────────────────────
                if (task.suppliesNeeded.isNotEmpty) ...[
                  _SectionHeader(title: 'Supplies Needed'),
                  const SizedBox(height: AppSizes.sm),
                  _BulletList(items: task.suppliesNeeded),
                  const SizedBox(height: AppSizes.lg),
                ],

                if (task.toolsNeeded.isNotEmpty ||
                    task.suppliesNeeded.isNotEmpty) ...[
                  const _SectionDivider(),
                  const SizedBox(height: AppSizes.lg),
                ],

                // ── Completion history ──────────────────────────────────────
                _SectionHeader(title: 'Completion History'),
                const SizedBox(height: AppSizes.md),
                _CompletionHistorySection(
                  completions: detail.completions,
                ),
                const SizedBox(height: AppSizes.xl),
              ],
            ),
          ),
        ),

        // ── Sticky action buttons ───────────────────────────────────────────
        _BottomActions(taskId: taskId, isDone: isDone),
      ],
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    return rem == 0 ? '${hours}h' : '${hours}h ${rem}min';
  }
}

// ── Badge row ─────────────────────────────────────────────────────────────────

class _BadgeRow extends StatelessWidget {
  const _BadgeRow({required this.task});

  final MaintenanceTask task;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.sm,
      runSpacing: AppSizes.xs,
      children: [
        _StatusBadge(status: task.status),
        _PriorityBadge(priority: task.priority),
        _DifficultyBadge(difficulty: task.difficulty),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      TaskStatus.scheduled => ('Scheduled', AppColors.statusScheduled),
      TaskStatus.due => ('Due', AppColors.statusDueToday),
      TaskStatus.overdue => ('Overdue', AppColors.statusOverdue),
      TaskStatus.completed => ('Completed', AppColors.statusCompleted),
      TaskStatus.skipped => ('Skipped', AppColors.textSecondary),
    };
    return _Chip(label: label, color: color);
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (priority) {
      TaskPriority.critical => ('Critical', AppColors.statusOverdue),
      TaskPriority.high => ('High Priority', AppColors.statusDueToday),
      TaskPriority.medium => ('Medium', AppColors.info),
      TaskPriority.low => ('Low', AppColors.textSecondary),
    };
    return _Chip(label: label, color: color);
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});

  final TaskDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final label = switch (difficulty) {
      TaskDifficulty.easy => 'Easy',
      TaskDifficulty.moderate => 'Moderate',
      TaskDifficulty.involved => 'Involved',
      TaskDifficulty.professional => 'Pro Required',
    };
    return _Chip(label: label, color: AppColors.deepNavy);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }
}

// ── Metadata row ──────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSizes.sm),
        Text(
          '$label:  ',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── DIY vs Pro chip ───────────────────────────────────────────────────────────

class _DiyProChip extends StatelessWidget {
  const _DiyProChip({required this.diyOrPro});

  final DiyOrPro diyOrPro;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (diyOrPro) {
      DiyOrPro.diy => (
          Icons.handyman_outlined,
          'DIY Friendly',
          AppColors.success,
        ),
      DiyOrPro.either => (
          Icons.handshake_outlined,
          'DIY or Professional',
          AppColors.info,
        ),
      DiyOrPro.professional => (
          Icons.engineering_outlined,
          'Hire a Professional',
          AppColors.warning,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: AppRadius.md,
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSizes.sm),
          Text(
            label,
            style: AppTextStyles.bodyMediumSemibold.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ── Linked entity chip ────────────────────────────────────────────────────────

class _LinkedEntityChip extends StatelessWidget {
  const _LinkedEntityChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: AppSizes.sm),
            Text(label, style: AppTextStyles.bodySmall),
            const SizedBox(width: AppSizes.xs),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section helpers ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: AppTextStyles.labelSmall.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.divider);
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5, right: 8),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(item, style: AppTextStyles.bodyMedium),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Completion history ────────────────────────────────────────────────────────

class _CompletionHistorySection extends StatelessWidget {
  const _CompletionHistorySection({required this.completions});

  final List<TaskCompletion> completions;

  @override
  Widget build(BuildContext context) {
    if (completions.isEmpty) {
      return _CompletionHistoryEmpty();
    }

    return Column(
      children: completions
          .map((c) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                child: _CompletionRow(completion: c),
              ))
          .toList(),
    );
  }
}

class _CompletionHistoryEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.checklist_outlined,
              size: 40,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'No completions yet',
              style: AppTextStyles.bodyMediumSemibold.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete this task to start tracking history.',
              style: AppTextStyles.bodySmall.copyWith(
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

class _CompletionRow extends StatelessWidget {
  const _CompletionRow({required this.completion});

  final TaskCompletion completion;

  @override
  Widget build(BuildContext context) {
    final totalCost = (completion.serviceCost ?? 0) +
        (completion.materialsCost ?? 0);

    return Container(
      padding: AppPadding.card,
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.success.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 16,
                color: AppColors.success,
              ),
              const SizedBox(width: AppSizes.xs),
              Text(
                DateFormat('MMMM d, y')
                    .format(completion.completedDate.toLocal()),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (totalCost > 0)
                Text(
                  '\$${totalCost.toStringAsFixed(2)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          if (completion.completedBy == 'contractor' &&
              completion.contractorName != null) ...[
            const SizedBox(height: 4),
            Text(
              completion.contractorName!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (completion.notes != null && completion.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              completion.notes!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Bottom action buttons ─────────────────────────────────────────────────────

class _BottomActions extends ConsumerStatefulWidget {
  const _BottomActions({required this.taskId, required this.isDone});

  final String taskId;
  final bool isDone;

  @override
  ConsumerState<_BottomActions> createState() => _BottomActionsState();
}

class _BottomActionsState extends ConsumerState<_BottomActions> {
  bool _isCompleting = false;
  bool _isSkipping = false;

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.md,
        AppSizes.screenPadding,
        AppSizes.screenPadding +
            MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isIOS ? CupertinoColors.systemBackground : AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick Complete — primary CTA.
          _QuickCompleteButton(
            isLoading: _isCompleting,
            isDisabled: widget.isDone,
            onPressed: widget.isDone ? null : _handleQuickComplete,
          ),
          const SizedBox(height: AppSizes.sm),

          Row(
            children: [
              // Detailed Complete — stub for #33.
              Expanded(
                child: _OutlinedActionButton(
                  label: 'Detailed Complete',
                  isDisabled: widget.isDone,
                  onPressed: widget.isDone
                      ? null
                      : () {
                          // TODO(#33): navigate to detailed completion form.
                          // context.push(AppRoutes.maintenanceCompleteTask
                          //     .replaceFirst(':taskId', widget.taskId));
                        },
                ),
              ),
              const SizedBox(width: AppSizes.sm),

              // Skip.
              Expanded(
                child: _SkipButton(
                  isLoading: _isSkipping,
                  isDisabled: widget.isDone,
                  onPressed: widget.isDone ? null : _handleSkip,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleQuickComplete() async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);

    String? completionId;
    try {
      completionId = await ref
          .read(taskDetailProvider(widget.taskId).notifier)
          .quickCompleteTask();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text("Couldn't complete task. Try again."),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      setState(() => _isCompleting = false);
      return;
    }

    if (!mounted) return;
    setState(() => _isCompleting = false);

    // Show undo snackbar — 5 seconds.
    final capturedId = completionId;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Task completed!'),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppColors.goldAccent,
            onPressed: () {
              ref
                  .read(taskDetailProvider(widget.taskId).notifier)
                  .undoQuickComplete(capturedId);
            },
          ),
        ),
      );
  }

  Future<void> _handleSkip() async {
    if (_isSkipping) return;

    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final reason = await _SkipReasonSheet.show(context, isIOS: isIOS);

    // null means user cancelled; empty string is a valid "no reason given".
    if (reason == null || !mounted) return;

    setState(() => _isSkipping = true);
    try {
      await ref
          .read(taskDetailProvider(widget.taskId).notifier)
          .skipTask(reason);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text("Couldn't skip task. Try again."),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _isSkipping = false);
    }
  }
}

// ── Action button variants ─────────────────────────────────────────────────────

class _QuickCompleteButton extends StatelessWidget {
  const _QuickCompleteButton({
    required this.isLoading,
    required this.isDisabled,
    required this.onPressed,
  });

  final bool isLoading;
  final bool isDisabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDisabled ? AppColors.gray300 : AppColors.deepNavy,
          foregroundColor: AppColors.textInverse,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textInverse,
                ),
              )
            : Text(
                isDisabled ? 'Already Done' : 'Quick Complete',
                style: AppTextStyles.bodyMediumSemibold.copyWith(
                  color: AppColors.textInverse,
                ),
              ),
      ),
    );
  }
}

class _OutlinedActionButton extends StatelessWidget {
  const _OutlinedActionButton({
    required this.label,
    required this.isDisabled,
    required this.onPressed,
  });

  final String label;
  final bool isDisabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor:
              isDisabled ? AppColors.textDisabled : AppColors.deepNavy,
          side: BorderSide(
            color: isDisabled ? AppColors.border : AppColors.deepNavy,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isDisabled ? AppColors.textDisabled : AppColors.deepNavy,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({
    required this.isLoading,
    required this.isDisabled,
    required this.onPressed,
  });

  final bool isLoading;
  final bool isDisabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextButton(
        onPressed: isLoading || isDisabled ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.error,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.md,
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.error,
                ),
              )
            : Text(
                'Skip',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDisabled ? AppColors.textDisabled : AppColors.error,
                ),
              ),
      ),
    );
  }
}

// ── Skip reason bottom sheet ──────────────────────────────────────────────────

/// Shows a bottom sheet that captures the reason for skipping a task.
///
/// Returns:
/// - `null`  — user cancelled (no skip should occur)
/// - `""`    — user confirmed with no reason
/// - `"..."`  — user confirmed with a typed reason
class _SkipReasonSheet extends ConsumerStatefulWidget {
  const _SkipReasonSheet();

  static Future<String?> show(
    BuildContext context, {
    required bool isIOS,
  }) {
    if (isIOS) {
      return showCupertinoModalPopup<String>(
        context: context,
        builder: (_) => Material(
          type: MaterialType.transparency,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: const _SkipReasonSheet(),
          ),
        ),
      );
    }
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const _SkipReasonSheet(),
      ),
    );
  }

  @override
  ConsumerState<_SkipReasonSheet> createState() => _SkipReasonSheetState();
}

class _SkipReasonSheetState extends ConsumerState<_SkipReasonSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.lg,
        AppSizes.screenPadding,
        AppSizes.screenPadding +
            MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar.
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),

          Text('Skip Task', style: AppTextStyles.h3),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Reason (optional)',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.md),

          TextField(
            controller: _controller,
            maxLines: 3,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g. Already done by contractor',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textDisabled,
              ),
              border: OutlineInputBorder(
                borderRadius: AppRadius.md,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.md,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.md,
                borderSide: const BorderSide(color: AppColors.deepNavy),
              ),
              filled: true,
              fillColor: AppColors.gray50,
              contentPadding: const EdgeInsets.all(AppSizes.md),
            ),
          ),
          const SizedBox(height: AppSizes.md),

          if (isIOS) ...[
            CupertinoButton.filled(
              onPressed: _confirm,
              child: const Text('Skip Task'),
            ),
            CupertinoButton(
              onPressed: _cancel,
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.md,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.bodyMediumSemibold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.textInverse,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.md,
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Skip Task',
                      style: AppTextStyles.bodyMediumSemibold.copyWith(
                        color: AppColors.textInverse,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _confirm() {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      Navigator.of(context, rootNavigator: true).pop(_controller.text.trim());
    } else {
      context.pop(_controller.text.trim());
    }
  }

  void _cancel() {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      Navigator.of(context, rootNavigator: true).pop();
    } else {
      context.pop();
    }
  }
}
