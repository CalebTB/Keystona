import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_motion.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/upgrade_sheet.dart';
import '../../../services/providers/service_providers.dart';
import '../models/document_search_hit.dart';
import '../providers/document_categories_provider.dart';
import '../providers/document_search_provider.dart';
import '../providers/documents_provider.dart';
import '../providers/recent_searches_provider.dart';
import '../widgets/search/search_field_bar.dart';
import '../widgets/search/search_results_body.dart';
import '../widgets/search/search_skeleton.dart';
import '../widgets/search/search_start_body.dart';
import '../widgets/search/search_suggestion_list.dart';
import '../widgets/docs_scroll_page.dart';

/// Search the vault: categories and recent searches to start from, then
/// results as you type (debounced) with the matched part underlined.
///
/// Covers kit screens Search (3.2) and SearchResults (3.3); they are the same
/// screen at two moments. Route: `/documents/search`.
class DocumentSearchScreen extends ConsumerStatefulWidget {
  const DocumentSearchScreen({
    super.key,
    this.initialQuery = '',
    this.initialCategoryId,
  });

  /// Pre-filled search text (deep links from tags).
  final String initialQuery;

  /// Pre-selected category token.
  final String? initialCategoryId;

  @override
  ConsumerState<DocumentSearchScreen> createState() =>
      _DocumentSearchScreenState();
}

class _DocumentSearchScreenState extends ConsumerState<DocumentSearchScreen> {
  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();
  Timer? _debounce;

  /// Settled (debounced) search text.
  late String _query;
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _query = widget.initialQuery.trim();
    _categoryId = widget.initialCategoryId;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _typed => _controller.text.trim();

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(AuroraDurations.searchDebounce, _settle);
    setState(() {});
  }

  void _settle() {
    if (!mounted) return;
    setState(() => _query = _typed);
  }

  void _setText(String text) {
    _debounce?.cancel();
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() => _query = text.trim());
  }

  void _remember() {
    if (_query.isNotEmpty) {
      ref.read(recentSearchesProvider.notifier).remember(_query);
    }
  }

  void _cancel() {
    _debounce?.cancel();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.documents);
    }
  }

  void _open(DocumentSearchHit hit) {
    _remember();
    context.push(AppRoutes.documentDetail.replaceFirst(':documentId', hit.id));
  }

  void _upgrade() {
    UpgradeSheet.show(
      context,
      config: const UpgradeSheetConfig(
        headline: 'Unlock Full-Text Search',
        reason: 'Free accounts can search by name and category only.',
        features: [
          'Search inside every document with OCR',
          'Find any text across your entire vault',
          'Instant results with highlighted snippets',
        ],
        triggerKey: 'document_full_text_search',
      ),
    );
  }

  Future<void> _retryResults() async {
    ref.invalidate(documentSearchProvider);
  }

  Future<void> _refreshStart() async {
    ref.invalidate(documentCategoriesProvider);
    ref.invalidate(documentCategoryCountsProvider);
    await ref.read(documentCategoryCountsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(documentCategoriesProvider).value ?? const [];
    String? categoryName;
    for (final c in categories) {
      if (c.id == _categoryId) categoryName = c.name;
    }
    final showResults = _typed.isNotEmpty || _categoryId != null;

    return Scaffold(
      backgroundColor: AuroraColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: context.aurora.symmetric(
                horizontal: AuroraSpacing.screenPadH,
                vertical: AuroraSpacing.space5,
              ),
              child: SearchFieldBar(
                controller: _controller,
                focusNode: _focus,
                tokenLabel: categoryName,
                onChanged: _onChanged,
                onSubmitted: (_) {
                  _settle();
                  _remember();
                },
                onClearText: () => _setText(''),
                onClearToken: () => setState(() => _categoryId = null),
                onCancel: _cancel,
              ),
            ),
            Expanded(
              child: showResults
                  ? _results(categoryName)
                  : _start(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _results(String? categoryName) {
    final results = ref.watch(
      documentSearchProvider(
        DocumentSearchQuery(text: _query, categoryId: _categoryId),
      ),
    );
    return SearchResultsBody(
      results: results,
      pending: _query != _typed,
      query: _query,
      categoryName: categoryName,
      isPremium: ref.watch(isPremiumProvider),
      onOpen: _open,
      onUpgrade: _upgrade,
      onRetry: _retryResults,
    );
  }

  Widget _start() {
    final categories = ref.watch(documentCategoriesProvider);
    final counts = ref.watch(documentCategoryCountsProvider);
    final recent = ref.watch(recentSearchesProvider).value ?? const [];

    if (categories.hasError || counts.hasError) {
      return ErrorView(
        message: "Couldn't load your categories.",
        onRetry: _refreshStart,
      );
    }
    final list = categories.value;
    final countMap = counts.value;
    if (list == null || countMap == null) {
      return DocsScrollPage(
        onRefresh: _refreshStart,
        topPadding: AuroraSpacing.space3,
        child: const SearchSkeleton(),
      );
    }

    return SearchStartBody(
      suggestions: [
        for (final c in list)
          SearchSuggestion(
            id: c.id,
            name: c.name,
            iconKey: c.icon,
            count: countMap[c.id] ?? 0,
          ),
      ],
      recent: recent,
      onPickCategory: (s) => setState(() => _categoryId = s.id),
      onPickRecent: _setText,
      onRefresh: _refreshStart,
    );
  }
}
