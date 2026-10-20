import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../../../core/theme/aurora_typography.dart';

/// Eyebrow ("HVAC · EVERY 3 MONTHS" and a status pill), the task name, and
/// its description.
class TaskDetailHeader extends StatelessWidget {
  const TaskDetailHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.pill,
    this.description,
  });

  final String eyebrow;
  final String title;

  /// A [TaskStatusPill] shown after the eyebrow, wrapping below it when the
  /// row is too narrow.
  final Widget? pill;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.space3));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: a.of(AuroraSpacing.space2),
          runSpacing: a.of(AuroraSpacing.space2),
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              eyebrow.toUpperCase(),
              style: AuroraType.label.copyWith(
                fontWeight: FontWeight.w600,
                color: AuroraColors.inkSecondary,
              ),
            ),
            ?pill,
          ],
        ),
        gap,
        Semantics(
          header: true,
          child: Text(title, style: AuroraTasksBType.pageTitle),
        ),
        if (description != null && description!.trim().isNotEmpty) ...[
          gap,
          Text(description!, style: AuroraTasksBType.subtitle),
        ],
      ],
    );
  }
}
