import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_shared.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../appliance_copy.dart';
import '../shared/item_key_value.dart';
import '../shared/item_key_value_card.dart';

/// "SPECIFICATIONS · 5" with HIDE / SHOW at the right, and the key/value card
/// under it while open.
class ApplianceSpecsCard extends StatelessWidget {
  const ApplianceSpecsCard({
    super.key,
    required this.rows,
    required this.expanded,
    required this.onToggle,
  });

  final List<ItemKeyValue> rows;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuroraPressable(
          onTap: onToggle,
          semanticLabel: ApplianceCopy.specsTitle(rows.length),
          selected: expanded,
          enforceTouchTarget: true,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  ApplianceCopy.specsTitle(rows.length).toUpperCase(),
                  style: AuroraType.label,
                ),
              ),
              Text(
                expanded ? ApplianceCopy.specsHide : ApplianceCopy.specsShow,
                style: AuroraHomeType.tag.copyWith(
                  color: AuroraColors.inkSecondary,
                ),
              ),
              SizedBox(width: a.of(AuroraSpacing.space1)),
              Icon(
                expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: a.of(AuroraIconSizes.sm),
                color: AuroraColors.inkHelper,
              ),
            ],
          ),
        ),
        if (expanded) ...[
          SizedBox(height: a.of(AuroraSpacing.space3)),
          ItemKeyValueCard(rows: rows),
        ],
      ],
    );
  }
}
