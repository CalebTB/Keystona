import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_tasks_c.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../maintenance/models/reminder_groups.dart';
import '../../maintenance/models/reminder_item.dart';
import '../../maintenance/providers/reminders_providers.dart';
import '../../maintenance/reminders_copy.dart';
import '../../maintenance/widgets/reminders/reminder_info_card.dart';
import '../../maintenance/widgets/reminders/reminders_back_link.dart';
import '../../maintenance/widgets/reminders/reminders_centered_page.dart';
import '../../maintenance/widgets/reminders/reminders_header.dart';
import '../../maintenance/widgets/reminders/reminders_page.dart';
import '../../maintenance/widgets/reminders/reminders_skeleton.dart';
import '../../maintenance/widgets/reminders/turned_off_group_section.dart';

/// Turned-off reminders (kit: SettingsReminders): the safety net listing
/// everything switched off for this home, by parent, with Turn on and Undo.
/// Route: `/settings/reminders`.
class SettingsRemindersScreen extends ConsumerStatefulWidget {
  const SettingsRemindersScreen({super.key});

  @override
  ConsumerState<SettingsRemindersScreen> createState() =>
      _SettingsRemindersScreenState();
}

class _SettingsRemindersScreenState
    extends ConsumerState<SettingsRemindersScreen> {
  /// Reminders that were off when the list loaded. A row stays in the list
  /// after Turn on (as "Back on" with Undo) until the next refresh.
  Set<String>? _listed;

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.settings);
    }
  }

  Future<void> _refresh() async {
    setState(() => _listed = null);
    ref.invalidate(remindersProvider);
    await ref.read(remindersProvider.future);
  }

  /// Turns [item] on, or off again (Undo). Undo puts back the time and the
  /// reason it was off with, which [item] still holds (the last change
  /// stands in for the time of a reminder turned off before it was recorded).
  Future<void> _set(ReminderItem item, {required bool enabled}) async {
    final notifier = ref.read(remindersProvider.notifier);
    try {
      await notifier.setEnabled(
        item.id,
        enabled: enabled,
        reason: enabled ? null : item.offReason,
        offAt: enabled ? null : item.offSince,
      );
    } catch (_) {
      if (mounted) {
        SnackbarService.showError(context, RemindersCopy.changeError);
      }
    }
  }

  void _seeAll(ReminderGroup group) {
    final id = group.itemId;
    final location = switch ((group.kind, group.itemIsAppliance)) {
      (ReminderGroupKind.item, true) =>
        AppRoutes.homeApplianceDetail.replaceFirst(':applianceId', id!),
      (ReminderGroupKind.item, false) =>
        AppRoutes.homeSystemDetail.replaceFirst(':systemId', id!),
      _ => AppRoutes.homeReminders,
    };
    context.push(location);
  }

  @override
  Widget build(BuildContext context) {
    final reminders = ref.watch(remindersProvider);
    final a = context.aurora;
    final back = Align(
      alignment: Alignment.centerLeft,
      child: RemindersBackLink(label: RemindersCopy.settingsBack, onTap: _back),
    );
    final gap = SizedBox(height: a.of(AuroraSpacing.space3));

    return reminders.when(
      loading: () => RemindersPage(
        onRefresh: _refresh,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [back, gap, const RemindersSkeleton()],
        ),
      ),
      error: (_, _) => RemindersCenteredPage(
        backLabel: RemindersCopy.settingsBack,
        onBack: _back,
        child: ErrorView(
          message: RemindersCopy.loadError,
          onRetry: () => ref.invalidate(remindersProvider),
        ),
      ),
      data: (data) {
        final listed = _listed ??= {
          for (final i in data.items)
            if (!i.enabled) i.id,
        };
        final shown = [
          for (final i in data.items)
            if (listed.contains(i.id)) i,
        ];
        if (shown.isEmpty) {
          return RemindersCenteredPage(
            backLabel: RemindersCopy.settingsBack,
            onBack: _back,
            child: const EmptyState(
              icon: CupertinoIcons.bell,
              title: RemindersCopy.settingsEmptyTitle,
              subtitle: RemindersCopy.settingsEmptyBody,
            ),
          );
        }
        final groups = ReminderGroups.turnedOff(shown);
        final section = SizedBox(height: a.of(AuroraTasksCSizes.blockGap));
        return RemindersPage(
          onRefresh: _refresh,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              back,
              gap,
              RemindersHeader(
                eyebrow: RemindersCopy.settingsEyebrow(
                  data.addressLine?.toUpperCase(),
                ),
                title: RemindersCopy.settingsTitle,
                blurb: RemindersCopy.settingsBlurb,
              ),
              for (final group in groups) ...[
                section,
                TurnedOffGroupSection(
                  group: group,
                  onSeeAll: () => _seeAll(group),
                  onTurnOn: (item) => _set(item, enabled: true),
                  onUndo: (item) => _set(item, enabled: false),
                ),
              ],
              section,
              const ReminderInfoCard(
                icon: Icons.home_outlined,
                text: RemindersCopy.savedForThisHouse,
              ),
            ],
          ),
        );
      },
    );
  }
}
