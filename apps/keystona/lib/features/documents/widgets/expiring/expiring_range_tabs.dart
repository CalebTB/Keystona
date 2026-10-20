import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_c.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../models/expiring_groups.dart';

/// "30 days | 90 days | All" segmented control; the chosen one is ink.
class ExpiringRangeTabs extends StatelessWidget {
  const ExpiringRangeTabs({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final ExpiringRange selected;
  final ValueChanged<ExpiringRange> onSelect;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: a.all(AuroraDocsCSizes.rangeTabsPad),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.md,
        border: Border.all(
          color: AuroraColors.inkTileBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Row(
        children: [
          for (final range in ExpiringRange.values)
            Expanded(
              child: _Tab(
                label: range.label,
                selected: range == selected,
                onTap: () => onSelect(range),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap});

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
          minHeight: a.minControl(AuroraDocsCSizes.rangeTabHeight),
        ),
        decoration: BoxDecoration(
          color: selected ? AuroraColors.ink : null,
          borderRadius: AuroraRadius.sm,
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AuroraType.buttonSm.copyWith(
              color: selected ? AuroraColors.paper : AuroraColors.inkBody,
            ),
          ),
        ),
      ),
    );
  }
}
