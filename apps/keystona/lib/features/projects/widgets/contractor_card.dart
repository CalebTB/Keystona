import 'package:flutter/material.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/theme/aurora_spacing.dart';

import '../models/project_contractor.dart';
import '../../../core/theme/aurora_radius.dart';

/// Single contractor card in the project contractors list.
class ContractorCard extends StatelessWidget {
  const ContractorCard({
    super.key,
    required this.contractor,
    required this.onTap,
  });

  final ProjectContractor contractor;
  final VoidCallback onTap;

  String _fmt(double v) => '\$${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final initials = contractor.contactName
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 72.0),
        padding: const EdgeInsets.symmetric(
          horizontal: AuroraSpacing.space7,
          vertical: AuroraSpacing.space3 + 2,
        ),
        decoration: BoxDecoration(
          color: AuroraColors.paper,
          borderRadius: AuroraRadius.md,
          border: Border.all(color: AuroraColors.inkBorder),
        ),
        child: Row(
          children: [
            // Avatar.
            CircleAvatar(
              radius: 22,
              backgroundColor: AuroraColors.ink.withValues(alpha: 0.1),
              child: Text(
                initials,
                style: AuroraType.label.copyWith(
                  color: AuroraColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AuroraSpacing.space7),
            // Name + role.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contractor.contactName,
                    style: AuroraType.h3,
                  ),
                  if (contractor.role != null)
                    Text(
                      ContractorRoles.labelFor(contractor.role!),
                      style: AuroraType.bodySm
                          .copyWith(color: AuroraColors.inkSecondary),
                    ),
                ],
              ),
            ),
            // Contract amount + rating.
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (contractor.contractAmount != null)
                  Text(
                    _fmt(contractor.contractAmount!),
                    style: AuroraType.bodySm.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (contractor.rating != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < contractor.rating! ? Icons.star : Icons.star_border,
                        size: 12,
                        color: AuroraColors.yellow,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AuroraSpacing.space1),
            const Icon(Icons.chevron_right, color: AuroraColors.inkTertiary, size: 18),
          ],
        ),
      ),
    );
  }
}
