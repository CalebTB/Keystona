import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home_profile/providers/home_profile_provider.dart';
import '../models/maintenance_task.dart';
import '../providers/maintenance_tasks_provider.dart';

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
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSizes.md),
                _HeroCard(
                  season: season,
                  total: total,
                  completed: completed,
                  progress: progress,
                  city: city,
                  climateZone: zone,
                ),
                if (urgent != null) ...[
                  const SizedBox(height: AppSizes.sm),
                  _SpotlightCard(task: urgent),
                ],
                const SizedBox(height: AppSizes.lg),
                if (total == 0) ...[
                  _EmptyState(season: season),
                ] else ...[
                  Row(
                    children: [
                      Text(
                        '${season.toUpperCase()} CHECKLIST',
                        style: AppTextStyles.monoSection,
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Text(
                        '${upNext.length} of $total',
                        style: AppTextStyles.monoSection.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text('Up next.', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: AppSizes.md),
                  if (upNext.isEmpty)
                    _AllDoneCard()
                  else
                    ...upNext.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.sm),
                        child: _SeasonalTaskCard(
                          task: t,
                          onTap: () => context.push(
                            '/maintenance/${t.id}',
                          ),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: AppSizes.xl),
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
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.forestGreen,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
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
                  color: AppColors.olive,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSizes.xs),
              Text(
                '$phase · IN SEASON',
                style: AppTextStyles.monoSection.copyWith(
                  color: AppColors.forestGreenLight,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Icon(icon, size: 28, color: AppColors.forestGreenLight),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            '$month\nchecklist.',
            style: AppTextStyles.displayMedium.copyWith(
              color: AppColors.warmOffWhite,
              height: 1.1,
            ),
          ),
          if (locationLine.isNotEmpty) ...[
            const SizedBox(height: AppSizes.xs),
            Text(
              locationLine,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.darkTextSecondary,
                fontFamily: 'IBM Plex Mono',
              ),
            ),
          ],
          const SizedBox(height: AppSizes.lg),
          Row(
            children: [
              _StatBlock(value: '$total', label: 'IN SEASON'),
              const SizedBox(width: AppSizes.lg),
              _StatBlock(value: '$completed', label: 'DONE'),
              const SizedBox(width: AppSizes.lg),
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
          style: AppTextStyles.monoDisplay.copyWith(
            color: AppColors.warmOffWhite,
            fontSize: 22,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.monoTiny.copyWith(
            color: AppColors.darkTextSecondary,
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
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.cardPadding, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isOverdue
                  ? AppColors.accent.withValues(alpha: 0.12)
                  : AppColors.olive.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOverdue ? Icons.schedule_outlined : Icons.arrow_upward,
              size: 18,
              color: isOverdue ? AppColors.accent : AppColors.olive,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tag,
                  style: AppTextStyles.monoSection.copyWith(
                    color: isOverdue ? AppColors.accent : AppColors.olive,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.name,
                  style: AppTextStyles.bodyMediumSemibold,
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
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 16, color: AppColors.accent),
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
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.warmFill,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(icon, size: 20, color: AppColors.textSecondary),
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
                          style: AppTextStyles.bodyMediumSemibold,
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
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
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
                        _Tag(label: timeLabel, color: AppColors.sandAmber),
                      if (timeLabel.isNotEmpty) const SizedBox(width: 6),
                      _Tag(
                        label: task.category.toUpperCase(),
                        color: AppColors.textSecondary,
                        background: AppColors.warmFill,
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
      return _Tag(label: 'DIY', color: AppColors.olive);
    }
    if (diyOrPro == DiyOrPro.professional) {
      return _Tag(label: 'PRO', color: AppColors.slate);
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
        borderRadius: BorderRadius.circular(AppSizes.radiusXs),
      ),
      child: Text(
        label,
        style: AppTextStyles.monoSection.copyWith(color: color),
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
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: AppColors.olive.withValues(alpha: 0.08),
        borderRadius: AppRadius.card,
        border: Border.all(
            color: AppColors.olive.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline,
              size: 32, color: AppColors.olive),
          const SizedBox(height: AppSizes.sm),
          Text("You're all caught up!",
              style:
                  AppTextStyles.bodyMediumSemibold.copyWith(color: AppColors.olive)),
          const SizedBox(height: 4),
          Text(
            'All seasonal tasks are done for this season.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
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
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(_seasonIcon(season), size: 32, color: AppColors.gray400),
          const SizedBox(height: AppSizes.sm),
          Text('No seasonal tasks yet',
              style: AppTextStyles.bodyMediumSemibold),
          const SizedBox(height: 4),
          Text(
            'Tasks tagged for $season will appear here.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
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
      baseColor: AppColors.gray200,
      highlightColor: AppColors.gray100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSizes.md),
            Container(
              height: 196,
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Container(height: 10, width: 140, color: AppColors.gray200),
            const SizedBox(height: AppSizes.sm),
            Container(height: 18, width: 100, color: AppColors.gray200),
            const SizedBox(height: AppSizes.md),
            _SkeletonTaskCard(),
            const SizedBox(height: AppSizes.sm),
            _SkeletonTaskCard(),
            const SizedBox(height: AppSizes.sm),
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
        color: AppColors.gray200,
        borderRadius: AppRadius.card,
      ),
    );
  }
}
