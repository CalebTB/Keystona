import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/aurora_docs_c.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/error_view.dart';
import '../../models/document_search_hit.dart';
import '../docs_scroll_page.dart';
import 'search_no_results.dart';
import 'search_premium_gate.dart';
import 'search_result_list.dart';
import 'search_skeleton.dart';

/// The results area: skeleton while loading, retry on error, results or the
/// "no match" message, and the Premium gate beneath for free accounts.
class SearchResultsBody extends StatelessWidget {
  const SearchResultsBody({
    super.key,
    required this.results,
    required this.pending,
    required this.query,
    required this.categoryName,
    required this.isPremium,
    required this.onOpen,
    required this.onUpgrade,
    required this.onRetry,
  });

  final AsyncValue<List<DocumentSearchHit>> results;

  /// True while typing has not settled (debounce) so results would be stale.
  final bool pending;

  /// Settled search text. Empty when only a category is chosen.
  final String query;
  final String? categoryName;
  final bool isPremium;
  final ValueChanged<DocumentSearchHit> onOpen;
  final VoidCallback onUpgrade;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (results.hasError && !pending && !results.isLoading) {
      return ErrorView(
        message: "Couldn't search your documents.",
        onRetry: onRetry,
      );
    }

    final a = context.aurora;
    final hits = results.value;
    final loading = pending || (results.isLoading && hits == null);

    return DocsScrollPage(
      onRefresh: onRetry,
      topPadding: AuroraSpacing.space3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (loading)
            const SearchSkeleton()
          else if (hits == null || hits.isEmpty)
            SearchNoResults(query: query, fullText: isPremium)
          else
            SearchResultList(
              hits: hits,
              query: query,
              categoryName: categoryName,
              onOpen: onOpen,
            ),
          if (query.isNotEmpty && !isPremium) ...[
            SizedBox(height: a.of(AuroraDocsCSizes.searchSectionGap)),
            SearchPremiumGate(query: query, onTap: onUpgrade),
          ],
        ],
      ),
    );
  }
}
