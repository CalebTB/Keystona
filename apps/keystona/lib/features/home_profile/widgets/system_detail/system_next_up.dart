import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_button.dart';
import '../../../../core/widgets/aurora/aurora_task_row.dart';
import '../../systems_copy.dart';
import '../shared/item_next_up_entry.dart';

/// "NEXT UP": the system's soonest tasks as rows (tap opens, check marks done,
/// long-press opens the task menu) and the "All 5 HVAC tasks" pill.
class SystemNextUp extends StatelessWidget {
  const SystemNextUp({
    super.key,
    required this.entries,
    required this.allLabel,
    required this.onTap,
    required this.onToggle,
    required this.onLongPress,
    required this.onAll,
  });

  final List<ItemNextUpEntry> entries;
  final String allLabel;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onLongPress;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final t in entries) ...[
          AuroraTaskRow(
            name: t.name,
            dueLabel: t.dateLabel,
            metaLine: t.isPro ? '${t.metaLine} · ${SystemsCopy.proTag}' : t.metaLine,
            dueToday: t.soon,
            overdue: t.overdue,
            onTap: () => onTap(t.id),
            onToggle: () => onToggle(t.id),
            onLongPress: () => onLongPress(t.id),
          ),
          SizedBox(height: a.of(AuroraSpacing.space3)),
        ],
        SecondaryButton(label: '$allLabel ›', onPressed: onAll, expand: true),
      ],
    );
  }
}
