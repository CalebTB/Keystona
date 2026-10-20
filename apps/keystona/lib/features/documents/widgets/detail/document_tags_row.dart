import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';

/// The document's tags as outlined "#tag" chips, under Notes.
class DocumentTagsRow extends StatelessWidget {
  const DocumentTagsRow({super.key, required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Wrap(
      spacing: a.of(AuroraSpacing.space3),
      runSpacing: a.of(AuroraSpacing.space3),
      children: [
        for (final tag in tags)
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AuroraRadius.full,
              border: Border.all(
                color: AuroraColors.inkInputBorder,
                width: AuroraBorders.regular,
              ),
            ),
            child: Padding(
              padding: a.symmetric(
                horizontal: AuroraSpacing.space6,
                vertical: AuroraSpacing.space3,
              ),
              child: Text('#$tag', style: AuroraType.chip),
            ),
          ),
      ],
    );
  }
}
