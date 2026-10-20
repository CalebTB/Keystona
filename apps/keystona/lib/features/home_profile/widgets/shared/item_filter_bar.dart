import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_shared.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_chip.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// One filter chip: what it selects, how it reads ("All 5", "Water").
class ItemFilterOption<T> {
  const ItemFilterOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// The controls above an item list: a row of filter chips that scrolls
/// sideways, then "N SHOWN" with the sort toggle.
///
/// Place it at full width: it pads itself with [horizontalInset] so the chips
/// scroll edge to edge, as in the kit.
class ItemFilterBar<T> extends StatelessWidget {
  const ItemFilterBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.shownCount,
    required this.sortLabels,
    required this.sortIndex,
    required this.onSortChanged,
    this.horizontalInset = AuroraSpacing.screenPadH,
  });

  final List<ItemFilterOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  /// The "N SHOWN" count.
  final int shownCount;

  /// "Oldest first", "A–Z".
  final List<String> sortLabels;
  final int sortIndex;
  final ValueChanged<int> onSortChanged;
  final double horizontalInset;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final inset = a.of(horizontalInset);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: inset),
          child: Row(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0) SizedBox(width: a.of(AuroraSpacing.space2)),
                FilterPill(
                  label: options[i].label,
                  selected: options[i].value == selected,
                  onTap: () => onSelected(options[i].value),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('$shownCount SHOWN', style: AuroraType.label, maxLines: 1),
              SizedBox(width: a.of(AuroraSpacing.space3)),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: a.of(AuroraSpacing.space1),
                    children: [
                      for (var i = 0; i < sortLabels.length; i++)
                        _SortButton(
                          label: sortLabels[i],
                          selected: i == sortIndex,
                          onTap: () => onSortChanged(i),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      selected: selected,
      enforceTouchTarget: true,
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.of(AuroraHomeSizes.sortHeight),
        ),
        padding: a.symmetric(
          horizontal: AuroraSpacing.space4,
          vertical: AuroraSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: selected ? AuroraColors.inkDisabledFill : null,
          borderRadius: AuroraRadius.sm,
        ),
        child: Text(
          label,
          style: AuroraHomeType.sort.copyWith(
            color: selected ? AuroraColors.ink : AuroraColors.inkSecondary,
          ),
        ),
      ),
    );
  }
}
