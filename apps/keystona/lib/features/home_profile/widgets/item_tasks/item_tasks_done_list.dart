import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../item_copy.dart';
import '../../models/item_completion.dart';
import '../../models/item_tasks.dart';
import 'item_done_summary_card.dart';
import 'item_done_tile.dart';

/// The "Done" tab: the total, a tile per finished task (newest first) and,
/// when there are more than [cap], the "+ 7 EARLIER · BACK TO MAR 2021" link
/// that shows the rest.
class ItemTasksDoneList extends StatelessWidget {
  const ItemTasksDoneList({
    super.key,
    required this.completions,
    required this.today,
    required this.onSchedule,
    required this.expanded,
    required this.onExpand,
  });

  final List<ItemCompletion> completions;
  final DateTime today;
  final bool onSchedule;
  final bool expanded;
  final VoidCallback onExpand;

  /// Completions shown before the "earlier" link.
  static const int cap = 20;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final shown = expanded ? completions : completions.take(cap).toList();
    final hidden = completions.length - shown.length;
    final summary = ItemTasks.summary(completions);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (summary != null)
          ItemDoneSummaryCard(summary: summary, onSchedule: onSchedule),
        SizedBox(height: a.of(AuroraSpacing.space4)),
        for (final c in shown) ...[
          ItemDoneTile(key: ValueKey(c.id), completion: c, today: today),
          SizedBox(height: a.of(AuroraSpacing.space4)),
        ],
        if (hidden > 0)
          AuroraPressable(
            onTap: onExpand,
            semanticLabel: ItemCopy.earlier(hidden, completions.last.completedOn),
            enforceTouchTarget: true,
            child: Center(
              child: Text(
                ItemCopy.earlier(hidden, completions.last.completedOn),
                textAlign: TextAlign.center,
                style: AuroraType.meta.copyWith(color: AuroraColors.inkHelper),
              ),
            ),
          ),
      ],
    );
  }
}
