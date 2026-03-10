import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/project_contractor.dart';

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
        constraints: const BoxConstraints(minHeight: AppSizes.cardMinHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Avatar.
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.deepNavy.withValues(alpha: 0.1),
              child: Text(
                initials,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.deepNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            // Name + role.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contractor.contactName,
                    style: AppTextStyles.bodyMediumSemibold,
                  ),
                  if (contractor.role != null)
                    Text(
                      ContractorRoles.labelFor(contractor.role!),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
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
                    style: AppTextStyles.bodySmall.copyWith(
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
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSizes.xs),
            const Icon(Icons.chevron_right, color: AppColors.gray400, size: 18),
          ],
        ),
      ),
    );
  }
}
