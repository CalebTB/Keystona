import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/aurora/aurora.dart';
import '../../../core/widgets/trial_banner.dart';
import '../../../features/maintenance/widgets/overdue_banner.dart';
import '../../../features/maintenance/widgets/task_card.dart';
import '../providers/dashboard_provider.dart';

/// Home tab root screen — Aurora Design System v2.0.
///
/// White paper canvas. Coral hero. Butter quick-action tiles. Ink typography.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardProvider);

    return CupertinoPageScaffold(
      backgroundColor: AuroraColors.paper,
      child: dashAsync.when(
        loading: () => const _DashboardSkeleton(),
        error: (_, _) => _ErrorView(
          onRetry: () => ref.invalidate(dashboardProvider),
        ),
        data: (data) => CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
            ),

            // ── A. Greeting header ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AuroraSpacing.screenPadH,
                    AuroraSpacing.screenPadTop,
                    AuroraSpacing.screenPadH,
                    0,
                  ),
                  child: _GreetingHeader(data: data),
                ),
              ),
            ),

            // ── B. Aurora hero card (coral) ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AuroraSpacing.screenPadH,
                  AuroraSpacing.space7,
                  AuroraSpacing.screenPadH,
                  0,
                ),
                child: _ScoreHero(data: data),
              ),
            ),

            // ── C. Quick actions row ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AuroraSpacing.screenPadH,
                  AuroraSpacing.space5,
                  AuroraSpacing.screenPadH,
                  0,
                ),
                child: const _QuickActionsRow(),
              ),
            ),

            // ── D. Your Home section ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AuroraSpacing.screenPadH,
                  AuroraSpacing.space5,
                  AuroraSpacing.screenPadH,
                  0,
                ),
                child: _YourHomeSection(data: data),
              ),
            ),

            // ── E. Overdue banner (conditional) ────────────────────────────
            if (data.overdueTasks.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AuroraSpacing.screenPadH,
                    AuroraSpacing.space5,
                    AuroraSpacing.screenPadH,
                    0,
                  ),
                  child: OverdueBanner(overdueTasks: data.overdueTasks),
                ),
              ),

            // ── F. Coming Up section (conditional) ─────────────────────────
            if (data.upcomingTasks.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AuroraSpacing.screenPadH,
                    AuroraSpacing.space5,
                    AuroraSpacing.screenPadH,
                    0,
                  ),
                  child: _ComingUpSection(data: data),
                ),
              ),

            // ── G. Trial banner ────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AuroraSpacing.screenPadH,
                  AuroraSpacing.space5,
                  AuroraSpacing.screenPadH,
                  0,
                ),
                child: TrialBanner(),
              ),
            ),

            const SliverSafeArea(
              top: false,
              minimum: EdgeInsets.only(bottom: AuroraSpacing.screenPadBottom),
              sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Greeting header ────────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.data});

  final DashboardData data;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _subtitle {
    final overdue = data.overdueTasks;
    if (overdue.isNotEmpty) {
      if (overdue.length == 1) return '${overdue.first.name} needs attention';
      return '${overdue.length} tasks need attention';
    }
    return 'Your home is looking good';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$_greeting, ${data.firstName}',
          style: AuroraType.h1,
        ),
        const SizedBox(height: 4),
        Text(
          _subtitle,
          style: AuroraType.body.copyWith(color: AuroraColors.inkSecondary),
        ),
      ],
    );
  }
}

// ── Score hero (coral) ─────────────────────────────────────────────────────────

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({required this.data});

  final DashboardData data;

  String _trendLabel(String trend) => switch (trend) {
        'improving' => '↗ Improving this month',
        'declining' => '↘ Needs attention',
        _ => '→ Stable this month',
      };

  @override
  Widget build(BuildContext context) {
    final score = data.score;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Property address row — sits above the coral card.
        if (data.property != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AuroraSpacing.space3),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.house,
                  size: 12,
                  color: AuroraColors.inkSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    data.property!.addressLine1,
                    style: AuroraType.label.copyWith(
                      color: AuroraColors.inkSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.homeEdit),
                  child: const Icon(
                    CupertinoIcons.settings,
                    size: 16,
                    color: AuroraColors.inkSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: AuroraSpacing.space3),
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.homeEdit),
              child: Text(
                'Set up your home →',
                style: AuroraType.label.copyWith(color: AuroraColors.coral),
              ),
            ),
          ),

        // Aurora coral hero card.
        AuroraHeroCard(
          score: score.score,
          trend: _trendLabel(score.trend),
          maintScore: score.score,
          docsScore: 0,
          emergScore: 0,
        ),
      ],
    );
  }
}

// ── Quick actions row ──────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: CupertinoIcons.camera_viewfinder,
            label: 'SCAN',
            tileColor: AuroraColors.cobalt,
            iconColor: AuroraColors.paper,
            onTap: () => context.push(AppRoutes.homeAppliancesAdd),
          ),
        ),
        const SizedBox(width: AuroraSpacing.space2),
        Expanded(
          child: _QuickAction(
            icon: CupertinoIcons.exclamationmark_shield_fill,
            label: 'EMERGENCY',
            tileColor: AuroraColors.coral,
            iconColor: AuroraColors.paper,
            onTap: () => context.push(AppRoutes.emergency),
          ),
        ),
        const SizedBox(width: AuroraSpacing.space2),
        Expanded(
          child: _QuickAction(
            icon: CupertinoIcons.plus_square,
            label: 'ADD TASK',
            tileColor: AuroraColors.ink,
            iconColor: AuroraColors.lime,
            onTap: () => context.push(AppRoutes.maintenanceCreate),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.tileColor,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tileColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AuroraSpacing.space3,
          vertical: AuroraSpacing.space4,
        ),
        decoration: const BoxDecoration(
          color: AuroraColors.butter,
          borderRadius: AuroraRadius.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: tileColor,
                borderRadius: AuroraRadius.sm,
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(height: AuroraSpacing.space1),
            Text(
              label,
              style: AuroraType.labelSm.copyWith(color: AuroraColors.ink),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Your Home section ─────────────────────────────────────────────────────────

class _YourHomeSection extends StatelessWidget {
  const _YourHomeSection({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AuroraColors.inkSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AuroraSpacing.space1),
            Text('YOUR HOME', style: AuroraType.label),
          ],
        ),
        const SizedBox(height: AuroraSpacing.space3),
        Row(
          children: [
            Expanded(
              child: _HomeStatTile(
                icon: CupertinoIcons.wrench,
                label: 'SYSTEMS',
                count: data.systemCount,
                onTap: () => context.push(AppRoutes.homeSystems),
              ),
            ),
            const SizedBox(width: AuroraSpacing.space2),
            Expanded(
              child: _HomeStatTile(
                icon: CupertinoIcons.device_laptop,
                label: 'APPLIANCES',
                count: data.applianceCount,
                onTap: () => context.push(AppRoutes.homeAppliances),
              ),
            ),
            const SizedBox(width: AuroraSpacing.space2),
            Expanded(
              child: _HomeStatTile(
                icon: CupertinoIcons.chart_bar,
                label: 'LIFESPAN',
                count: null,
                onTap: () => context.push(AppRoutes.homeLifespan),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HomeStatTile extends StatelessWidget {
  const _HomeStatTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AuroraSpacing.space3,
          vertical: AuroraSpacing.space4,
        ),
        decoration: const BoxDecoration(
          color: AuroraColors.butter,
          borderRadius: AuroraRadius.lg,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AuroraColors.ink),
            const SizedBox(width: AuroraSpacing.space1),
            Expanded(
              child: Text(
                count != null ? '$count $label' : label,
                style: AuroraType.labelSm.copyWith(color: AuroraColors.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 10,
              color: AuroraColors.inkTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Coming Up section ──────────────────────────────────────────────────────────

class _ComingUpSection extends StatelessWidget {
  const _ComingUpSection({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AuroraColors.inkSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AuroraSpacing.space1),
            Text('COMING UP', style: AuroraType.label),
            const Spacer(),
            GestureDetector(
              onTap: () => context.go(AppRoutes.maintenance),
              child: Text(
                'View all',
                style: AuroraType.label.copyWith(color: AuroraColors.coral),
              ),
            ),
          ],
        ),
        const SizedBox(height: AuroraSpacing.space3),
        ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: data.upcomingTasks.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AuroraSpacing.space2),
          itemBuilder: (_, index) => TaskCard(task: data.upcomingTasks[index]),
        ),
      ],
    );
  }
}

// ── Error view ─────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AuroraSpacing.space10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_circle,
                size: 48,
                color: AuroraColors.inkTertiary,
              ),
              const SizedBox(height: AuroraSpacing.space7),
              Text(
                'Could not load your dashboard',
                style: AuroraType.body.copyWith(color: AuroraColors.inkSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AuroraSpacing.space7),
              GhostButton(
                label: 'Try again',
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Skeleton loading ───────────────────────────────────────────────────────────

class _DashboardSkeleton extends StatefulWidget {
  const _DashboardSkeleton();

  @override
  State<_DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<_DashboardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
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
      animation: _anim,
      builder: (_, _) {
        final shimmer = AuroraColors.butter.withValues(alpha: _anim.value + 0.3);
        return SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AuroraSpacing.screenPadH,
                AuroraSpacing.screenPadTop,
                AuroraSpacing.screenPadH,
                AuroraSpacing.screenPadBottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting bars.
                  _SkeletonBar(color: shimmer, width: 200, height: 22),
                  const SizedBox(height: 6),
                  _SkeletonBar(color: shimmer, width: 150, height: 14),
                  const SizedBox(height: AuroraSpacing.space7),

                  // Hero card shimmer (taller — coral hero is bigger).
                  _SkeletonBar(
                    color: AuroraColors.coralDim,
                    width: double.infinity,
                    height: 148,
                    radius: 22,
                  ),
                  const SizedBox(height: AuroraSpacing.space5),

                  // Quick action tiles (3).
                  Row(
                    children: List.generate(3, (i) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: i == 0 ? 0 : 3,
                            right: i == 2 ? 0 : 3,
                          ),
                          child: _SkeletonBar(
                            color: shimmer,
                            width: double.infinity,
                            height: 64,
                            radius: 14,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AuroraSpacing.space5),

                  // Your Home tiles (3).
                  _SkeletonBar(color: shimmer, width: 80, height: 10),
                  const SizedBox(height: AuroraSpacing.space3),
                  Row(
                    children: List.generate(3, (i) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: i == 0 ? 0 : 3,
                            right: i == 2 ? 0 : 3,
                          ),
                          child: _SkeletonBar(
                            color: shimmer,
                            width: double.infinity,
                            height: 42,
                            radius: 14,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AuroraSpacing.space5),

                  // Coming Up label + two task rows.
                  _SkeletonBar(color: shimmer, width: 80, height: 10),
                  const SizedBox(height: AuroraSpacing.space3),
                  _SkeletonBar(
                    color: shimmer,
                    width: double.infinity,
                    height: 58,
                    radius: 14,
                  ),
                  const SizedBox(height: AuroraSpacing.space2),
                  _SkeletonBar(
                    color: shimmer,
                    width: double.infinity,
                    height: 58,
                    radius: 14,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({
    required this.color,
    required this.width,
    required this.height,
    this.radius = 4,
  });

  final Color color;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
