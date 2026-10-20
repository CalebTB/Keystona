import 'package:flutter/material.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_docs_a.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_sizes.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/aurora/aurora_pressable.dart';
import 'expiration_badge.dart';

/// One document: file tile, name, "CATEGORY · DATE", an optional expiry pill
/// and a chevron (kit: DocsSearchLed "Recently added").
///
/// Draws no border of its own, so it sits inside a bordered list or card.
class DocumentRow extends StatelessWidget {
  const DocumentRow({
    super.key,
    required this.name,
    required this.meta,
    required this.onTap,
    this.expirationDate,
  });

  final String name;

  /// Already formatted and upper-cased, e.g. "MAINTENANCE · OCT 2".
  final String meta;
  final DateTime? expirationDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: name,
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraDocsA.rowMinHeight),
        ),
        padding: a.symmetric(
          horizontal: AuroraSpacing.space6,
          vertical: AuroraSpacing.space5,
        ),
        child: Row(
          children: [
            const _FileTile(),
            SizedBox(width: a.of(AuroraSpacing.space5)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AuroraType.rowTitle,
                  ),
                  SizedBox(height: a.of(AuroraDocsA.hairlineGap)),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AuroraType.meta,
                  ),
                ],
              ),
            ),
            if (expirationDate != null) ...[
              SizedBox(width: a.of(AuroraSpacing.space3)),
              ExpirationBadge(expirationDate: expirationDate!),
            ],
            SizedBox(width: a.of(AuroraSpacing.space3)),
            Icon(
              Icons.chevron_right,
              size: a.of(AuroraIconSizes.sm),
              color: AuroraColors.inkCheckBorder,
            ),
          ],
        ),
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile();

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      width: a.of(AuroraDocsA.docThumbWidth),
      height: a.of(AuroraDocsA.docThumbHeight),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.sm,
        border: Border.all(
          color: AuroraColors.inkTileBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Icon(
        Icons.description_outlined,
        size: a.of(AuroraDocsA.docThumbGlyph),
        color: AuroraColors.inkSubtle,
      ),
    );
  }
}
