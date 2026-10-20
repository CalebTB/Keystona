import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_c.dart';
import '../../../../core/theme/aurora_home_shared.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../maintenance/services/task_format.dart';
import '../../models/item_completion.dart';
import '../../models/item_tasks.dart';

/// A finished task: olive check, the name, "JUL 6 · YOU" and the cost at the
/// right edge.
class ItemDoneTile extends StatelessWidget {
  const ItemDoneTile({super.key, required this.completion, required this.today});

  final ItemCompletion completion;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final cost = completion.cost;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.xl,
        border: Border.all(
          color: AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Padding(
        padding: a.symmetric(
          horizontal: AuroraSpacing.space6,
          vertical: AuroraSpacing.space5,
        ),
        child: Row(
          children: [
            Container(
              width: a.of(AuroraHomeCSizes.doneCheck),
              height: a.of(AuroraHomeCSizes.doneCheck),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AuroraColors.olive,
              ),
              child: Icon(
                Icons.check,
                size: a.of(AuroraIconSizes.xs),
                color: AuroraColors.lime,
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space5)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    completion.taskName,
                    style: AuroraHomeType.entryTitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: a.of(AuroraSpacing.space1)),
                  Text(
                    ItemTasks.doneMeta(completion, today),
                    style: AuroraType.meta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (cost != null) ...[
              SizedBox(width: a.of(AuroraSpacing.space4)),
              Text(TaskFormat.money(cost), style: AuroraHomeType.entryTitle),
            ],
          ],
        ),
      ),
    );
  }
}
