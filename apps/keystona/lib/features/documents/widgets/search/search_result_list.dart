import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../models/document_search_hit.dart';
import '../shared/docs_section_header.dart';
import 'search_result_row.dart';

/// "2 RESULTS IN WARRANTIES" and the results as one bordered list.
class SearchResultList extends StatelessWidget {
  const SearchResultList({
    super.key,
    required this.hits,
    required this.query,
    required this.onOpen,
    this.categoryName,
  });

  final List<DocumentSearchHit> hits;
  final String query;
  final ValueChanged<DocumentSearchHit> onOpen;

  /// Category the search is scoped to, shown after "IN".
  final String? categoryName;

  /// "2 RESULTS IN WARRANTIES", "1 RESULT".
  static String label(int count, String? categoryName) {
    final base = '$count ${count == 1 ? 'RESULT' : 'RESULTS'}';
    return categoryName == null ? base : '$base IN ${categoryName.toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DocsSectionHeader(title: label(hits.length, categoryName)),
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
                for (var i = 0; i < hits.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: AuroraBorders.hairline,
                      thickness: AuroraBorders.hairline,
                      color: AuroraColors.inkBorder,
                    ),
                  SearchResultRow(
                    hit: hits[i],
                    query: query,
                    onTap: () => onOpen(hits[i]),
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
