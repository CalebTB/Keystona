import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_c.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../models/document.dart';
import '../../docs_copy.dart';
import '../../models/document_format.dart';
import '../../models/document_renewal.dart';
import '../../models/docs_expiry.dart';
import '../../models/expiry_labels.dart';

/// Category eyebrow with a status pill, the document name, and the file line.
class DocumentDetailHeader extends StatelessWidget {
  const DocumentDetailHeader({super.key, required this.document});

  final Document document;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final replacedAt = DocumentRenewal.replacedAt(document.metadata);
    final badge = replacedAt != null
        ? StatusBadge.neutral(DocsCopy.replacedChip(replacedAt))
        : _badge(document.expirationDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: a.of(AuroraSpacing.space2),
          runSpacing: a.of(AuroraSpacing.space1),
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (document.category != null)
              Text(
                document.category!.name.toUpperCase(),
                style: AuroraType.label.copyWith(fontWeight: FontWeight.w600),
              ),
            ?badge,
          ],
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        Semantics(
          header: true,
          child: Text(document.name, style: AuroraDocsCType.screenTitle),
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        Text(DocumentFormat.metaLine(document), style: AuroraType.meta),
      ],
    );
  }

  Widget? _badge(DateTime? expiration) {
    if (expiration == null) return null;
    final info = DocsExpiry.of(expiration);
    if (info.expired) return StatusBadge.overdue('Expired');
    return switch (info.tone) {
      DocsExpiryTone.urgent => StatusBadge.overdue(_left(info)),
      DocsExpiryTone.soon => StatusBadge.warning(_left(info)),
      DocsExpiryTone.far => const StatusBadge(
          label: 'Active',
          color: AuroraColors.olive,
          textColor: AuroraColors.olive,
          showCheck: true,
        ),
    };
  }

  String _left(DocsExpiry info) =>
      info.isToday ? 'Today' : '${ExpiryLabels.chip(info.days)} left';
}
