import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_tasks_c.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/reminder_frequency.dart';
import '../models/reminder_groups.dart';
import '../providers/reminders_providers.dart';
import '../reminders_copy.dart';
import '../widgets/reminders/review_footer.dart';
import '../widgets/reminders/review_footer_note.dart';
import '../widgets/reminders/review_groups_list.dart';
import '../widgets/reminders/review_summary_card.dart';
import '../widgets/reminders/review_top_bar.dart';
import '../widgets/reminders/reminders_back_link.dart';
import '../widgets/reminders/reminders_centered_page.dart';
import '../widgets/reminders/reminders_header.dart';
import '../widgets/reminders/reminders_page.dart';
import '../widgets/reminders/reminders_skeleton.dart';

/// Review your reminders (kit: TaskReview), step 2 of setup: everything the
/// app suggested for the home, each with a switch. Route:
/// `/maintenance/review`.
class TaskReviewScreen extends ConsumerWidget {
  const TaskReviewScreen({super.key});

  void _home(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  /// "Looks good" carries on to Home even when the person arrived from there.
  void _continue(BuildContext context) => context.go(AppRoutes.home);

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(remindersProvider);
    await ref.read(remindersProvider.future);
  }

  Future<void> _run(
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(remindersProvider);
    final notifier = ref.read(remindersProvider.notifier);
    final a = context.aurora;
    final back = RemindersBackLink(
      label: RemindersCopy.reviewBack,
      onTap: () => _home(context),
    );

    return reminders.when(
      loading: () => RemindersPage(
        onRefresh: () => _refresh(ref),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ReviewTopBar(leading: back, onTurnAllOn: null),
            SizedBox(height: a.of(AuroraSpacing.space5)),
            const RemindersSkeleton(),
          ],
        ),
      ),
      error: (_, _) => RemindersCenteredPage(
        backLabel: RemindersCopy.reviewBack,
        onBack: () => _home(context),
        child: ErrorView(
          message: RemindersCopy.loadError,
          onRetry: () => ref.invalidate(remindersProvider),
        ),
      ),
      data: (data) {
        final groups = ReminderGroups.review(data.items);
        final all = [for (final g in groups) ...g.items];
        if (all.isEmpty) {
          return RemindersCenteredPage(
            backLabel: RemindersCopy.reviewBack,
            onBack: () => _home(context),
            child: const EmptyState(
              icon: CupertinoIcons.bell,
              title: RemindersCopy.reviewEmptyTitle,
              subtitle: RemindersCopy.reviewEmptyBody,
            ),
          );
        }
        final on = all.where((i) => i.enabled).toList();
        final gap = SizedBox(height: a.of(AuroraTasksCSizes.blockGap));
        return RemindersPage(
          onRefresh: () => _refresh(ref),
          footer: ReviewFooter(
            label: RemindersCopy.keepLabel(on.length),
            onPressed: on.isEmpty ? null : () => _continue(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReviewTopBar(
                leading: Align(alignment: Alignment.centerLeft, child: back),
                onTurnAllOn: () => _run(
                  context,
                  () => notifier.turnAllOn([for (final i in all) i.id]),
                ),
              ),
              SizedBox(height: a.of(AuroraSpacing.space2)),
              const RemindersHeader(
                eyebrow: RemindersCopy.setupStep,
                title: RemindersCopy.reviewTitle,
                blurb: RemindersCopy.reviewBlurb,
              ),
              gap,
              ReviewSummaryCard(
                on: on.length,
                all: all.length,
                perMonth: ReminderFrequency.perMonth(
                  on.map((i) => i.recurrence),
                ),
              ),
              gap,
              ReviewGroupsList(
                groups: groups,
                climateZone: data.climateZone,
                onToggle: (id, enabled) => _run(
                  context,
                  () => notifier.setEnabled(id, enabled: enabled),
                ),
              ),
              const ReviewFooterNote(),
            ],
          ),
        );
      },
    );
  }
}
