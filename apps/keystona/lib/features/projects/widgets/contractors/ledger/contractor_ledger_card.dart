import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../models/project_contractor.dart';
import '../shared/contractor_avatar.dart';
import '../shared/contractor_role_palette.dart';

/// Full-detail contractor card used inside [ContractorsLedgerView].
///
/// Sections:
///   1. Top row — avatar, name/role, action buttons (call)
///   2. Contract progress bar
///   3. Foot stats pills (phases deferred, receipts deferred, owed/rate)
class ContractorLedgerCard extends StatelessWidget {
  const ContractorLedgerCard({
    super.key,
    required this.contractor,
    required this.isProjectOnHold,
    required this.onEdit,
    required this.onCall,
  });

  final ProjectContractor contractor;

  /// True when the parent project status is 'on_hold'.
  /// Used to colour-flag outstanding amounts.
  final bool isProjectOnHold;

  final VoidCallback onEdit;
  final VoidCallback? onCall;

  // ── Money helpers ────────────────────────────────────────────────────────────

  double get _paid => contractor.amountPaid ?? 0.0;
  double get _contract => contractor.contractAmount ?? 0.0;
  double get _owed => (_contract - _paid).clamp(0.0, double.infinity);

  bool get _hasContract => _contract > 0;
  bool get _isPaidInFull => _hasContract && _paid >= _contract;
  bool get _isPayingDown => _hasContract && _paid < _contract;

  String _fmtCompact(double v) {
    if (v >= 10000) return '\$${(v / 1000).toStringAsFixed(0)}k';
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}k';
    return '\$${v.toStringAsFixed(0)}';
  }

  // ── Role label ───────────────────────────────────────────────────────────────

  String get _roleLabel {
    final r = contractor.role;
    if (r == null || r.isEmpty) return '';
    return switch (r) {
      'general_contractor' => 'General Contractor',
      'plumber'            => 'Plumber',
      'electrician'        => 'Electrician',
      'hvac'               => 'HVAC',
      'painter'            => 'Painter',
      'landscaper'         => 'Landscaper',
      'roofer'             => 'Roofer',
      'flooring'           => 'Flooring',
      'tiler'              => 'Tiler',
      'carpenter'          => 'Carpenter',
      'designer'           => 'Designer',
      'architect'          => 'Architect',
      _                    => r,
    };
  }

  @override
  Widget build(BuildContext context) {
    final roleColor =
        contractorRoleColor(contractor.role);
    final hasPhone = contractor.contactPhone != null &&
        contractor.contactPhone!.isNotEmpty;

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.cardMinHeight),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSizes.md, AppSizes.md, AppSizes.md, AppSizes.sm + 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopRow(
              contractor: contractor,
              roleColor: roleColor,
              roleLabel: _roleLabel,
              hasPhone: hasPhone,
              onCall: onCall,
            ),
            const SizedBox(height: AppSizes.sm + 2),
            _ContractProgress(
              paid: _paid,
              contract: _contract,
              hasContract: _hasContract,
              isPaidInFull: _isPaidInFull,
              isPayingDown: _isPayingDown,
              fmtCompact: _fmtCompact,
            ),
            const SizedBox(height: AppSizes.sm + 2),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSizes.sm + 2),
            _FootPills(
              owed: _owed,
              isPaidInFull: _isPaidInFull,
              isProjectOnHold: isProjectOnHold,
              rated: contractor.rating != null,
              fmtCompact: _fmtCompact,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top row ───────────────────────────────────────────────────────────────────

class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.contractor,
    required this.roleColor,
    required this.roleLabel,
    required this.hasPhone,
    required this.onCall,
  });

  final ProjectContractor contractor;
  final Color roleColor;
  final String roleLabel;
  final bool hasPhone;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ContractorAvatar(
          name: contractor.contactName,
          roleColor: roleColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contractor.contactName,
                style: GoogleFonts.fraunces(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              _RoleLine(
                roleLabel: roleLabel,
                rating: contractor.rating,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        // Call button.
        Opacity(
          opacity: hasPhone ? 1.0 : 0.4,
          child: GestureDetector(
            onTap: hasPhone ? onCall : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.phone_outlined,
                size: 16,
                color: AppColors.success,
              ),
            ),
          ),
        ),
        // note: Docs button deferred — needs contractor-document filter integration
      ],
    );
  }
}

// ── Role + stars line ─────────────────────────────────────────────────────────

class _RoleLine extends StatelessWidget {
  const _RoleLine({required this.roleLabel, required this.rating});

  final String roleLabel;
  final int? rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (roleLabel.isNotEmpty) ...[
          Text(
            roleLabel.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: AppColors.textSecondary,
            ),
          ),
          if (rating != null) const SizedBox(width: AppSizes.sm),
        ],
        if (rating != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (i) => Icon(
                i < rating! ? Icons.star : Icons.star_border,
                size: 11,
                color: AppColors.goldAccent,
              ),
            ),
          )
        else
          Text(
            'Not rated',
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

// ── Contract progress ─────────────────────────────────────────────────────────

class _ContractProgress extends StatelessWidget {
  const _ContractProgress({
    required this.paid,
    required this.contract,
    required this.hasContract,
    required this.isPaidInFull,
    required this.isPayingDown,
    required this.fmtCompact,
  });

  final double paid;
  final double contract;
  final bool hasContract;
  final bool isPaidInFull;
  final bool isPayingDown;
  final String Function(double) fmtCompact;

  @override
  Widget build(BuildContext context) {
    if (!hasContract) {
      // Emergency contact — no contract data.
      return const _NoContractRow();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isPaidInFull ? 'PAID IN FULL' : 'CONTRACT',
              style: const TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
            if (isPayingDown)
              Text(
                '${fmtCompact(paid)} of ${fmtCompact(contract)}',
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              )
            else if (isPaidInFull)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${fmtCompact(paid)}  ✓',
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 5),
        // Progress bar.
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: contract > 0
                ? (paid / contract).clamp(0.0, 1.0)
                : 0.0,
            minHeight: 6,
            backgroundColor: AppColors.gray200,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _NoContractRow extends StatelessWidget {
  const _NoContractRow();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Emergency contact',
      style: TextStyle(
        fontFamily: 'IBMPlexMono',
        fontSize: 11,
        fontStyle: FontStyle.italic,
        color: AppColors.textSecondary,
      ),
    );
  }
}

// ── Foot pills ────────────────────────────────────────────────────────────────

class _FootPills extends StatelessWidget {
  const _FootPills({
    required this.owed,
    required this.isPaidInFull,
    required this.isProjectOnHold,
    required this.rated,
    required this.fmtCompact,
  });

  final double owed;
  final bool isPaidInFull;
  final bool isProjectOnHold;
  final bool rated;
  final String Function(double) fmtCompact;

  @override
  Widget build(BuildContext context) {
    // Phases pill — deferred (no phase assignment in schema yet)
    // Receipts pill — deferred (no per-contractor doc count yet)
    // Owed pill — active

    final owedLabel = rated ? 'Owed' : 'Rate';
    final owedValue = isPaidInFull
        ? '\$0'
        : owed > 0
            ? fmtCompact(owed)
            : '\$0';

    final owedColor = !rated
        ? AppColors.goldAccent
        : (isProjectOnHold && owed > 0)
            ? AppColors.error
            : AppColors.textPrimary;

    return Row(
      children: [
        Expanded(
          child: _Pill(
            value: '—',
            label: 'Phases',
            // note: Deferred — phase assignment not yet in schema
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _Pill(
            value: '—',
            label: 'Receipts',
            // note: Deferred — per-contractor doc count not yet integrated
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _Pill(
            value: owedValue,
            label: owedLabel,
            valueColor: owedColor,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.value,
    required this.label,
    this.valueColor = AppColors.textPrimary,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
