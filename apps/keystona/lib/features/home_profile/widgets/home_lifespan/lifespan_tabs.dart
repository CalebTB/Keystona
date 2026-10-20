import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_a.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// Equal-width tabs in one outlined bar ("All 10", "Systems", "Appliances").
/// The selected tab is solid ink.
class LifespanTabs extends StatelessWidget {
  const LifespanTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.md,
        border: Border.all(
          color: AuroraColors.inkInputBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Padding(
        padding: a.all(AuroraSpacing.space1),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: _Tab(
                    label: labels[i],
                    selected: i == selected,
                    onTap: () => onChanged(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
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
      semanticLabel: label,
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraHomeASizes.tabHeight),
        ),
        padding: a.symmetric(horizontal: AuroraSpacing.space2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AuroraColors.ink : null,
          borderRadius: AuroraRadius.md,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AuroraHomeAType.tab.copyWith(
            color: selected ? AuroraColors.paper : AuroraColors.inkBody,
          ),
        ),
      ),
    );
  }
}
