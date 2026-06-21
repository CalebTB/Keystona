import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/trial_banner.dart';
import '../../../features/home_profile/models/property.dart';
import '../../../features/maintenance/widgets/health_score_widget.dart';
import '../../../features/maintenance/widgets/overdue_banner.dart';
import '../../../features/maintenance/widgets/task_card.dart';
import '../providers/dashboard_provider.dart';

/// The Home tab root screen — a scrollable dashboard with greeting, health
/// score hero, quick actions, overdue banner, upcoming tasks, and trial banner.
///
/// Uses [CupertinoPageScaffold] (iOS-first) with no nav bar; the large title
/// sits inline in the scroll content.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.warmOffWhite,
      child: dashAsync.when(
        loading: () => const _DashboardSkeleton(),
        error: (_, _) => _ErrorView(
          onRetry: () => ref.invalidate(dashboardProvider),
        ),
        data: (data) => CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Pull-to-refresh (iOS-native spinner).
            CupertinoSliverRefreshControl(
              onRefresh: () =>
                  ref.read(dashboardProvider.notifier).refresh(),
            ),

            // ── A. Greeting header — top padding respects safe area ─────
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _GreetingHeader(data: data),
                ),
              ),
            ),

            // ── B. Health score hero card ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _HeroCard(data: data),
              ),
            ),

            // ── C. Quick actions row ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: const _QuickActionsRow(),
              ),
            ),

            // ── D. Your Home section (systems + appliances) ─────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _YourHomeSection(data: data),
              ),
            ),

            // ── E. Overdue banner (conditional) ────────────────────────
            if (data.overdueTasks.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: OverdueBanner(overdueTasks: data.overdueTasks),
                ),
              ),

            // ── F. Coming Up section (conditional) ─────────────────────
            if (data.upcomingTasks.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _ComingUpSection(data: data),
                ),
              ),

            // ── G. Trial banner — padding lives inside TrialBanner itself
            //    so this sliver vanishes when no trial is active.
            const SliverToBoxAdapter(child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: TrialBanner(),
            )),

            // Bottom safe area.
            const SliverSafeArea(
              top: false,
              minimum: EdgeInsets.only(bottom: 24),
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
      if (overdue.length == 1) {
        return '${overdue.first.name} needs attention';
      }
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
          style: AppTextStyles.h2.copyWith(color: AppColors.deepNavy),
        ),
        const SizedBox(height: 4),
        Text(
          _subtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Health score hero card ─────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final property = data.property;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSm,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: address + settings gear.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.md,
              AppSizes.md,
              AppSizes.sm,
              4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: property != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              property.addressLine1,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.deepNavy,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _buildSubtitle(property),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        )
                      : GestureDetector(
                          onTap: () => context.push(AppRoutes.homeEdit),
                          child: Text(
                            'Set up your home',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.accent,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.accent,
                            ),
                          ),
                        ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  onPressed: () => context.push(AppRoutes.homeEdit),
                  child: const Icon(
                    CupertinoIcons.settings,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Divider.
          const Divider(color: AppColors.border, height: 1),

          // compact: true strips the inner card border/padding — hero card is the container.
          const HealthScoreWidget(compact: true),
        ],
      ),
    );
  }

  String _buildSubtitle(Property property) {
    final label = property.propertyType.propertyTypeLabel;
    final year = property.yearBuilt;
    if (year != null) return '$label · Built $year';
    return label;
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
            icon: CupertinoIcons.exclamationmark_shield,
            label: 'Emergency',
            // push — Emergency is a sub-screen within the Home branch, not a tab
            onTap: () => context.push(AppRoutes.emergency),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _QuickAction(
            icon: CupertinoIcons.doc,
            label: 'Documents',
            // go — switches to the Documents tab
            onTap: () => context.go(AppRoutes.documents),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _QuickAction(
            icon: CupertinoIcons.checkmark_square,
            label: 'Tasks',
            // go — switches to the Tasks tab
            onTap: () => context.go(AppRoutes.maintenance),
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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: AppColors.deepNavy),
            const SizedBox(height: AppSizes.xs),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
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
            Text(
              'Your Home',
              style: AppTextStyles.bodyMediumSemibold.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          children: [
            Expanded(
              child: _HomeStatCard(
                icon: CupertinoIcons.wrench_fill,
                label: 'Systems',
                count: data.systemCount,
                route: AppRoutes.homeSystems,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: _HomeStatCard(
                icon: CupertinoIcons.device_laptop,
                label: 'Appliances',
                count: data.applianceCount,
                route: AppRoutes.homeAppliances,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: _HomeStatCard(
                icon: CupertinoIcons.chart_bar,
                label: 'Lifespan',
                count: null,
                route: AppRoutes.homeLifespan,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HomeStatCard extends StatelessWidget {
  const _HomeStatCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.route,
  });

  final IconData icon;
  final String label;
  final int? count;
  final String route;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.deepNavy),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                count != null ? '$count $label' : label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 12,
              color: AppColors.gray400,
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
        // Section header row.
        Row(
          children: [
            Text(
              'Coming Up',
              style: AppTextStyles.bodyMediumSemibold.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.go(AppRoutes.maintenance),
              child: Text(
                'View all',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        // Task list (non-scrollable — sits inside CustomScrollView).
        ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: data.upcomingTasks.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
          itemBuilder: (_, index) =>
              TaskCard(task: data.upcomingTasks[index]),
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
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_circle,
              size: AppSizes.iconXl,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'Could not load your dashboard',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.md),
            CupertinoButton(
              onPressed: onRetry,
              child: Text(
                'Try again',
                style: AppTextStyles.button.copyWith(color: AppColors.accent),
              ),
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
        final shimmer = AppColors.gray200.withValues(alpha: _anim.value);
        return SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting: two shimmer bars.
                  _SkeletonBar(color: shimmer, width: 200, height: 20),
                  const SizedBox(height: 6),
                  _SkeletonBar(color: shimmer, width: 160, height: 14),
                  const SizedBox(height: 16),

                  // Hero card shimmer.
                  Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: shimmer,
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick action boxes (3).
                  Row(
                    children: List.generate(3, (i) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: i == 0 ? 0 : 4,
                            right: i == 2 ? 0 : 4,
                          ),
                          child: Container(
                            height: 64,
                            decoration: BoxDecoration(
                              color: shimmer,
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusMd),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),

                  // Your Home row (3 stat cards).
                  Row(
                    children: List.generate(3, (i) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: i == 0 ? 0 : 4,
                            right: i == 2 ? 0 : 4,
                          ),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: shimmer,
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusMd),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),

                  // Coming Up label + two task bars.
                  _SkeletonBar(color: shimmer, width: 90, height: 14),
                  const SizedBox(height: 8),
                  _SkeletonBar(
                    color: shimmer,
                    width: double.infinity,
                    height: 64,
                    radius: AppSizes.radiusCard,
                  ),
                  const SizedBox(height: 8),
                  _SkeletonBar(
                    color: shimmer,
                    width: double.infinity,
                    height: 64,
                    radius: AppSizes.radiusCard,
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
    this.radius = AppSizes.radiusXs,
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
