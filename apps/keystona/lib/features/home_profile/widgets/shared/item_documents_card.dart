import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_shared.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import 'item_document_row.dart';
import 'item_row_group.dart';

/// The DOCUMENTS card: a file icon, the title and a meta line, and a chevron.
/// [onTap] gets the tapped document's id.
class ItemDocumentsCard extends StatelessWidget {
  const ItemDocumentsCard({super.key, required this.rows, required this.onTap});

  final List<ItemDocumentRow> rows;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return ItemRowGroup(
      children: [
        for (final row in rows)
          AuroraPressable(
            onTap: () => onTap(row.id),
            semanticLabel: '${row.title}, ${row.meta}',
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: a.of(AuroraHomeSizes.docRowMin),
              ),
              child: Padding(
                padding: a.symmetric(
                  horizontal: AuroraSpacing.space6,
                  vertical: AuroraSpacing.space4,
                ),
                child: Row(
                  children: [
                    Container(
                      width: a.of(AuroraHomeSizes.docTile),
                      height: a.of(AuroraHomeSizes.docTile),
                      decoration: BoxDecoration(
                        borderRadius: AuroraRadius.tile,
                        border: Border.all(
                          color: AuroraColors.inkTileBorder,
                          width: AuroraBorders.regular,
                        ),
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        size: a.of(AuroraHomeSizes.docTileGlyph),
                        color: AuroraColors.ink,
                      ),
                    ),
                    SizedBox(width: a.of(AuroraSpacing.space5)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.title,
                            style: AuroraHomeType.entryTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: a.of(AuroraSpacing.space1)),
                          Text(
                            row.meta.toUpperCase(),
                            style: AuroraType.meta,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: a.of(AuroraSpacing.space3)),
                    Icon(
                      Icons.chevron_right,
                      size: a.of(AuroraIconSizes.md),
                      color: AuroraColors.inkTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
