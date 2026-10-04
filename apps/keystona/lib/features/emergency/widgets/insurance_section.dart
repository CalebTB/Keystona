import 'package:flutter/material.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../models/insurance_policy.dart';

/// Insurance quick reference section on the Emergency Hub main screen.
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
        Row(
          children: [
            Text(
              'Insurance',
              style: AuroraType.body.copyWith(fontWeight: FontWeight.w700, color: AuroraColors.ink),
            ),
            const Spacer(),
            if (policies.isNotEmpty)
              GestureDetector(
                onTap: onSeeAll,
                child: Text(
                  'See all (${policies.length})',
                  style: AuroraType.bodySm.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AuroraColors.ink,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AuroraSpacing.space3),

        if (policies.isEmpty)
          _EmptyInsurance(onAdd: onAddPolicy)
        else ...[
          ...policies.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: AuroraSpacing.space3),
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
        color: AuroraColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: expiring ? AuroraColors.yellowDeep : AuroraColors.inkBorder,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.space7,
        vertical: AuroraSpacing.space3,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AuroraColors.ink.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _policyIcon,
              size: 20,
              color: AuroraColors.ink,
            ),
          ),
          const SizedBox(width: AuroraSpacing.space7),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${policy.policyType.policyTypeLabel} · ${policy.carrier}',
                  style: AuroraType.body.copyWith(fontWeight: FontWeight.w600, color: AuroraColors.ink),
                ),
                if (policy.policyNumber != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    policy.policyNumber!,
                    style: AuroraType.bodySm.copyWith(
                      color: AuroraColors.inkSecondary,
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
                        color: AuroraColors.yellowDeep,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Expiring soon',
                        style: AuroraType.bodySm.copyWith(
                          fontSize: 10,
                          color: AuroraColors.yellowDeep,
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
            color: AuroraColors.inkSecondary,
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
      padding: const EdgeInsets.all(AuroraSpacing.space7),
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AuroraColors.inkBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shield_outlined,
            size: 20,
            color: AuroraColors.inkSecondary,
          ),
          const SizedBox(width: AuroraSpacing.space3),
          Expanded(
            child: Text(
              'No insurance info yet',
              style: AuroraType.body.copyWith(
                color: AuroraColors.inkSecondary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: Text(
              '+ Add',
              style: AuroraType.bodySm.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AuroraColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
