import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../models/document.dart';
import '../../models/document_format.dart';
import '../shared/docs_section_header.dart';
import 'detail_fact_card.dart';
import 'document_claim_card.dart';

/// "What it says": the details held on the document, plus a one-tap claim
/// call when the document names a claims line.
class DocumentFactsSection extends StatelessWidget {
  const DocumentFactsSection({
    super.key,
    required this.document,
    required this.onClaim,
  });

  final Document document;

  /// Called with the claims phone number.
  final ValueChanged<String> onClaim;

  /// Metadata keys that describe the claims line rather than a fact row.
  static const String claimPhoneKey = 'claim_phone';
  static const String claimProviderKey = 'claim_provider';
  static const String claimPageKey = 'claim_page';
  static const String tagsKey = 'tags';
  static const Set<String> _claimKeys = {
    claimPhoneKey,
    claimProviderKey,
    claimPageKey,
    // Tags are shown as chips under Notes, not as a fact row.
    tagsKey,
  };

  /// Facts to list, skipping empty values and the claim keys.
  static List<DetailFact> factsOf(Document document) => [
        for (final entry in document.metadata.entries)
          if (!_claimKeys.contains(entry.key) &&
              entry.value != null &&
              entry.value.toString().trim().isNotEmpty)
            DetailFact(
              DocumentFormat.humanizeKey(entry.key),
              entry.value.toString(),
            ),
      ];

  /// "NORTHLINE · 1-800-555-0142 · FROM PAGE 3", or null with no phone.
  static String? claimDetail(Document document) {
    final phone = document.metadata[claimPhoneKey];
    if (phone is! String || phone.trim().isEmpty) return null;
    final provider = document.metadata[claimProviderKey];
    final page = document.metadata[claimPageKey];
    return [
      if (provider is String && provider.trim().isNotEmpty)
        provider.trim().toUpperCase(),
      phone.trim(),
      if (page != null) 'FROM PAGE $page',
    ].join(' · ');
  }

  /// True when this section has anything to show.
  static bool hasContent(Document document) =>
      factsOf(document).isNotEmpty || claimDetail(document) != null;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final facts = factsOf(document);
    final claim = claimDetail(document);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DocsSectionHeader(
          title: 'What it says',
          trailing: document.ocrStatus == 'complete'
              ? const _SmartScanTag()
              : null,
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        if (facts.isNotEmpty) DetailFactCard(facts: facts),
        if (claim != null) ...[
          if (facts.isNotEmpty) SizedBox(height: a.of(AuroraSpacing.space3)),
          DocumentClaimCard(
            detail: claim,
            onTap: () => onClaim(
              (document.metadata[claimPhoneKey] as String).trim(),
            ),
          ),
        ],
      ],
    );
  }
}

class _SmartScanTag extends StatelessWidget {
  const _SmartScanTag();

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.document_scanner_outlined,
          size: a.of(AuroraIconSizes.xs),
          color: AuroraColors.cobalt,
        ),
        SizedBox(width: a.of(AuroraSpacing.space1)),
        Flexible(
          child: Text(
            'READ BY SMART SCAN',
            textAlign: TextAlign.right,
            style: AuroraType.label.copyWith(
              color: AuroraColors.cobalt,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
