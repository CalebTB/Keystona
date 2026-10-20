import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_c.dart';
import '../../../../core/theme/aurora_typography.dart';

/// Eyebrow, big title and the paragraph under it.
class RemindersHeader extends StatelessWidget {
  const RemindersHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.blurb,
  });

  final String eyebrow;
  final String title;
  final String blurb;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow.toUpperCase(), style: AuroraType.label),
        SizedBox(height: a.of(AuroraSpacing.space2)),
        Semantics(
          header: true,
          child: Text(title, style: AuroraTasksCType.screenTitle),
        ),
        SizedBox(height: a.of(AuroraSpacing.space5)),
        Text(blurb, style: AuroraTasksCType.blurb),
      ],
    );
  }
}
