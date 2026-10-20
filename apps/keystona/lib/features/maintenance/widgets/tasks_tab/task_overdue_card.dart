import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_a.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_button.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../../documents/widgets/docs_tab/pulse_dot.dart';
import '../../tasks_copy.dart';

/// The one overdue task, large, with its actions (kit: the coral card on the
/// Tasks tab). Mark done and Snooze sit side by side; at large text they stack.
class TaskOverdueCard extends StatelessWidget {
  const TaskOverdueCard({
    super.key,
    required this.name,
    required this.daysLate,
    required this.meta,
    required this.onMarkDone,
    required this.onSnooze,
    required this.onDoesntApply,
    this.onLongPress,
    this.description,
  });

  final String name;
  final String? description;
  final int daysLate;
  final String meta;
  final VoidCallback onMarkDone;
  final VoidCallback onSnooze;
  final VoidCallback onDoesntApply;

  /// Opens the task menu, like every other task row.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final stacked = a.textScale >= AuroraTasksA.stackTextScale;
    final gap = a.of(AuroraSpacing.space3);
    final markDone = PrimaryButton(
      label: TasksCopy.markDone,
      onPressed: onMarkDone,
      expand: true,
    );
    final snooze = SecondaryButton(
      label: TasksCopy.snooze,
      onPressed: onSnooze,
      expand: stacked,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const PulseDot(),
            SizedBox(width: a.of(AuroraSpacing.space2)),
            Text(
              TasksCopy.overdueHeading,
              style: AuroraType.sectionTitle.copyWith(
                color: AuroraColors.coralDeep,
              ),
            ),
          ],
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        GestureDetector(
          onLongPress: onLongPress,
          child: Container(
            padding: a.all(AuroraSpacing.space7),
            decoration: BoxDecoration(
              borderRadius: AuroraRadius.banner,
              border: Border.all(
                color: AuroraColors.coral,
                width: AuroraBorders.emphasis,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _IconTile(),
                    Flexible(child: _LateChip(days: daysLate)),
                  ],
                ),
                SizedBox(height: a.of(AuroraSpacing.space5)),
                Text(name, style: AuroraTasksAType.heroTitle),
                if (description != null && description!.isNotEmpty) ...[
                  SizedBox(height: a.of(AuroraSpacing.space2)),
                  Text(description!, style: AuroraTasksAType.heroBody),
                ],
                SizedBox(height: a.of(AuroraSpacing.space5)),
                Text(meta, style: AuroraType.meta),
                SizedBox(height: a.of(AuroraSpacing.space5)),
                if (stacked) ...[
                  markDone,
                  SizedBox(height: gap),
                  snooze,
                ] else
                  Row(
                    children: [
                      Expanded(child: markDone),
                      SizedBox(width: gap),
                      snooze,
                    ],
                  ),
                SizedBox(height: a.of(AuroraSpacing.space5)),
                const Divider(
                  height: AuroraBorders.hairline,
                  thickness: AuroraBorders.hairline,
                  color: AuroraColors.inkBorder,
                ),
                _DoesntApplyRow(onTap: onDoesntApply),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      width: a.of(AuroraSharedSizes.iconTile),
      height: a.of(AuroraSharedSizes.iconTile),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.md,
        border: Border.all(
          color: AuroraColors.inkTileBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Icon(
        Icons.home_outlined,
        size: a.of(AuroraTasksA.heroGlyph),
        color: AuroraColors.ink,
      ),
    );
  }
}

/// The solid coral "6 DAYS LATE" pill.
class _LateChip extends StatelessWidget {
  const _LateChip({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: a.of(AuroraSpacing.space3),
        vertical: a.of(AuroraSpacing.space1),
      ),
      decoration: const BoxDecoration(
        borderRadius: AuroraRadius.full,
        color: AuroraColors.coral,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: a.of(AuroraTasksA.lateGlyph),
            color: AuroraColors.paper,
          ),
          SizedBox(width: a.of(AuroraTasksA.lateGlyphGap)),
          Flexible(
            child: Text(
              TasksCopy.daysLate(days),
              style: AuroraType.labelSm.copyWith(
                color: AuroraColors.paper,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoesntApplyRow extends StatelessWidget {
  const _DoesntApplyRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: TasksCopy.doesntApply,
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraTasksA.linkRowMinHeight),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                TasksCopy.doesntApply,
                style: AuroraTasksAType.quietLink,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: a.of(AuroraIconSizes.sm),
              color: AuroraColors.inkCheckBorder,
            ),
          ],
        ),
      ),
    );
  }
}
