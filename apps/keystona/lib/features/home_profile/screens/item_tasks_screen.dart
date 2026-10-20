import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_home_c.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../maintenance/models/task_schedule.dart';
import '../../maintenance/providers/maintenance_tasks_provider.dart';
import '../../maintenance/providers/tasks_today_provider.dart';
import '../item_copy.dart';
import '../models/item_completion.dart';
import '../models/item_ref.dart';
import '../models/item_summary.dart';
import '../models/item_tasks.dart';
import '../providers/item_data_providers.dart';
import '../providers/item_summary_provider.dart';
import '../widgets/item/item_header.dart';
import '../widgets/item/item_page.dart';
import '../widgets/item/item_skeleton.dart';
import '../widgets/item/item_top_bar.dart';
import '../widgets/item/item_top_bar_action.dart';
import '../widgets/item_tasks/item_tasks_done_list.dart';
import '../widgets/item_tasks/item_tasks_open_list.dart';
import '../widgets/item_tasks/item_tasks_tabs.dart';

/// A system's or appliance's tasks: "Coming up" and "Done" (kit: ItemTasks).
/// Routes: `/home/systems/:systemId/tasks`,
/// `/home/appliances/:applianceId/tasks`. The item's name is loaded by id.
class ItemTasksScreen extends ConsumerStatefulWidget {
  const ItemTasksScreen({super.key, required this.item});

  final ItemRef item;

  @override
  ConsumerState<ItemTasksScreen> createState() => _ItemTasksScreenState();
}

class _ItemTasksScreenState extends ConsumerState<ItemTasksScreen> {
  static const int _upTab = 0;

  int _tab = _upTab;
  bool _showAllDone = false;

  ItemRef get _item => widget.item;

  String get _detailRoute => _item.isSystem
      ? AppRoutes.homeSystemDetail.replaceFirst(':systemId', _item.id)
      : AppRoutes.homeApplianceDetail.replaceFirst(':applianceId', _item.id);

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(_detailRoute);
    }
  }

  void _manage() => context.push(
    _item.isSystem
        ? AppRoutes.homeSystemReminders.replaceFirst(':systemId', _item.id)
        : AppRoutes.homeApplianceReminders.replaceFirst(
            ':applianceId',
            _item.id,
          ),
  );

  void _addTask() => context.push(AppRoutes.maintenanceCreateFor(_item.id));

  Future<void> _refresh() async {
    ref.invalidate(itemSummaryProvider(_item));
    ref.invalidate(itemCompletionsProvider(_item));
    await ref.read(maintenanceTasksProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(itemSummaryProvider(_item));
    final tasks = ref.watch(maintenanceTasksProvider);
    final done = ref.watch(itemCompletionsProvider(_item));
    final today = ref.watch(tasksTodayProvider);
    final gap = SizedBox(height: context.aurora.of(AuroraSpacing.space7));

    if (summary.hasError || tasks.hasError) {
      return ItemPage(
        onRefresh: _refresh,
        fill: ErrorView(
          message: ItemCopy.loadError,
          onRetry: () {
            ref.invalidate(itemSummaryProvider(_item));
            ref.invalidate(maintenanceTasksProvider);
          },
        ),
        child: ItemTopBar(backLabel: ItemCopy.back, onBack: _back),
      );
    }
    final info = summary.value;
    final all = tasks.value;
    if (summary.hasValue && info == null) {
      return ItemPage(
        fill: const EmptyState(
          icon: Icons.search_off_outlined,
          title: ItemCopy.notFoundTitle,
          subtitle: ItemCopy.notFoundBody,
        ),
        child: ItemTopBar(backLabel: ItemCopy.back, onBack: _back),
      );
    }
    if (info == null || all == null) {
      return ItemPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ItemTopBar(backLabel: ItemCopy.back, onBack: _back),
            gap,
            const ItemSkeleton(
              heights: [
                AuroraHomeCSizes.skeletonHero,
                AuroraHomeCSizes.skeletonTab,
                AuroraHomeCSizes.skeletonCard,
                AuroraHomeCSizes.skeletonCard,
              ],
            ),
          ],
        ),
      );
    }

    final open = ItemTasks.open(all, _item);
    final completions = done.value;
    final overdue = open.any((t) => TaskSchedule.isOverdue(t, today));
    final Widget? fill = _fill(info, open.isEmpty, done);

    return ItemPage(
      onRefresh: _refresh,
      fill: fill,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ItemTopBar(
            backLabel: info.name,
            onBack: _back,
            trailing: ItemTopBarAction(
              label: ItemCopy.manage,
              onTap: _manage,
            ),
          ),
          gap,
          ItemHeader(
            eyebrow: info.eyebrow,
            title: ItemCopy.tasksTitle(info),
          ),
          gap,
          ItemTasksTabs(
            labels: [
              ItemCopy.comingUpTab(open.length),
              ItemCopy.doneTab(completions?.length ?? 0),
            ],
            selected: _tab,
            onSelected: (i) => setState(() => _tab = i),
          ),
          gap,
          if (fill == null && _tab == _upTab)
            ItemTasksOpenList(
              cards: [for (final t in open) ItemTasks.card(t, today)],
              addLabel: ItemCopy.addTask(info),
              onAdd: _addTask,
            )
          else if (fill == null && completions != null)
            ItemTasksDoneList(
              completions: completions,
              today: today,
              onSchedule: !overdue,
              expanded: _showAllDone,
              onExpand: () => setState(() => _showAllDone = true),
            )
          else if (fill == null)
            const ItemSkeleton(
              heights: [
                AuroraHomeCSizes.skeletonCard,
                AuroraHomeCSizes.skeletonCard,
              ],
            ),
        ],
      ),
    );
  }

  /// The state that takes the page under the tabs: empty tab or failed Done
  /// tab. Null when the tab has content (or is still loading).
  Widget? _fill(
    ItemSummary info,
    bool noOpen,
    AsyncValue<List<ItemCompletion>> done,
  ) {
    if (_tab == _upTab) {
      if (!noOpen) return null;
      return EmptyState(
        icon: Icons.checklist_outlined,
        title: ItemCopy.upEmptyTitle,
        subtitle: ItemCopy.upEmptyBody(info),
        actionLabel: ItemCopy.addTask(info),
        onAction: _addTask,
      );
    }
    if (done.hasError) {
      return ErrorView(
        message: ItemCopy.loadError,
        onRetry: () => ref.invalidate(itemCompletionsProvider(_item)),
      );
    }
    final list = done.value;
    if (list != null && list.isEmpty) {
      return EmptyState(
        icon: Icons.history_outlined,
        title: ItemCopy.doneEmptyTitle,
        subtitle: ItemCopy.doneEmptyBody(info),
      );
    }
    return null;
  }
}
