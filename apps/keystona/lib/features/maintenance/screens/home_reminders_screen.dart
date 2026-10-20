import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_motion.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/widgets/aurora/aurora_sheet.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/reminder_frequency.dart';
import '../models/reminder_item.dart';
import '../providers/reminders_providers.dart';
import '../providers/task_deletion.dart';
import '../reminders_copy.dart';
import '../widgets/reminders/home_reminders_body.dart';
import '../widgets/reminders/reminders_back_link.dart';
import '../widgets/reminders/reminders_centered_page.dart';
import '../widgets/reminders/reminders_page.dart';
import '../widgets/reminders/reminders_skeleton.dart';

/// Around the house (kit: HomeReminders): reminders that belong to the home as
/// a whole, each with a switch and a how-often choice, plus the ones the
/// person made. Route: `/home/reminders`.
class HomeRemindersScreen extends ConsumerWidget {
  const HomeRemindersScreen({super.key});

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(remindersProvider);
    await ref.read(remindersProvider.future);
  }

  /// Runs a change; says so when it could not be saved. True when it was.
  Future<bool> _change(
    BuildContext context,
    Future<void> Function() change, {
    String error = RemindersCopy.changeError,
  }) async {
    try {
      await change();
      return true;
    } catch (_) {
      if (context.mounted) SnackbarService.showError(context, error);
      return false;
    }
  }

  Future<void> _pickFrequency(
    BuildContext context,
    WidgetRef ref,
    ReminderItem item,
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
    if (picked == item.recurrence) return;
    await _change(context, () => notifier.setRecurrence(item.id, picked));
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ReminderItem item,
  ) async {
    final notifier = ref.read(remindersProvider.notifier);
    // Undo outlives this screen's providers' listeners: keep the container.
    final container = ProviderScope.containerOf(context);
    final confirmed = await ConfirmDialog.show(
      context,
      title: RemindersCopy.deleteTitle,
      message: RemindersCopy.deleteBody(item.name),
      confirmLabel: RemindersCopy.deleteConfirm,
      onConfirm: () {},
    );
    if (confirmed != true || !context.mounted) return;
    final deleted = await _change(
      context,
      () => notifier.delete(item.id),
      error: RemindersCopy.deleteError,
    );
    if (!deleted || !context.mounted) return;
    SnackbarService.showUndo(
      context,
      message: RemindersCopy.deleted,
      duration: AuroraDurations.undoDelete,
      onUndo: () => _restore(context, container, item.id),
    );
  }

  /// Undo for [_delete]: brings the reminder back and refreshes every list.
  Future<void> _restore(
    BuildContext context,
    ProviderContainer container,
    String id,
  ) async {
    try {
      await TaskDeletion.restore(container, id);
    } catch (_) {
      if (context.mounted) {
        SnackbarService.showError(context, RemindersCopy.changeError);
      }
    }
  }

  void _edit(BuildContext context, ReminderItem item) => context.push(
    AppRoutes.maintenanceEditTask.replaceFirst(':taskId', item.id),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(remindersProvider);
    final notifier = ref.read(remindersProvider.notifier);
    final a = context.aurora;
    final back = Align(
      alignment: Alignment.centerLeft,
      child: RemindersBackLink(
        label: RemindersCopy.homeBack,
        onTap: () => _back(context),
      ),
    );
    final gap = SizedBox(height: a.of(AuroraSpacing.space3));

    return reminders.when(
      loading: () => RemindersPage(
        onRefresh: () => _refresh(ref),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [back, gap, const RemindersSkeleton()],
        ),
      ),
      error: (_, _) => RemindersCenteredPage(
        backLabel: RemindersCopy.homeBack,
        onBack: () => _back(context),
        child: ErrorView(
          message: RemindersCopy.loadError,
          onRetry: () => ref.invalidate(remindersProvider),
        ),
      ),
      data: (data) => RemindersPage(
        onRefresh: () => _refresh(ref),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            back,
            gap,
            HomeRemindersBody(
              data: data,
              onToggle: (item, on) => _change(
                context,
                () => notifier.setEnabled(item.id, enabled: on),
              ),
              onPickFrequency: (item) => _pickFrequency(context, ref, item),
              onEdit: (item) => _edit(context, item),
              onDelete: (item) => _delete(context, ref, item),
              onAdd: () => context.push(AppRoutes.maintenanceCreate),
            ),
          ],
        ),
      ),
    );
  }
}
