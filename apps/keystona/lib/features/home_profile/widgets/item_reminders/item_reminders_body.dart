import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_c.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../maintenance/models/reminder_frequency.dart';
import '../../../maintenance/models/reminder_item.dart';
import '../../../maintenance/reminders_copy.dart';
import '../../../maintenance/widgets/reminders/reminder_add_row.dart';
import '../../../maintenance/widgets/reminders/reminder_frequency_row.dart';
import '../../../maintenance/widgets/reminders/reminder_group_card.dart';
import '../../../maintenance/widgets/reminders/reminder_group_header.dart';
import '../../item_copy.dart';
import '../../models/item_summary.dart';

/// The reminders of one item: the blurb, the ON card with a switch and a
/// how-often pill per row, the TURNED OFF card with why, and the add row.
class ItemRemindersBody extends StatelessWidget {
  const ItemRemindersBody({
    super.key,
    required this.info,
    required this.on,
    required this.off,
    required this.proIds,
    required this.onToggle,
    required this.onPickFrequency,
    required this.onAdd,
  });

  final ItemSummary info;
  final List<ReminderItem> on;
  final List<ReminderItem> off;

  /// Ids of the reminders whose task is a job for a pro (they carry a PRO tag).
  final Set<String> proIds;
  final void Function(ReminderItem item, bool on) onToggle;
  final ValueChanged<ReminderItem> onPickFrequency;
  final VoidCallback onAdd;

  Widget _row(ReminderItem item) => ReminderFrequencyRow(
    key: ValueKey(item.id),
    name: item.name,
    frequency: ReminderFrequency.label(
      item.recurrence,
      intervalYears: item.intervalYears,
    ),
    on: item.enabled,
    offReason: RemindersCopy.offSince(item.offSince, item.offReason),
    tags: [
      ...item.tags,
      if (proIds.contains(item.id)) 'PRO',
    ],
    onChanged: (v) => onToggle(item, v),
    onPickFrequency: () => onPickFrequency(item),
  );

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.space8));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(ItemCopy.remindersBlurb(info), style: AuroraTasksCType.blurb),
        gap,
        if (on.isNotEmpty) ...[
          ReminderGroupHeader(
            title: ItemCopy.onTitle(on.length),
            trailing: const ReminderHeaderNote(ItemCopy.onNote),
          ),
          SizedBox(height: a.of(AuroraSpacing.space3)),
          ReminderGroupCard(rows: [for (final i in on) _row(i)]),
          gap,
        ],
        if (off.isNotEmpty) ...[
          ReminderGroupHeader(
            title: ItemCopy.offTitle(off.length),
            trailing: const ReminderHeaderNote(ItemCopy.offNote),
          ),
          SizedBox(height: a.of(AuroraSpacing.space3)),
          ReminderGroupCard(rows: [for (final i in off) _row(i)]),
          gap,
        ],
        ReminderAddRow(label: ItemCopy.addOwn(info), onTap: onAdd),
        SizedBox(height: a.of(AuroraSpacing.space5)),
        Text(
          ItemCopy.suggestionsNote(info).toUpperCase(),
          textAlign: TextAlign.center,
          style: AuroraType.meta,
        ),
      ],
    );
  }
}
