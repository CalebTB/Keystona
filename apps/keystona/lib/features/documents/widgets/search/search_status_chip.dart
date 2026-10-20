import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../models/docs_expiry.dart';
import '../../models/expiry_labels.dart';

/// End-date chip on a search result: coral and amber carry a clock; a far
/// date is a neutral "TO 2035".
class SearchStatusChip extends StatelessWidget {
  const SearchStatusChip({super.key, required this.expirationDate});

  final DateTime expirationDate;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final info = DocsExpiry.of(expirationDate);
    final chip = ExpiryLabels.chip(info.days);
    final (stroke, text, clock, label) = switch (info.tone) {
      DocsExpiryTone.urgent => (
          AuroraColors.coral,
          AuroraColors.coralDeep,
          true,
          chip,
        ),
      DocsExpiryTone.soon => (
          AuroraColors.amber,
          AuroraColors.amberDeep,
          true,
          chip,
        ),
      DocsExpiryTone.far => (
          AuroraColors.inkBorderStrong,
          AuroraColors.inkSecondary,
          false,
          'TO ${expirationDate.year}',
        ),
    };
    return Container(
      padding: a.symmetric(
        horizontal: AuroraSpacing.space3,
        vertical: AuroraSpacing.space1,
      ),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.full,
        border: Border.all(color: stroke, width: AuroraBorders.regular),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (clock) ...[
            Icon(Icons.schedule, size: a.of(AuroraIconSizes.xs), color: text),
            SizedBox(width: a.of(AuroraSpacing.space1)),
          ],
          Text(
            label,
            maxLines: 1,
            style: AuroraSharedType.pill.copyWith(
              color: text,
              fontWeight: clock ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
