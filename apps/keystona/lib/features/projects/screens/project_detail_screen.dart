import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/project.dart';
import '../models/project_journal_note.dart';
import '../models/project_phase.dart';
import '../providers/project_budget_provider.dart';
import '../providers/project_detail_provider.dart';
import '../providers/project_journal_provider.dart';
import '../providers/project_phases_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _statusColor(String s) => switch (s) {
      'in_progress' => AppColors.slate,
      'planning' => AppColors.sand,
      'on_hold' => AppColors.amber,
      'completed' => AppColors.olive,
      'cancelled' => AppColors.gray400,
      _ => AppColors.gray400,
    };

Color _statusDim(String s) => switch (s) {
      'in_progress' => AppColors.slateDim,
      'planning' => AppColors.sandDim,
      'on_hold' => AppColors.amberDim,
      'completed' => AppColors.oliveDim,
      _ => AppColors.gray200,
    };

String _headerDateRange(DateTime? start, DateTime? end) {
  if (start == null && end == null) return '';
  final m = DateFormat('MMM d');
  if (start != null && end != null) {
    if (start.year == end.year) {
      return '${m.format(start)} – ${m.format(end)}, ${end.year}';
    }
    return '${DateFormat('MMM d, y').format(start)} – ${DateFormat('MMM d, y').format(end)}';
  }
  if (start != null) return 'From ${DateFormat('MMM d, y').format(start)}';
  return 'Until ${DateFormat('MMM d, y').format(end!)}';
}

String _phaseDates(ProjectPhase p) {
  final start = p.actualStartDate ?? p.plannedStartDate;
  final end = p.actualEndDate ?? p.plannedEndDate;
  if (start == null) return '';
  final m = DateFormat('MMM d');
  if (p.status == 'in_progress' && end == null) return '${m.format(start)} – now';
  if (end != null) {
    if (start.year == end.year && start.month == end.month) {
      return '${m.format(start)} – ${DateFormat('d').format(end)}';
    }
    if (start.year == end.year) return '${m.format(start)} – ${m.format(end)}';
    return '${DateFormat('MMM d, y').format(start)} – ${DateFormat('MMM d, y').format(end)}';
  }
  return m.format(start);
}

String _noteDate(DateTime d) {
  final now = DateTime.now();
  return d.year == now.year
      ? DateFormat('MMM d').format(d)
      : DateFormat('MMM d, y').format(d);
}

// ── Main screen ───────────────────────────────────────────────────────────────

class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProject = ref.watch(projectDetailProvider(projectId));
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return asyncProject.when(
      loading: () => _skeleton(isIOS),
      error: (_, _) => _errorScaffold(context, ref, isIOS),
      data: (project) => _buildScaffold(context, ref, project, isIOS),
    );
  }

  // ── Skeleton ────────────────────────────────────────────────────────────────

  Widget _skeleton(bool isIOS) {
    if (isIOS) {
      return CupertinoPageScaffold(
        backgroundColor: AppColors.warmOffWhite,
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Project'),
          backgroundColor: AppColors.warmOffWhite,
          border: Border(),
        ),
        child: const _DetailSkeleton(),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      appBar: AppBar(
        title: const Text('Project'),
        backgroundColor: AppColors.warmOffWhite,
      ),
      body: const _DetailSkeleton(),
    );
  }

  // ── Error ────────────────────────────────────────────────────────────────────

  Widget _errorScaffold(BuildContext context, WidgetRef ref, bool isIOS) {
    final body = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 40, color: AppColors.error),
          const SizedBox(height: AppSizes.md),
          Text("Couldn't load project",
              style: AppTextStyles.h3, textAlign: TextAlign.center),
          const SizedBox(height: AppSizes.lg),
          FilledButton(
            onPressed: () => ref.invalidate(projectDetailProvider(projectId)),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Retry'),
          ),
        ],
      ),
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        backgroundColor: AppColors.warmOffWhite,
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Project'),
          backgroundColor: AppColors.warmOffWhite,
          border: const Border(),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.back),
            onPressed: () => context.pop(),
          ),
        ),
        child: body,
      );
    }
    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      appBar: AppBar(
        title: const Text('Project'),
        backgroundColor: AppColors.warmOffWhite,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: body,
    );
  }

  // ── Main scaffold ─────────────────────────────────────────────────────────

  Widget _buildScaffold(
    BuildContext context,
    WidgetRef ref,
    Project project,
    bool isIOS,
  ) {
    Future<void> onEdit() async {
      final result = await context.push<String>(
        '/projects/$projectId/edit',
        extra: project,
      );
      if (result != null) {
        ref.invalidate(projectDetailProvider(projectId));
        ref.invalidate(projectBudgetSummaryProvider(projectId));
      }
    }

    final body = SafeArea(
      bottom: false,
      child: _DetailBody(project: project, projectId: projectId),
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        backgroundColor: AppColors.warmOffWhite,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: AppColors.warmOffWhite,
          border: const Border(),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.chevron_back,
                    size: 20, color: AppColors.accent),
                Text('Projects',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.accent)),
              ],
            ),
            onPressed: () => context.pop(),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onEdit,
                child: const Icon(CupertinoIcons.pencil,
                    size: 20, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 4),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onEdit,
                child: const Icon(CupertinoIcons.ellipsis,
                    size: 20, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      appBar: AppBar(
        backgroundColor: AppColors.warmOffWhite,
        title: Text(project.name, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: onEdit),
        ],
      ),
      body: body,
    );
  }
}

// ── Detail body ───────────────────────────────────────────────────────────────

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.project, required this.projectId});

  final Project project;
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phasesAsync = ref.watch(projectPhasesProvider(projectId));
    final notesAsync = ref.watch(projectJournalProvider(projectId));

    final phases = phasesAsync.value ?? [];
    final notes = notesAsync.value ?? [];

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () async {
        ref.invalidate(projectDetailProvider(projectId));
        ref.invalidate(projectPhasesProvider(projectId));
        ref.invalidate(projectJournalProvider(projectId));
      },
      child: CustomScrollView(
        slivers: [
          // ── Project header card ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _ProjectHeaderCard(project: project, phases: phases),
            ),
          ),

          // ── Section grid ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionGrid(
              projectId: projectId,
              project: project,
              phases: phases,
              notes: notes,
            ),
          ),

          // ── Timeline ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _TimelineSection(
              project: project,
              projectId: projectId,
              phases: phases,
              notes: notes,
              ref: ref,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }
}

// ── Project header card ───────────────────────────────────────────────────────

class _ProjectHeaderCard extends StatelessWidget {
  const _ProjectHeaderCard({required this.project, required this.phases});

  final Project project;
  final List<ProjectPhase> phases;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        _headerDateRange(project.plannedStartDate, project.plannedEndDate);
    final hasBudget = project.estimatedBudget != null;
    final statusColor = _statusColor(project.status);
    final statusDim = _statusDim(project.status);

    // Compute active phase from live phases list (projectDetailProvider does
    // not join phases, so project.currentPhaseIndex is always null here).
    final validPhases = phases
        .where((p) => p.status != 'cancelled' && p.deletedAt == null)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    int? activePhaseIndex;
    String? activePhaseName;
    for (int i = 0; i < validPhases.length; i++) {
      if (validPhases[i].status == 'in_progress') {
        activePhaseIndex = i;
        activePhaseName = validPhases[i].name;
        break;
      }
    }
    if (activePhaseIndex == null) {
      for (int i = 0; i < validPhases.length; i++) {
        if (validPhases[i].status == 'planning') {
          activePhaseIndex = i;
          activePhaseName = validPhases[i].name;
          break;
        }
      }
    }

    final phaseCount =
        validPhases.isNotEmpty ? validPhases.length : project.phaseCount;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSm,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge + work type
          Row(
            children: [
              Container(
                constraints: const BoxConstraints(minHeight: 44),
                alignment: Alignment.centerLeft,
                child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusDim,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      project.status.statusLabel.toUpperCase(),
                      style: AppTextStyles.monoTiny.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              ),
              const SizedBox(width: 8),
              Text(
                project.workType.workTypeLabel,
                style: AppTextStyles.monoTiny.copyWith(
                  color: AppColors.gray500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Project name
          Text(
            project.name,
            style: AppTextStyles.headlineMedium.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.6,
              height: 1.15,
            ),
          ),

          // Type + description
          const SizedBox(height: 4),
          Text(
            project.projectType.projectTypeLabel +
                (project.description != null && project.description!.isNotEmpty
                    ? ' · ${project.description!}'
                    : ''),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Date range
          if (dateStr.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppColors.gray500),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    dateStr,
                    style: AppTextStyles.monoLabel.copyWith(color: AppColors.gray500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // Phase dot strip
          if (phaseCount > 0) ...[
            const SizedBox(height: 14),
            _MiniPhaseDots(
              phases: phases,
              phaseCount: phaseCount,
              activePhaseIndex: activePhaseIndex,
              activePhaseName: activePhaseName,
            ),
          ],

          // Budget strip
          if (hasBudget) ...[
            const SizedBox(height: 14),
            const Divider(color: AppColors.warmFill, height: 1),
            const SizedBox(height: 14),
            _BudgetStrip(project: project),
          ],
        ],
      ),
    );
  }
}

// ── Mini phase dots (header card) ─────────────────────────────────────────────

class _MiniPhaseDots extends StatelessWidget {
  const _MiniPhaseDots({
    required this.phases,
    required this.phaseCount,
    required this.activePhaseIndex,
    required this.activePhaseName,
  });

  final List<ProjectPhase> phases;
  final int phaseCount;
  final int? activePhaseIndex;
  final String? activePhaseName;

  @override
  Widget build(BuildContext context) {
    final count = math.min(phaseCount, 8);
    final activeIdx = activePhaseIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (int i = 0; i < count; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    color: activeIdx != null && i <= activeIdx
                        ? (i < activeIdx
                            ? AppColors.olive
                            : AppColors.slate.withValues(alpha: 0.4))
                        : AppColors.border,
                  ),
                ),
              _MiniDot(
                state: activeIdx == null
                    ? _DS.upcoming
                    : i < activeIdx
                        ? _DS.completed
                        : i == activeIdx
                            ? _DS.active
                            : _DS.upcoming,
              ),
            ],
          ],
        ),
        if (activeIdx != null && activePhaseName != null) ...[
          const SizedBox(height: 8),
          Text(
            'Phase ${activeIdx + 1} of $phaseCount · $activePhaseName',
            style: AppTextStyles.monoLabel.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.slate,
            ),
          ),
        ],
      ],
    );
  }
}

enum _DS { completed, active, upcoming }

class _MiniDot extends StatelessWidget {
  const _MiniDot({required this.state});
  final _DS state;

  @override
  Widget build(BuildContext context) => switch (state) {
        _DS.completed => Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.olive,
            ),
          ),
        _DS.active => Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.slate,
              boxShadow: [
                BoxShadow(
                  color: AppColors.slate.withValues(alpha: 0.3),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
        _DS.upcoming => Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.warmInset,
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
          ),
      };
}

// ── Budget strip (header card) ────────────────────────────────────────────────

class _BudgetStrip extends StatelessWidget {
  const _BudgetStrip({required this.project});
  final Project project;

  static String _compact(double v) {
    if (v >= 1000) {
      final k = v / 1000;
      return '\$${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(1)}k';
    }
    return '\$${NumberFormat('#,###').format(v.toInt())}';
  }

  @override
  Widget build(BuildContext context) {
    final estimated = project.estimatedBudget!;
    final spent = project.actualSpent;
    final pct = estimated > 0 ? (spent / estimated).clamp(0.0, 1.0) : 0.0;
    final isOver = spent >= estimated && estimated > 0;
    final ringColor = isOver ? AppColors.error : AppColors.olive;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$${NumberFormat('#,###').format(spent.toInt())}',
                style: AppTextStyles.monoLabel.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isOver ? AppColors.error : AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'of ${_compact(estimated)} budget',
                style: AppTextStyles.monoLabel
                    .copyWith(color: AppColors.gray500, fontSize: 12),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 52,
          height: 52,
          child: CustomPaint(
            painter: _BudgetRingPainter(fraction: pct, color: ringColor),
            child: Center(
              child: Text(
                '${(pct * 100).round()}%',
                style: AppTextStyles.monoLabel.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetRingPainter extends CustomPainter {
  const _BudgetRingPainter({required this.fraction, required this.color});
  final double fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - 6) / 2;
    const strokeW = 5.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..color = AppColors.warmInset,
    );

    if (fraction > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_BudgetRingPainter old) =>
      old.fraction != fraction || old.color != color;
}

// ── Section grid (3 × 2 compact cards) ───────────────────────────────────────

typedef _Section = ({
  IconData icon,
  String label,
  String metric,
  Color color,
  String route,
});

class _SectionGrid extends StatelessWidget {
  const _SectionGrid({
    required this.projectId,
    required this.project,
    required this.phases,
    required this.notes,
  });

  final String projectId;
  final Project project;
  final List<ProjectPhase> phases;
  final List<ProjectJournalNote> notes;

  static String _compact(double v) {
    if (v >= 1000) {
      final k = v / 1000;
      return '\$${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(1)}k';
    }
    return '\$${NumberFormat('#,###').format(v.toInt())}';
  }

  @override
  Widget build(BuildContext context) {
    final hasBudget = project.estimatedBudget != null;
    final isOverBudget =
        hasBudget && project.actualSpent >= project.estimatedBudget!;

    final sections = <_Section>[
      (
        icon: Icons.format_list_numbered_outlined,
        label: 'Phases',
        metric: phases.isEmpty
            ? 'Add phases'
            : '${phases.length} phase${phases.length == 1 ? '' : 's'}',
        color: AppColors.slate,
        route: '/projects/$projectId/phases',
      ),
      (
        icon: Icons.account_balance_wallet_outlined,
        label: 'Budget',
        metric: hasBudget ? _compact(project.estimatedBudget!) : 'Not set',
        color: isOverBudget ? AppColors.error : AppColors.olive,
        route: '/projects/$projectId/budget',
      ),
      (
        icon: Icons.photo_library_outlined,
        label: 'Photos',
        metric: 'Progress shots',
        color: AppColors.accent,
        route: '/projects/$projectId/photos',
      ),
      (
        icon: Icons.menu_book_outlined,
        label: 'Journal',
        metric: notes.isEmpty
            ? 'Start logging'
            : '${notes.length} note${notes.length == 1 ? '' : 's'}',
        color: AppColors.sand,
        route: '/projects/$projectId/notes',
      ),
      (
        icon: Icons.people_outline,
        label: 'Contractors',
        metric: project.contractorIds.isEmpty
            ? 'None linked'
            : '${project.contractorIds.length} linked',
        color: AppColors.plum,
        route: '/projects/$projectId/contractors',
      ),
      (
        icon: Icons.folder_outlined,
        label: 'Documents',
        metric: 'Permits, quotes',
        color: AppColors.teal,
        route: '/projects/$projectId/documents',
      ),
    ];

    Widget buildRow(List<_Section> row) => Row(
          children: row.asMap().entries.map((e) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: e.key > 0 ? 8 : 0),
                child: _SectionCard(
                  section: e.value,
                  onTap: () => context.push(e.value.route),
                ),
              ),
            );
          }).toList(),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          buildRow(sections.sublist(0, 3)),
          const SizedBox(height: 8),
          buildRow(sections.sublist(3)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section, required this.onTap});

  final _Section section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = section.color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon bubble
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(section.icon, size: 15, color: color),
            ),
            const SizedBox(height: 8),
            // Label
            Text(
              section.label,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Metric
            Text(
              section.metric,
              style: AppTextStyles.monoLabel.copyWith(
                fontSize: 10,
                color: AppColors.gray500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Timeline section ──────────────────────────────────────────────────────────

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({
    required this.project,
    required this.projectId,
    required this.phases,
    required this.notes,
    required this.ref,
  });

  final Project project;
  final String projectId;
  final List<ProjectPhase> phases;
  final List<ProjectJournalNote> notes;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    // Sort phases newest-first (highest sortOrder at top).
    final sortedPhases = [...phases]
      ..sort((a, b) => b.sortOrder.compareTo(a.sortOrder));

    // Group notes by phaseId.
    final Map<String, List<ProjectJournalNote>> byPhase = {};
    final List<ProjectJournalNote> unlinked = [];
    for (final n in notes) {
      if (n.phaseId != null) {
        byPhase.putIfAbsent(n.phaseId!, () => []).add(n);
      } else {
        unlinked.add(n);
      }
    }

    // Build timeline rows: unlinked notes, then phases with their notes.
    final List<_TLRow> rows = [];
    for (final n in unlinked) {
      rows.add(_TLRow.note(n));
    }
    for (final p in sortedPhases) {
      rows.add(_TLRow.phase(p));
      final pNotes = byPhase[p.id] ?? [];
      for (final n in pNotes) {
        rows.add(_TLRow.note(n));
      }
    }

    final hasContent = rows.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline label
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'ACTIVITY',
              style: AppTextStyles.monoTiny.copyWith(
                color: AppColors.gray500,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          if (hasContent)
            _TimelineList(rows: rows, projectId: projectId)
          else
            _EmptyTimeline(phases: phases, project: project, ref: ref),

          const SizedBox(height: 20),

          // Add entry dashed button
          _AddEntryButton(
            onTap: () =>
                context.push('/projects/$projectId/notes/create'),
          ),

          if (phases.isEmpty) ...[
            const SizedBox(height: 16),
            _TemplatePrompt(
              project: project,
              projectId: projectId,
              ref: ref,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Timeline list (with vertical line) ───────────────────────────────────────

class _TLRow {
  final bool isPhase;
  final ProjectPhase? phase;
  final ProjectJournalNote? note;

  const _TLRow._({required this.isPhase, this.phase, this.note});

  factory _TLRow.phase(ProjectPhase p) =>
      _TLRow._(isPhase: true, phase: p);
  factory _TLRow.note(ProjectJournalNote n) =>
      _TLRow._(isPhase: false, note: n);
}

class _TimelineList extends StatelessWidget {
  const _TimelineList({required this.rows, required this.projectId});

  final List<_TLRow> rows;
  final String projectId;

  static const double _dotColW = 26;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Vertical line — runs from center of first dot downward.
        const Positioned(
          left: _dotColW / 2 - 1,
          top: 13,
          bottom: 0,
          child: SizedBox(
            width: 2,
            child: ColoredBox(color: AppColors.border),
          ),
        ),

        // Timeline rows.
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows.map((r) {
            if (r.isPhase) {
              return _PhaseMarkerRow(phase: r.phase!);
            }
            return _NoteTimelineCard(note: r.note!, projectId: projectId);
          }).toList(),
        ),
      ],
    );
  }
}

// ── Phase marker row ──────────────────────────────────────────────────────────

class _PhaseMarkerRow extends StatelessWidget {
  const _PhaseMarkerRow({required this.phase});
  final ProjectPhase phase;

  @override
  Widget build(BuildContext context) {
    final isActive = phase.status == 'in_progress';
    final isDone = phase.status == 'completed';
    final dotColor = isActive
        ? AppColors.slate
        : isDone
            ? AppColors.olive
            : AppColors.gray300;
    final dateStr = _phaseDates(phase);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Large phase dot (26px)
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
            ),
            child: Icon(
              isDone
                  ? Icons.check
                  : isActive
                      ? Icons.build_outlined
                      : Icons.schedule_outlined,
              size: 12,
              color: (isActive || isDone) ? Colors.white : AppColors.gray500,
            ),
          ),
          const SizedBox(width: 10),

          // Phase name
          Expanded(
            child: Text(
              phase.name,
              style: AppTextStyles.headlineSmall.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Dates
          if (dateStr.isNotEmpty)
            Text(
              dateStr,
              style: AppTextStyles.monoLabel.copyWith(
                fontSize: 10,
                color: AppColors.gray500,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Note timeline card ────────────────────────────────────────────────────────

class _NoteTimelineCard extends StatelessWidget {
  const _NoteTimelineCard({required this.note, required this.projectId});

  final ProjectJournalNote note;
  final String projectId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Small dot (8px) centered in 26px column
          SizedBox(
            width: 26,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.sandDim,
                    border: Border.all(color: AppColors.sand, width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Note card
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowXs,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _noteDate(note.noteDate),
                          style: AppTextStyles.monoLabel.copyWith(
                            fontSize: 10,
                            color: AppColors.gray500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.sandDim,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'NOTE',
                            style: AppTextStyles.monoTiny.copyWith(
                              color: AppColors.sand,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (note.title != null && note.title!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        note.title!,
                        style: AppTextStyles.bodyMediumSemibold.copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      note.content,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty timeline ────────────────────────────────────────────────────────────

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline({
    required this.phases,
    required this.project,
    required this.ref,
  });

  final List<ProjectPhase> phases;
  final Project project;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        phases.isEmpty
            ? 'Add phases and notes to track this project\'s progress.'
            : 'No notes yet. Tap "Add note" below to start the project log.',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500),
      ),
    );
  }
}

// ── Add entry dashed button ───────────────────────────────────────────────────

class _AddEntryButton extends StatelessWidget {
  const _AddEntryButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        foregroundPainter: _DashedBorderPainter(
          color: AppColors.borderStrong,
          radius: 12,
          strokeWidth: 1.5,
          dashLength: 5,
          gapLength: 4,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                'Add note, photo, or document',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2,
          size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dashLength), paint);
        d += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength;
}

// ── Phase template prompt ─────────────────────────────────────────────────────

class _TemplatePrompt extends ConsumerStatefulWidget {
  const _TemplatePrompt({
    required this.project,
    required this.projectId,
    required this.ref,
  });

  final Project project;
  final String projectId;
  final WidgetRef ref;

  @override
  ConsumerState<_TemplatePrompt> createState() => _TemplatePromptState();
}

class _TemplatePromptState extends ConsumerState<_TemplatePrompt> {
  bool _loading = false;

  Future<void> _loadTemplates() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(projectPhasesProvider(widget.projectId).notifier)
          .loadTemplatesAndCreate(widget.project.projectType);
      if (!mounted) return;
      SnackbarService.showSuccess(context, 'Starter phases added!');
    } catch (_) {
      if (!mounted) return;
      SnackbarService.showError(
          context, 'Could not load templates. Add phases manually.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.slateDim,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.slate.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start with a template',
            style: AppTextStyles.bodyMediumSemibold,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Load starter phases for a '
            '${widget.project.projectType.projectTypeLabel} project.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading ? null : _loadTemplates,
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Load Template'),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              TextButton(
                onPressed: () => context.push(
                    '/projects/${widget.projectId}/phases/create'),
                child: const Text('Add Manually'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Detail skeleton ───────────────────────────────────────────────────────────

class _DetailSkeleton extends StatefulWidget {
  const _DetailSkeleton();

  @override
  State<_DetailSkeleton> createState() => _DetailSkeletonState();
}

class _DetailSkeletonState extends State<_DetailSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(_ctrl);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, _) => Opacity(
        opacity: _opacity.value,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card placeholder
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 16),
              // Quick-access chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    4,
                    (_) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        width: 88,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.gray200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Timeline items
              ...List.generate(
                3,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gray300,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.gray200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
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
