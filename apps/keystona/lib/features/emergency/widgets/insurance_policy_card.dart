import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../models/insurance_policy.dart';
import '../../../core/theme/aurora_radius.dart';

/// Card displaying an insurance policy summary.
class InsurancePolicyCard extends StatelessWidget {
  const InsurancePolicyCard({
    super.key,
    required this.policy,
    required this.onTap,
  });

  final InsurancePolicy policy;
  final VoidCallback onTap;

  static IconData _iconFor(String policyType) => switch (policyType) {
        'homeowners' => Icons.home_outlined,
        'flood' => Icons.water_outlined,
        'earthquake' => Icons.terrain_outlined,
        'umbrella' => Icons.umbrella_outlined,
        'home_warranty' => Icons.handyman_outlined,
        _ => Icons.shield_outlined,
      };

  bool get _isExpiringSoon {
    final exp = policy.expirationDate;
    if (exp == null) return false;
    return exp.difference(DateTime.now()).inDays <= 30 &&
        exp.isAfter(DateTime.now());
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      final m = amount / 1000000;
      return '\$${m % 1 == 0 ? m.toInt() : m.toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      final k = amount / 1000;
      return '\$${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(1)}K';
    }
    return '\$${amount.toInt()}';
  }

  String _formatDate(DateTime dt) =>
      '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}/${dt.year}';

  Future<void> _callPhone(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
    if (!context.mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    final expiringSoon = _isExpiringSoon;
    final borderColor =
        expiringSoon ? AuroraColors.yellowDeep : AuroraColors.inkBorder;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AuroraColors.paper,
          borderRadius: AuroraRadius.md,
          border: Border.all(color: borderColor, width: expiringSoon ? 1.5 : 1),
        ),
        padding: const EdgeInsets.all(AuroraSpacing.space7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AuroraColors.ink.withValues(alpha: 0.08),
                    borderRadius: AuroraRadius.sm,
                  ),
                  child: Icon(
                    _iconFor(policy.policyType),
                    size: 24,
                    color: AuroraColors.ink,
                  ),
                ),
                const SizedBox(width: AuroraSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${policy.policyType.policyTypeLabel} · ${policy.carrier}',
                        style: AuroraType.body.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (policy.policyNumber != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Policy #${policy.policyNumber}',
                          style: AuroraType.bodySm.copyWith(
                            color: AuroraColors.inkSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AuroraSpacing.space1),
                const Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: AuroraColors.inkSecondary,
                ),
              ],
            ),

            // ── Coverage / Deductible / Premium ─────────────────────────────
            if (policy.coverageAmount != null ||
                policy.deductible != null ||
                policy.premiumAnnual != null) ...[
              const SizedBox(height: AuroraSpacing.space3),
              Row(
                children: [
                  if (policy.coverageAmount != null)
                    _MetricChip(
                      label: 'Coverage',
                      value: _formatCurrency(policy.coverageAmount!),
                    ),
                  if (policy.deductible != null) ...[
                    const SizedBox(width: AuroraSpacing.space3),
                    _MetricChip(
                      label: 'Deductible',
                      value: _formatCurrency(policy.deductible!),
                    ),
                  ],
                  if (policy.premiumAnnual != null) ...[
                    const SizedBox(width: AuroraSpacing.space3),
                    _MetricChip(
                      label: 'Premium/yr',
                      value: _formatCurrency(policy.premiumAnnual!),
                    ),
                  ],
                ],
              ),
            ],

            // ── Expiration date ──────────────────────────────────────────────
            if (policy.expirationDate != null) ...[
              const SizedBox(height: AuroraSpacing.space3),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 12,
                    color: expiringSoon
                        ? AuroraColors.yellowDeep
                        : AuroraColors.inkSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Expires ${_formatDate(policy.expirationDate!)}',
                    style: AuroraType.bodySm.copyWith(
                      color: expiringSoon
                          ? AuroraColors.yellowDeep
                          : AuroraColors.inkSecondary,
                    ),
                  ),
                  if (expiringSoon) ...[
                    const SizedBox(width: AuroraSpacing.space1),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AuroraColors.yellowDim,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        'Expiring soon',
                        style: AuroraType.bodySm.copyWith(
                          fontSize: 10,
                          color: AuroraColors.yellowDeep,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],

            // ── Call buttons ─────────────────────────────────────────────────
            if (policy.claimsPhone != null || policy.agentPhone != null) ...[
              const SizedBox(height: AuroraSpacing.space3),
              const Divider(height: 1, color: AuroraColors.inkBorder),
              const SizedBox(height: AuroraSpacing.space3),
              Row(
                children: [
                  if (policy.claimsPhone != null)
                    _CallButton(
                      label: 'Claims',
                      phone: policy.claimsPhone!,
                      onTap: () => _callPhone(context, policy.claimsPhone!),
                    ),
                  if (policy.claimsPhone != null && policy.agentPhone != null)
                    const SizedBox(width: AuroraSpacing.space3),
                  if (policy.agentPhone != null)
                    _CallButton(
                      label: 'Agent',
                      phone: policy.agentPhone!,
                      onTap: () => _callPhone(context, policy.agentPhone!),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Private helpers ────────────────────────────────────────────────────────────

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AuroraColors.butter,
        borderRadius: AuroraRadius.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AuroraType.bodySm.copyWith(
              color: AuroraColors.inkSecondary,
            ),
          ),
          Text(
            value,
            style: AuroraType.bodySm.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AuroraColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.label,
    required this.phone,
    required this.onTap,
  });

  final String label;
  final String phone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.phone_outlined,
            size: 14,
            color: AuroraColors.ink,
          ),
          const SizedBox(width: 4),
          Text(
            '$label: $phone',
            style: AuroraType.bodySm.copyWith(
              color: AuroraColors.ink,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
