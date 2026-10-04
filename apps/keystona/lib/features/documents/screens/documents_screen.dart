import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/theme/aurora_shadows.dart';
import '../../../core/widgets/aurora/aurora.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/upgrade_sheet.dart';
import '../../../services/providers/service_providers.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../models/document.dart';
import '../models/document_category.dart';
import '../providers/document_categories_provider.dart';
import '../providers/document_upload_provider.dart';
import '../providers/documents_provider.dart';
import '../widgets/category_form_sheet.dart';
import '../widgets/document_empty_state.dart';
import '../widgets/document_list_skeleton.dart';
import '../widgets/document_search_empty_state.dart';
import '../widgets/document_search_result_card.dart';
import '../widgets/upload_source_sheet.dart';

// ── Top-level helpers ─────────────────────────────────────────────────────────

/// Parses a hex category color string (e.g. '#B85638') to a [Color].
/// Falls back to [AuroraColors.coral] when parsing fails.
Color _parseCatColor(String? hex) {
  if (hex == null || hex.isEmpty) return AuroraColors.coral;
  final s = hex.replaceAll('#', '');
  if (s.length != 6) return AuroraColors.coral;
  final v = int.tryParse('FF$s', radix: 16);
  return v != null ? Color(v) : AuroraColors.coral;
}

/// Returns a short file-type label from a MIME type string.
String _fileTypeLabel(String? mimeType) {
  if (mimeType == null) return 'FILE';
  if (mimeType.contains('pdf')) return 'PDF';
  if (mimeType.contains('jpeg') || mimeType.contains('jpg')) return 'JPG';
  if (mimeType.contains('png')) return 'PNG';
  if (mimeType.contains('word') || mimeType.contains('docx')) return 'DOC';
  return 'FILE';
}

/// Formats a file size in bytes to a human-readable string.
String _formatSize(int? bytes) {
  if (bytes == null) return '';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Returns badge style for a document's expiration date.
/// Returns null when no badge should be shown (> 90 days or null).
({Color bg, Color text, String label})? _expiryBadgeStyle(DateTime? exp) {
  if (exp == null) return null;
  final days = exp.difference(DateTime.now()).inDays;
  if (days < 0) {
    return (
      bg: AuroraColors.coralDim,
      text: AuroraColors.coral,
      label: 'EXPIRED',
    );
  }
  if (days <= 30) {
    return (
      bg: AuroraColors.coralDim,
      text: AuroraColors.coral,
      label: '${days}d',
    );
  }
  if (days <= 90) {
    return (
      bg: AuroraColors.yellowDim,
      text: AuroraColors.yellowDeep,
      label: '${days}d',
    );
  }
  return null;
}

// ── Entry point ───────────────────────────────────────────────────────────────

/// The Document Vault list screen — Tab 1 of the main shell.
class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return isIOS
        ? const _IOSDocumentsLayout()
        : const _AndroidDocumentsLayout();
  }
}

// ── iOS layout ────────────────────────────────────────────────────────────────

class _IOSDocumentsLayout extends ConsumerStatefulWidget {
  const _IOSDocumentsLayout();

  @override
  ConsumerState<_IOSDocumentsLayout> createState() =>
      _IOSDocumentsLayoutState();
}

class _IOSDocumentsLayoutState extends ConsumerState<_IOSDocumentsLayout> {
  String? _selectedCategoryId;
  bool _recentlyAddedExpanded = true;

  Future<void> _onAddTapped() async {
    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) {
      final docs = ref.read(documentsProvider).value ?? [];
      if (docs.length >= kFreeDocumentLimit) {
        if (!mounted) return;
        await UpgradeSheet.show(
          context,
          config: const UpgradeSheetConfig(
            headline: 'Unlock Unlimited Documents',
            reason:
                'Your Document Vault is full with 25 documents on the Free plan.',
            features: [
              'Unlimited document storage',
              'Full-text search across all docs',
              'Home health score tracking',
              'Weather-based maintenance alerts',
            ],
            triggerKey: 'doc_limit',
          ),
        );
        return;
      }
    }
    if (!mounted) return;

    ref.invalidate(documentUploadProvider);

    bool filePicked = false;
    await UploadSourceSheet.show(
      context,
      ref,
      onFilePicked: () => filePicked = true,
    );

    if (!filePicked || !mounted) return;
    context.push(AppRoutes.documentsUpload);
  }

  @override
  Widget build(BuildContext context) {
    final documentsState = ref.watch(documentsProvider);
    final categoriesState = ref.watch(documentCategoriesProvider);
    final countsState = ref.watch(documentCategoryCountsProvider);
    final notifier = ref.read(documentsProvider.notifier);
    final isSearchActive = notifier.isSearchActive;
    final isPremium = ref.watch(isPremiumProvider);

    final categoryCounts = countsState.value ?? {};

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.top,
                ),
              ),
              CupertinoSliverRefreshControl(
                onRefresh: () =>
                    ref.read(documentsProvider.notifier).refresh(),
              ),

              // Title row: large title + add button.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 10, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Documents',
                          style: AuroraType.displayLg.copyWith(
                            color: AuroraColors.ink,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _onAddTapped,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: AuroraColors.coral,
                            borderRadius: AuroraRadius.full,
                            boxShadow: [
                              BoxShadow(
                                color: AuroraColors.coral.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded,
                                  color: AuroraColors.paper, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Add',
                                style: AuroraType.label.copyWith(
                                  color: AuroraColors.paper,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search bar with OCR badge.
              SliverToBoxAdapter(
                child: _DocSearchBar(
                  onChanged: (query) =>
                      ref.read(documentsProvider.notifier).setSearchQuery(query),
                ),
              ),

              // Category filter pills — hidden during active search.
              if (!isSearchActive)
                SliverToBoxAdapter(
                  child: _CategoryLegend(
                    categoriesState: categoriesState,
                    selectedCategoryId: _selectedCategoryId,
                    onCategorySelected: (id) {
                      setState(() => _selectedCategoryId = id);
                      ref.read(documentsProvider.notifier).setCategory(id);
                    },
                    categoryCounts: categoryCounts,
                  ),
                ),

              // Document body.
              ..._buildBody(
                context: context,
                documentsState: documentsState,
                categoriesState: categoriesState,
                isSearchActive: isSearchActive,
                selectedCategoryId: _selectedCategoryId,
                totalDocCount: categoryCounts.values.fold(0, (a, b) => a + b),
                notifier: notifier,
                isPremium: isPremium,
                onAddTapped: _onAddTapped,
                recentlyAddedExpanded: _recentlyAddedExpanded,
                onToggleRecentlyAdded: () => setState(
                  () => _recentlyAddedExpanded = !_recentlyAddedExpanded,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Android layout ────────────────────────────────────────────────────────────

class _AndroidDocumentsLayout extends ConsumerStatefulWidget {
  const _AndroidDocumentsLayout();

  @override
  ConsumerState<_AndroidDocumentsLayout> createState() =>
      _AndroidDocumentsLayoutState();
}

class _AndroidDocumentsLayoutState
    extends ConsumerState<_AndroidDocumentsLayout> {
  String? _selectedCategoryId;
  bool _recentlyAddedExpanded = true;

  Future<void> _onAddTapped() async {
    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) {
      final docs = ref.read(documentsProvider).value ?? [];
      if (docs.length >= kFreeDocumentLimit) {
        if (!mounted) return;
        await UpgradeSheet.show(
          context,
          config: const UpgradeSheetConfig(
            headline: 'Unlock Unlimited Documents',
            reason:
                'Your Document Vault is full with 25 documents on the Free plan.',
            features: [
              'Unlimited document storage',
              'Full-text search across all docs',
              'Home health score tracking',
              'Weather-based maintenance alerts',
            ],
            triggerKey: 'doc_limit',
          ),
        );
        return;
      }
    }
    if (!mounted) return;

    ref.invalidate(documentUploadProvider);

    bool filePicked = false;
    await UploadSourceSheet.show(
      context,
      ref,
      onFilePicked: () => filePicked = true,
    );

    if (!filePicked || !mounted) return;
    context.push(AppRoutes.documentsUpload);
  }

  @override
  Widget build(BuildContext context) {
    final documentsState = ref.watch(documentsProvider);
    final categoriesState = ref.watch(documentCategoriesProvider);
    final countsState = ref.watch(documentCategoryCountsProvider);
    final notifier = ref.read(documentsProvider.notifier);
    final isSearchActive = notifier.isSearchActive;
    final isPremium = ref.watch(isPremiumProvider);

    final categoryCounts = countsState.value ?? {};

    return Scaffold(
      backgroundColor: AuroraColors.paper,
      body: RefreshIndicator(
        color: AuroraColors.ink,
        onRefresh: () => ref.read(documentsProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text('Documents', style: AuroraType.h3),
              floating: true,
              backgroundColor: AuroraColors.paper,
              scrolledUnderElevation: 0,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  color: AuroraColors.inkSecondary,
                  onPressed: () =>
                      context.push(AppRoutes.documentsCategories),
                ),
                _SortButton(
                  isIOS: false,
                  currentSort: notifier.currentSortOrder,
                  onSortSelected: (order) => notifier.setSortOrder(order),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: _onAddTapped,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AuroraColors.coral,
                        borderRadius: AuroraRadius.full,
                        boxShadow: [
                          BoxShadow(
                            color: AuroraColors.coral.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded,
                              color: AuroraColors.paper, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Add',
                            style: AuroraType.label.copyWith(
                              color: AuroraColors.paper,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: _DocSearchBar(
                onChanged: (query) =>
                    ref.read(documentsProvider.notifier).setSearchQuery(query),
              ),
            ),

            if (!isSearchActive)
              SliverToBoxAdapter(
                child: _CategoryLegend(
                  categoriesState: categoriesState,
                  selectedCategoryId: _selectedCategoryId,
                  onCategorySelected: (id) {
                    setState(() => _selectedCategoryId = id);
                    ref.read(documentsProvider.notifier).setCategory(id);
                  },
                  categoryCounts: categoryCounts,
                ),
              ),

            ..._buildBody(
              context: context,
              documentsState: documentsState,
              categoriesState: categoriesState,
              isSearchActive: isSearchActive,
              selectedCategoryId: _selectedCategoryId,
              totalDocCount: categoryCounts.values.fold(0, (a, b) => a + b),
              notifier: notifier,
              isPremium: isPremium,
              onAddTapped: _onAddTapped,
              recentlyAddedExpanded: _recentlyAddedExpanded,
              onToggleRecentlyAdded: () => setState(
                () => _recentlyAddedExpanded = !_recentlyAddedExpanded,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }
}

// ── Shared body builder ───────────────────────────────────────────────────────

List<Widget> _buildBody({
  required BuildContext context,
  required AsyncValue<List<Document>> documentsState,
  required AsyncValue<List<DocumentCategory>> categoriesState,
  required bool isSearchActive,
  required String? selectedCategoryId,
  required int totalDocCount,
  required DocumentsNotifier notifier,
  required bool isPremium,
  required VoidCallback onAddTapped,
  required bool recentlyAddedExpanded,
  required VoidCallback onToggleRecentlyAdded,
}) {
  return documentsState.when(
    loading: () => [
      const SliverFillRemaining(child: DocumentListSkeleton()),
    ],
    error: (e, _) => [
      SliverFillRemaining(
        child: ErrorView(
          message: "Couldn't load documents.",
          onRetry: () => notifier.refresh(),
        ),
      ),
    ],
    data: (docs) {
      if (docs.isEmpty) {
        if (isSearchActive) {
          return [
            const SliverFillRemaining(child: DocumentSearchEmptyState()),
          ];
        }
        if (selectedCategoryId != null) {
          return [
            SliverFillRemaining(
              child: EmptyState(
                icon: CupertinoIcons.doc_text,
                title: 'No matching documents',
                subtitle:
                    'Try clearing your filters or search term.',
                actionLabel: 'Clear filters',
                onAction: () => notifier.setCategory(null),
              ),
            ),
          ];
        }
        return [
          SliverFillRemaining(
            child: DocumentEmptyState(onAdd: onAddTapped),
          ),
        ];
      }

      // When search is active, show search result cards.
      if (isSearchActive) {
        return [
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AuroraSpacing.screenPadH,
              vertical: AuroraSpacing.space3,
            ),
            sliver: SliverList.separated(
              itemCount: docs.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AuroraSpacing.space3),
              itemBuilder: (_, i) => DocumentSearchResultCard(
                document: docs[i],
                snippet: notifier.snippetFor(docs[i].id),
              ),
            ),
          ),
        ];
      }

      // Normal data view: recently-added grid + all docs feed + storage card.
      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      final recentDocs = docs
          .where((d) => d.createdAt.isAfter(cutoff))
          .take(6)
          .toList();
      final categories = categoriesState.value ?? [];

      return [
        if (recentDocs.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: GestureDetector(
              onTap: onToggleRecentlyAdded,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                child: Row(
                  children: [
                    // Cobalt dot for recently-added (active/recent = action).
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: const BoxDecoration(
                        color: AuroraColors.cobalt,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'RECENTLY ADDED',
                        style: AuroraType.label.copyWith(
                          color: AuroraColors.inkSecondary,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: recentlyAddedExpanded ? 0 : -0.25,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AuroraColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (recentlyAddedExpanded)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _DocGridTile(document: recentDocs[i]),
                  childCount: recentDocs.length,
                ),
              ),
            ),
        ],

        SliverToBoxAdapter(
          child: _AllDocsFeed(
            docs: docs,
            categories: categories,
            notifier: notifier,
            currentSort: notifier.currentSortOrder,
            sectionTitle: selectedCategoryId != null
                ? ((categoriesState.value ?? [])
                        .where((c) => c.id == selectedCategoryId)
                        .map((c) => c.name)
                        .firstOrNull ??
                    'Documents')
                : 'All Documents',
          ),
        ),

        if (!isPremium)
          SliverToBoxAdapter(
            child: _StorageTierCard(docCount: totalDocCount),
          ),
      ];
    },
  );
}

// ── _DocSearchBar ─────────────────────────────────────────────────────────────

/// Inline search bar with OCR badge and 300ms debounce.
class _DocSearchBar extends ConsumerStatefulWidget {
  const _DocSearchBar({required this.onChanged});

  final void Function(String? query) onChanged;

  @override
  ConsumerState<_DocSearchBar> createState() => _DocSearchBarState();
}

class _DocSearchBarState extends ConsumerState<_DocSearchBar> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final trimmed = value.trim();
      widget.onChanged(trimmed.isEmpty ? null : trimmed);
    });
  }

  Future<void> _showOcrUpgradeSheet() async {
    await UpgradeSheet.show(
      context,
      config: const UpgradeSheetConfig(
        headline: 'Unlock Full-Text Search',
        reason: 'Free accounts can search by name and category only.',
        features: [
          'Search inside every document with OCR',
          'Find any text across your entire vault',
          'Instant results with highlighted snippets',
        ],
        triggerKey: 'ocr_search',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AuroraSpacing.screenPadH,
        0,
        AuroraSpacing.screenPadH,
        AuroraSpacing.space1,
      ),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AuroraColors.paper,
          borderRadius: AuroraRadius.full,
          border: Border.all(color: AuroraColors.inkBorder, width: 1),
          boxShadow: AuroraShadows.card,
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(
                CupertinoIcons.search,
                size: 18,
                color: AuroraColors.inkTertiary,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: _onTextChanged,
                style: AuroraType.body.copyWith(color: AuroraColors.ink),
                decoration: InputDecoration(
                  hintText: 'Search documents...',
                  hintStyle:
                      AuroraType.body.copyWith(color: AuroraColors.inkSecondary),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: true,
                  fillColor: Colors.transparent,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (!isPremium)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _showOcrUpgradeSheet,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AuroraColors.coralDim,
                      borderRadius: AuroraRadius.xs,
                    ),
                    child: Text(
                      'PREMIUM',
                      style: AuroraType.labelSm.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AuroraColors.coral,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── _CategoryLegend ───────────────────────────────────────────────────────────

class _CategoryLegend extends StatelessWidget {
  const _CategoryLegend({
    required this.categoriesState,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.categoryCounts,
  });

  final AsyncValue<List<DocumentCategory>> categoriesState;
  final String? selectedCategoryId;
  final void Function(String? id) onCategorySelected;
  final Map<String, int> categoryCounts;

  @override
  Widget build(BuildContext context) {
    final categories = List<DocumentCategory>.from(
      categoriesState.value ?? [],
    );

    final totalCount = categoryCounts.values.fold(0, (a, b) => a + b);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AuroraSpacing.screenPadH,
              vertical: 8,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterPill(
                  label: 'All',
                  count: totalCount,
                  isSelected: selectedCategoryId == null,
                  activeColor: AuroraColors.ink,
                  onTap: () => onCategorySelected(null),
                ),
              ),
              ...categories.map((cat) {
                final isSelected = selectedCategoryId == cat.id;
                final catColor = _parseCatColor(cat.color);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterPill(
                    label: cat.name,
                    count: categoryCounts[cat.id] ?? 0,
                    isSelected: isSelected,
                    dotColor: catColor,
                    activeColor: catColor,
                    onTap: () =>
                        onCategorySelected(isSelected ? null : cat.id),
                  ),
                );
              }),
            ],
          ),
        ),
        const Divider(
          height: 1,
          thickness: 1,
          color: AuroraColors.inkBorder,
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
    this.dotColor,
  });

  final String label;
  final int count;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AuroraColors.paper,
          borderRadius: AuroraRadius.full,
          border: Border.all(
            color: isSelected ? activeColor : AuroraColors.inkBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null && !isSelected) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: AuroraType.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? AuroraColors.paper : AuroraColors.ink,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: AuroraType.bodySm.copyWith(
                fontWeight: FontWeight.w400,
                color: isSelected
                    ? AuroraColors.paper.withValues(alpha: 0.75)
                    : AuroraColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _DocGridTile ──────────────────────────────────────────────────────────────

class _DocGridTile extends StatelessWidget {
  const _DocGridTile({required this.document});

  final Document document;

  @override
  Widget build(BuildContext context) {
    final cat = document.category;
    final catColor = _parseCatColor(cat?.color);
    final expiry = _expiryBadgeStyle(document.expirationDate);
    final typeLabel = _fileTypeLabel(document.mimeType);
    final dateStr = DateFormat('MMM d').format(document.createdAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AuroraRadius.md,
        onTap: () {
          final path = AppRoutes.documentDetail.replaceFirst(
            ':documentId',
            document.id,
          );
          context.push(path);
        },
        child: Container(
          decoration: BoxDecoration(
            color: AuroraColors.paper,
            borderRadius: AuroraRadius.md,
            border: Border.all(color: AuroraColors.inkBorder, width: 1.5),
            boxShadow: AuroraShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category color stripe at top.
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10.5),
                  topRight: Radius.circular(10.5),
                ),
                child: Container(height: 4, color: catColor),
              ),

              // Icon area.
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        CategoryIcons.forKey(cat?.icon ?? ''),
                        size: 44,
                        color: catColor.withAlpha(160),
                      ),
                    ),

                    // Expiry badge — top-right.
                    if (expiry != null)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: expiry.bg,
                            borderRadius: AuroraRadius.xs,
                          ),
                          child: Text(
                            expiry.label,
                            style: AuroraType.labelSm.copyWith(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: expiry.text,
                            ),
                          ),
                        ),
                      ),

                    // File type badge — bottom-right.
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AuroraColors.butter,
                          borderRadius: AuroraRadius.xs,
                        ),
                        child: Text(
                          typeLabel,
                          style: AuroraType.labelSm.copyWith(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: catColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AuroraColors.butter),

              // Footer: name + date.
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 7,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      document.name,
                      style: AuroraType.bodySm.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AuroraColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: AuroraType.bodySm.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w400,
                        color: AuroraColors.inkTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _AllDocsFeed ──────────────────────────────────────────────────────────────

class _AllDocsFeed extends StatelessWidget {
  const _AllDocsFeed({
    required this.docs,
    required this.categories,
    required this.notifier,
    required this.currentSort,
    required this.sectionTitle,
  });

  final List<Document> docs;
  final List<DocumentCategory> categories;
  final DocumentsNotifier notifier;
  final DocumentSortOrder currentSort;
  final String sectionTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AuroraSpacing.screenPadH,
        AuroraSpacing.space1,
        AuroraSpacing.screenPadH,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Dot + label section header pattern.
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 6),
                decoration: const BoxDecoration(
                  color: AuroraColors.inkSecondary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  sectionTitle.toUpperCase(),
                  style: AuroraType.label.copyWith(
                    color: AuroraColors.inkSecondary,
                  ),
                ),
              ),
              _SortButton(
                isIOS: Theme.of(context).platform == TargetPlatform.iOS,
                currentSort: currentSort,
                onSortSelected: (order) => notifier.setSortOrder(order),
              ),
            ],
          ),
          const SizedBox(height: AuroraSpacing.space5),
          ...docs.map((doc) => _FeedRow(document: doc)),
        ],
      ),
    );
  }
}

// ── _FeedRow ──────────────────────────────────────────────────────────────────

class _FeedRow extends StatelessWidget {
  const _FeedRow({required this.document});

  final Document document;

  @override
  Widget build(BuildContext context) {
    final cat = document.category;
    final catColor = _parseCatColor(cat?.color);
    final expiry = _expiryBadgeStyle(document.expirationDate);
    final dateStr = DateFormat('MMM d, yyyy').format(document.createdAt);
    final sizeStr = _formatSize(document.fileSizeBytes);

    final typeLabel = _fileTypeLabel(document.mimeType);

    return Container(
      margin: const EdgeInsets.only(bottom: AuroraSpacing.space3),
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.xl,
        border: Border.all(color: AuroraColors.inkBorder, width: 1),
        boxShadow: AuroraShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AuroraRadius.xl,
        child: InkWell(
          borderRadius: AuroraRadius.xl,
          onTap: () {
            final path = AppRoutes.documentDetail.replaceFirst(
              ':documentId',
              document.id,
            );
            context.push(path);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // 44×44 color thumbnail square (category color).
                Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: catColor.withAlpha(28),
                    borderRadius: AuroraRadius.md,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          CategoryIcons.forKey(cat?.icon ?? ''),
                          size: 20,
                          color: catColor,
                        ),
                      ),
                      // Doc type chip — bottom-left of thumbnail.
                      Positioned(
                        bottom: 4,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: catColor.withAlpha(48),
                              borderRadius: AuroraRadius.xs,
                            ),
                            child: Text(
                              typeLabel,
                              style: AuroraType.labelSm.copyWith(
                                color: catColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Info column.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.name,
                        style: AuroraType.h3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Date in JetBrains Mono number style.
                          Text(
                            dateStr,
                            style: AuroraType.number.copyWith(
                              fontSize: 11,
                              color: AuroraColors.inkSecondary,
                            ),
                          ),
                          if (cat != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: AuroraColors.inkTertiary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Category name in bodySm inkSecondary.
                            Flexible(
                              child: Text(
                                cat.name,
                                style: AuroraType.bodySm.copyWith(
                                  color: AuroraColors.inkSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AuroraSpacing.space3),

                // End: expiry badge or file size, then chevron.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (expiry != null)
                      StatusChip(
                        label: expiry.label,
                        background: expiry.bg,
                        foreground: expiry.text,
                      )
                    else if (sizeStr.isNotEmpty)
                      Text(
                        sizeStr,
                        style: AuroraType.number.copyWith(
                          fontSize: 11,
                          color: AuroraColors.inkTertiary,
                        ),
                      ),
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: AuroraColors.inkSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── _StorageTierCard ──────────────────────────────────────────────────────────

class _StorageTierCard extends StatelessWidget {
  const _StorageTierCard({required this.docCount});

  final int docCount;

  @override
  Widget build(BuildContext context) {
    final fraction = (docCount / kFreeDocumentLimit).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AuroraSpacing.screenPadH,
        AuroraSpacing.space5,
        AuroraSpacing.screenPadH,
        0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AuroraColors.ink,
        borderRadius: AuroraRadius.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$docCount of $kFreeDocumentLimit documents used',
                  style: AuroraType.bodySm.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AuroraColors.paper,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Free tier · Upgrade for unlimited',
                  style: AuroraType.bodySm.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AuroraColors.paper.withValues(alpha: 102 / 255),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: AuroraRadius.xs,
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 3,
                    backgroundColor:
                        AuroraColors.paper.withValues(alpha: 40 / 255),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AuroraColors.coral,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AuroraSpacing.space5),
          GestureDetector(
            onTap: () => UpgradeSheet.show(
              context,
              config: const UpgradeSheetConfig(
                headline: 'Unlock Unlimited Documents',
                reason: 'Upgrade to store as many documents as you need.',
                features: [
                  'Unlimited document storage',
                  'Full-text search across all docs',
                  'Home health score tracking',
                  'Weather-based maintenance alerts',
                ],
                triggerKey: 'storage_card',
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AuroraColors.coralDim,
                borderRadius: AuroraRadius.sm,
              ),
              child: Text(
                'UPGRADE',
                style: AuroraType.labelSm.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AuroraColors.coral,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── _SortButton ───────────────────────────────────────────────────────────────

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.isIOS,
    required this.currentSort,
    required this.onSortSelected,
  });

  final bool isIOS;
  final DocumentSortOrder currentSort;
  final void Function(DocumentSortOrder order) onSortSelected;

  static const _options = [
    (label: 'Date Added', order: DocumentSortOrder.dateAddedDesc),
    (label: 'Name A–Z', order: DocumentSortOrder.nameAsc),
    (label: 'Category', order: DocumentSortOrder.categoryAsc),
  ];

  String get _currentLabel => _options
      .firstWhere(
        (o) => o.order == currentSort,
        orElse: () => _options.first,
      )
      .label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          isIOS ? _showIOSSortSheet(context) : _showAndroidSortSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AuroraColors.paper,
          borderRadius: AuroraRadius.full,
          border: Border.all(color: AuroraColors.inkBorder, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currentLabel,
              style: AuroraType.bodySm.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AuroraColors.inkSecondary,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: AuroraColors.inkSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showIOSSortSheet(BuildContext context) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Sort By'),
        actions: _options
            .map(
              (opt) => CupertinoActionSheetAction(
                isDefaultAction: opt.order == currentSort,
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  onSortSelected(opt.order);
                },
                child: Text(opt.label),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _showAndroidSortSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AuroraColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              'Sort By',
              style:
                  AuroraType.bodySm.copyWith(fontWeight: FontWeight.w600),
            ),
            const Divider(height: 16),
            ..._options.map(
              (opt) => ListTile(
                title: Text(opt.label, style: AuroraType.body),
                trailing: opt.order == currentSort
                    ? const Icon(Icons.check_rounded,
                        color: AuroraColors.coral, size: 20)
                    : null,
                onTap: () {
                  Navigator.of(context).pop();
                  onSortSelected(opt.order);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
