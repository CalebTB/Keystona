import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../../maintenance/widgets/tasks_tab/task_check_button.dart';
import '../../item_copy.dart';
import '../../models/item_tasks.dart';
import 'item_task_pill.dart';

/// An open task on the ItemTasks list: check circle, name and date, then the
/// EVERY / DIY or PRO pills and the time and cost. Due soon gets an amber
/// border, overdue a coral one. Long-press opens the task menu; there are no
/// edit or delete buttons.
class ItemOpenTaskCard extends StatelessWidget {
  const ItemOpenTaskCard({
    super.key,
    required this.card,
    required this.onToggle,
    required this.onOpen,
    required this.onMenu,
  });

  final ItemTaskCard card;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final border = card.overdue
        ? AuroraColors.coral
        : card.soon
        ? AuroraColors.amber
        : AuroraColors.inkBorder;
    final emphasised = card.overdue || card.soon;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.xl,
        border: Border.all(
          color: border,
          width: emphasised ? AuroraBorders.emphasis : AuroraBorders.regular,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: a.of(AuroraSpacing.space2)),
          TaskCheckButton(
            onTap: onToggle,
            semanticLabel: ItemCopy.markDone(card.task.name),
            overdue: card.overdue,
          ),
          Expanded(
            child: AuroraPressable(
              onTap: onOpen,
              onLongPress: onMenu,
              semanticLabel: card.task.name,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  a.of(AuroraSpacing.space3),
                  a.of(AuroraSpacing.space5),
                  a.of(AuroraSpacing.space6),
                  a.of(AuroraSpacing.space5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            card.task.name,
                            style: AuroraType.h3,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: a.of(AuroraSpacing.space4)),
                        Text(
                          card.dateLabel,
                          style: AuroraType.rowDate.copyWith(
                            color: card.overdue
                                ? AuroraColors.coralDeep
                                : card.soon
                                ? AuroraColors.amberDeep
                                : AuroraColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: a.of(AuroraSpacing.space3)),
                    Wrap(
                      spacing: a.of(AuroraSpacing.space2),
                      runSpacing: a.of(AuroraSpacing.space2),
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ItemTaskPill(label: card.every),
                        ItemTaskPill(label: card.who, solid: card.pro),
                        if (card.meta.isNotEmpty)
                          Text(card.meta, style: AuroraType.meta),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
