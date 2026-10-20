import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';

/// Cobalt dot, uppercase section title, and a quiet label on the right
/// ("13 OF 25 · FREE PLAN").
class UploadSectionHeader extends StatelessWidget {
  const UploadSectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: a.of(AuroraSizes.sectionDot),
          height: a.of(AuroraSizes.sectionDot),
          decoration: const BoxDecoration(
            color: AuroraColors.cobalt,
            borderRadius: AuroraRadius.full,
          ),
        ),
        SizedBox(width: a.of(AuroraSpacing.space2)),
        Flexible(
          child: Semantics(
            header: true,
            child: Text(title.toUpperCase(), style: AuroraType.sectionTitle),
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: a.of(AuroraSpacing.space3)),
          Flexible(
            child: Text(
              trailing!,
              textAlign: TextAlign.end,
              style: AuroraType.label,
            ),
          ),
        ],
      ],
    );
  }
}
