import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_typography.dart';

import '../models/project.dart';
import '../models/project_phase.dart';
import '../providers/project_phases_provider.dart';

String _compact(double v) {
  if (v >= 1000) {
    final k = v / 1000;
    return '\$${k % 1 == 0 ? k.toInt().toString() : k.toStringAsFixed(1)}k';
  }
  return '\$${NumberFormat('#,###').format(v.toInt())}';
}

class ProjectPhaseTimelineCard extends ConsumerWidget {
  const ProjectPhaseTimelineCard({
    super.key,
    required this.project,
    required this.onOpen,
  });

  final Project project;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPhases = ref.watch(projectPhasesProvider(project.id));

    return asyncPhases.when(
      loading: () => _CardShell(project: project, onOpen: onOpen, child: const _PhasesSkeleton()),
      error: (_, _) => _CardShell(
        project: project,
        onOpen: onOpen,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, size: 28, color: AuroraColors.inkTertiary),
                const SizedBox(height: 8),
                Text(
                  "Couldn't load phases",
                  style: AuroraType.bodySm.copyWith(color: AuroraColors.inkSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      data: (phases) {
        final visible = phases
            .where((p) => p.status != 'cancelled' && p.deletedAt == null)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        return _CardShell(
          project: project,
          onOpen: onOpen,
          phases: visible,
          child: visible.isEmpty
              ? const _NoPhasesMessage()
              : _PhaseTimeline(phases: visible),
        );
      },
    );
  }
}

// ── Card shell ────────────────────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.project,
    required this.onOpen,
    required this.child,
    this.phases,
  });

  final Project project;
  final VoidCallback onOpen;
  final List<ProjectPhase>? phases;
  final Widget child;

  static String _statusLabel(String s) => switch (s) {
        'in_progress' => 'IN PROGRESS',
        'planning'    => 'PLANNING',
        'on_hold'     => 'ON HOLD',
        'completed'   => 'COMPLETED',
        'cancelled'   => 'CANCELLED',
        _             => s.toUpperCase(),
      };

  static Color _statusDot(String s) => switch (s) {
        'in_progress' => AuroraColors.coral,
        'planning'    => AuroraColors.yellow,
        'on_hold'     => AuroraColors.yellow,
        'completed'   => AuroraColors.lime,
        _             => const Color(0xFF9D9BB0),
      };

  static Color _statusBorderColor(String s) => switch (s) {
        'in_progress' => AuroraColors.coral,
        'planning'    => AuroraColors.yellow,
        'on_hold'     => AuroraColors.yellow,
        'completed'   => AuroraColors.lime,
        'cancelled'   => AuroraColors.inkTertiary,
        _             => AuroraColors.ink,
      };

  @override
  Widget build(BuildContext context) {
    final done = phases?.where((p) => p.status == 'completed').length ?? 0;
    final total = phases?.length ?? 0;
    final pct = total > 0 ? (done / total * 100).round() : 0;
    final hasBudget = project.estimatedBudget != null;

    return GestureDetector(
      onTap: onOpen,
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AuroraColors.ink,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statusBorderColor(project.status).withValues(alpha: 0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AuroraColors.ink.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero header — cover photo or solid color
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1D38),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              image: project.coverPhotoPath != null
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(project.coverPhotoPath!),
                      fit: BoxFit.cover,
                      colorFilter: const ColorFilter.mode(
                        Color(0xCC000000),
                        BlendMode.darken,
                      ),
                    )
                  : null,
            ),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 7),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _statusDot(project.status),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _statusLabel(project.status),
                        style: AuroraType.label.copyWith(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 9,
                          letterSpacing: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  project.name,
                  style: AuroraType.h2.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.05,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Stat('$total ${total == 1 ? 'phase' : 'phases'}'),
                    _StatDot(),
                    _Stat('$pct% done'),
                    if (hasBudget) ...[
                      _StatDot(),
                      _Stat(
                        '${_compact(project.actualSpent)} / ${_compact(project.estimatedBudget!)}',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Timeline — white background
          Expanded(
            child: Container(
              color: AuroraColors.paper,
              child: child,
            ),
          ),
          // Footer strip inside card
          _InCardFooter(
            project: project,
            onOpen: onOpen,
            activePhase: phases?.where((p) => p.status == 'in_progress').firstOrNull,
          ),
        ],
      ),
    ),
    );
  }
}

class _InCardFooter extends StatelessWidget {
  const _InCardFooter({
    required this.project,
    required this.onOpen,
    this.activePhase,
  });

  final Project project;
  final VoidCallback onOpen;
  final ProjectPhase? activePhase;

  @override
  Widget build(BuildContext context) {
    final hasBudget = project.estimatedBudget != null;
    final remaining = hasBudget
        ? (project.estimatedBudget! - project.actualSpent).clamp(0.0, double.infinity)
        : null;

    return Container(
      decoration: const BoxDecoration(
        color: AuroraColors.butter,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (remaining != null) ...[
            Text(
              _compact(remaining),
              style: AuroraType.h1.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: remaining > 0 ? AuroraColors.ink : AuroraColors.coral,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'REMAINING BUDGET',
              style: AuroraType.label.copyWith(
                fontSize: 8,
                color: AuroraColors.inkSecondary,
                letterSpacing: 1.0,
              ),
            ),
          ] else if (activePhase != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CURRENT PHASE',
                  style: AuroraType.label.copyWith(
                    fontSize: 8,
                    color: AuroraColors.inkSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activePhase!.name,
                  style: AuroraType.h3.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AuroraColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
          const Spacer(),
          GestureDetector(
            onTap: onOpen,
            child: Container(
              constraints: const BoxConstraints(minHeight: 36),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AuroraColors.ink,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Open',
                    style: AuroraType.label.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios, size: 9, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AuroraType.label.copyWith(
        fontSize: 11,
        color: Colors.white.withValues(alpha: 0.75),
      ),
    );
  }
}

class _StatDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

// ── Phase timeline ─────────────────────────────────────────────────────────────

enum _DotState { done, current, upcoming }

class _PhaseTimeline extends StatelessWidget {
  const _PhaseTimeline({required this.phases});

  final List<ProjectPhase> phases;

  _DotState _stateFor(ProjectPhase phase) {
    if (phase.status == 'completed') return _DotState.done;
    if (phase.status == 'in_progress') return _DotState.current;
    return _DotState.upcoming;
  }

  @override
  Widget build(BuildContext context) {
    final states = phases.map(_stateFor).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Column(
        children: [
          for (int i = 0; i < phases.length; i++)
            _PhaseRow(
              phase: phases[i],
              index: i,
              state: states[i],
              isLast: i == phases.length - 1,
            ),
        ],
      ),
    );
  }
}

class _PhaseRow extends StatelessWidget {
  const _PhaseRow({
    required this.phase,
    required this.index,
    required this.state,
    required this.isLast,
  });

  final ProjectPhase phase;
  final int index;
  final _DotState state;
  final bool isLast;

  Color get _connectorColor => switch (state) {
        _DotState.done     => AuroraColors.lime,
        _DotState.current  => AuroraColors.coral,
        _DotState.upcoming => AuroraColors.inkBorderStrong,
      };

  // Right-side label: "DONE · JAN 15" / "NOW · 12D LEFT" / "APR 20"
  ({String label, Color color}) _rightLabel() {
    switch (state) {
      case _DotState.done:
        final end = phase.actualEndDate ?? phase.plannedEndDate;
        final dateStr = end != null ? ' · ${DateFormat('MMM d').format(end).toUpperCase()}' : '';
        return (label: 'DONE$dateStr', color: AuroraColors.lime);

      case _DotState.current:
        final end = phase.plannedEndDate;
        String suffix = '';
        if (end != null) {
          final days = end.difference(DateTime.now()).inDays;
          if (days > 0) {
            suffix = ' · ${days}D LEFT';
          } else if (days == 0) {
            suffix = ' · TODAY';
          } else {
            suffix = ' · ${-days}D OVER';
          }
        }
        return (label: 'NOW$suffix', color: AuroraColors.coral);

      case _DotState.upcoming:
        final start = phase.plannedStartDate;
        final label = start != null ? DateFormat('MMM d').format(start).toUpperCase() : '';
        return (label: label, color: AuroraColors.inkSecondary.withValues(alpha: 0.6));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = state == _DotState.done;
    final isCurrent = state == _DotState.current;
    final right = _rightLabel();
    final hasSubtitle = phase.description != null && phase.description!.isNotEmpty;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot + connector
          SizedBox(
            width: 22,
            child: Column(
              children: [
                const SizedBox(height: 4),
                _Dot(state: state, number: index + 1),
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        color: _connectorColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2, bottom: isLast ? 4 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          phase.name,
                          style: AuroraType.h3.copyWith(
                            fontSize: 14,
                            fontWeight: isDone || isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color: (!isDone && !isCurrent)
                                ? AuroraColors.ink.withValues(alpha: 0.4)
                                : AuroraColors.ink,
                            fontStyle: FontStyle.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (right.label.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          right.label,
                          style: AuroraType.label.copyWith(
                            fontSize: 9,
                            color: right.color,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (hasSubtitle)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        phase.description!,
                        style: AuroraType.bodySm.copyWith(
                          fontSize: 10,
                          color: AuroraColors.inkSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.state, required this.number});

  final _DotState state;
  final int number;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      _DotState.done => Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AuroraColors.lime,
          ),
          child: const Icon(Icons.check, size: 13, color: Colors.white),
        ),
      _DotState.current => Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AuroraColors.coral,
            boxShadow: [
              BoxShadow(
                color: AuroraColors.coral.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$number',
              style: AuroraType.label.copyWith(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      _DotState.upcoming => Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AuroraColors.butter,
            border: Border.all(color: AuroraColors.inkBorderStrong, width: 1.5),
          ),
          child: Center(
            child: Text(
              '$number',
              style: AuroraType.label.copyWith(
                fontSize: 10,
                color: const Color(0xFF9D9BB0),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
    };
  }
}

// ── Empty / skeleton states ────────────────────────────────────────────────────

class _NoPhasesMessage extends StatelessWidget {
  const _NoPhasesMessage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No phases added yet.\nOpen the project to set up your timeline.',
          style: AuroraType.body.copyWith(
            color: Colors.white.withValues(alpha: 0.55),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _PhasesSkeleton extends StatelessWidget {
  const _PhasesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        children: List.generate(
          3,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
