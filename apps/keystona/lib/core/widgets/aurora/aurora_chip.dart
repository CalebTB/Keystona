import 'package:flutter/material.dart';

import '../../theme/aurora_colors.dart';
import '../../theme/aurora_radius.dart';
import '../../theme/aurora_scale.dart';
import '../../theme/aurora_sizes.dart';
import '../../theme/aurora_spacing.dart';
import '../../theme/aurora_typography.dart';
import 'aurora_pressable.dart';

/// Status chip — 9 pt uppercase word in a pill. The word always accompanies
/// the color.
///
/// The kit forbids tinted fills, so statuses are outlines on paper; only a win
/// ([StatusChip.done]) is a solid lime fill.
///
///   Overdue:   coral outline, coralDeep text
///   Due soon:  amber outline, amberDeep text
///   Scheduled: cobalt outline, cobaltDeep text
///   Done:      solid lime, oliveDeep text
///
/// Pass [background] and [foreground] (and optionally [borderColor]) for
/// custom states.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.borderColor,
  });

  final String label;
  final Color background;
  final Color foreground;

  /// Outline color; null draws no outline.
  final Color? borderColor;

  const StatusChip.overdue({super.key, required this.label})
      : background = AuroraColors.paper,
        foreground = AuroraColors.coralDeep,
        borderColor = AuroraColors.coral;

  const StatusChip.dueSoon({super.key, required this.label})
      : background = AuroraColors.paper,
        foreground = AuroraColors.amberDeep,
        borderColor = AuroraColors.amber;

  const StatusChip.scheduled({super.key, required this.label})
      : background = AuroraColors.paper,
        foreground = AuroraColors.cobaltDeep,
        borderColor = AuroraColors.cobalt;

  const StatusChip.done({super.key, required this.label})
      : background = AuroraColors.lime,
        foreground = AuroraColors.oliveDeep,
        borderColor = null;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: a.symmetric(
        horizontal: AuroraSpacing.space3,
        vertical: AuroraSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AuroraRadius.full,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: AuroraBorders.regular),
      ),
      child: Text(
        label.toUpperCase(),
        style: AuroraType.labelSm.copyWith(color: foreground),
      ),
    );
  }
}

/// Filter chip — 36 pt pill. Selected: ink fill, paper text. Unselected:
/// paper with an ink 18% border. Optional [count] follows the label.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final fg = selected ? AuroraColors.paper : AuroraColors.ink;

    return AuroraPressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: count == null ? label : '$label, $count',
      enforceTouchTarget: true,
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.of(AuroraSizes.chipHeight),
        ),
        padding: a.symmetric(
          horizontal: AuroraSpacing.space5,
          vertical: AuroraSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: selected ? AuroraColors.ink : AuroraColors.paper,
          borderRadius: AuroraRadius.full,
          border: Border.all(
            color: selected ? AuroraColors.ink : AuroraColors.inkInputBorder,
            width: AuroraBorders.regular,
          ),
        ),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AuroraType.chip.copyWith(color: fg),
                ),
              ),
              if (count != null) ...[
                SizedBox(width: a.of(AuroraSpacing.space1)),
                Text('$count', style: AuroraType.labelSm.copyWith(color: fg)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
