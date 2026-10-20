import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_button.dart';
import '../../../../core/widgets/aurora/aurora_task_row.dart';
import 'item_next_up_entry.dart';

/// The item's upcoming tasks as `AuroraTaskRow`s, with the "All 5 HVAC tasks"
/// pill under them. Tapping the check circle calls [onToggle]; the row calls
/// [onTap].
class ItemNextUpList extends StatelessWidget {
  const ItemNextUpList({
    super.key,
    required this.tasks,
    required this.onTap,
    this.onToggle,
    this.allLabel,
    this.onAll,
  });

  final List<ItemNextUpEntry> tasks;
  final ValueChanged<String> onTap;
  final ValueChanged<String>? onToggle;

  /// "All 5 HVAC tasks". With [onAll], draws the pill under the rows.
  final String? allLabel;
  final VoidCallback? onAll;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final task in tasks) ...[
          AuroraTaskRow(
            name: task.name,
            dueLabel: task.dateLabel,
            metaLine: task.isPro ? '${task.metaLine} · PRO' : task.metaLine,
            dueToday: task.soon,
            overdue: task.overdue,
            done: task.done,
            onTap: () => onTap(task.id),
            onToggle: onToggle == null ? null : () => onToggle!(task.id),
          ),
          SizedBox(height: a.of(AuroraSpacing.space3)),
        ],
        if (allLabel != null && onAll != null)
          SecondaryButton(label: allLabel!, onPressed: onAll, expand: true),
      ],
    );
  }
}
