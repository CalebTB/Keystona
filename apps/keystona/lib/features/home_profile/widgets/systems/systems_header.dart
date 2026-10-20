import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../systems_copy.dart';

/// The eyebrow ("1428 ELM HOLLOW · 5 TRACKED · 1 AGING") and the "Systems"
/// heading.
class SystemsHeader extends StatelessWidget {
  const SystemsHeader({super.key, required this.eyebrow});

  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow, style: AuroraType.label),
        SizedBox(height: a.of(AuroraSpacing.space2)),
        Semantics(
          header: true,
          child: Text(SystemsCopy.listTitle, style: AuroraType.h1),
        ),
      ],
    );
  }
}
