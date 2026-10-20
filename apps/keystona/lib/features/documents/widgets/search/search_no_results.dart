import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_c.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';

/// Nothing matched. Names the search and says what free search covers.
class SearchNoResults extends StatelessWidget {
  const SearchNoResults({super.key, required this.query, required this.fullText});

  final String query;

  /// True for Premium, whose search also reads inside files.
  final bool fullText;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Padding(
      padding: a.symmetric(
        horizontal: AuroraSpacing.space7,
        vertical: AuroraSpacing.space10,
      ),
      child: Column(
        children: [
          Text(
            query.isEmpty ? 'No documents here' : 'No documents match “$query”',
            textAlign: TextAlign.center,
            style: AuroraDocsCType.noResultsTitle,
          ),
          SizedBox(height: a.of(AuroraSpacing.space3)),
          Text(
            fullText
                ? 'Try a shorter word or clear the category.'
                : 'Free search checks document names and categories. '
                    'Try a shorter word or clear the category.',
            textAlign: TextAlign.center,
            style: AuroraType.body.copyWith(color: AuroraColors.inkSecondary),
          ),
        ],
      ),
    );
  }
}
