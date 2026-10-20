import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_motion.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../maintenance/widgets/reminders/reminders_centered_page.dart';
import '../../maintenance/widgets/reminders/reminders_page.dart';
import '../models/item_ref.dart';
import '../models/scan_prefill.dart';
import '../models/system.dart';
import '../models/system_template.dart';
import '../models/systems_list_view.dart';
import '../providers/item_task_counts_provider.dart';
import '../providers/systems_provider.dart';
import '../systems_copy.dart';
import '../widgets/scan/scan_entry.dart';
import '../widgets/shared/item_filter_bar.dart';
import '../widgets/systems/systems_header.dart';
import '../widgets/systems/systems_list_card.dart';
import '../widgets/systems/systems_scan_button.dart';
import '../widgets/systems/systems_skeleton.dart';
import '../widgets/systems/systems_top_bar.dart';
import '../widgets/systems/system_suggestions.dart';
import '../../../core/theme/aurora_home_b.dart';

/// Systems list (kit: HomeSystems). Route: `/home/systems`.
///
/// Filter chips group the database categories (Heating & cooling, Water,
/// Structure, Electrical); sort is "Oldest first" or A to Z.
class SystemsScreen extends ConsumerStatefulWidget {
  const SystemsScreen({super.key});

  @override
  ConsumerState<SystemsScreen> createState() => _SystemsScreenState();
}

class _SystemsScreenState extends ConsumerState<SystemsScreen> {
  SystemGroup? _group;
  SystemSort _sort = SystemSort.oldestFirst;

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.homeProfile);
    }
  }

  void _add() => ScanEntry.open(context, ref, kind: ScanKind.system);

  void _open(String id) =>
      context.push(AppRoutes.homeSystemDetail.replaceFirst(':systemId', id));

  void _addByHand() => context.push(AppRoutes.homeSystemsAdd);

  Future<void> _refresh() async {
    await ref.read(systemsProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final systems = ref.watch(systemsProvider);
    return systems.when(
      loading: () => RemindersPage(
        onRefresh: _refresh,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SystemsTopBar(onBack: _back, onAdd: _add),
            SizedBox(height: context.aurora.of(AuroraSpacing.space3)),
            const SystemsSkeleton(),
          ],
        ),
      ),
      error: (_, _) => RemindersCenteredPage(
        backLabel: SystemsCopy.homeBack,
        onBack: _back,
        child: ErrorView(
          message: SystemsCopy.loadError,
          onRetry: () => ref.invalidate(systemsProvider),
        ),
      ),
      data: (list) => list.isEmpty ? _empty() : _content(list),
    );
  }

  Widget _empty() => RemindersCenteredPage(
    backLabel: SystemsCopy.homeBack,
    onBack: _back,
    child: Center(
      child: SingleChildScrollView(
        child: EmptyState(
          icon: Icons.home_repair_service_outlined,
          title: SystemsCopy.emptyTitle,
          subtitle: SystemsCopy.emptySubtitle,
          actionLabel: SystemsCopy.emptyAction,
          onAction: _addByHand,
          secondaryLabel: SystemsCopy.emptyScan,
          onSecondary: _add,
        ),
      ),
    ),
  );

  Widget _content(List<HomeSystem> list) {
    final a = context.aurora;
    final counts = ref.watch(itemTaskCountsProvider);
    final brief = ref.watch(propertyBriefProvider).value;
    final present = SystemsListView.groupsPresent(list);
    // A filter whose last system was removed falls back to "All".
    final group = present.contains(_group) ? _group : null;
    final items = SystemsListView.items(list, group: group, sort: _sort);
    final suggestions = SystemTemplates.suggestionsFor(
      yearBuilt: brief?.yearBuilt,
      tracked: list,
      limit: AuroraHomeBSizes.maxSuggestions,
    );
    final online = ScanEntry.isOnline(ref);

    return RemindersPage(
      onRefresh: _refresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SystemsTopBar(onBack: _back, onAdd: _add),
          SizedBox(height: a.of(AuroraSpacing.space3)),
          SystemsHeader(
            eyebrow: SystemsCopy.listEyebrow(
              address: brief?.addressLine1,
              tracked: list.length,
              aging: SystemsListView.agingCount(list),
            ),
          ),
          SizedBox(height: a.of(AuroraSpacing.space7)),
          ItemFilterBar<SystemGroup?>(
            horizontalInset: 0,
            options: [
              ItemFilterOption(
                value: null,
                label: SystemsCopy.filterAll(list.length),
              ),
              for (final g in present)
                ItemFilterOption(value: g, label: g.label),
            ],
            selected: group,
            onSelected: (g) => setState(() => _group = g),
            shownCount: items.length,
            sortLabels: const [SystemsCopy.sortOldest, SystemsCopy.sortAz],
            sortIndex: _sort.index,
            onSortChanged: (i) => setState(() => _sort = SystemSort.values[i]),
          ),
          SizedBox(height: a.of(AuroraSpacing.space5)),
          SystemsListCard(
            items: items,
            taskCount: (id) => counts[ItemRef.system(id)] ?? 0,
            onOpen: _open,
          ),
          if (suggestions.isNotEmpty) ...[
            SizedBox(height: a.of(AuroraSpacing.space9)),
            SystemSuggestions(
              yearBuilt: brief?.yearBuilt,
              templates: suggestions,
              onPick: (t) => context.push(AppRoutes.homeSystemsAdd, extra: t),
            ),
          ],
          SizedBox(height: a.of(AuroraSpacing.space8)),
          Opacity(
            opacity: online ? 1 : AuroraOpacity.disabled,
            child: SystemsScanButton(onTap: _add),
          ),
        ],
      ),
    );
  }
}
