import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';

/// "This log goes into your Home History Report": a cobalt-outlined note.
class TaskHistoryCallout extends StatelessWidget {
  const TaskHistoryCallout({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: a.symmetric(
        horizontal: AuroraSpacing.space6,
        vertical: AuroraSpacing.space5,
      ),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.lg,
        border: Border.all(
          color: AuroraColors.cobaltBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.done_all,
              size: a.of(AuroraIconSizes.md),
              color: AuroraColors.cobalt,
            ),
          ),
          SizedBox(width: a.of(AuroraSpacing.space4)),
          Expanded(child: Text(text, style: AuroraTasksBType.callout)),
        ],
      ),
    );
  }
}
