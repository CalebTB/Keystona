import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../models/reminder_frequency.dart';
import '../../models/reminder_item.dart';
import '../../reminders_copy.dart';
import 'reminder_add_row.dart';
import 'reminder_group_card.dart';
import 'reminder_group_header.dart';
import 'reminder_own_row.dart';

/// "Yours": the reminders the person made (Edit and Delete) and the
/// "Add a reminder" row.
class YoursSection extends StatelessWidget {
  const YoursSection({
    super.key,
    required this.items,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

  final List<ReminderItem> items;
  final void Function(ReminderItem item) onEdit;
  final void Function(ReminderItem item) onDelete;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.space3));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ReminderGroupHeader(
          title: RemindersCopy.yoursTitle,
          trailing: ReminderHeaderNote(RemindersCopy.yoursSubtitle),
        ),
        gap,
        if (items.isNotEmpty) ...[
          ReminderGroupCard(
            rows: [
              for (final item in items)
                ReminderOwnRow(
                  key: ValueKey(item.id),
                  name: item.name,
                  meta: RemindersCopy.yoursMeta(
                    ReminderFrequency.label(
                      item.recurrence,
                      intervalYears: item.intervalYears,
                    ),
                    item.createdAt,
                  ),
                  onEdit: () => onEdit(item),
                  onDelete: () => onDelete(item),
                ),
            ],
          ),
          gap,
        ],
        ReminderAddRow(label: RemindersCopy.addReminder, onTap: onAdd),
      ],
    );
  }
}
