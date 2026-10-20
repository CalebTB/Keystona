import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';

/// Outlined status word ("DUE IN 3 DAYS", "DONE TODAY", "HEALTHY"): a 9 pt
/// uppercase label on paper with a colored ring, and a check when [check].
///
/// The kit forbids tinted fills; the word always accompanies the color.
class TaskStatusPill extends StatelessWidget {
  const TaskStatusPill({
    super.key,
    required this.label,
    required this.ring,
    required this.text,
    this.check = false,
  });

  final String label;

  /// Outline color.
  final Color ring;

  /// Label (and check) color.
  final Color text;
  final bool check;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: a.symmetric(
        horizontal: AuroraSpacing.space2,
        vertical: AuroraTasksB.hairlineGap,
      ),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.full,
        border: Border.all(color: ring, width: AuroraBorders.regular),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (check) ...[
            Icon(
              Icons.check,
              size: a.of(AuroraSharedSizes.pillCheck),
              color: text,
            ),
            SizedBox(width: a.of(AuroraSpacing.space1)),
          ],
          Flexible(
            child: Text(
              label.toUpperCase(),
              style: AuroraTasksBType.pill.copyWith(color: text),
            ),
          ),
        ],
      ),
    );
  }
}
