import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/widgets/error_view.dart';
import '../appliance_copy.dart';
import '../models/appliance.dart';
import '../models/appliance_list.dart';
import '../models/appliance_suggestion.dart';
import '../models/item_ref.dart';
import '../providers/appliances_provider.dart';
import '../providers/item_task_counts_provider.dart';
import '../widgets/appliances/appliance_rows.dart';
import '../widgets/appliances/appliance_suggestions.dart';
import '../widgets/appliances/appliances_empty_state.dart';
import '../widgets/item/item_header.dart';
import '../widgets/item/item_page.dart';
import '../widgets/item/item_skeleton.dart';
import '../widgets/item/item_top_bar.dart';
import '../widgets/item/item_top_bar_action.dart';
import '../widgets/shared/dashed_action_button.dart';
import '../widgets/shared/item_filter_bar.dart';
import '../../../core/theme/aurora_home_c.dart';

/// Every appliance in the home with its lifespan (kit: HomeAppliances).
/// Route: `/home/appliances`.
class AppliancesScreen extends ConsumerStatefulWidget {
  const AppliancesScreen({super.key, this.today});

  /// Today's date; tests pass a fixed one.
  final DateTime? today;

  @override
  ConsumerState<AppliancesScreen> createState() => _AppliancesScreenState();
}

class _AppliancesScreenState extends ConsumerState<AppliancesScreen> {
  ApplianceCategory? _category;
  ApplianceSort _sort = ApplianceSort.oldestFirst;

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _scan() => context.push(AppRoutes.homeScan, extra: ItemKind.appliance);

  void _add() => context.push(AppRoutes.homeAppliancesAdd);

  void _suggest(ApplianceSuggestion s) =>
      context.push(AppRoutes.homeAppliancesAdd, extra: s);

  void _open(String id) => context.push(
    AppRoutes.homeApplianceDetail.replaceFirst(':applianceId', id),
  );

  Future<void> _refresh() async {
    await ref.read(appliancesProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final appliances = ref.watch(appliancesProvider);
    final topBar = ItemTopBar(
      backLabel: ApplianceCopy.listBack,
      onBack: _back,
      trailing: ItemTopBarAction(
        label: ApplianceCopy.add,
        style: ItemTopBarStyle.outline,
        onTap: _scan,
      ),
    );
    final gap = SizedBox(height: context.aurora.of(AuroraSpacing.space7));

    return appliances.when(
      loading: () => ItemPage(
        onRefresh: _refresh,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            topBar,
            gap,
            const ItemHeader(
              eyebrow: ApplianceCopy.listTitle,
              title: ApplianceCopy.listTitle,
            ),
            gap,
            const ItemSkeleton(
              heights: [
                AuroraHomeCSizes.skeletonRow,
                AuroraHomeCSizes.skeletonRow,
                AuroraHomeCSizes.skeletonRow,
              ],
            ),
          ],
        ),
      ),
      error: (_, _) => ItemPage(
        onRefresh: _refresh,
        fill: ErrorView(
          message: ApplianceCopy.listLoadError,
          onRetry: () => ref.invalidate(appliancesProvider),
        ),
        child: topBar,
      ),
      data: (all) => ItemPage(
        onRefresh: _refresh,
        fill: all.isEmpty
            ? AppliancesEmptyState(onAdd: _add, onScan: _scan)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            topBar,
            gap,
            if (all.isEmpty)
              const ItemHeader(
                eyebrow: ApplianceCopy.listTitle,
                title: ApplianceCopy.listTitle,
              )
            else
              _Content(
                all: all,
                category: _category,
                sort: _sort,
                today: widget.today,
                onCategory: (c) => setState(() => _category = c),
                onSort: (i) =>
                    setState(() => _sort = ApplianceSort.values[i]),
                onOpen: _open,
                onSuggest: _suggest,
                onScan: _scan,
              ),
          ],
        ),
      ),
    );
  }
}

/// The populated list: header, filter bar, rows, suggestions, scan button.
class _Content extends ConsumerWidget {
  const _Content({
    required this.all,
    required this.category,
    required this.sort,
    required this.today,
    required this.onCategory,
    required this.onSort,
    required this.onOpen,
    required this.onSuggest,
    required this.onScan,
  });

  final List<Appliance> all;
  final ApplianceCategory? category;
  final ApplianceSort sort;
  final DateTime? today;
  final ValueChanged<ApplianceCategory?> onCategory;
  final ValueChanged<int> onSort;
  final ValueChanged<String> onOpen;
  final ValueChanged<ApplianceSuggestion> onSuggest;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aurora;
    final now = today ?? DateTime.now();
    final address = ref.watch(homeAddressLineProvider).value;
    final counts = ref.watch(itemTaskCountsProvider);
    final shown = ApplianceList.shown(
      all,
      category: category,
      sort: sort,
      now: now,
    );
    final gap = SizedBox(height: a.of(AuroraSpacing.space8));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ItemHeader(
          eyebrow: ApplianceList.eyebrow(address, all, now: now),
          title: ApplianceCopy.listTitle,
        ),
        gap,
        ItemFilterBar<ApplianceCategory?>(
          horizontalInset: 0,
          options: [
            ItemFilterOption(
              value: null,
              label: ApplianceCopy.allChip(all.length),
            ),
            for (final c in ApplianceList.categories(all))
              ItemFilterOption(value: c, label: c.label),
          ],
          selected: category,
          onSelected: onCategory,
          shownCount: shown.length,
          sortLabels: [for (final s in ApplianceSort.values) s.label],
          sortIndex: sort.index,
          onSortChanged: onSort,
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        ApplianceRows(
          appliances: shown,
          taskCounts: counts,
          today: now,
          onOpen: onOpen,
        ),
        gap,
        ApplianceSuggestions(
          suggestions: ApplianceSuggestion.oftenForgotten,
          onPick: onSuggest,
        ),
        gap,
        DashedActionButton(
          icon: Icons.photo_camera_outlined,
          label: ApplianceCopy.scanToAdd,
          onTap: onScan,
        ),
      ],
    );
  }
}
