import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_tasks_c.dart';
import '../../models/reminder_frequency.dart';
import '../../models/reminder_groups.dart';
import '../../models/review_row.dart';
import '../../reminders_copy.dart';
import 'review_group_section.dart';

/// The suggested reminders on the Review screen: one section per system,
/// appliance or kind of house reminder.
class ReviewGroupsList extends StatelessWidget {
  const ReviewGroupsList({
    super.key,
    required this.groups,
    required this.climateZone,
    required this.onToggle,
  });

  final List<ReminderGroup> groups;
  final int? climateZone;
  final void Function(String id, bool on) onToggle;

  String _subtitle(ReminderGroup group) => switch (group.kind) {
    ReminderGroupKind.item => RemindersCopy.becauseYouAdded(group.title),
    ReminderGroupKind.climate => RemindersCopy.zone(climateZone),
    _ => RemindersCopy.everyHouse,
  };

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: context.aurora.of(AuroraTasksCSizes.blockGap));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in groups) ...[
          ReviewGroupSection(
            title: group.title,
            subtitle: _subtitle(group),
            rows: [
              for (final item in group.items)
                ReviewRow(
                  key: item.id,
                  name: item.name,
                  frequency: ReminderFrequency.label(
                    item.recurrence,
                    intervalYears: item.intervalYears,
                  ),
                  on: item.enabled,
                ),
            ],
            onToggle: onToggle,
          ),
          gap,
        ],
      ],
    );
  }
}
