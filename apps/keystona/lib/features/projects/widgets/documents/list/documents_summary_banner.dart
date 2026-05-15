import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../models/project_document_link.dart';

/// Dark deepNavy summary banner for the documents vault list.
///
/// Shows total linked count, unique type count, PDF count, and expiring count.
/// Tapping the expiring stat toggles [onExpiringToggle].
class DocumentsSummaryBanner extends StatelessWidget {
  const DocumentsSummaryBanner({
    super.key,
    required this.links,
    required this.showExpiringOnly,
    required this.onExpiringToggle,
  });

  final List<ProjectDocumentLink> links;
  final bool showExpiringOnly;
  final VoidCallback onExpiringToggle;

  @override
  Widget build(BuildContext context) {
    final total = links.length;

    // Unique link types present
    final typeCount = links.map((l) => l.linkType).toSet().length;

    // PDF count
    final pdfCount =
        links.where((l) => (l.documentTypeName ?? '').toLowerCase() == 'pdf' ||
                _isPdf(l)).length;

    // Expiring within 90 days
    // note: current model has no expirationDate field — always 0.
    // Implement when model gains expirationDate.
    final expiringCount = 0;

    final subLabel = typeCount == 1
        ? 'all ${links.first.linkType}s'
        : 'across $typeCount link types';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.deepNavy,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: count + sub
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LINKED DOCUMENTS',
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Color(0x80FFFFFF),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$total',
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
              Text(
                subLabel,
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 10,
                  color: Color(0x8CFFFFFF),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Right: PDFs + Expiring
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _MiniStat(
                value: '$pdfCount',
                label: 'PDFS',
                valueColor: Colors.white,
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: onExpiringToggle,
                child: _MiniStat(
                  value: '$expiringCount',
                  label: 'EXPIRING',
                  valueColor: expiringCount > 0
                      ? const Color(0xFFC49A48)
                      : Colors.white,
                  isActive: showExpiringOnly,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static bool _isPdf(ProjectDocumentLink l) {
    return l.documentTypeName?.toLowerCase().contains('pdf') ?? false;
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
    required this.valueColor,
    this.isActive = false,
  });

  final String value;
  final String label;
  final Color valueColor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: isActive
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 4)
          : null,
      decoration: isActive
          ? BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Color(0x73FFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}
