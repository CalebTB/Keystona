import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../home_lifespan_copy.dart';
import '../models/item_ref.dart';
import '../providers/home_profile_provider.dart';
import '../widgets/home_common/home_back_link.dart';
import '../widgets/home_common/home_page_frame.dart';
import '../widgets/home_lifespan/lifespan_content.dart';
import '../widgets/home_lifespan/lifespan_skeleton.dart';

/// How long things last (kit: HomeLifespan): every system and appliance on a
/// timeline, the five-year total and what to set aside. Route:
/// `/home/lifespan`.
class HomeLifespanScreen extends ConsumerStatefulWidget {
  const HomeLifespanScreen({super.key});

  @override
  ConsumerState<HomeLifespanScreen> createState() => _HomeLifespanScreenState();
}

class _HomeLifespanScreenState extends ConsumerState<HomeLifespanScreen> {
  /// 0 all, 1 systems, 2 appliances.
  int _tab = 0;

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.homeProfile);
    }
  }

  void _open(ItemRef item) {
    final route = item.isSystem
        ? AppRoutes.homeSystemDetail.replaceFirst(':systemId', item.id)
        : AppRoutes.homeApplianceDetail.replaceFirst(':applianceId', item.id);
    context.push(route);
  }

  Future<void> _refresh() async {
    ref.invalidate(homeProfileProvider);
    await ref.read(homeProfileProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final overview = ref.watch(homeProfileProvider);
    final back = HomeBackLink(label: HomeLifespanCopy.back, onTap: _back);
    final gap = SizedBox(height: a.of(AuroraSpacing.space3));
    Widget framed(Widget body, {bool refreshable = false}) => HomePageFrame(
      onRefresh: refreshable ? _refresh : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: Alignment.centerLeft, child: back),
          gap,
          body,
        ],
      ),
    );
    return overview.when(
      loading: () => framed(const LifespanSkeleton()),
      error: (_, _) => framed(
        ErrorView(
          message: HomeLifespanCopy.loadError,
          onRetry: () => ref.invalidate(homeProfileProvider),
        ),
      ),
      data: (data) {
        if (data.items.isEmpty) {
          return framed(
            EmptyState(
              icon: Icons.hourglass_empty,
              title: HomeLifespanCopy.emptyTitle,
              subtitle: HomeLifespanCopy.emptyBody,
              actionLabel: HomeLifespanCopy.emptyAction,
              onAction: () => context.push(AppRoutes.homeScan),
            ),
            refreshable: true,
          );
        }
        return framed(
          LifespanContent(
            data: data.lifespan,
            tab: _tab,
            onTab: (tab) => setState(() => _tab = tab),
            onOpen: _open,
          ),
          refreshable: true,
        );
      },
    );
  }
}
