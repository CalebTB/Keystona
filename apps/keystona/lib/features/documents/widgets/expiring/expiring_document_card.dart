import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_button.dart';
import '../../../../core/widgets/aurora/aurora_chip.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../models/document_format.dart';
import '../../models/expiring_document.dart';
import '../../models/docs_expiry.dart';
import '../../models/expiry_labels.dart';
import '../../models/category_icons.dart';

/// An upcoming end date: icon, name, who issued it, days left and the date.
///
/// Inside 30 days the card is outlined in coral and offers "Upload renewal".
class ExpiringDocumentCard extends StatelessWidget {
  const ExpiringDocumentCard({
    super.key,
    required this.document,
    required this.onOpen,
    required this.onRenew,
  });

  final ExpiringDocument document;
  final VoidCallback onOpen;
  final VoidCallback onRenew;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final info = document.expiry();
    final urgent = info.tone == DocsExpiryTone.urgent;
    final tile = a.of(AuroraSharedSizes.iconTile);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.xl,
        border: Border.all(
          color: urgent ? AuroraColors.coral : AuroraColors.inkBorder,
          width: urgent ? AuroraBorders.emphasis : AuroraBorders.regular,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuroraPressable(
            onTap: onOpen,
            semanticLabel: '${document.name}, ${ExpiryLabels.chip(info.days)}',
            child: Padding(
              padding: a.symmetric(
                horizontal: AuroraSpacing.space6,
                vertical: AuroraSpacing.space5,
              ),
              child: Row(
                children: [
                  Container(
                    width: tile,
                    height: tile,
                    decoration: BoxDecoration(
                      borderRadius: AuroraRadius.tile,
                      border: Border.all(
                        color: AuroraColors.inkTileBorder,
                        width: AuroraBorders.regular,
                      ),
                    ),
                    child: ExcludeSemantics(
                      child: Icon(
                        CategoryIcons.forKey(document.categoryIcon),
                        size: a.of(AuroraIconSizes.md),
                        color: AuroraColors.ink,
                      ),
                    ),
                  ),
                  SizedBox(width: a.of(AuroraSpacing.space5)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(document.name, style: AuroraType.h3),
                        SizedBox(height: a.of(AuroraSpacing.space1)),
                        Text(document.subtitle, style: AuroraType.meta),
                      ],
                    ),
                  ),
                  SizedBox(width: a.of(AuroraSpacing.space3)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _chip(info),
                      SizedBox(height: a.of(AuroraSpacing.space1)),
                      Text(
                        DocumentFormat.shortDateUpper(document.expirationDate),
                        style: AuroraType.rowDate,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (urgent)
            Padding(
              padding: EdgeInsets.fromLTRB(
                a.of(AuroraSpacing.space6),
                0,
                a.of(AuroraSpacing.space6),
                a.of(AuroraSpacing.space5),
              ),
              child: PrimaryButton(
                label: 'Upload renewal',
                expand: true,
                onPressed: onRenew,
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(DocsExpiry info) {
    final label = ExpiryLabels.chip(info.days);
    return switch (info.tone) {
      DocsExpiryTone.urgent => StatusChip.overdue(label: label),
      DocsExpiryTone.soon => StatusChip.dueSoon(label: label),
      DocsExpiryTone.far => StatusChip.scheduled(label: label),
    };
  }
}
