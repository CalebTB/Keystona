import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../models/project.dart';
import '../../../models/project_contractor.dart';

// ── Helpers ────────────────────────────────────────────────────────────────────

String _fmtAmount(double v) =>
    '\$${NumberFormat('#,###').format(v.round())}';

String _fmtDate(DateTime d) => DateFormat('MMM d, yyyy').format(d);

String _fmtPhone(String phone) {
  final d = phone.replaceAll(RegExp(r'\D'), '');
  if (d.length == 10) {
    return '(${d.substring(0, 3)}) ${d.substring(3, 6)}-${d.substring(6)}';
  }
  if (d.length == 11 && d.startsWith('1')) {
    return '+1 (${d.substring(1, 4)}) ${d.substring(4, 7)}-${d.substring(7)}';
  }
  return phone;
}

// ── Contractor Story Card ──────────────────────────────────────────────────────

class ContractorStoryCard extends StatelessWidget {
  const ContractorStoryCard({
    super.key,
    required this.contractor,
    required this.project,
    required this.isLead,
    required this.reviewerName,
    required this.onEdit,
    required this.onDocs,
  });

  final ProjectContractor contractor;
  final Project project;
  final bool isLead;
  final String reviewerName;
  final VoidCallback onEdit;
  final VoidCallback onDocs;

  String get _initials {
    final parts = contractor.contactName.trim().split(RegExp(r'\s+')).take(2);
    return parts.map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
  }

  Future<void> _call() async {
    final phone = contractor.contactPhone;
    if (phone == null) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _sms() async {
    final phone = contractor.contactPhone;
    if (phone == null) return;
    final uri = Uri(scheme: 'sms', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.contractorCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.contractorCardBorder, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Dark top section: avatar, name, quote (tap to edit) ──────
            GestureDetector(
              onTap: onEdit,
              child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopRow(initials: _initials, isLead: isLead),
                  const SizedBox(height: 12),
                  Text(
                    contractor.contactName,
                    style: GoogleFonts.fraunces(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textInverse,
                      height: 1.05,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _Subtitle(contractor: contractor),
                  const SizedBox(height: 16),
                  _QuoteBlock(
                    contractor: contractor,
                    reviewerName: reviewerName,
                  ),
                ],
              ),
            ),
            ), // GestureDetector

            // ── White bottom section: stats, projects, buttons ────────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StatsGrid(contractor: contractor),
                            const SizedBox(height: 16),
                            _ProjectsSection(
                              project: project,
                              contractor: contractor,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    _ActionBar(
                      hasPhone: contractor.contactPhone != null,
                      onCall: _call,
                      onSms: _sms,
                      onDocs: onDocs,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top row: avatar (left) + LEAD badge (right) ────────────────────────────────

class _TopRow extends StatelessWidget {
  const _TopRow({required this.initials, required this.isLead});

  final String initials;
  final bool isLead;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: AppColors.contractorAvatarBg,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials.isEmpty ? '?' : initials,
            style: GoogleFonts.fraunces(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textInverse,
              height: 1,
            ),
          ),
        ),
        const Spacer(),
        if (isLead)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.contractorLeadBg,
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text(
              'LEAD',
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: AppColors.contractorCardBg,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Subtitle: company · role ───────────────────────────────────────────────────

class _Subtitle extends StatelessWidget {
  const _Subtitle({required this.contractor});

  final ProjectContractor contractor;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    final company = contractor.contactCompany;
    if (company != null && company.isNotEmpty) parts.add(company.toUpperCase());
    final role = contractor.role;
    if (role != null) parts.add(ContractorRoles.labelFor(role).toUpperCase());
    if (parts.isEmpty) return const SizedBox.shrink();

    return Text(
      parts.join(' · '),
      style: const TextStyle(
        fontFamily: 'IBMPlexMono',
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: AppColors.contractorMuted,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ── Quote block ────────────────────────────────────────────────────────────────

class _QuoteBlock extends StatelessWidget {
  const _QuoteBlock({required this.contractor, required this.reviewerName});

  final ProjectContractor contractor;
  final String reviewerName;

  @override
  Widget build(BuildContext context) {
    final notes = contractor.reviewNotes;
    final hasNotes = notes != null && notes.trim().isNotEmpty;

    if (!hasNotes) {
      return Text(
        'No review yet',
        style: GoogleFonts.inter(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: AppColors.textInverse.withValues(alpha: 0.35),
        ),
      );
    }

    final attribution =
        '${reviewerName.isNotEmpty ? reviewerName.toUpperCase() : 'YOU'} · '
        '${_fmtDate(contractor.createdAt).toUpperCase()}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '"${notes.trim()}"',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
            color: AppColors.textInverse.withValues(alpha: 0.8),
            height: 1.5,
          ),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          attribution,
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: AppColors.textInverse.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

// ── Stats 2×2 grid ─────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.contractor});

  final ProjectContractor contractor;

  @override
  Widget build(BuildContext context) {
    final rating = contractor.rating ?? 0;
    final paid   = contractor.amountPaid ?? 0.0;
    final phone  = contractor.contactPhone;

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _RatingCell(rating: rating)),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCell(label: 'TOTAL PAID', value: _fmtAmount(paid)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(child: _StatCell(label: 'PROJECTS', value: '1')),
              const SizedBox(width: 8),
              Expanded(child: _PhoneCell(phone: phone)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      constraints: const BoxConstraints(minHeight: 72),
      decoration: BoxDecoration(
        color: AppColors.warmInset,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderStrong, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.contractorStatLabel,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingCell extends StatelessWidget {
  const _RatingCell({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      constraints: const BoxConstraints(minHeight: 72),
      decoration: BoxDecoration(
        color: AppColors.warmInset,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderStrong, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'RATING',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.contractorStatLabel,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 15,
                color: AppColors.goldAccent,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PhoneCell extends StatelessWidget {
  const _PhoneCell({required this.phone});

  final String? phone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      constraints: const BoxConstraints(minHeight: 72),
      decoration: BoxDecoration(
        color: AppColors.warmInset,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderStrong, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'PHONE',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.contractorStatLabel,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            phone != null ? _fmtPhone(phone!) : '—',
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Projects Together ──────────────────────────────────────────────────────────

class _ProjectsSection extends StatelessWidget {
  const _ProjectsSection({required this.project, required this.contractor});

  final Project project;
  final ProjectContractor contractor;

  @override
  Widget build(BuildContext context) {
    final isActive =
        project.status == 'in_progress' || project.status == 'planning';
    final dotColor = isActive ? AppColors.accent : AppColors.gray400;
    final contractAmt = contractor.contractAmount ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.gray400,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'PROJECTS TOGETHER',
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${project.status.statusLabel} · '
                    '${project.projectType.projectTypeLabel}',
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 10,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _fmtAmount(contractAmt),
              style: const TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Action bar — solid filled dark green buttons ───────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.hasPhone,
    required this.onCall,
    required this.onSms,
    required this.onDocs,
  });

  final bool hasPhone;
  final VoidCallback onCall;
  final VoidCallback onSms;
  final VoidCallback onDocs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Row(
        children: [
          Expanded(
            child: _PillButton(
              icon: Icons.phone_outlined,
              label: 'Call',
              enabled: hasPhone,
              onTap: onCall,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PillButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Message',
              enabled: hasPhone,
              onTap: onSms,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PillButton(
              icon: Icons.description_outlined,
              label: 'Docs',
              enabled: true,
              onTap: onDocs,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = enabled
        ? AppColors.contractorCardBg
        : AppColors.contractorCardBg.withValues(alpha: 0.35);
    final fg = enabled
        ? AppColors.textInverse
        : AppColors.textInverse.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
