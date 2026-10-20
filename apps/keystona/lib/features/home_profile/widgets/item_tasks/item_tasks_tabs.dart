import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_c.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// The two-way switch under the ItemTasks title: "Coming up · 5" and
/// "Done · 12". The chosen one is solid ink.
class ItemTasksTabs extends StatelessWidget {
  const ItemTasksTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.md,
        border: Border.all(
          color: AuroraColors.inkTileBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(AuroraHomeCSizes.tabsInset),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: AuroraPressable(
                  onTap: () => onSelected(i),
                  selected: i == selected,
                  semanticLabel: labels[i],
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: a.minControl(AuroraSizes.minTouch),
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == selected ? AuroraColors.ink : null,
                      borderRadius: AuroraRadius.sm,
                    ),
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: AuroraType.button.copyWith(
                        color: i == selected
                            ? AuroraColors.paper
                            : AuroraColors.inkSubtle,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
