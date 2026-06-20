import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
import '../../documents/models/document.dart';
import '../../documents/providers/documents_provider.dart';


/// Task Detail screen — "Ledger" layout.
///
/// Route: `/maintenance/:taskId`
class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return isIOS
        ? _IOSLayout(taskId: taskId)
        : _AndroidLayout(taskId: taskId);
  }
}

// ── iOS layout ────────────────────────────────────────────────────────────────

class _IOSLayout extends ConsumerWidget {
  const _IOSLayout({required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(taskDetailProvider(taskId));
    return CupertinoPageScaffold(
      backgroundColor: AppColors.warmOffWhite,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.warmOffWhite,
        border: null,
        previousPageTitle: 'Tasks',
        middle: const SizedBox.shrink(),
        trailing: state.maybeWhen(
          data: (detail) => CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => context.push(
              AppRoutes.maintenanceEditTask
                  .replaceFirst(':taskId', taskId),
              extra: detail.task,
            ),
            child: const Text('Edit'),
          ),
          orElse: () => null,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: _StateBody(taskId: taskId, state: state),
      ),
    );
  }
}

// ── Android layout ────────────────────────────────────────────────────────────

class _AndroidLayout extends ConsumerWidget {
  const _AndroidLayout({required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(taskDetailProvider(taskId));
    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      appBar: AppBar(
        backgroundColor: AppColors.warmOffWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const SizedBox.shrink(),
        actions: [
          state.maybeWhen(
            data: (detail) => TextButton(
              onPressed: () => context.push(
                AppRoutes.maintenanceEditTask
                    .replaceFirst(':taskId', taskId),
                extra: detail.task,
              ),
              child: Text(
                'Edit',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.accent),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: _StateBody(taskId: taskId, state: state),
    );
  }
}

// ── State switcher ────────────────────────────────────────────────────────────

class _StateBody extends ConsumerWidget {
  const _StateBody({required this.taskId, required this.state});
  final String taskId;
  final AsyncValue<TaskDetail> state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return state.when(
      loading: () => const TaskDetailSkeleton(),
      error: (e, _) => ErrorView(
        message: "Couldn't load task.",
        onRetry: () => ref.invalidate(taskDetailProvider(taskId)),
      ),
      data: (detail) => _LedgerBody(taskId: taskId, detail: detail),
    );
  }
}

// ── Ledger body ───────────────────────────────────────────────────────────────

class _LedgerBody extends StatelessWidget {
  const _LedgerBody({required this.taskId, required this.detail});
  final String taskId;
  final TaskDetail detail;

  @override
  Widget build(BuildContext context) {
    final task = detail.task;
    final completions = detail.completions;
    final isDone = task.status == TaskStatus.completed ||
        task.status == TaskStatus.skipped;

    // Only show action bar when the task is actually due — tasks scheduled
    // far in the future should be view-only so completing them doesn't
    // create an infinite chain of future occurrences.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isActionable = !isDone &&
        !task.dueDate.toLocal().isAfter(today.add(const Duration(days: 30)));

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              // ── Header ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _LedgerHeader(task: task),
              ),

              // ── Stat strip ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _StatStrip(task: task, completions: completions),
              ),

              // ── Instructions (collapsed) ──────────────────────────────────
              SliverToBoxAdapter(
                child: _InstructionsRow(task: task),
              ),

              // ── Service history ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: _ServiceHistory(task: task, completions: completions),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),

        // ── Action bar — only for due/overdue tasks ────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
          child: isActionable
              ? _BottomActions(taskId: taskId, isDone: isDone)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _LedgerHeader extends StatelessWidget {
  const _LedgerHeader({required this.task});
  final MaintenanceTask task;

  String _eyebrow() {
    final cat = task.category.toUpperCase();
    final system = task.linkedSystemName;
    if (system != null && system.isNotEmpty) {
      return '$cat · ${system.toUpperCase()}';
    }
    return cat;
  }

  @override
  Widget build(BuildContext context) {
    final overdueDays = _overdueDays(task);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Eyebrow + Title ──────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _eyebrow(),
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.gray500,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  task.name.endsWith('.')
                      ? task.name
                      : '${task.name}.',
                  style: GoogleFonts.fraunces(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.1,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // ── Status badge ─────────────────────────────────────────────────
          if (overdueDays != null) ...[
            const SizedBox(width: 12),
            _OverdueBadge(days: overdueDays),
          ] else if (task.status == TaskStatus.completed) ...[
            const SizedBox(width: 12),
            _DoneBadge(),
          ] else if (task.status == TaskStatus.scheduled ||
              task.status == TaskStatus.due) ...[
            const SizedBox(width: 12),
            _DueBadge(task: task),
          ],
        ],
      ),
    );
  }

  static int? _overdueDays(MaintenanceTask task) {
    if (task.status == TaskStatus.completed ||
        task.status == TaskStatus.skipped) {
      return null;
    }
    final now = DateTime.now();
    final dueLocal = task.dueDate.toLocal();
    if (dueLocal.isBefore(DateTime(now.year, now.month, now.day))) {
      return now.difference(dueLocal).inDays;
    }
    if (task.status == TaskStatus.overdue) return 0;
    return null;
  }
}

class _OverdueBadge extends StatelessWidget {
  const _OverdueBadge({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accentDim,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withAlpha(60)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            days == 0 ? 'Due' : '${days}d',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'OVERDUE',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.oliveDim,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.olive.withAlpha(60)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, color: AppColors.olive, size: 18),
          const SizedBox(height: 2),
          Text(
            'DONE',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AppColors.olive,
            ),
          ),
        ],
      ),
    );
  }
}

class _DueBadge extends StatelessWidget {
  const _DueBadge({required this.task});
  final MaintenanceTask task;

  @override
  Widget build(BuildContext context) {
    final daysUntil = task.dueDate
        .toLocal()
        .difference(DateTime.now())
        .inDays
        .abs();
    final label = task.status == TaskStatus.due ? 'TODAY' : '${daysUntil}d';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.slateDim,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.slate.withAlpha(60)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.ibmPlexMono(
              fontSize: task.status == TaskStatus.due ? 12 : 18,
              fontWeight: FontWeight.w700,
              color: AppColors.slate,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            task.status == TaskStatus.due ? 'DUE' : 'DAYS',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AppColors.slate,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat strip ────────────────────────────────────────────────────────────────

class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.task, required this.completions});
  final MaintenanceTask task;
  final List<TaskCompletion> completions;

  String _spentLabel() {
    final total = completions.fold<double>(
      0,
      (s, c) => s + (c.serviceCost ?? 0) + (c.materialsCost ?? 0),
    );
    if (total == 0) return '\$0';
    if (total >= 1000) return '\$${(total / 1000).toStringAsFixed(1)}k';
    return '\$${total.toInt()}';
  }

  String _cycleLabel() => switch (task.recurrence) {
        RecurrenceType.none => '—',
        RecurrenceType.weekly => '7d',
        RecurrenceType.biweekly => '14d',
        RecurrenceType.monthly => '30d',
        RecurrenceType.quarterly => '90d',
        RecurrenceType.biannual => '180d',
        RecurrenceType.annual => '1yr',
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          _StatCell(value: '${completions.length}', label: 'DONE'),
          const SizedBox(width: 8),
          _StatCell(value: _spentLabel(), label: 'SPENT'),
          const SizedBox(width: 8),
          _StatCell(value: _cycleLabel(), label: 'CYCLE'),
          const SizedBox(width: 8),
          _StatCell(
            value: '${completions.length}',
            label: 'STREAK',
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Instructions row (collapsible) ────────────────────────────────────────────

class _InstructionsRow extends StatefulWidget {
  const _InstructionsRow({required this.task});
  final MaintenanceTask task;

  @override
  State<_InstructionsRow> createState() => _InstructionsRowState();
}

class _InstructionsRowState extends State<_InstructionsRow> {
  bool _expanded = false;

  String _summaryLine() {
    final parts = <String>[];
    if (widget.task.estimatedMinutes != null) {
      final m = widget.task.estimatedMinutes!;
      parts.add(m < 60 ? '$m min' : '${m ~/ 60}h');
    }
    parts.add(switch (widget.task.difficulty) {
      TaskDifficulty.easy => 'easy',
      TaskDifficulty.moderate => 'moderate',
      TaskDifficulty.involved => 'involved',
      TaskDifficulty.professional => 'pro required',
    });
    parts.add(switch (widget.task.diyOrPro) {
      DiyOrPro.diy => 'DIY',
      DiyOrPro.either => 'DIY/PRO',
      DiyOrPro.professional => 'hire PRO',
    });
    return parts.join(' · ');
  }

  String _headerLine() {
    final parts = <String>['Instructions'];
    if (widget.task.toolsNeeded.isNotEmpty) parts.add('tools');
    if (widget.task.suppliesNeeded.isNotEmpty) parts.add('supplies');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = (widget.task.description != null &&
            widget.task.description!.isNotEmpty) ||
        (widget.task.instructions != null &&
            widget.task.instructions!.isNotEmpty) ||
        widget.task.toolsNeeded.isNotEmpty ||
        widget.task.suppliesNeeded.isNotEmpty;

    if (!hasContent) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Collapsed header row ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.accentDim,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(
                        _expanded ? Icons.remove : Icons.add,
                        size: 16,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _headerLine(),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _expanded
                                ? 'Tap to collapse'
                                : 'Tap to expand · ${_summaryLine()}',
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Chevron
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Expandable content ──────────────────────────────────────
              ClipRect(
                child: AnimatedAlign(
                  alignment: Alignment.topCenter,
                  heightFactor: _expanded ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1, color: AppColors.divider),
                        const SizedBox(height: 12),
                        if (widget.task.description != null &&
                            widget.task.description!.isNotEmpty) ...[
                          Text(
                            widget.task.description!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (widget.task.instructions != null &&
                            widget.task.instructions!.isNotEmpty) ...[
                          _InstructionLabel('HOW TO DO IT'),
                          const SizedBox(height: 6),
                          Text(
                            widget.task.instructions!,
                            style: AppTextStyles.bodySmall
                                .copyWith(height: 1.6),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (widget.task.toolsNeeded.isNotEmpty) ...[
                          _InstructionLabel('TOOLS'),
                          const SizedBox(height: 6),
                          _BulletList(items: widget.task.toolsNeeded),
                          const SizedBox(height: 8),
                        ],
                        if (widget.task.suppliesNeeded.isNotEmpty) ...[
                          _InstructionLabel('SUPPLIES'),
                          const SizedBox(height: 6),
                          _BulletList(items: widget.task.suppliesNeeded),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstructionLabel extends StatelessWidget {
  const _InstructionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.ibmPlexMono(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.gray500,
        ),
      );
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
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 7),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.gray500,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style:
                          AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Service history timeline ───────────────────────────────────────────────────

class _ServiceHistory extends StatefulWidget {
  const _ServiceHistory({required this.task, required this.completions});
  final MaintenanceTask task;
  final List<TaskCompletion> completions;

  @override
  State<_ServiceHistory> createState() => _ServiceHistoryState();
}

class _ServiceHistoryState extends State<_ServiceHistory>
    with TickerProviderStateMixin {
  // Completion entry: slide up + fade in.
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  // Next service entry: scale pop + fade in (fires shortly after completion).
  late final AnimationController _nextCtrl;
  late final Animation<double> _nextFade;
  late final Animation<double> _nextScale;

  int _prevCount = 0;

  @override
  void initState() {
    super.initState();
    _prevCount = widget.completions.length;

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _nextCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _nextFade = CurvedAnimation(
      parent: _nextCtrl,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
    );
    _nextScale = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(parent: _nextCtrl, curve: Curves.easeOutBack),
    );

    // Completion entries: always start visible (history was already on screen).
    _ctrl.value = 1.0;
    // Next-service entry: start invisible only when we're waiting for the
    // pop-in animation (task is currently overdue/due with no history yet).
    // Any other case — scheduled future task, or returning to an already
    // completed task — starts fully visible so it doesn't re-animate.
    final waitingForFirstCompletion =
        _isOverdueOrDue(widget.task) && widget.completions.isEmpty;
    _nextCtrl.value = waitingForFirstCompletion ? 0.0 : 1.0;
  }

  @override
  void didUpdateWidget(_ServiceHistory old) {
    super.didUpdateWidget(old);
    if (widget.completions.length > _prevCount) {
      // Completion card slides in immediately.
      _ctrl.forward(from: 0.0);
      // Next service card pops in with a short delay for sequencing.
      if (widget.task.recurrence != RecurrenceType.none) {
        Future.delayed(const Duration(milliseconds: 180), () {
          if (mounted) _nextCtrl.forward(from: 0.0);
        });
      }
    }
    _prevCount = widget.completions.length;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _nextCtrl.dispose();
    super.dispose();
  }

  static bool _isOverdueOrDue(MaintenanceTask task) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !task.dueDate.toLocal().isAfter(today);
  }

  @override
  Widget build(BuildContext context) {
    final isDone = widget.task.status == TaskStatus.completed ||
        widget.task.status == TaskStatus.skipped;
    final completions = widget.completions;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section label ─────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isDone ? AppColors.olive : AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'SERVICE HISTORY',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Timeline entries ─────────────────────────────────────────────
          // Only show the overdue/due-now entry when the task is actually
          // past its due date — not for future scheduled tasks.
          if (!isDone && _isOverdueOrDue(widget.task)) ...[
            _OverdueEntry(task: widget.task, isLast: completions.isEmpty),
          ],

          // Scheduled entry — shown whenever the task is not yet done and
          // not currently overdue/due. Covers both "never completed" (first
          // service preview) and "just completed a recurring task" (next
          // occurrence). Hidden for overdue/due tasks where _OverdueEntry
          // already anchors the timeline.
          if (!isDone && !_isOverdueOrDue(widget.task))
            FadeTransition(
              opacity: _nextFade,
              child: ScaleTransition(
                scale: _nextScale,
                alignment: Alignment.topCenter,
                child: _ScheduledNextEntry(
                  task: widget.task,
                  nextDate: widget.task.dueDate,
                  isLast: completions.isEmpty,
                ),
              ),
            ),

          ...List.generate(completions.length, (i) {
            final c = completions[i];
            final isNextShowing =
                !isDone && !_isOverdueOrDue(widget.task);
            final isLast = i == completions.length - 1;
            final entry = _CompletionEntry(
              completion: c,
              isFirst: !isDone && i == 0,
              isLast: isLast,
            );
            // Animate only the newest entry (index 0 — sorted desc).
            if (i == 0 && !isNextShowing) {
              return FadeTransition(
                opacity: _fade,
                child: SlideTransition(position: _slide, child: entry),
              );
            }
            return entry;
          }),

          if (isDone && completions.isEmpty) _EmptyHistory(),
        ],
      ),
    );
  }
}

// ── Scheduled next entry ──────────────────────────────────────────────────────


class _ScheduledNextEntry extends StatelessWidget {
  const _ScheduledNextEntry({
    required this.task,
    required this.nextDate,
    required this.isLast,
  });

  final MaintenanceTask task;
  final DateTime nextDate;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final next = nextDate.toLocal();
    final daysUntil = next.difference(DateTime.now()).inDays.clamp(0, 9999);
    final dateStr =
        DateFormat('MMM d').format(next).toUpperCase();
    final yearStr = next.year.toString();

    return _TimelineRow(
      isLast: isLast,
      dot: _ScheduledDot(),
      content: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.slateDim,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.slate.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$dateStr · $yearStr',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.slate,
                  ),
                ),
                Text(
                  'in $daysUntil days',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              task.recurrence == RecurrenceType.none
                  ? 'Scheduled service'
                  : 'Next service',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              task.recurrence == RecurrenceType.none
                  ? 'One-time task'
                  : 'Auto-scheduled · ${task.recurrence.label}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.slate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduledDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.slateDim,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.slate.withAlpha(100)),
        ),
        child: const Center(
          child: Icon(
            Icons.event_rounded,
            color: AppColors.slate,
            size: 13,
          ),
        ),
      );
}

// ── Overdue timeline entry ─────────────────────────────────────────────────────

class _OverdueEntry extends StatelessWidget {
  const _OverdueEntry({required this.task, required this.isLast});
  final MaintenanceTask task;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final due = task.dueDate.toLocal();
    final days = now.difference(due).inDays;
    final lateLabel = days == 0 ? 'due today' : '${days}d late';
    final today = DateFormat('MMM d').format(now).toUpperCase();
    final scheduledLabel =
        'Was scheduled ${DateFormat('MMM d').format(due)}';

    return _TimelineRow(
      isLast: isLast,
      dot: _TerracottaDot(),
      content: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.accentDim,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.accent.withAlpha(40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$today · TODAY',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.accent,
                  ),
                ),
                Text(
                  lateLabel,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Due now',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              scheduledLabel,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Completion timeline entry ──────────────────────────────────────────────────

class _CompletionEntry extends ConsumerWidget {
  const _CompletionEntry({
    required this.completion,
    required this.isFirst,
    required this.isLast,
  });

  final TaskCompletion completion;
  final bool isFirst;
  final bool isLast;

  String _completedByLabel() {
    if (completion.completedBy == 'contractor') {
      final name = completion.contractorName;
      return name != null && name.isNotEmpty
          ? 'Done by $name'
          : 'Done by contractor';
    }
    return 'Done by you';
  }

  String _metaLine() {
    final parts = <String>[];
    parts.add(completion.completedBy == 'diy' ? 'DIY' : 'PRO');
    if (completion.timeSpentMinutes != null) {
      parts.add('${completion.timeSpentMinutes} min');
    }
    if (completion.notes != null && completion.notes!.isNotEmpty) {
      parts.add(completion.notes!);
    }
    return parts.join(' · ');
  }

  double get _totalCost =>
      (completion.serviceCost ?? 0) + (completion.materialsCost ?? 0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr =
        DateFormat('MMM d').format(completion.completedDate.toLocal()).toUpperCase();
    final hasCost = _totalCost > 0;
    final meta = _metaLine();

    // Resolve linked receipt names from the already-loaded documents provider.
    // No extra Supabase query — falls back to "Receipt" if docs aren't loaded yet.
    final allDocs = ref.watch(documentsProvider).value ?? const <Document>[];
    final linkedDocs = completion.linkedDocumentIds.isEmpty
        ? const <Document>[]
        : allDocs
            .where((d) => completion.linkedDocumentIds.contains(d.id))
            .toList();

    return _TimelineRow(
      isLast: isLast,
      dot: _OliveDot(),
      content: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.gray500,
                  ),
                ),
                if (hasCost)
                  Text(
                    '\$${_totalCost.toInt()}',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _completedByLabel(),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                meta,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            // Linked receipt chips
            if (completion.linkedDocumentIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: completion.linkedDocumentIds.map((docId) {
                  final doc = linkedDocs
                      .where((d) => d.id == docId)
                      .firstOrNull;
                  final label = doc?.name ?? 'Receipt';
                  return GestureDetector(
                    onTap: () => context.push('/documents/$docId'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warmFill,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_outlined,
                            size: 11,
                            color: AppColors.gray500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.chevron_right,
                            size: 11,
                            color: AppColors.gray500,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Timeline layout primitives ────────────────────────────────────────────────

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.dot,
    required this.content,
    required this.isLast,
  });

  final Widget dot;
  final Widget content;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left rail: dot + line ─────────────────────────────────────
          SizedBox(
            width: 24,
            child: Column(
              children: [
                dot,
                if (!isLast)
                  Container(
                    width: 1.5,
                    height: 56,
                    color: AppColors.divider,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // ── Content ───────────────────────────────────────────────────
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _TerracottaDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.priority_high_rounded,
            color: AppColors.textInverse,
            size: 13,
          ),
        ),
      );
}

class _OliveDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.oliveDim,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.olive.withAlpha(100)),
        ),
        child: const Center(
          child: Icon(
            Icons.check_rounded,
            color: AppColors.olive,
            size: 13,
          ),
        ),
      );
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 32, color: AppColors.gray500),
            const SizedBox(height: 8),
            Text(
              'No history yet',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.gray500,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Complete this task to start your service log.',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom action bar ─────────────────────────────────────────────────────────

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
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.md,
        AppSizes.screenPadding,
        AppSizes.sm + bottomPad,
      ),
      decoration: const BoxDecoration(
        color: AppColors.warmOffWhite,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Mark Complete ───────────────────────────────────────────────
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: (_isCompleting || widget.isDone)
                  ? null
                  : _handleMarkComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    widget.isDone ? AppColors.gray300 : AppColors.accent,
                foregroundColor: AppColors.textInverse,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isCompleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.textInverse),
                    )
                  : Text(
                      widget.isDone ? 'Already Done' : 'Mark Complete',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textInverse,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Add Details + Skip ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: widget.isDone ? null : _handleAddDetails,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color:
                            widget.isDone ? AppColors.border : AppColors.accent.withAlpha(140),
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Add Details',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: widget.isDone ? AppColors.gray500 : AppColors.accent,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: (_isSkipping || widget.isDone)
                        ? null
                        : _handleSkip,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSkipping
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.gray500),
                          )
                        : Text(
                            'Skip',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: widget.isDone
                                  ? AppColors.gray500
                                  : AppColors.error,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleMarkComplete() async {
    if (_isCompleting) return;
    HapticFeedback.mediumImpact();
    setState(() => _isCompleting = true);

    late final ({String completionId, DateTime? originalDueDate}) result;
    try {
      result = await ref
          .read(taskDetailProvider(widget.taskId).notifier)
          .quickCompleteTask();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: const Text("Couldn't complete task. Try again."),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      setState(() => _isCompleting = false);
      return;
    }

    if (!mounted) return;
    setState(() => _isCompleting = false);

    final capturedCompletionId = result.completionId;
    final capturedOriginalDueDate = result.originalDueDate;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text('Task completed!'),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.goldAccent,
          onPressed: () {
            ref
                .read(taskDetailProvider(widget.taskId).notifier)
                .undoQuickComplete(
                  capturedCompletionId,
                  originalDueDate: capturedOriginalDueDate,
                );
          },
        ),
      ));
  }

  Future<void> _handleAddDetails() async {
    final completionId = await context.push<String>(
      AppRoutes.maintenanceCompleteTask
          .replaceFirst(':taskId', widget.taskId),
    );
    if (completionId == null || !mounted) return;
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text('Task completed!'),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.goldAccent,
          onPressed: () {
            ref
                .read(taskDetailProvider(widget.taskId).notifier)
                .undoQuickComplete(completionId);
          },
        ),
      ));
  }

  Future<void> _handleSkip() async {
    if (_isSkipping) return;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final reason = await _SkipReasonSheet.show(context, isIOS: isIOS);
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
        ..showSnackBar(SnackBar(
          content: const Text("Couldn't skip task. Try again."),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
    } finally {
      if (mounted) setState(() => _isSkipping = false);
    }
  }
}

// ── Skip reason sheet (unchanged) ─────────────────────────────────────────────

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
        AppSizes.screenPadding + MediaQuery.of(context).padding.bottom,
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
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizes.md),
          TextField(
            controller: _controller,
            maxLines: 3,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g. Already done by contractor',
              hintStyle: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textDisabled),
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
                    child: Text('Cancel', style: AppTextStyles.bodyMediumSemibold),
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
                      style: AppTextStyles.bodyMediumSemibold
                          .copyWith(color: AppColors.textInverse),
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
