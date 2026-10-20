import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_home_c.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/widgets/aurora/aurora_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../maintenance/models/maintenance_task.dart';
import '../../maintenance/models/reminder_frequency.dart';
import '../../maintenance/models/reminder_item.dart';
import '../../maintenance/providers/maintenance_tasks_provider.dart';
import '../../maintenance/providers/reminders_providers.dart';
import '../../maintenance/reminders_copy.dart';
import '../item_copy.dart';
import '../models/item_ref.dart';
import '../providers/item_summary_provider.dart';
import '../widgets/item/item_header.dart';
import '../widgets/item/item_page.dart';
import '../widgets/item/item_skeleton.dart';
import '../widgets/item/item_top_bar.dart';
import '../widgets/item/item_top_bar_action.dart';
import '../widgets/item_reminders/item_reminders_body.dart';

/// A system's or appliance's reminders: a switch and a how-often choice per
/// task (kit: ItemReminders). Turning one off records when and why, so it is
/// hidden everywhere and left out of Home Health. Routes:
/// `/home/systems/:systemId/reminders`,
/// `/home/appliances/:applianceId/reminders`.
class ItemRemindersScreen extends ConsumerWidget {
  const ItemRemindersScreen({super.key, required this.item});

  final ItemRef item;

  String get _tasksRoute => item.isSystem
      ? AppRoutes.homeSystemTasks.replaceFirst(':systemId', item.id)
      : AppRoutes.homeApplianceTasks.replaceFirst(':applianceId', item.id);

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(_tasksRoute);
    }
  }

  Future<void> _change(
    BuildContext context,
    Future<void> Function() change,
  ) async {
    try {
      await change();
    } catch (_) {
      if (context.mounted) {
        SnackbarService.showError(context, RemindersCopy.changeError);
      }
    }
  }

  Future<void> _pickFrequency(
    BuildContext context,
    WidgetRef ref,
    ReminderItem reminder,
  ) async {
    final notifier = ref.read(remindersProvider.notifier);
    final choice = await AuroraSheet.actionSheet(
      context,
      title: RemindersCopy.howOften,
      actions: [
        for (final r in ReminderFrequency.choices)
          AuroraSheetAction(label: ReminderFrequency.label(r)),
      ],
    );
    if (choice == null || !context.mounted) return;
    final picked = ReminderFrequency.choices[choice];
    if (picked == reminder.recurrence) return;
    await _change(
      context,
      () => notifier.setRecurrence(reminder.id, picked),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(remindersProvider);
    await ref.read(remindersProvider.future);
  }

  bool _mine(ReminderItem r) => item.isSystem
      ? r.systemId == item.id
      : r.applianceId == item.id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(itemSummaryProvider(item));
    final reminders = ref.watch(remindersProvider);
    final tasks = ref.watch(maintenanceTasksProvider).value;
    final gap = SizedBox(height: context.aurora.of(AuroraSpacing.space7));
    final info = summary.value;

    ItemTopBar bar([String? back]) => ItemTopBar(
      backLabel: back ?? ItemCopy.back,
      onBack: () => _back(context),
      trailing: ItemTopBarAction(
        label: ItemCopy.done,
        style: ItemTopBarStyle.filled,
        onTap: () => _back(context),
      ),
    );

    if (summary.hasError || reminders.hasError) {
      return ItemPage(
        fill: ErrorView(
          message: ItemCopy.loadError,
          onRetry: () {
            ref.invalidate(itemSummaryProvider(item));
            ref.invalidate(remindersProvider);
          },
        ),
        child: bar(),
      );
    }
    if (summary.hasValue && info == null) {
      return ItemPage(
        fill: const EmptyState(
          icon: Icons.search_off_outlined,
          title: ItemCopy.notFoundTitle,
          subtitle: ItemCopy.notFoundBody,
        ),
        child: bar(),
      );
    }
    final data = reminders.value;
    if (info == null || data == null) {
      return ItemPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            bar(),
            gap,
            const ItemSkeleton(
              heights: [
                AuroraHomeCSizes.skeletonHero,
                AuroraHomeCSizes.skeletonBlock,
              ],
            ),
          ],
        ),
      );
    }

    final mine = [for (final r in data.items) if (_mine(r)) r];
    final on = [for (final r in mine) if (r.enabled) r];
    final off = [for (final r in mine) if (!r.enabled) r];
    final proIds = {
      for (final t in tasks ?? const <MaintenanceTask>[])
        if (t.diyOrPro == DiyOrPro.professional) t.id,
    };
    final notifier = ref.read(remindersProvider.notifier);
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        bar(ItemCopy.backToTasks(info)),
        gap,
        ItemHeader(
          eyebrow: info.eyebrow,
          title: ItemCopy.remindersTitle(info),
        ),
        gap,
      ],
    );

    if (mine.isEmpty) {
      return ItemPage(
        onRefresh: () => _refresh(ref),
        fill: EmptyState(
          icon: Icons.notifications_none_outlined,
          title: ItemCopy.remindersEmptyTitle,
          subtitle: ItemCopy.remindersEmptyBody(info),
          actionLabel: ItemCopy.addOwn(info),
          onAction: () => context.push(AppRoutes.maintenanceCreateFor(item.id)),
        ),
        child: header,
      );
    }
    return ItemPage(
      onRefresh: () => _refresh(ref),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          ItemRemindersBody(
            info: info,
            on: on,
            off: off,
            proIds: proIds,
            onToggle: (r, value) => _change(
              context,
              () => notifier.setEnabled(r.id, enabled: value),
            ),
            onPickFrequency: (r) => _pickFrequency(context, ref, r),
            onAdd: () => context.push(AppRoutes.maintenanceCreateFor(item.id)),
          ),
        ],
      ),
    );
  }
}
