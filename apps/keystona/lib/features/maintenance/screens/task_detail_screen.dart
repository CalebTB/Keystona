import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
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
      backgroundColor: AuroraColors.paper,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AuroraColors.paper,
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
      backgroundColor: AuroraColors.paper,
      appBar: AppBar(
        backgroundColor: AuroraColors.paper,
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
                style: AuroraType.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AuroraColors.coral,
                ),
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

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isActionable = !isDone &&
        !task.dueDate.toLocal().isAfter(today.add(const Duration(days: 30)));

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _LedgerHeader(task: task)),
              SliverToBoxAdapter(
                child: _StatStrip(task: task, completions: completions),
              ),
              SliverToBoxAdapter(child: _InstructionsRow(task: task)),
              SliverToBoxAdapter(
                child: _ServiceHistory(task: task, completions: completions),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _eyebrow(),
                  style: AuroraType.label.copyWith(
                    color: AuroraColors.inkTertiary,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  task.name.endsWith('.') ? task.name : '${task.name}.',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.1,
                    color: AuroraColors.ink,
                  ),
                ),
              ],
            ),
          ),
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
        color: AuroraColors.coralDim,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AuroraColors.coral.withValues(alpha: 0.24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            days == 0 ? 'Due' : '${days}d',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AuroraColors.coral,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'OVERDUE',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AuroraColors.coral,
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
        color: AuroraColors.limeDim,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AuroraColors.lime.withValues(alpha: 0.24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, color: AuroraColors.limeDeep, size: 18),
          const SizedBox(height: 2),
          Text(
            'DONE',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AuroraColors.limeDeep,
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
        color: AuroraColors.cobaltDim,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AuroraColors.cobalt.withValues(alpha: 0.24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: task.status == TaskStatus.due ? 12 : 18,
              fontWeight: FontWeight.w700,
              color: AuroraColors.cobalt,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            task.status == TaskStatus.due ? 'DUE' : 'DAYS',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AuroraColors.cobalt,
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
          _StatCell(value: '${completions.length}', label: 'STREAK'),
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
          color: AuroraColors.paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AuroraColors.inkBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AuroraColors.ink,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: AuroraColors.inkTertiary,
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
            color: AuroraColors.paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AuroraColors.inkBorder),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AuroraColors.coralDim,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(
                        _expanded ? Icons.remove : Icons.add,
                        size: 16,
                        color: AuroraColors.coral,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _headerLine(),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AuroraColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _expanded
                                ? 'Tap to collapse'
                                : 'Tap to expand · ${_summaryLine()}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AuroraColors.inkTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: AuroraColors.inkTertiary,
                      ),
                    ),
                  ],
                ),
              ),
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
                        Divider(height: 1, color: AuroraColors.inkBorder),
                        const SizedBox(height: 12),
                        if (widget.task.description != null &&
                            widget.task.description!.isNotEmpty) ...[
                          Text(
                            widget.task.description!,
                            style: AuroraType.bodySm.copyWith(
                              color: AuroraColors.inkSecondary,
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
                            style: AuroraType.bodySm.copyWith(height: 1.6),
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
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AuroraColors.inkTertiary,
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
                        color: AuroraColors.inkTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: AuroraType.bodySm.copyWith(
                        color: AuroraColors.inkSecondary,
                      ),
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
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

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

    _ctrl.value = 1.0;
    final waitingForFirstCompletion =
        _isOverdueOrDue(widget.task) && widget.completions.isEmpty;
    _nextCtrl.value = waitingForFirstCompletion ? 0.0 : 1.0;
  }

  @override
  void didUpdateWidget(_ServiceHistory old) {
    super.didUpdateWidget(old);
    if (widget.completions.length > _prevCount) {
      _ctrl.forward(from: 0.0);
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
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isDone ? AuroraColors.lime : AuroraColors.coral,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'SERVICE HISTORY',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AuroraColors.inkTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (!isDone && _isOverdueOrDue(widget.task)) ...[
            _OverdueEntry(task: widget.task, isLast: completions.isEmpty),
          ],

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
    final dateStr = DateFormat('MMM d').format(next).toUpperCase();
    final yearStr = next.year.toString();

    return _TimelineRow(
      isLast: isLast,
      dot: _ScheduledDot(),
      content: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AuroraColors.cobaltDim,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AuroraColors.cobalt.withValues(alpha: 0.20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$dateStr · $yearStr',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AuroraColors.cobalt,
                  ),
                ),
                Text(
                  'in $daysUntil days',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AuroraColors.cobalt,
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
                color: AuroraColors.ink,
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
                color: AuroraColors.cobalt,
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
          color: AuroraColors.cobaltDim,
          shape: BoxShape.circle,
          border: Border.all(color: AuroraColors.cobalt.withValues(alpha: 0.40)),
        ),
        child: const Center(
          child: Icon(
            Icons.event_rounded,
            color: AuroraColors.cobalt,
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
    final scheduledLabel = 'Was scheduled ${DateFormat('MMM d').format(due)}';

    return _TimelineRow(
      isLast: isLast,
      dot: _TerracottaDot(),
      content: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AuroraColors.coralDim,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AuroraColors.coral.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$today · TODAY',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AuroraColors.coral,
                  ),
                ),
                Text(
                  lateLabel,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AuroraColors.coral,
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
                color: AuroraColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              scheduledLabel,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AuroraColors.coral,
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
          color: AuroraColors.paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AuroraColors.inkBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AuroraColors.inkTertiary,
                  ),
                ),
                if (hasCost)
                  Text(
                    '\$${_totalCost.toInt()}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AuroraColors.inkSecondary,
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
                color: AuroraColors.ink,
              ),
            ),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                meta,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AuroraColors.inkTertiary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (completion.linkedDocumentIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: completion.linkedDocumentIds.map((docId) {
                  final doc = linkedDocs.where((d) => d.id == docId).firstOrNull;
                  final label = doc?.name ?? 'Receipt';
                  return GestureDetector(
                    onTap: () => context.push('/documents/$docId'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AuroraColors.butter,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AuroraColors.inkBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_outlined,
                            size: 11,
                            color: AuroraColors.inkTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AuroraColors.inkSecondary,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.chevron_right,
                            size: 11,
                            color: AuroraColors.inkTertiary,
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
          SizedBox(
            width: 24,
            child: Column(
              children: [
                dot,
                if (!isLast)
                  Container(
                    width: 1.5,
                    height: 56,
                    color: AuroraColors.inkBorder,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
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
          color: AuroraColors.coral,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.priority_high_rounded,
            color: Colors.white,
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
          color: AuroraColors.limeDim,
          shape: BoxShape.circle,
          border: Border.all(color: AuroraColors.lime.withValues(alpha: 0.40)),
        ),
        child: const Center(
          child: Icon(
            Icons.check_rounded,
            color: AuroraColors.limeDeep,
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
            Icon(Icons.history, size: 32, color: AuroraColors.inkTertiary),
            const SizedBox(height: 8),
            Text(
              'No history yet',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AuroraColors.inkTertiary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Complete this task to start your service log.',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AuroraColors.inkTertiary,
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
        AuroraSpacing.screenPadH,
        AuroraSpacing.space5,
        AuroraSpacing.screenPadH,
        AuroraSpacing.space3 + bottomPad,
      ),
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        border: Border(top: BorderSide(color: AuroraColors.inkBorder, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: (_isCompleting || widget.isDone)
                  ? null
                  : _handleMarkComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isDone
                    ? AuroraColors.inkTertiary
                    : AuroraColors.coral,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isCompleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      widget.isDone ? 'Already Done' : 'Mark Complete',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: widget.isDone ? null : _handleAddDetails,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: widget.isDone
                            ? AuroraColors.inkBorder
                            : AuroraColors.coral.withValues(alpha: 0.55),
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Add Details',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: widget.isDone
                            ? AuroraColors.inkTertiary
                            : AuroraColors.coral,
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
                      side: const BorderSide(color: AuroraColors.inkBorder),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSkipping
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AuroraColors.inkTertiary),
                          )
                        : Text(
                            'Skip',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: widget.isDone
                                  ? AuroraColors.inkTertiary
                                  : AuroraColors.coral,
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
          backgroundColor: AuroraColors.coral,
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
          textColor: AuroraColors.yellow,
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
          textColor: AuroraColors.yellow,
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
          backgroundColor: AuroraColors.coral,
          behavior: SnackBarBehavior.floating,
        ));
    } finally {
      if (mounted) setState(() => _isSkipping = false);
    }
  }
}

// ── Skip reason sheet ─────────────────────────────────────────────────────────

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
      backgroundColor: AuroraColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
        AuroraSpacing.screenPadH,
        AuroraSpacing.space7,
        AuroraSpacing.screenPadH,
        AuroraSpacing.screenPadH + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                color: AuroraColors.inkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AuroraSpacing.space7),
          Text('Skip Task', style: AuroraType.h3),
          const SizedBox(height: AuroraSpacing.space2),
          Text(
            'Reason (optional)',
            style: AuroraType.bodySm.copyWith(color: AuroraColors.inkSecondary),
          ),
          const SizedBox(height: AuroraSpacing.space5),
          TextField(
            controller: _controller,
            maxLines: 3,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g. Already done by contractor',
              hintStyle: AuroraType.body.copyWith(color: AuroraColors.inkTertiary),
              border: OutlineInputBorder(
                borderRadius: AuroraRadius.md,
                borderSide: const BorderSide(color: AuroraColors.inkBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AuroraRadius.md,
                borderSide: const BorderSide(color: AuroraColors.inkBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AuroraRadius.md,
                borderSide: const BorderSide(color: AuroraColors.ink),
              ),
              filled: true,
              fillColor: AuroraColors.butter,
              contentPadding: const EdgeInsets.all(AuroraSpacing.space5),
            ),
          ),
          const SizedBox(height: AuroraSpacing.space5),
          if (isIOS) ...[
            CupertinoButton.filled(
              onPressed: _confirm,
              child: const Text('Skip Task'),
            ),
            CupertinoButton(
              onPressed: _cancel,
              child: Text(
                'Cancel',
                style: TextStyle(color: AuroraColors.inkSecondary),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AuroraColors.inkBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: AuroraRadius.md,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AuroraType.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AuroraSpacing.space3),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuroraColors.coral,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: AuroraRadius.md,
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Skip Task',
                      style: AuroraType.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
