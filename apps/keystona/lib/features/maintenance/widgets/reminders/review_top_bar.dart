import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../reminders_copy.dart';

/// Review your reminders: a leading action on the left ("Home" back link, or
/// "Skip") and "Turn all on" in cobalt on the right.
class ReviewTopBar extends StatelessWidget {
  const ReviewTopBar({
    super.key,
    required this.leading,
    required this.onTurnAllOn,
  });

  final Widget leading;
  final VoidCallback? onTurnAllOn;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    // Flexible + spaceBetween, not Expanded + Flexible.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: leading),
        SizedBox(width: a.of(AuroraSpacing.space3)),
        Flexible(
          child: AuroraPressable(
            onTap: onTurnAllOn,
            semanticLabel: RemindersCopy.turnAllOn,
            enforceTouchTarget: true,
            child: Text(
              RemindersCopy.turnAllOn,
              textAlign: TextAlign.end,
              style: AuroraType.button.copyWith(
                fontWeight: FontWeight.w600,
                color: onTurnAllOn == null
                    ? AuroraColors.inkPlaceholder
                    : AuroraColors.cobalt,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
