import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../home_profile/providers/home_profile_provider.dart';
import '../models/maintenance_task.dart';
import '../providers/maintenance_tasks_provider.dart';
import '../../../core/theme/aurora_radius.dart';

// ── Season helpers ─────────────────────────────────────────────────────────────

String _currentSeason() {
  final m = DateTime.now().month;
  if (m >= 3 && m <= 5) return 'spring';
  if (m >= 6 && m <= 8) return 'summer';
  if (m >= 9 && m <= 11) return 'fall';
  return 'winter';
}

String _seasonPhaseLabel(int month) => switch (month) {
      3 => 'EARLY SPRING',
      4 => 'SPRING',
      5 => 'LATE SPRING',
      6 => 'EARLY SUMMER',
      7 => 'SUMMER',
      8 => 'LATE SUMMER',
      9 => 'EARLY FALL',
      10 => 'FALL',
      11 => 'LATE FALL',
      12 => 'EARLY WINTER',
      1 => 'WINTER',
      _ => 'LATE WINTER',
    };

IconData _seasonIcon(String season) => switch (season) {
      'spring' => Icons.eco_outlined,
      'summer' => Icons.wb_sunny_outlined,
      'fall' => Icons.park_outlined,
      _ => Icons.ac_unit_outlined,
    };

IconData _categoryIcon(String category) {
  final lower = category.toLowerCase();
  if (lower.contains('hvac') || lower.contains('heat') || lower.contains('ac')) {
    return Icons.ac_unit_outlined;
  }
  if (lower.contains('plumb') || lower.contains('water')) {
    return Icons.water_drop_outlined;
  }
  if (lower.contains('electric')) return Icons.electrical_services_outlined;
  if (lower.contains('roof')) return Icons.roofing_outlined;
  if (lower.contains('lawn') || lower.contains('garden') || lower.contains('exterior')) {
    return Icons.yard_outlined;
  }
  if (lower.contains('pest')) return Icons.bug_report_outlined;
  if (lower.contains('gutter')) return Icons.water_outlined;
  return Icons.build_outlined;
}

String _timeLabel(int? minutes) {
  if (minutes == null) return '';
  if (minutes < 60) return '$minutes MIN';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (m == 0) return '$h HR${h > 1 ? 'S' : ''}';
  return '${h}H ${m}M';
}

// ── Main sliver widget ─────────────────────────────────────────────────────────

class SeasonalView extends ConsumerWidget {
  const SeasonalView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(maintenanceTasksProvider);
    final profileAsync = ref.watch(homeProfileProvider);

    return tasksAsync.when(
      loading: () => _SeasonalSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (allTasks) {
        final season = _currentSeason();
        final seasonalTasks = allTasks
            .where((t) =>
                t.season?.toLowerCase() == season &&
                t.status != TaskStatus.skipped)
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

        final completed =
            seasonalTasks.where((t) => t.status == TaskStatus.completed).length;
        final total = seasonalTasks.length;
        final progress = total > 0 ? (completed / total * 100).round() : 0;

        final today = DateTime.now();
        final todayMid = DateTime(today.year, today.month, today.day);

        final upNext = seasonalTasks
            .where((t) => t.status != TaskStatus.completed)
            .toList();

        // Nullable — only used when upNext is non-empty.
        final MaintenanceTask? urgent = upNext.isEmpty
            ? null
            : upNext.firstWhere(
                (t) {
                  final due = t.dueDate.toLocal();
                  final dueMid = DateTime(due.year, due.month, due.day);
                  return t.status == TaskStatus.overdue ||
                      dueMid.isBefore(todayMid) ||
                      dueMid == todayMid;
                },
                orElse: () => upNext.first,
              );

        final city = profileAsync.value?.property.city;
        final zone = profileAsync.value?.property.climateZone;

        return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _HeroCard(
                  season: season,
                  total: total,
                  completed: completed,
                  progress: progress,
                  city: city,
                  climateZone: zone,
                ),
                if (urgent != null) ...[
                  const SizedBox(height: 8),
                  _SpotlightCard(task: urgent),
                ],
                const SizedBox(height: 16),
                if (total == 0) ...[
                  _EmptyState(season: season),
                ] else ...[
                  Row(
                    children: [
                      Text(
                        '${season.toUpperCase()} CHECKLIST',
                        style: AuroraType.label,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${upNext.length} of $total',
                        style: AuroraType.label.copyWith(
                          color: AuroraColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Up next.', style: AuroraType.h2),
                  const SizedBox(height: 12),
                  if (upNext.isEmpty)
                    _AllDoneCard()
                  else
                    ...upNext.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SeasonalTaskCard(
                          task: t,
                          onTap: () => context.push(
                            '/maintenance/${t.id}',
                          ),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          );
      },
    );
  }
}

// ── Hero card ──────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.season,
    required this.total,
    required this.completed,
    required this.progress,
    this.city,
    this.climateZone,
  });

  final String season;
  final int total;
  final int completed;
  final int progress;
  final String? city;
  final int? climateZone;

  @override
  Widget build(BuildContext context) {
    final month = DateFormat('MMMM').format(DateTime.now());
    final phase = _seasonPhaseLabel(DateTime.now().month);
    final icon = _seasonIcon(season);

    String locationLine = '';
    if (climateZone != null && city != null) {
      locationLine = 'Climate zone $climateZone · $city';
    } else if (city != null) {
      locationLine = city!;
    } else if (climateZone != null) {
      locationLine = 'Climate zone $climateZone';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuroraColors.ink,
        borderRadius: AuroraRadius.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AuroraColors.limeDeep,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$phase · IN SEASON',
                style: AuroraType.label.copyWith(
                  color: AuroraColors.paper.withValues(alpha: 0.7),
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Icon(icon, size: 28, color: AuroraColors.paper.withValues(alpha: 0.7)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$month\nchecklist.',
            style: AuroraType.h1.copyWith(
              color: AuroraColors.paper,
              height: 1.1,
            ),
          ),
          if (locationLine.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              locationLine,
              style: AuroraType.bodySm.copyWith(
                color: AuroraColors.paper.withValues(alpha: 0.6),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _StatBlock(value: '$total', label: 'IN SEASON'),
              const SizedBox(width: 16),
              _StatBlock(value: '$completed', label: 'DONE'),
              const SizedBox(width: 16),
              _StatBlock(value: '$progress%', label: 'PROGRESS'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AuroraType.number.copyWith(
            color: AuroraColors.paper,
            fontSize: 22,
          ),
        ),
        Text(
          label,
          style: AuroraType.labelSm.copyWith(
            color: AuroraColors.paper.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

// ── Spotlight card ─────────────────────────────────────────────────────────────

class _SpotlightCard extends StatelessWidget {
  const _SpotlightCard({required this.task});

  final MaintenanceTask task;

  String get _tag {
    final today = DateTime.now();
    final todayMid = DateTime(today.year, today.month, today.day);
    final dueMid = DateTime(task.dueDate.toLocal().year,
        task.dueDate.toLocal().month, task.dueDate.toLocal().day);
    if (task.status == TaskStatus.overdue || dueMid.isBefore(todayMid)) {
      return 'OVERDUE';
    }
    return 'UP NEXT';
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = _tag == 'OVERDUE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.lg,
        border: Border.all(color: AuroraColors.inkBorder, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isOverdue
                  ? AuroraColors.coral.withValues(alpha: 0.12)
                  : AuroraColors.limeDeep.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOverdue ? Icons.schedule_outlined : Icons.arrow_upward,
              size: 18,
              color: isOverdue ? AuroraColors.coral : AuroraColors.limeDeep,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tag,
                  style: AuroraType.label.copyWith(
                    color: isOverdue ? AuroraColors.coral : AuroraColors.limeDeep,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.name,
                  style: AuroraType.body.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/maintenance/${task.id}'),
            child: Row(
              children: [
                Text(
                  'Start',
                  style: AuroraType.label.copyWith(
                    color: AuroraColors.coral,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 16, color: AuroraColors.coral),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Seasonal task card ─────────────────────────────────────────────────────────

class _SeasonalTaskCard extends StatelessWidget {
  const _SeasonalTaskCard({required this.task, required this.onTap});

  final MaintenanceTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = _categoryIcon(task.category);
    final timeLabel = _timeLabel(task.estimatedMinutes);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AuroraColors.paper,
          borderRadius: AuroraRadius.lg,
          border: Border.all(color: AuroraColors.inkBorder, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AuroraColors.butter,
                borderRadius: AuroraRadius.sm,
              ),
              child: Icon(icon, size: 20, color: AuroraColors.inkSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.name,
                          style: AuroraType.body.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _DiyProBadge(diyOrPro: task.diyOrPro),
                    ],
                  ),
                  if (task.description != null &&
                      task.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description!,
                      style: AuroraType.bodySm.copyWith(
                        color: AuroraColors.inkSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (timeLabel.isNotEmpty)
                        _Tag(label: timeLabel, color: AuroraColors.yellowDeep),
                      if (timeLabel.isNotEmpty) const SizedBox(width: 6),
                      _Tag(
                        label: task.category.toUpperCase(),
                        color: AuroraColors.inkSecondary,
                        background: AuroraColors.butter,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiyProBadge extends StatelessWidget {
  const _DiyProBadge({required this.diyOrPro});

  final DiyOrPro diyOrPro;

  @override
  Widget build(BuildContext context) {
    if (diyOrPro == DiyOrPro.diy) {
      return _Tag(label: 'DIY', color: AuroraColors.limeDeep);
    }
    if (diyOrPro == DiyOrPro.professional) {
      return _Tag(label: 'PRO', color: AuroraColors.cobalt);
    }
    return const SizedBox.shrink();
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.color,
    this.background,
  });

  final String label;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.12),
        borderRadius: AuroraRadius.xs,
      ),
      child: Text(
        label,
        style: AuroraType.label.copyWith(color: color),
      ),
    );
  }
}

// ── All done card ──────────────────────────────────────────────────────────────

class _AllDoneCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AuroraColors.limeDeep.withValues(alpha: 0.08),
        borderRadius: AuroraRadius.lg,
        border: Border.all(
            color: AuroraColors.limeDeep.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline,
              size: 32, color: AuroraColors.limeDeep),
          const SizedBox(height: 8),
          Text("You're all caught up!",
              style: AuroraType.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AuroraColors.limeDeep,
              )),
          const SizedBox(height: 4),
          Text(
            'All seasonal tasks are done for this season.',
            style: AuroraType.bodySm.copyWith(
              color: AuroraColors.inkSecondary,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.season});

  final String season;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.lg,
        border: Border.all(color: AuroraColors.inkBorder, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(_seasonIcon(season), size: 32, color: AuroraColors.inkTertiary),
          const SizedBox(height: 8),
          Text('No seasonal tasks yet',
              style: AuroraType.body.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'Tasks tagged for $season will appear here.',
            style: AuroraType.bodySm.copyWith(
              color: AuroraColors.inkSecondary,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ───────────────────────────────────────────────────────────────────

class _SeasonalSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AuroraColors.butter,
      highlightColor: AuroraColors.paper,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Container(
              height: 196,
              decoration: BoxDecoration(
                color: AuroraColors.butter,
                borderRadius: AuroraRadius.xl,
              ),
            ),
            const SizedBox(height: 16),
            Container(height: 10, width: 140, color: AuroraColors.butter),
            const SizedBox(height: 8),
            Container(height: 18, width: 100, color: AuroraColors.butter),
            const SizedBox(height: 12),
            _SkeletonTaskCard(),
            const SizedBox(height: 8),
            _SkeletonTaskCard(),
            const SizedBox(height: 8),
            _SkeletonTaskCard(),
          ],
        ),
      ),
    );
  }
}

class _SkeletonTaskCard extends StatelessWidget {
  const _SkeletonTaskCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: AuroraColors.butter,
        borderRadius: AuroraRadius.lg,
      ),
    );
  }
}
