import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/upgrade_sheet.dart';
import '../../../services/providers/service_providers.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../models/document.dart';
import '../models/document_category.dart';
import '../providers/document_categories_provider.dart';
import '../providers/documents_provider.dart';
import '../widgets/document_empty_state.dart';
import '../widgets/document_list_skeleton.dart';
import '../widgets/document_search_empty_state.dart';
import '../widgets/document_search_result_card.dart';

// ── Top-level helpers ─────────────────────────────────────────────────────────

/// Parses a hex category color string (e.g. '#B85638') to a [Color].
/// Falls back to [AppColors.accent] when parsing fails.
Color _parseCatColor(String? hex) {
  if (hex == null || hex.isEmpty) return AppColors.accent;
  final s = hex.replaceAll('#', '');
  if (s.length != 6) return AppColors.accent;
  final v = int.tryParse('FF$s', radix: 16);
  return v != null ? Color(v) : AppColors.accent;
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
    return (bg: AppColors.accentDim, text: AppColors.accent, label: 'EXPIRED');
  }
  if (days <= 30) {
    return (bg: AppColors.accentDim, text: AppColors.accent, label: '${days}d');
  }
  if (days <= 90) {
    return (
      bg: AppColors.sandDim,
      text: const Color(0xFF9B7E3E),
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
    return isIOS ? const _IOSDocumentsLayout() : const _AndroidDocumentsLayout();
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
    context.push(AppRoutes.documentsUpload);
  }

  Future<void> _showIOSOverflow(BuildContext ctx) async {
    await showCupertinoModalPopup<void>(
      context: ctx,
      builder: (_) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx, rootNavigator: true).pop();
              ctx.push(AppRoutes.documentsCategories);
            },
            child: const Text('Manage Categories'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final documentsState = ref.watch(documentsProvider);
    final categoriesState = ref.watch(documentCategoriesProvider);
    final notifier = ref.read(documentsProvider.notifier);
    final isSearchActive = notifier.isSearchActive;
    final isPremium = ref.watch(isPremiumProvider);

    final allDocs = documentsState.value ?? [];
    final docCount = allDocs.length;
    final catCount = (categoriesState.value ?? []).length;

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Nav bar with Sort + Filter actions in trailing.
              CupertinoSliverNavigationBar(
                largeTitle: Text(
                  'Documents',
                  style: GoogleFonts.fraunces(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FilterButton(
                      isIOS: true,
                      onTap: () => _showIOSOverflow(context),
                    ),
                    const SizedBox(width: 6),
                    _SortButton(
                      isIOS: true,
                      onSortSelected: (order) =>
                          ref.read(documentsProvider.notifier).setSortOrder(order),
                    ),
                  ],
                ),
              ),

              // Pull-to-refresh.
              CupertinoSliverRefreshControl(
                onRefresh: () =>
                    ref.read(documentsProvider.notifier).refresh(),
              ),

              // Subtitle row: doc count + category count.
              SliverToBoxAdapter(
                child: _DocSubtitle(
                  docCount: docCount,
                  catCount: catCount,
                ),
              ),

              // Search bar with OCR badge.
              SliverToBoxAdapter(
                child: _DocSearchBar(
                  onChanged: (query) =>
                      ref.read(documentsProvider.notifier).setSearchQuery(query),
                ),
              ),

              // Category legend — horizontal dot + name + count row.
              SliverToBoxAdapter(
                child: _CategoryLegend(
                  categoriesState: categoriesState,
                  selectedCategoryId: _selectedCategoryId,
                  onCategorySelected: (id) {
                    setState(() => _selectedCategoryId = id);
                    ref.read(documentsProvider.notifier).setCategory(id);
                  },
                ),
              ),

              // Document body.
              ..._buildBody(
                context: context,
                documentsState: documentsState,
                categoriesState: categoriesState,
                isSearchActive: isSearchActive,
                notifier: notifier,
                isPremium: isPremium,
                onAddTapped: _onAddTapped,
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),

          // iOS FAB — Stack + Positioned.
          Positioned(
            bottom: 110,
            right: 22,
            child: GestureDetector(
              onTap: _onAddTapped,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.deepNavy,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepNavy.withAlpha(60),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.add,
                  color: AppColors.textInverse,
                  size: 22,
                ),
              ),
            ),
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
    context.push(AppRoutes.documentsUpload);
  }

  @override
  Widget build(BuildContext context) {
    final documentsState = ref.watch(documentsProvider);
    final categoriesState = ref.watch(documentCategoriesProvider);
    final notifier = ref.read(documentsProvider.notifier);
    final isSearchActive = notifier.isSearchActive;
    final isPremium = ref.watch(isPremiumProvider);

    final allDocs = documentsState.value ?? [];
    final docCount = allDocs.length;
    final catCount = (categoriesState.value ?? []).length;

    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.deepNavy,
        foregroundColor: AppColors.textInverse,
        onPressed: _onAddTapped,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        color: AppColors.deepNavy,
        onRefresh: () => ref.read(documentsProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text('Documents', style: AppTextStyles.h3),
              floating: true,
              backgroundColor: AppColors.warmOffWhite,
              scrolledUnderElevation: 0,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  color: AppColors.textSecondary,
                  onPressed: () => context.push(AppRoutes.documentsCategories),
                ),
                _SortButton(
                  isIOS: false,
                  onSortSelected: (order) =>
                      ref.read(documentsProvider.notifier).setSortOrder(order),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: _DocSubtitle(
                docCount: docCount,
                catCount: catCount,
              ),
            ),

            SliverToBoxAdapter(
              child: _DocSearchBar(
                onChanged: (query) =>
                    ref.read(documentsProvider.notifier).setSearchQuery(query),
              ),
            ),

            SliverToBoxAdapter(
              child: _CategoryLegend(
                categoriesState: categoriesState,
                selectedCategoryId: _selectedCategoryId,
                onCategorySelected: (id) {
                  setState(() => _selectedCategoryId = id);
                  ref.read(documentsProvider.notifier).setCategory(id);
                },
              ),
            ),

            ..._buildBody(
              context: context,
              documentsState: documentsState,
              categoriesState: categoriesState,
              isSearchActive: isSearchActive,
              notifier: notifier,
              isPremium: isPremium,
              onAddTapped: _onAddTapped,
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
  required DocumentsNotifier notifier,
  required bool isPremium,
  required VoidCallback onAddTapped,
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
              horizontal: AppSizes.screenPadding,
              vertical: AppSizes.sm,
            ),
            sliver: SliverList.separated(
              itemCount: docs.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
              itemBuilder: (_, i) => DocumentSearchResultCard(
                document: docs[i],
                snippet: notifier.snippetFor(docs[i].id),
              ),
            ),
          ),
        ];
      }

      // Normal data view: recently-added grid + all docs feed + storage card.
      final recentDocs = docs.take(6).toList();
      final categories = categoriesState.value ?? [];

      return [
        SliverToBoxAdapter(
          child: _RecentlyAddedSection(docs: recentDocs, categories: categories),
        ),
        SliverToBoxAdapter(
          child: _AllDocsFeed(
            docs: docs,
            categories: categories,
            notifier: notifier,
          ),
        ),
        if (!isPremium)
          SliverToBoxAdapter(
            child: _StorageTierCard(docCount: docs.length),
          ),
      ];
    },
  );
}

// ── _DocSubtitle ──────────────────────────────────────────────────────────────

class _DocSubtitle extends StatelessWidget {
  const _DocSubtitle({required this.docCount, required this.catCount});

  final int docCount;
  final int catCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.xs,
        AppSizes.screenPadding,
        AppSizes.xs,
      ),
      child: Text(
        '$docCount docs · $catCount categories',
        style: GoogleFonts.ibmPlexMono(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

// ── _FilterButton ─────────────────────────────────────────────────────────────

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.isIOS, required this.onTap});

  final bool isIOS;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (isIOS) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(32, 32),
        onPressed: onTap,
        child: const Icon(
          CupertinoIcons.slider_horizontal_3,
          size: 20,
          color: AppColors.accent,
        ),
      );
    }
    return IconButton(
      icon: const Icon(Icons.tune_rounded),
      color: AppColors.textSecondary,
      onPressed: onTap,
    );
  }
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
        AppSizes.screenPadding,
        0,
        AppSizes.screenPadding,
        AppSizes.xs,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D2A2420),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.search_rounded,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: _onTextChanged,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search documents...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.transparent,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            GestureDetector(
              onTap: isPremium ? null : _showOcrUpgradeSheet,
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentDim,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'OCR',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
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
  });

  final AsyncValue<List<DocumentCategory>> categoriesState;
  final String? selectedCategoryId;
  final void Function(String? id) onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final categories = categoriesState.value ?? [];

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.screenPadding,
        ),
        children: [
          // "All" item — always first, no dot.
          _LegendItem(
            label: 'All',
            count: null,
            dotColor: null,
            isSelected: selectedCategoryId == null,
            onTap: () => onCategorySelected(null),
          ),
          ...categories.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _LegendItem(
                label: cat.name,
                count: null,
                dotColor: _parseCatColor(cat.color),
                isSelected: selectedCategoryId == cat.id,
                onTap: () => onCategorySelected(cat.id),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.count,
    required this.dotColor,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int? count;
  final Color? dotColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelColor = isSelected ? AppColors.textPrimary : AppColors.textTertiary;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
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
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 3),
            Text(
              '$count',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: labelColor.withAlpha(128),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── _RecentlyAddedSection ─────────────────────────────────────────────────────

class _RecentlyAddedSection extends StatelessWidget {
  const _RecentlyAddedSection({
    required this.docs,
    required this.categories,
  });

  final List<Document> docs;
  final List<DocumentCategory> categories;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.xs,
        AppSizes.screenPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recently Added',
            style: GoogleFonts.fraunces(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            itemCount: docs.length,
            itemBuilder: (_, i) => _DocGridTile(document: docs[i]),
          ),
        ],
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
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        onTap: () {
          final path = AppRoutes.documentDetail.replaceFirst(
            ':documentId',
            document.id,
          );
          context.push(path);
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D2A2420),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top area: icon + color stripe + badges.
              Expanded(
                child: Stack(
                  children: [
                    // Category color stripe at top.
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppSizes.radiusMd - 1.5),
                          topRight: Radius.circular(AppSizes.radiusMd - 1.5),
                        ),
                        child: Container(
                          height: 3,
                          color: catColor,
                        ),
                      ),
                    ),

                    // Centered category icon.
                    Center(
                      child: Icon(
                        Icons.insert_drive_file_outlined,
                        size: 28,
                        color: catColor.withAlpha(128),
                      ),
                    ),

                    // Expiry badge — top-left.
                    if (expiry != null)
                      Positioned(
                        top: 8,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: expiry.bg,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            expiry.label,
                            style: GoogleFonts.ibmPlexMono(
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
                          color: const Color(0x0F000000),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          typeLabel,
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Footer: title + date.
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFE9E4DC), width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.name,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textTertiary,
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
  });

  final List<Document> docs;
  final List<DocumentCategory> categories;
  final DocumentsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.xs,
        AppSizes.screenPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header.
          Row(
            children: [
              Expanded(
                child: Text(
                  'All Documents',
                  style: GoogleFonts.fraunces(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _SortButton(
                isIOS: Theme.of(context).platform == TargetPlatform.iOS,
                onSortSelected: (order) => notifier.setSortOrder(order),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),

          // Feed rows.
          ...docs.map(
            (doc) => _FeedRow(document: doc),
          ),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        onTap: () {
          final path = AppRoutes.documentDetail.replaceFirst(
            ':documentId',
            document.id,
          );
          context.push(path);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            children: [
              // Colored dot.
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 10, top: 2),
                decoration: BoxDecoration(
                  color: catColor,
                  shape: BoxShape.circle,
                ),
              ),

              // Info column.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.name,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        // Category badge.
                        if (cat != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: catColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              cat.name,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: catColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          dateStr,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSizes.sm),

              // End column: expiry badge or file size.
              if (expiry != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: expiry.bg,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    expiry.label,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: expiry.text,
                    ),
                  ),
                )
              else if (sizeStr.isNotEmpty)
                Text(
                  sizeStr,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textTertiary,
                  ),
                ),

              const SizedBox(width: AppSizes.xs),

              // Chevron.
              const Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: AppColors.borderStrong,
              ),
            ],
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
        AppSizes.screenPadding,
        AppSizes.md,
        AppSizes.screenPadding,
        0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.deepNavy,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$docCount of $kFreeDocumentLimit documents used',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Free tier · Upgrade for unlimited',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textInverse.withAlpha(102),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 3,
                    backgroundColor: const Color(0x14FFFFFF),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.md),
          GestureDetector(
            onTap: () => UpgradeSheet.show(
              context,
              config: const UpgradeSheetConfig(
                headline: 'Unlock Unlimited Documents',
                reason:
                    'Upgrade to store as many documents as you need.',
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
                color: const Color(0x26B85638),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Text(
                'UPGRADE',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
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
    required this.onSortSelected,
  });

  final bool isIOS;
  final void Function(DocumentSortOrder order) onSortSelected;

  static const _options = [
    (label: 'Date Added', order: DocumentSortOrder.dateAddedDesc),
    (label: 'Name', order: DocumentSortOrder.nameAsc),
    (label: 'Category', order: DocumentSortOrder.categoryAsc),
  ];

  @override
  Widget build(BuildContext context) {
    if (isIOS) {
      return GestureDetector(
        onTap: () => _showIOSSortSheet(context),
        child: Text(
          'Sort \u2193',
          style: GoogleFonts.ibmPlexMono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
            letterSpacing: 0,
          ),
        ),
      );
    }

    return PopupMenuButton<DocumentSortOrder>(
      icon: const Icon(Icons.sort, color: AppColors.accent, size: 18),
      color: AppColors.surface,
      onSelected: onSortSelected,
      itemBuilder: (_) => _options
          .map(
            (opt) => PopupMenuItem<DocumentSortOrder>(
              value: opt.order,
              child: Text(opt.label, style: AppTextStyles.bodyMedium),
            ),
          )
          .toList(),
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
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  onSortSelected(opt.order);
                },
                child: Text(opt.label),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}
