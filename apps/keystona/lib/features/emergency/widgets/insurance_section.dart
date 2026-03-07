import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/insurance_policy.dart';

/// Insurance quick reference section on the Emergency Hub main screen.
///
/// Shows all policy summaries (type icon + carrier + policy number).
/// Full CRUD + tap-to-call implemented by [#47 Insurance Quick Reference].
class InsuranceSection extends StatelessWidget {
  const InsuranceSection({
    super.key,
    required this.policies,
    required this.onSeeAll,
    required this.onAddPolicy,
  });

  final List<InsurancePolicy> policies;
  final VoidCallback onSeeAll;
  final VoidCallback onAddPolicy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header.
        Row(
          children: [
            Text(
              'Insurance',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (policies.isNotEmpty)
              GestureDetector(
                onTap: onSeeAll,
                child: Text(
                  'See all (${policies.length})',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.deepNavy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),

        if (policies.isEmpty)
          _EmptyInsurance(onAdd: onAddPolicy)
        else ...[
          ...policies.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                child: _PolicyRow(policy: p),
              )),
        ],
      ],
    );
  }
}

class _PolicyRow extends StatelessWidget {
  const _PolicyRow({required this.policy});
  final InsurancePolicy policy;

  @override
  Widget build(BuildContext context) {
    final expiring = _isExpiringSoon;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: expiring ? AppColors.healthFair : AppColors.border,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      child: Row(
        children: [
          // Policy type icon.
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.deepNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(
              _policyIcon,
              size: 20,
              color: AppColors.deepNavy,
            ),
          ),
          const SizedBox(width: AppSizes.md),

          // Carrier + policy number.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${policy.policyType.policyTypeLabel} · ${policy.carrier}',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (policy.policyNumber != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    policy.policyNumber!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (expiring) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 12,
                        color: AppColors.healthFair,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Expiring soon',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.healthFair,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  bool get _isExpiringSoon {
    if (policy.expirationDate == null) return false;
    final daysLeft =
        policy.expirationDate!.difference(DateTime.now()).inDays;
    return daysLeft >= 0 && daysLeft <= 30;
  }

  IconData get _policyIcon => switch (policy.policyType) {
        'homeowners' => Icons.home_outlined,
        'flood' => Icons.water_outlined,
        'earthquake' => Icons.terrain_outlined,
        'umbrella' => Icons.umbrella_outlined,
        'home_warranty' => Icons.handyman_outlined,
        _ => Icons.shield_outlined,
      };
}

class _EmptyInsurance extends StatelessWidget {
  const _EmptyInsurance({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shield_outlined,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              'No insurance info yet',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: Text(
              '+ Add',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.deepNavy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
