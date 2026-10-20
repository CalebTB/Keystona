import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_docs_c.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../docs_scroll_page.dart';
import 'search_recent_list.dart';
import 'search_suggestion_list.dart';

/// Nothing typed yet: the categories to search in, then recent searches.
class SearchStartBody extends StatelessWidget {
  const SearchStartBody({
    super.key,
    required this.suggestions,
    required this.recent,
    required this.onPickCategory,
    required this.onPickRecent,
    required this.onRefresh,
  });

  final List<SearchSuggestion> suggestions;
  final List<String> recent;
  final ValueChanged<SearchSuggestion> onPickCategory;
  final ValueChanged<String> onPickRecent;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return DocsScrollPage(
      onRefresh: onRefresh,
      topPadding: AuroraSpacing.space3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (suggestions.isNotEmpty)
            SearchSuggestionList(suggestions: suggestions, onPick: onPickCategory),
          if (suggestions.isNotEmpty && recent.isNotEmpty)
            SizedBox(height: a.of(AuroraDocsCSizes.searchSectionGap)),
          if (recent.isNotEmpty)
            SearchRecentList(searches: recent, onPick: onPickRecent),
        ],
      ),
    );
  }
}
