import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_a.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../categories_copy.dart';

/// The coral "★ PREMIUM" pill beside a Premium-only feature's eyebrow.
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: a.symmetric(
        horizontal: AuroraSpacing.space2,
        vertical: AuroraDocsA.hairlineGap,
      ),
      decoration: const BoxDecoration(
        color: AuroraColors.coral,
        borderRadius: AuroraRadius.full,
      ),
      child: Text(
        CategoriesCopy.premium,
        maxLines: 1,
        style: AuroraSharedType.pill.copyWith(
          color: AuroraColors.paper,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
