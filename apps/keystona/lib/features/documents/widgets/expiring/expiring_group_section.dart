import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../models/expiring_document.dart';
import '../../models/expiring_groups.dart';
import '../shared/docs_section_header.dart';
import 'expiring_document_card.dart';

/// One urgency band: colored title, item count, and its cards.
class ExpiringGroupSection extends StatelessWidget {
  const ExpiringGroupSection({
    super.key,
    required this.group,
    required this.onOpen,
    required this.onRenew,
  });

  final ExpiringGroup group;
  final ValueChanged<ExpiringDocument> onOpen;
  final ValueChanged<ExpiringDocument> onRenew;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final count = group.documents.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DocsSectionHeader(
          title: group.band.title,
          bold: true,
          color: switch (group.band) {
            ExpiringBand.next30 => AuroraColors.coralDeep,
            ExpiringBand.next90 => AuroraColors.amberDeep,
            ExpiringBand.later => AuroraColors.inkSecondary,
          },
          trailing: Text(
            '$count ${count == 1 ? 'ITEM' : 'ITEMS'}',
            textAlign: TextAlign.right,
            style: AuroraType.meta,
          ),
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        for (var i = 0; i < count; i++) ...[
          if (i > 0) SizedBox(height: a.of(AuroraSpacing.space3)),
          ExpiringDocumentCard(
            document: group.documents[i],
            onOpen: () => onOpen(group.documents[i]),
            onRenew: () => onRenew(group.documents[i]),
          ),
        ],
      ],
    );
  }
}
