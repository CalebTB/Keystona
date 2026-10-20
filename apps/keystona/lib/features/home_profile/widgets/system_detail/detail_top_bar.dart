import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../../maintenance/widgets/reminders/reminders_back_link.dart';
import '../../systems_copy.dart';

/// "‹ Systems" at the left, "Edit" at the right.
class DetailTopBar extends StatelessWidget {
  const DetailTopBar({super.key, required this.onBack, this.onEdit});

  final VoidCallback onBack;

  /// Null hides Edit (while loading).
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: RemindersBackLink(label: SystemsCopy.systemsBack, onTap: onBack),
        ),
        if (onEdit != null) ...[
          SizedBox(width: a.of(AuroraSpacing.space3)),
          AuroraPressable(
            onTap: onEdit,
            semanticLabel: SystemsCopy.edit,
            enforceTouchTarget: true,
            child: Text(
              SystemsCopy.edit,
              style: AuroraType.button.copyWith(color: AuroraColors.ink),
            ),
          ),
        ],
      ],
    );
  }
}
