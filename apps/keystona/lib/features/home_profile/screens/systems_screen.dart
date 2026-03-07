import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../models/system.dart';
import '../providers/systems_provider.dart';
import '../widgets/system_card.dart';
import '../widgets/system_list_skeleton.dart';
import '../widgets/systems_empty_state.dart';

/// Systems list screen — lives at [AppRoutes.homeSystems].
///
/// Shows all home systems grouped by category.
///
/// Adaptive layout:
///   iOS  → [CupertinoPageScaffold] + [CupertinoSliverNavigationBar]
///           FAB via [Stack] + [Positioned]
///   Android → [Scaffold] with [floatingActionButton]
class SystemsScreen extends ConsumerWidget {
  const SystemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return isIOS ? const _IOSLayout() : const _AndroidLayout();
  }
}

// ── iOS layout ─────────────────────────────────────────────────────────────────

class _IOSLayout extends ConsumerWidget {
  const _IOSLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                previousPageTitle: 'Home',
                largeTitle: const Text('Systems'),
              ),
              CupertinoSliverRefreshControl(
                onRefresh: () =>
                    ref.read(systemsProvider.notifier).refresh(),
              ),
              const _SystemsContentSliver(),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          // iOS FAB — Stack + Positioned pattern.
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + AppSizes.md,
            right: AppSizes.md,
            child: _AddFab(
              onPressed: () => context.push(AppRoutes.homeSystemsAdd),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Android layout ─────────────────────────────────────────────────────────────

class _AndroidLayout extends ConsumerWidget {
  const _AndroidLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      body: RefreshIndicator(
        color: AppColors.deepNavy,
        onRefresh: () => ref.read(systemsProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text('Systems', style: AppTextStyles.h3),
              floating: true,
              backgroundColor: AppColors.warmOffWhite,
              scrolledUnderElevation: 0,
              elevation: 0,
            ),
            const _SystemsContentSliver(),
            const SliverToBoxAdapter(child: SizedBox(height: AppSizes.xl)),
          ],
        ),
      ),
      floatingActionButton: _AddFab(
        onPressed: () => context.push(AppRoutes.homeSystemsAdd),
      ),
    );
  }
}

// ── Content sliver ─────────────────────────────────────────────────────────────

class _SystemsContentSliver extends ConsumerWidget {
  const _SystemsContentSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemsAsync = ref.watch(systemsProvider);

    return systemsAsync.when(
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: SystemListSkeleton(),
      ),
      error: (_, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorView(
          message: "Couldn't load your systems.",
          onRetry: () => ref.read(systemsProvider.notifier).refresh(),
        ),
      ),
      data: (systems) {
        if (systems.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: SystemsEmptyState(
              onAddSystem: () => context.push(AppRoutes.homeSystemsAdd),
            ),
          );
        }
        return _GroupedSystemsSliver(systems: systems);
      },
    );
  }
}

// ── Grouped list ───────────────────────────────────────────────────────────────

class _GroupedSystemsSliver extends StatelessWidget {
  const _GroupedSystemsSliver({required this.systems});

  final List<HomeSystem> systems;

  /// Groups [systems] by category, preserving order.
  Map<SystemCategory, List<HomeSystem>> get _grouped {
    final map = <SystemCategory, List<HomeSystem>>{};
    for (final s in systems) {
      map.putIfAbsent(s.category, () => []).add(s);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;

    final children = <Widget>[];
    for (final entry in grouped.entries) {
      children.add(_CategoryHeader(category: entry.key));
      for (final system in entry.value) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.sm),
          child: SystemCard(system: system),
        ));
      }
      children.add(const SizedBox(height: AppSizes.md));
    }

    return SliverPadding(
      padding: AppPadding.screen,
      sliver: SliverList.list(children: children),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.category});

  final SystemCategory category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Text(
        category.label.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── FAB ────────────────────────────────────────────────────────────────────────

class _AddFab extends StatelessWidget {
  const _AddFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: AppColors.deepNavy,
      foregroundColor: AppColors.textInverse,
      child: const Icon(Icons.add),
    );
  }
}
