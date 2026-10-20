import 'package:flutter/cupertino.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// Back link to the parent screen ("Tasks", "Task") at the left, with an
/// optional [trailing] action pinned to the right edge.
class TaskTopBar extends StatelessWidget {
  const TaskTopBar({
    super.key,
    required this.backLabel,
    required this.onBack,
    this.trailing,
  });

  final String backLabel;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final back = AuroraPressable(
      onTap: onBack,
      semanticLabel: 'Back to $backLabel',
      enforceTouchTarget: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.chevron_back,
            size: a.of(AuroraIconSizes.lg),
            color: AuroraColors.ink,
          ),
          SizedBox(width: a.of(AuroraSpacing.space1)),
          Flexible(
            child: Text(
              backLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AuroraType.button.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
    final action = trailing;
    if (action == null) {
      return Align(alignment: Alignment.centerLeft, child: back);
    }
    // Large text: the action drops below the back link instead of squeezing
    // it.
    if (a.textScale >= AuroraTasksB.stackTextScale) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: Alignment.centerLeft, child: back),
          Align(alignment: Alignment.centerRight, child: action),
        ],
      );
    }
    return Row(
      children: [
        // Expanded (not Flexible + Spacer): those split the free space
        // equally and leave the back link's unused share empty, which floats
        // the trailing action toward the middle of the bar.
        Expanded(
          child: Align(alignment: Alignment.centerLeft, child: back),
        ),
        action,
      ],
    );
  }
}
