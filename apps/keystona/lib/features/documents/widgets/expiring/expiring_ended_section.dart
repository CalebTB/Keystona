import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_c.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../docs_copy.dart';
import '../../models/expiring_document.dart';
import '../shared/docs_section_header.dart';

/// "Already ended": documents past their end date, muted, kept for the record.
class ExpiringEndedSection extends StatelessWidget {
  const ExpiringEndedSection({
    super.key,
    required this.documents,
    required this.onOpen,
  });

  final List<ExpiringDocument> documents;
  final ValueChanged<ExpiringDocument> onOpen;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DocsSectionHeader(title: 'Already ended · ${documents.length}'),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AuroraRadius.xl,
            border: Border.all(
              color: AuroraColors.inkBorder,
              width: AuroraBorders.regular,
            ),
          ),
          child: ClipRRect(
            borderRadius: AuroraRadius.xl,
            child: Column(
              children: [
                for (var i = 0; i < documents.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: AuroraBorders.hairline,
                      thickness: AuroraBorders.hairline,
                      color: AuroraColors.inkBorder,
                    ),
                  _EndedRow(
                    document: documents[i],
                    onTap: () => onOpen(documents[i]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EndedRow extends StatelessWidget {
  const _EndedRow({required this.document, required this.onTap});

  final ExpiringDocument document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel:
          '${document.name}, ${document.isReplaced ? 'replaced' : 'ended'}',
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraDocsCSizes.endedRowMinHeight),
        ),
        child: Padding(
          padding: a.symmetric(
            horizontal: AuroraSpacing.space6,
            vertical: AuroraSpacing.space4,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.name,
                      style: AuroraType.rowTitle.copyWith(
                        color: AuroraColors.inkSecondary,
                      ),
                    ),
                    SizedBox(height: a.of(AuroraSpacing.space1)),
                    Text(
                      DocsCopy.endedMeta(
                        endedOn: document.expirationDate,
                        replacedAt: document.replacedAt,
                      ),
                      style: AuroraType.meta,
                    ),
                  ],
                ),
              ),
              SizedBox(width: a.of(AuroraSpacing.space3)),
              Icon(
                CupertinoIcons.chevron_right,
                size: a.of(AuroraIconSizes.sm),
                color: AuroraColors.inkPlaceholder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
