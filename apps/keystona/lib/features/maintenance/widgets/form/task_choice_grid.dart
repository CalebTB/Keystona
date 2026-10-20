import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_c.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// One tile in a [TaskChoiceGrid].
class TaskChoice<T> {
  const TaskChoice({required this.value, required this.label, this.sub});

  final T value;
  final String label;

  /// Small uppercase line under the label ("SUN 4").
  final String? sub;
}

/// A single-choice row of equal tiles (Systems / Appliances, the first-due
/// chips, "Who does it"). The selected tile is solid ink; the rest are
/// outlined.
///
/// Tiles sit side by side while each can keep [minTileWidth] (grown with the
/// text size); below that they wrap onto more rows instead of squeezing.
class TaskChoiceGrid<T> extends StatelessWidget {
  const TaskChoiceGrid({
    super.key,
    required this.choices,
    required this.selected,
    required this.onSelect,
    required this.minHeight,
    required this.labelStyle,
    this.minTileWidth = AuroraTasksCSizes.dueChipMinWidth,
    this.gap = AuroraSpacing.space2,
    this.radius = AuroraRadius.md,
  });

  final List<TaskChoice<T>> choices;
  final T selected;
  final ValueChanged<T> onSelect;
  final double minHeight;
  final TextStyle labelStyle;
  final double minTileWidth;
  final double gap;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final spacing = a.of(gap);
    return LayoutBuilder(
      builder: (context, constraints) {
        final needed = a.of(minTileWidth) * (a.textScale > 1 ? a.textScale : 1);
        var columns = choices.length;
        while (columns > 1 &&
            (constraints.maxWidth - spacing * (columns - 1)) / columns <
                needed) {
          columns--;
        }
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final choice in choices)
              SizedBox(
                width: tileWidth,
                child: _Tile<T>(
                  choice: choice,
                  on: choice.value == selected,
                  minHeight: minHeight,
                  labelStyle: labelStyle,
                  radius: radius,
                  onTap: () => onSelect(choice.value),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Tile<T> extends StatelessWidget {
  const _Tile({
    required this.choice,
    required this.on,
    required this.minHeight,
    required this.labelStyle,
    required this.radius,
    required this.onTap,
  });

  final TaskChoice<T> choice;
  final bool on;
  final double minHeight;
  final TextStyle labelStyle;
  final BorderRadius radius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final sub = choice.sub;
    return AuroraPressable(
      onTap: onTap,
      selected: on,
      semanticLabel: sub == null ? choice.label : '${choice.label}, $sub',
      child: Container(
        constraints: BoxConstraints(minHeight: a.minControl(minHeight)),
        alignment: Alignment.center,
        padding: a.symmetric(
          horizontal: AuroraSpacing.space3,
          vertical: AuroraSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: on ? AuroraColors.ink : AuroraColors.paper,
          borderRadius: radius,
          border: Border.all(
            color: on ? AuroraColors.ink : AuroraColors.inkInputBorder,
            width: on ? AuroraBorders.emphasis : AuroraBorders.regular,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              choice.label,
              textAlign: TextAlign.center,
              style: labelStyle.copyWith(
                color: on ? AuroraColors.paper : AuroraColors.inkBody,
              ),
            ),
            if (sub != null) ...[
              SizedBox(height: a.of(AuroraSpacing.space1)),
              Text(
                sub.toUpperCase(),
                textAlign: TextAlign.center,
                style: AuroraTasksCType.chipSub.copyWith(
                  color: on ? AuroraOnInk.secondary : AuroraColors.inkSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
