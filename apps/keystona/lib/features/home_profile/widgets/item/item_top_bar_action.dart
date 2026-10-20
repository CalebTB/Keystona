import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_c.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_button.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// How an [ItemTopBarAction] is drawn.
enum ItemTopBarStyle {
  /// Plain bold text: "Edit", "Manage".
  text,

  /// Outlined cobalt pill: "+ Add".
  outline,

  /// Solid cobalt pill: "Done".
  filled,
}

/// The action at the right of an item screen's top bar. At least 44 pt tall.
class ItemTopBarAction extends StatelessWidget {
  const ItemTopBarAction({
    super.key,
    required this.label,
    required this.onTap,
    this.style = ItemTopBarStyle.text,
  });

  final String label;
  final VoidCallback? onTap;
  final ItemTopBarStyle style;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    switch (style) {
      case ItemTopBarStyle.filled:
        return SaveButton(label: label, onPressed: onTap, compact: true);
      case ItemTopBarStyle.outline:
        return AuroraPressable(
          onTap: onTap,
          semanticLabel: label,
          enforceTouchTarget: true,
          child: Container(
            constraints: BoxConstraints(
              minHeight: a.of(AuroraHomeCSizes.pillHeight),
            ),
            padding: a.symmetric(horizontal: AuroraSpacing.pillHCompact),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: AuroraRadius.full,
              border: Border.all(
                color: AuroraColors.cobalt,
                width: AuroraBorders.emphasis,
              ),
            ),
            child: Text(
              label,
              style: AuroraType.buttonSm.copyWith(color: AuroraColors.cobalt),
            ),
          ),
        );
      case ItemTopBarStyle.text:
        return AuroraPressable(
          onTap: onTap,
          semanticLabel: label,
          enforceTouchTarget: true,
          child: Padding(
            padding: a.symmetric(horizontal: AuroraSpacing.space2),
            child: Text(label, style: AuroraType.button),
          ),
        );
    }
  }
}
