import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/widgets/aurora/aurora.dart';

import '../../../core/widgets/snackbar_service.dart';
import '../models/project.dart';
import '../models/project_budget_item.dart';
import '../models/project_journal_note.dart';
import '../models/project_phase.dart';
import '../providers/project_budget_provider.dart';
import '../providers/project_detail_provider.dart';
import '../providers/project_journal_provider.dart';
import '../providers/project_phases_provider.dart';
import '../providers/project_photos_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _noteDate(DateTime d) {
  final now = DateTime.now();
  return d.year == now.year
      ? DateFormat('MMM d').format(d)
      : DateFormat('MMM d, y').format(d);
}

String _phaseShortDate(ProjectPhase p) {
  final isDone = p.status == 'completed';
  final date = isDone
      ? (p.actualEndDate ?? p.plannedEndDate)
      : (p.plannedStartDate ?? p.actualStartDate);
  if (date == null) return '';
  return DateFormat('MMM d').format(date).toUpperCase();
}

String _compact(double v) {
  if (v >= 1000) {
    final k = v / 1000;
    return '\$${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(1)}k';
  }
  return '\$${NumberFormat('#,###').format(v.toInt())}';
}

// ── Main screen ───────────────────────────────────────────────────────────────

class ProjectDetailScreen extends ConsumerStatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  int _tab = 1;
  late final PageController _pageCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(initialPage: _tab);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pulseCtrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // Called when user taps a tab pill — animate PageView to match
  void _handleTabChange(int index) {
    setState(() => _tab = index);
    _pageCtrl.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  // Called when user swipes PageView — update pill without re-animating
  void _handlePageChanged(int index) {
    setState(() => _tab = index);
  }

  @override
  Widget build(BuildContext context) {
    final asyncProject = ref.watch(projectDetailProvider(widget.projectId));
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return asyncProject.when(
      loading: () => _skeletonScaffold(isIOS),
      error: (_, _) => _errorScaffold(context, isIOS),
      data: (project) => _buildScaffold(context, project, isIOS),
    );
  }

  // ── Skeleton ─────────────────────────────────────────────────────────────

  Widget _skeletonScaffold(bool isIOS) {
    if (isIOS) {
      return CupertinoPageScaffold(
        backgroundColor: AuroraColors.paper,
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Project'),
          backgroundColor: AuroraColors.paper,
          border: Border(),
        ),
        child: const _DetailSkeleton(),
      );
    }
    return Scaffold(
      backgroundColor: AuroraColors.paper,
      appBar: AppBar(
        title: const SizedBox.shrink(),
        backgroundColor: AuroraColors.paper,
        foregroundColor: AuroraColors.ink,
        elevation: 0,
      ),
      body: const _DetailSkeleton(),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────

  Widget _errorScaffold(BuildContext context, bool isIOS) {
    final body = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 40, color: AuroraColors.coral),
          const SizedBox(height: AuroraSpacing.space7),
          Text("Couldn't load project",
              style: AuroraType.h3, textAlign: TextAlign.center),
          const SizedBox(height: AuroraSpacing.space9),
          PrimaryButton(
            label: 'Retry',
            onPressed: () =>
                ref.invalidate(projectDetailProvider(widget.projectId)),
          ),
        ],
      ),
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        backgroundColor: AuroraColors.paper,
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Project'),
          backgroundColor: AuroraColors.paper,
          border: const Border(),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.back, color: AuroraColors.coral),
            onPressed: () => context.pop(),
          ),
        ),
        child: body,
      );
    }
    return Scaffold(
      backgroundColor: AuroraColors.paper,
      appBar: AppBar(
        title: const SizedBox.shrink(),
        backgroundColor: AuroraColors.paper,
        foregroundColor: AuroraColors.ink,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AuroraColors.coral),
          onPressed: () => context.pop(),
        ),
      ),
      body: body,
    );
  }

  // ── Main scaffold ─────────────────────────────────────────────────────────

  Widget _buildScaffold(
    BuildContext context,
    Project project,
    bool isIOS,
  ) {
    Future<void> onEdit() async {
      final result = await context.push<String>(
        '/projects/${widget.projectId}/edit',
        extra: project,
      );
      if (result != null) {
        ref.invalidate(projectDetailProvider(widget.projectId));
        ref.invalidate(projectBudgetSummaryProvider(widget.projectId));
      }
    }

    final body = _DetailContent(
      project: project,
      projectId: widget.projectId,
      tab: _tab,
      onTabChange: _handleTabChange,
      onPageChanged: _handlePageChanged,
      pageCtrl: _pageCtrl,
      pulseScale: _pulseScale,
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        backgroundColor: AuroraColors.paper,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: AuroraColors.paper,
          border: const Border(),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.chevron_back,
                    size: 20, color: AuroraColors.coral),
                Text('Projects',
                    style:
                        AuroraType.body.copyWith(color: AuroraColors.coral)),
              ],
            ),
            onPressed: () => context.pop(),
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onEdit,
            child: const Icon(CupertinoIcons.ellipsis,
                size: 20, color: AuroraColors.inkSecondary),
          ),
        ),
        child: SafeArea(bottom: false, child: body),
      );
    }

    return Scaffold(
      backgroundColor: AuroraColors.paper,
      appBar: AppBar(
        backgroundColor: AuroraColors.paper,
        foregroundColor: AuroraColors.ink,
        elevation: 0,
        title: const SizedBox.shrink(),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AuroraColors.coral),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.more_vert,
                  color: AuroraColors.inkSecondary),
              onPressed: onEdit),
        ],
      ),
      body: SafeArea(bottom: false, child: body),
    );
  }
}

// ── Detail content ────────────────────────────────────────────────────────────

class _DetailContent extends ConsumerWidget {
  const _DetailContent({
    required this.project,
    required this.projectId,
    required this.tab,
    required this.onTabChange,
    required this.onPageChanged,
    required this.pageCtrl,
    required this.pulseScale,
  });

  final Project project;
  final String projectId;
  final int tab;
  final void Function(int) onTabChange;
  final void Function(int) onPageChanged;
  final PageController pageCtrl;
  final Animation<double> pulseScale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phasesAsync = ref.watch(projectPhasesProvider(projectId));
    final notesAsync = ref.watch(projectJournalProvider(projectId));

    final phases = phasesAsync.value ?? [];
    final notes = notesAsync.value ?? [];

    final validPhases = phases
        .where((p) => p.status != 'cancelled' && p.deletedAt == null)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final doneCount =
        validPhases.where((p) => p.status == 'completed').length;
    final activeCount =
        validPhases.where((p) => p.status == 'in_progress').length;
    final upcomingCount = validPhases.length - doneCount - activeCount;
    final completionPct =
        validPhases.isEmpty ? 0.0 : doneCount / validPhases.length;

    return Column(
      children: [
        _CoralHero(
          project: project,
          completionPct: completionPct,
          pulseScale: pulseScale,
        ),
        _ProjectTabBar(selectedIndex: tab, onTap: onTabChange),
        Expanded(
          child: RefreshIndicator(
            color: AuroraColors.coral,
            onRefresh: () async {
              ref.invalidate(projectDetailProvider(projectId));
              ref.invalidate(projectPhasesProvider(projectId));
              ref.invalidate(projectJournalProvider(projectId));
              ref.invalidate(projectBudgetProvider(projectId));
              ref.invalidate(projectBudgetSummaryProvider(projectId));
              ref.invalidate(projectPhotosProvider(projectId));
            },
            child: PageView(
              controller: pageCtrl,
              onPageChanged: onPageChanged,
              children: [
                _OverviewView(
                  projectId: projectId,
                  project: project,
                  phases: phases,
                  notes: notes,
                ),
                _PhasesView(
                  project: project,
                  projectId: projectId,
                  phases: validPhases,
                  notes: notes,
                  doneCount: doneCount,
                  activeCount: activeCount,
                  upcomingCount: upcomingCount,
                ),
                _BudgetView(projectId: projectId, project: project),
                _PhotosView(projectId: projectId),
                _NotesView(projectId: projectId),
              ],
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );
  }
}

// ── Coral hero ────────────────────────────────────────────────────────────────

class _CoralHero extends StatelessWidget {
  const _CoralHero({
    required this.project,
    required this.completionPct,
    required this.pulseScale,
  });

  final Project project;
  final double completionPct;
  final Animation<double> pulseScale;

  String get _eyebrow {
    final started = project.actualStartDate ?? project.plannedStartDate;
    if (started != null) {
      return '${project.status.statusLabel.toUpperCase()} · STARTED ${DateFormat('MMM d').format(started).toUpperCase()}';
    }
    return project.status.statusLabel.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          color: AuroraColors.coral,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Decorative yellow blob
              Positioned(
                right: -30,
                top: -20,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AuroraColors.yellow.withValues(alpha: 0.35),
                  ),
                ),
              ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pulsing lime dot + eyebrow
              Row(
                children: [
                  AnimatedBuilder(
                    animation: pulseScale,
                    builder: (_, _) => Transform.scale(
                      scale: pulseScale.value,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AuroraColors.lime,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _eyebrow,
                      style: AuroraType.labelSm.copyWith(
                        color: AuroraColors.paper.withValues(alpha: 0.70),
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Project name
              Text(
                '${project.name}.',
                style: AuroraType.h1.copyWith(
                  color: AuroraColors.paper,
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  letterSpacing: -0.5,
                  height: 1.15,
                ),
              ),

              const SizedBox(height: 16),

              // Lime progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: completionPct,
                  backgroundColor:
                      AuroraColors.paper.withValues(alpha: 0.20),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AuroraColors.lime,
                  ),
                  minHeight: 5,
                ),
              ),

              const SizedBox(height: 8),

              // Progress labels
              Row(
                children: [
                  Text(
                    '${(completionPct * 100).round()}% complete',
                    style: AuroraType.bodySm.copyWith(
                      color: AuroraColors.lime,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (project.estimatedBudget != null)
                    Text(
                      '\$${NumberFormat('#,###').format(project.actualSpent.toInt())} / ${_compact(project.estimatedBudget!)}',
                      style: AuroraType.bodySm.copyWith(
                        color: AuroraColors.paper.withValues(alpha: 0.80),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }
}

// ── Tab bar — compact fixed row, all 5 fit without scrolling ─────────────────

class _ProjectTabBar extends StatelessWidget {
  const _ProjectTabBar({
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final void Function(int) onTap;

  static const _tabs = ['Overview', 'Phases', 'Budget', 'Photos', 'Notes'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AuroraColors.paper,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: _tabs.asMap().entries.map((e) {
                final i = e.key;
                final label = e.value;
                final selected = i == selectedIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected
                            ? AuroraColors.coral
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: AuroraType.label.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: selected
                              ? AuroraColors.paper
                              : AuroraColors.ink,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1, color: AuroraColors.inkBorder),
        ],
      ),
    );
  }
}

// ── Overview view ─────────────────────────────────────────────────────────────

class _OverviewView extends StatelessWidget {
  const _OverviewView({
    required this.projectId,
    required this.project,
    required this.phases,
    required this.notes,
  });

  final String projectId;
  final Project project;
  final List<ProjectPhase> phases;
  final List<ProjectJournalNote> notes;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _SectionGrid(
          projectId: projectId,
          project: project,
          phases: phases,
          notes: notes,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Phases view ───────────────────────────────────────────────────────────────

class _PhasesView extends StatelessWidget {
  const _PhasesView({
    required this.project,
    required this.projectId,
    required this.phases,
    required this.notes,
    required this.doneCount,
    required this.activeCount,
    required this.upcomingCount,
  });

  final Project project;
  final String projectId;
  final List<ProjectPhase> phases;
  final List<ProjectJournalNote> notes;
  final int doneCount;
  final int activeCount;
  final int upcomingCount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _PhasesHeader(
          phaseCount: phases.length,
          doneCount: doneCount,
          activeCount: activeCount,
          upcomingCount: upcomingCount,
        ),
        ...phases.map((p) {
          final isDone = p.status == 'completed';
          final isActive = p.status == 'in_progress';
          if (isDone) return _DonePhaseRow(phase: p);
          if (isActive) return _ActivePhaseRow(phase: p);
          return _UpcomingPhaseRow(phase: p);
        }),
        _ActivitySection(
          project: project,
          projectId: projectId,
          phases: phases,
          notes: notes,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Budget view ───────────────────────────────────────────────────────────────

class _BudgetView extends ConsumerWidget {
  const _BudgetView({required this.projectId, required this.project});

  final String projectId;
  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(projectBudgetSummaryProvider(projectId));
    final itemsAsync = ref.watch(projectBudgetProvider(projectId));

    return summaryAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Text('Could not load budget',
            style: AuroraType.bodySm
                .copyWith(color: AuroraColors.inkSecondary)),
      ),
      data: (summary) {
        final items = itemsAsync.value ?? [];
        final isOver = summary.remaining < 0;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // Summary header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isOver ? AuroraColors.coral : AuroraColors.cobaltDim,
                borderRadius: AuroraRadius.md,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _BudgetStat(
                        label: 'ESTIMATED',
                        value: _compact(summary.estimatedTotal),
                        onDark: isOver,
                      ),
                      _BudgetStat(
                        label: 'SPENT',
                        value: _compact(summary.actualTotal),
                        onDark: isOver,
                      ),
                      _BudgetStat(
                        label: isOver ? 'OVER BY' : 'REMAINING',
                        value: _compact(summary.remaining.abs()),
                        onDark: isOver,
                        highlight: true,
                      ),
                    ],
                  ),
                  if (summary.estimatedTotal > 0) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (summary.actualTotal /
                                summary.estimatedTotal)
                            .clamp(0.0, 1.0),
                        backgroundColor:
                            AuroraColors.paper.withValues(alpha: 0.30),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOver
                              ? AuroraColors.paper
                              : AuroraColors.cobalt,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No budget items yet.',
                  style: AuroraType.bodySm
                      .copyWith(color: AuroraColors.inkSecondary),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...items.map((item) => _BudgetItemRow(item: item)),
          ],
        );
      },
    );
  }
}

class _BudgetStat extends StatelessWidget {
  const _BudgetStat({
    required this.label,
    required this.value,
    required this.onDark,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool onDark;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final baseColor = onDark ? AuroraColors.paper : AuroraColors.ink;
    final accentColor = onDark ? AuroraColors.paper : AuroraColors.limeDeep;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AuroraType.labelSm.copyWith(
            color: baseColor.withValues(alpha: 0.70),
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AuroraType.h3.copyWith(
            color: highlight ? accentColor : baseColor,
            fontWeight: FontWeight.w800,
            fontSize: highlight ? 20 : 16,
          ),
        ),
      ],
    );
  }
}

class _BudgetItemRow extends StatelessWidget {
  const _BudgetItemRow({required this.item});
  final ProjectBudgetItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.md,
        border: Border.all(color: AuroraColors.inkBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AuroraType.body
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                if (item.vendor != null && item.vendor!.isNotEmpty)
                  Text(
                    item.vendor!,
                    style: AuroraType.label.copyWith(
                        color: AuroraColors.inkSecondary),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _compact(item.actualCost > 0 ? item.actualCost : item.estimatedCost),
                style: AuroraType.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: item.isPaid
                      ? AuroraColors.limeDeep
                      : AuroraColors.ink,
                ),
              ),
              if (item.isPaid)
                Text(
                  'PAID',
                  style: AuroraType.labelSm.copyWith(
                    color: AuroraColors.limeDeep,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Photos view ───────────────────────────────────────────────────────────────

class _PhotosView extends ConsumerWidget {
  const _PhotosView({required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(projectPhotosProvider(projectId));

    return photosAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Text('Could not load photos',
            style: AuroraType.bodySm
                .copyWith(color: AuroraColors.inkSecondary)),
      ),
      data: (photos) {
        if (photos.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_library_outlined,
                    size: 48, color: AuroraColors.inkSecondary),
                const SizedBox(height: 12),
                Text(
                  'No photos yet.',
                  style: AuroraType.body.copyWith(
                      color: AuroraColors.inkSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Document your progress by adding photos.',
                  style: AuroraType.bodySm.copyWith(
                      color: AuroraColors.inkSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: photos.length,
          itemBuilder: (context, i) {
            final photo = photos[i];
            final url = photo.signedUrl;
            return ClipRRect(
              borderRadius: AuroraRadius.sm,
              child: url != null && url.isNotEmpty
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _PhotoPlaceholder(),
                    )
                  : _PhotoPlaceholder(),
            );
          },
        );
      },
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AuroraColors.butter,
      child: const Icon(Icons.image_outlined,
          color: AuroraColors.inkSecondary),
    );
  }
}

// ── Notes view ────────────────────────────────────────────────────────────────

class _NotesView extends ConsumerWidget {
  const _NotesView({required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(projectJournalProvider(projectId));

    return notesAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Text('Could not load notes',
            style: AuroraType.bodySm
                .copyWith(color: AuroraColors.inkSecondary)),
      ),
      data: (notes) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          if (notes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No notes yet. Start logging your project progress.',
                style: AuroraType.bodySm
                    .copyWith(color: AuroraColors.inkSecondary),
                textAlign: TextAlign.center,
              ),
            )
          else
            _TimelineList(notes: notes, projectId: projectId),
          const SizedBox(height: 8),
          _AddEntryButton(
            onTap: () =>
                context.push('/projects/$projectId/notes/create'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Phases header ─────────────────────────────────────────────────────────────

class _PhasesHeader extends StatelessWidget {
  const _PhasesHeader({
    required this.phaseCount,
    required this.doneCount,
    required this.activeCount,
    required this.upcomingCount,
  });

  final int phaseCount;
  final int doneCount;
  final int activeCount;
  final int upcomingCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AuroraColors.cobalt,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$phaseCount PHASES',
            style: AuroraType.labelSm.copyWith(
              color: AuroraColors.cobalt,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$doneCount done · $activeCount active · $upcomingCount to go',
              style: AuroraType.label.copyWith(color: AuroraColors.inkSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Done phase row ────────────────────────────────────────────────────────────

class _DonePhaseRow extends StatelessWidget {
  const _DonePhaseRow({required this.phase});
  final ProjectPhase phase;

  @override
  Widget build(BuildContext context) {
    final dateStr = _phaseShortDate(phase);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AuroraColors.paper,
          borderRadius: AuroraRadius.md,
          border: Border.all(color: AuroraColors.inkBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AuroraColors.cobaltDim,
              ),
              child: Icon(
                Icons.check,
                size: 14,
                color: AuroraColors.cobalt.withValues(alpha: 0.70),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phase.name,
                    style: AuroraType.body.copyWith(
                      color: AuroraColors.inkTertiary,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AuroraColors.inkTertiary,
                    ),
                  ),
                  if (phase.description != null &&
                      phase.description!.isNotEmpty)
                    Text(
                      phase.description!.toUpperCase(),
                      style: AuroraType.labelSm.copyWith(
                        color: AuroraColors.inkTertiary,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (dateStr.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                dateStr,
                style:
                    AuroraType.labelSm.copyWith(color: AuroraColors.inkTertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Active phase row ──────────────────────────────────────────────────────────

class _ActivePhaseRow extends StatelessWidget {
  const _ActivePhaseRow({required this.phase});
  final ProjectPhase phase;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AuroraColors.lime,
          borderRadius: AuroraRadius.md,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AuroraColors.limeDeep.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.build_outlined,
                size: 14,
                color: AuroraColors.limeDeep,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phase.name,
                    style: AuroraType.body.copyWith(
                      color: AuroraColors.limeDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (phase.description != null &&
                      phase.description!.isNotEmpty)
                    Text(
                      phase.description!,
                      style: AuroraType.bodySm.copyWith(
                        color: AuroraColors.limeDeep,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AuroraColors.limeDeep,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'IN PROGRESS',
                style: AuroraType.labelSm.copyWith(
                  color: AuroraColors.lime,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Upcoming phase row ────────────────────────────────────────────────────────

class _UpcomingPhaseRow extends StatelessWidget {
  const _UpcomingPhaseRow({required this.phase});
  final ProjectPhase phase;

  @override
  Widget build(BuildContext context) {
    final dateStr = _phaseShortDate(phase);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AuroraColors.paper,
          borderRadius: AuroraRadius.md,
          border: Border.all(color: AuroraColors.inkBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AuroraColors.butter,
                border: Border.all(color: AuroraColors.inkBorderStrong),
              ),
              child: Center(
                child: Text(
                  '${phase.sortOrder + 1}',
                  style: AuroraType.labelSm.copyWith(
                    color: AuroraColors.inkTertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phase.name,
                    style: AuroraType.body.copyWith(color: AuroraColors.ink),
                  ),
                  if (phase.description != null &&
                      phase.description!.isNotEmpty)
                    Text(
                      phase.description!.toUpperCase(),
                      style: AuroraType.labelSm.copyWith(
                        color: AuroraColors.inkSecondary,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (dateStr.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                dateStr,
                style: AuroraType.labelSm
                    .copyWith(color: AuroraColors.inkSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Activity section ──────────────────────────────────────────────────────────

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({
    required this.project,
    required this.projectId,
    required this.phases,
    required this.notes,
  });

  final Project project;
  final String projectId;
  final List<ProjectPhase> phases;
  final List<ProjectJournalNote> notes;

  @override
  Widget build(BuildContext context) {
    final unlinkedNotes =
        notes.where((n) => n.phaseId == null).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVITY',
            style: AuroraType.labelSm.copyWith(
              color: AuroraColors.inkTertiary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          if (unlinkedNotes.isNotEmpty)
            _TimelineList(notes: unlinkedNotes, projectId: projectId)
          else
            _EmptyTimeline(phases: phases, project: project),

          const SizedBox(height: 16),

          _AddEntryButton(
            onTap: () => context.push('/projects/$projectId/notes/create'),
          ),

          if (phases.isEmpty) ...[
            const SizedBox(height: 16),
            _TemplatePrompt(
              project: project,
              projectId: projectId,
            ),
          ],
        ],
      ),
    );
  }
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
        color: AuroraColors.cobalt,
        route: '/projects/$projectId/phases',
      ),
      (
        icon: Icons.account_balance_wallet_outlined,
        label: 'Budget',
        metric:
            hasBudget ? _compact(project.estimatedBudget!) : 'Not set',
        color: isOverBudget ? AuroraColors.coral : AuroraColors.limeDeep,
        route: '/projects/$projectId/budget',
      ),
      (
        icon: Icons.photo_library_outlined,
        label: 'Photos',
        metric: 'Progress shots',
        color: AuroraColors.coral,
        route: '/projects/$projectId/photos',
      ),
      (
        icon: Icons.menu_book_outlined,
        label: 'Journal',
        metric: notes.isEmpty
            ? 'Start logging'
            : '${notes.length} note${notes.length == 1 ? '' : 's'}',
        color: AuroraColors.yellow,
        route: '/projects/$projectId/notes',
      ),
      (
        icon: Icons.people_outline,
        label: 'Contractors',
        metric: project.contractorIds.isEmpty
            ? 'None linked'
            : '${project.contractorIds.length} linked',
        color: AuroraColors.cobalt,
        route: '/projects/$projectId/contractors',
      ),
      (
        icon: Icons.folder_outlined,
        label: 'Documents',
        metric: 'Permits, quotes',
        color: AuroraColors.cobalt,
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
          color: AuroraColors.paper,
          borderRadius: AuroraRadius.md,
          border: Border.all(color: AuroraColors.inkBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: AuroraRadius.sm,
              ),
              child: Icon(section.icon, size: 15, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              section.label,
              style: AuroraType.bodySm.copyWith(
                fontWeight: FontWeight.w700,
                color: AuroraColors.ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              section.metric,
              style: AuroraType.label.copyWith(
                color: AuroraColors.inkTertiary,
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

// ── Timeline list (notes only) ────────────────────────────────────────────────

class _TimelineList extends StatelessWidget {
  const _TimelineList({required this.notes, required this.projectId});

  final List<ProjectJournalNote> notes;
  final String projectId;

  static const double _dotColW = 26;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          left: _dotColW / 2 - 1,
          top: 13,
          bottom: 0,
          child: SizedBox(
            width: 2,
            child: ColoredBox(color: AuroraColors.inkBorder),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: notes
              .map((n) => _NoteTimelineCard(note: n, projectId: projectId))
              .toList(),
        ),
      ],
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
                    color: AuroraColors.yellowDim,
                    border: Border.all(color: AuroraColors.yellow, width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AuroraColors.paper,
                borderRadius: AuroraRadius.md,
                border: Border.all(color: AuroraColors.inkBorder),
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
                          style: AuroraType.label.copyWith(
                            color: AuroraColors.inkTertiary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AuroraColors.yellowDim,
                            borderRadius: AuroraRadius.xs,
                          ),
                          child: Text(
                            'NOTE',
                            style: AuroraType.labelSm.copyWith(
                              color: AuroraColors.yellow,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (note.title != null && note.title!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(note.title!, style: AuroraType.body),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      note.content,
                      style: AuroraType.bodySm.copyWith(
                        color: AuroraColors.inkSecondary,
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
  });

  final List<ProjectPhase> phases;
  final Project project;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        phases.isEmpty
            ? 'Add phases and notes to track this project\'s progress.'
            : 'No notes yet. Tap "Add note" below to start the project log.',
        style: AuroraType.bodySm.copyWith(color: AuroraColors.inkTertiary),
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
          color: AuroraColors.inkBorderStrong,
          radius: 12,
          strokeWidth: 1.5,
          dashLength: 5,
          gapLength: 4,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AuroraColors.paper,
            borderRadius: AuroraRadius.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, size: 18, color: AuroraColors.coral),
              const SizedBox(width: 8),
              Text(
                'Add note, photo, or document',
                style: AuroraType.bodySm.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AuroraColors.coral,
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
  });

  final Project project;
  final String projectId;

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
      padding: const EdgeInsets.all(AuroraSpacing.space7),
      decoration: BoxDecoration(
        color: AuroraColors.cobaltDim,
        borderRadius: AuroraRadius.md,
        border: Border.all(color: AuroraColors.cobalt.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Start with a template', style: AuroraType.h3),
          const SizedBox(height: AuroraSpacing.space1),
          Text(
            'Load starter phases for a '
            '${widget.project.projectType.projectTypeLabel} project.',
            style:
                AuroraType.bodySm.copyWith(color: AuroraColors.inkSecondary),
          ),
          const SizedBox(height: AuroraSpacing.space3),
          Row(
            children: [
              Expanded(
                child: SaveButton(
                  label: 'Load Template',
                  onPressed: _loading ? null : _loadTemplates,
                  loading: _loading,
                  expand: true,
                ),
              ),
              const SizedBox(width: AuroraSpacing.space3),
              GhostButton(
                label: 'Add Manually',
                onPressed: () => context
                    .push('/projects/${widget.projectId}/phases/create'),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero placeholder
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 140,
                  color: AuroraColors.coral.withValues(alpha: 0.6),
                ),
              ),
            ),

            // Tab bar placeholder
            Container(
              height: 52,
              color: AuroraColors.paper,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: List.generate(
                  5,
                  (i) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: AuroraColors.butter,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: AuroraColors.inkBorder),

            // Phase rows placeholder
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                children: List.generate(
                  4,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: AuroraColors.butter,
                        borderRadius: AuroraRadius.md,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
