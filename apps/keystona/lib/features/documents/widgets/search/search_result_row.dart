import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_c.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../models/document_format.dart';
import '../../models/document_search_hit.dart';
import '../../models/search_highlight.dart';
import 'highlighted_text.dart';
import 'search_status_chip.dart';

/// One search result: page icon, name with the match underlined, category and
/// date, the matched snippet (Premium), and an end-date chip.
class SearchResultRow extends StatelessWidget {
  const SearchResultRow({
    super.key,
    required this.hit,
    required this.query,
    required this.onTap,
  });

  final DocumentSearchHit hit;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final snippet = hit.snippet;
    final expiration = hit.expirationDate;
    final meta = [
      if (hit.categoryName.isNotEmpty) hit.categoryName.toUpperCase(),
      DocumentFormat.shortDateUpper(hit.addedAt),
    ].join(' · ');

    return AuroraPressable(
      onTap: onTap,
      semanticLabel: hit.name,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraDocsCSizes.resultRowMinHeight),
        ),
        child: Padding(
          padding: a.symmetric(
            horizontal: AuroraSpacing.space6,
            vertical: AuroraSpacing.space5,
          ),
          child: Row(
            children: [
              Container(
                width: a.of(AuroraDocsCSizes.resultThumbWidth),
                height: a.of(AuroraDocsCSizes.resultThumbHeight),
                decoration: BoxDecoration(
                  borderRadius: AuroraRadius.sm,
                  border: Border.all(
                    color: AuroraColors.inkTileBorder,
                    width: AuroraBorders.regular,
                  ),
                ),
                child: ExcludeSemantics(
                  child: Icon(
                    Icons.insert_drive_file_outlined,
                    size: a.of(AuroraIconSizes.md),
                    color: AuroraColors.inkSubtle,
                  ),
                ),
              ),
              SizedBox(width: a.of(AuroraSpacing.space5)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HighlightedText(
                      spans: SearchHighlight.name(hit.name, query),
                      maxLines: 2,
                      style: AuroraType.rowTitle.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: a.of(AuroraSpacing.space1)),
                    Text(meta, style: AuroraType.meta),
                    if (snippet != null) ...[
                      SizedBox(height: a.of(AuroraSpacing.space1)),
                      HighlightedText(
                        spans: SearchHighlight.snippet(snippet),
                        maxLines: 2,
                        underline: false,
                        style: AuroraType.bodySm.copyWith(
                          color: AuroraColors.inkBody,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (expiration != null) ...[
                SizedBox(width: a.of(AuroraSpacing.space3)),
                SearchStatusChip(expirationDate: expiration),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
