import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_a.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import 'task_check_button.dart';

/// One task row of a list card: check circle, title and meta, an optional
/// chip, and the date at the right edge. Long-press opens the task menu; there
/// is no ⋯ button.
class TaskRowItem extends StatelessWidget {
  const TaskRowItem({
    super.key,
    required this.name,
    required this.meta,
    required this.checkLabel,
    required this.onToggle,
    required this.onTap,
    this.onLongPress,
    this.date,
    this.chip,
    this.late = false,
    this.done = false,
  });

  final String name;
  final String meta;

  /// "OCT 7", "TODAY" or "DONE"; none when null.
  final String? date;

  /// "PRO" (outlined), or the "6 DAYS LATE" pill when [late].
  final String? chip;

  /// Overdue: coral circle and a filled coral chip.
  final bool late;
  final bool done;

  final String checkLabel;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final showChip = chip != null && !done;
    // At large text the chip would squeeze the title, so it drops under the
    // meta line and only the date stays at the edge.
    final chipBelow = showChip && a.textScale >= AuroraTasksA.stackTextScale;
    final hasTrailing = (showChip && !chipBelow) || date != null;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: a.minControl(AuroraTasksA.rowMinHeight),
      ),
      child: Row(
        children: [
          SizedBox(width: a.of(AuroraSpacing.space1)),
          TaskCheckButton(
            onTap: onToggle,
            semanticLabel: checkLabel,
            done: done,
            overdue: late,
          ),
          SizedBox(width: a.of(AuroraSpacing.space2)),
          Expanded(
            child: AuroraPressable(
              onTap: onTap,
              onLongPress: onLongPress,
              semanticLabel: name,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  0,
                  a.of(AuroraSpacing.space3),
                  a.of(AuroraSpacing.space6),
                  a.of(AuroraSpacing.space3),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AuroraType.rowTitle.copyWith(
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: done
                                  ? AuroraColors.inkHelper
                                  : AuroraColors.ink,
                            ),
                          ),
                          SizedBox(height: a.of(AuroraSpacing.space1)),
                          Text(
                            meta,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AuroraType.meta,
                          ),
                          if (chipBelow) ...[
                            SizedBox(height: a.of(AuroraSpacing.space2)),
                            _Chip(label: chip!, late: late),
                          ],
                        ],
                      ),
                    ),
                    if (hasTrailing) ...[
                      SizedBox(width: a.of(AuroraTasksA.rowGap)),
                      _Trailing(
                        chip: showChip && !chipBelow ? chip : null,
                        late: late,
                        date: date,
                      ),
                    ],
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

/// The chip (when it fits beside the title) and the date at a row's right
/// edge.
class _Trailing extends StatelessWidget {
  const _Trailing({required this.chip, required this.late, required this.date});

  final String? chip;
  final bool late;
  final String? date;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (chip != null) _Chip(label: chip!, late: late),
        if (chip != null && date != null)
          SizedBox(width: a.of(AuroraTasksA.rowGap)),
        if (date != null)
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: a.of(AuroraTasksA.dateMinWidth),
            ),
            child: Text(
              date!,
              textAlign: TextAlign.end,
              style: AuroraType.rowDate,
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.late});

  final String label;
  final bool late;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: a.of(AuroraSpacing.space3),
        vertical: a.of(AuroraSpacing.space1),
      ),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.full,
        color: late ? AuroraColors.coral : null,
        border: late
            ? null
            : Border.all(
                color: AuroraColors.inkInputBorder,
                width: AuroraBorders.regular,
              ),
      ),
      child: Text(
        label,
        style: AuroraType.labelSm.copyWith(
          color: late ? AuroraColors.paper : AuroraColors.inkSecondary,
          fontWeight: late ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }
}
