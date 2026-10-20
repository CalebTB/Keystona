import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../maintenance/providers/home_health_score_provider.dart';
import '../../maintenance/providers/reminders_providers.dart';
import '../home_profile_copy.dart';
import '../models/home_profile_overview.dart';
import '../models/item_ref.dart';
import '../providers/home_profile_provider.dart';
import '../widgets/home_common/home_page_frame.dart';
import '../widgets/home_profile/profile_actions.dart';
import '../widgets/home_profile/profile_content.dart';
import '../widgets/home_profile/profile_skeleton.dart';
import '../widgets/home_profile/profile_top_bar.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';

/// Home profile (kit: HomeProfile): the cover photo, the address and facts, a
/// callout for the item most worn out, the upkeep score, the systems, the next
/// five years of replacements and the property details. Route:
/// `/home/profile`.
///
/// Left out for want of a data source: the Records and Emergency scores, the
/// "up N since Sep" trend, the project card, "Recently", and the Home History
/// Report card.
class HomeProfileScreen extends ConsumerWidget {
  const HomeProfileScreen({super.key});

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  ProfileActions _actions(BuildContext context) => ProfileActions(
    onEdit: () => context.push(AppRoutes.homeEdit),
    onOpenSystem: (ItemRef item) => context.push(
      AppRoutes.homeSystemDetail.replaceFirst(':systemId', item.id),
    ),
    onAllSystems: () => context.push(AppRoutes.homeSystems),
    onAppliances: () => context.push(AppRoutes.homeAppliances),
    onScan: () => context.push(AppRoutes.homeScan),
    onAround: () => context.push(AppRoutes.homeReminders),
    onLifespan: () => context.push(AppRoutes.homeLifespan),
    onTasks: () => context.go(AppRoutes.maintenance),
  );

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(homeProfileProvider);
    await ref.read(homeProfileProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(homeProfileProvider);
    return overview.when(
      loading: () => HomePageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileTopBar(
              backLabel: HomeProfileCopy.back,
              onBack: () => _back(context),
            ),
            const ProfileSkeleton(),
          ],
        ),
      ),
      error: (error, _) => _Message(
        onBack: () => _back(context),
        child: error is NoPropertyException
            ? EmptyState(
                icon: Icons.home_outlined,
                title: HomeProfileCopy.noHomeTitle,
                subtitle: HomeProfileCopy.noHomeBody,
                actionLabel: HomeProfileCopy.noHomeAction,
                onAction: () => context.push(AppRoutes.onboardingProperty),
                accent: true,
              )
            : ErrorView(
                message: HomeProfileCopy.loadError,
                onRetry: () => ref.invalidate(homeProfileProvider),
              ),
      ),
      data: (data) => _Loaded(
        overview: data,
        actions: _actions(context),
        onBack: () => _back(context),
        onRefresh: () => _refresh(ref),
      ),
    );
  }
}

class _Loaded extends ConsumerWidget {
  const _Loaded({
    required this.overview,
    required this.actions,
    required this.onBack,
    required this.onRefresh,
  });

  final HomeProfileOverview overview;
  final ProfileActions actions;
  final VoidCallback onBack;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aurora;
    final health = ref.watch(
      homeHealthScoreProvider.select((v) => v.value),
    );
    final aroundMeta = ref.watch(
      remindersProvider.select((v) {
        final items = v.value?.items;
        if (items == null) return null;
        final around = items.where((i) => i.isAroundTheHouse).toList();
        return HomeProfileCopy.aroundMeta(
          around.length,
          around.where((i) => !i.enabled).length,
        );
      }),
    );
    return HomePageFrame(
      onRefresh: onRefresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileTopBar(
            backLabel: HomeProfileCopy.back,
            onBack: onBack,
            editLabel: HomeProfileCopy.edit,
            onEdit: actions.onEdit,
          ),
          SizedBox(height: a.of(AuroraSpacing.space3)),
          ProfileContent(
            overview: overview,
            actions: actions,
            health: health,
            aroundMeta: aroundMeta,
          ),
        ],
      ),
    );
  }
}

/// A back bar over a centered message (empty or error).
class _Message extends StatelessWidget {
  const _Message({required this.onBack, required this.child});

  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return HomePageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileTopBar(backLabel: HomeProfileCopy.back, onBack: onBack),
          child,
        ],
      ),
    );
  }
}
