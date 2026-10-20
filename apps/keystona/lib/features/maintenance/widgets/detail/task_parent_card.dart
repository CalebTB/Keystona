import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../models/task_parent.dart';
import '../shared/task_parent_icon.dart';
import '../shared/task_status_pill.dart';

/// The "For" card: the system, appliance or area this task belongs to, its
/// model and place, and where it is in its life. Tapping opens the item;
/// an area has no page, so it is not tappable.
class TaskParentCard extends StatelessWidget {
  const TaskParentCard({super.key, required this.parent, this.onTap});

  final TaskParent parent;

  /// Null for an area.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final detail = parent.detail;
    // Large text: the health pill drops under the name instead of taking the
    // row from it.
    final stacked = a.textScale >= AuroraTasksB.stackTextScale;
    final health = parent.health;
    final card = Container(
      constraints: BoxConstraints(
        minHeight: a.minControl(AuroraTasksB.parentMinHeight),
      ),
      padding: a.symmetric(
        horizontal: AuroraSpacing.space6,
        vertical: AuroraSpacing.space5,
      ),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.xl,
        border: Border.all(
          color: AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: a.of(AuroraTasksB.parentTile),
            height: a.of(AuroraTasksB.parentTile),
            decoration: BoxDecoration(
              borderRadius: AuroraRadius.md,
              border: Border.all(
                color: AuroraColors.inkTileBorder,
                width: AuroraBorders.regular,
              ),
            ),
            child: ExcludeSemantics(
              child: Icon(
                parent.kind.icon,
                size: a.of(AuroraIconSizes.md),
                color: AuroraColors.ink,
              ),
            ),
          ),
          SizedBox(width: a.of(AuroraSpacing.space5)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(parent.name, style: AuroraTasksBType.itemTitle),
                if (detail != null) ...[
                  SizedBox(height: a.of(AuroraTasksB.hairlineGap)),
                  Text(detail.toUpperCase(), style: AuroraType.meta),
                ],
                if (stacked && health != null) ...[
                  SizedBox(height: a.of(AuroraSpacing.space2)),
                  _HealthPill(health: health),
                ],
              ],
            ),
          ),
          if (!stacked && health != null) ...[
            SizedBox(width: a.of(AuroraSpacing.space3)),
            _HealthPill(health: health),
          ],
          if (onTap != null) ...[
            SizedBox(width: a.of(AuroraSpacing.space3)),
            Icon(
              Icons.chevron_right,
              size: a.of(AuroraIconSizes.sm),
              color: AuroraColors.inkPlaceholder,
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return card;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: 'Open ${parent.name}',
      child: card,
    );
  }
}

class _HealthPill extends StatelessWidget {
  const _HealthPill({required this.health});

  final TaskParentHealth health;

  @override
  Widget build(BuildContext context) {
    return switch (health) {
      TaskParentHealth.healthy => const TaskStatusPill(
        label: 'Healthy',
        ring: AuroraColors.olive,
        text: AuroraColors.olive,
        check: true,
      ),
      TaskParentHealth.aging => const TaskStatusPill(
        label: 'Aging',
        ring: AuroraColors.amber,
        text: AuroraColors.amberDeep,
      ),
      TaskParentHealth.endOfLife => const TaskStatusPill(
        label: 'End of life',
        ring: AuroraColors.coral,
        text: AuroraColors.coralDeep,
      ),
    };
  }
}
