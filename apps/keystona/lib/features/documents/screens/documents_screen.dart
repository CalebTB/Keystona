import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../models/document_category.dart';
import '../providers/document_categories_provider.dart';
import '../providers/documents_provider.dart';
import '../widgets/document_card.dart';
import '../widgets/document_empty_state.dart';
import '../widgets/document_list_skeleton.dart';
import '../widgets/document_search_bar.dart';
import '../widgets/document_search_empty_state.dart';
import '../widgets/document_search_result_card.dart';

/// The Document Vault list screen — Tab 1 of the main shell.
///
/// Adaptive layout:
/// - iOS: [CustomScrollView] with [CupertinoSliverNavigationBar] large title,
///   [CupertinoSliverRefreshControl] for pull-to-refresh, sticky filter chips.
/// - Android: [Scaffold] with a floating [SliverAppBar], [RefreshIndicator],
///   and a [FloatingActionButton] for add.
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

  @override
  Widget build(BuildContext context) {
    final documentsState = ref.watch(documentsProvider);
    final categoriesState = ref.watch(documentCategoriesProvider);
    final notifier = ref.read(documentsProvider.notifier);
    final isSearchActive = notifier.isSearchActive;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          // Large-title navigation bar with sort + add buttons.
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Documents'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SortButton(
                  isIOS: true,
                  onSortSelected: (order) =>
                      ref.read(documentsProvider.notifier).setSortOrder(order),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => context.push(AppRoutes.documentsUpload),
                  child: const Icon(CupertinoIcons.add),
                ),
              ],
            ),
          ),

          // Pull-to-refresh control.
          CupertinoSliverRefreshControl(
            onRefresh: () => ref.read(documentsProvider.notifier).refresh(),
          ),

          // Search bar — debounced 300ms, PRO badge for free users.
          SliverToBoxAdapter(
            child: DocumentSearchBar(
              onChanged: (query) {
                ref.read(documentsProvider.notifier).setSearchQuery(query);
              },
            ),
          ),

          // Filter chips row — visible but inactive while search is active.
          SliverToBoxAdapter(
            child: _FilterRow(
              categoriesState: categoriesState,
              selectedCategoryId: _selectedCategoryId,
              onCategorySelected: (id) {
                setState(() => _selectedCategoryId = id);
                ref.read(documentsProvider.notifier).setCategory(id);
              },
            ),
          ),

          // Document list body.
          documentsState.when(
            loading: () => const SliverFillRemaining(
              child: DocumentListSkeleton(),
            ),
            error: (e, _) => SliverFillRemaining(
              child: ErrorView(
                message: "Couldn't load documents.",
                onRetry: () =>
                    ref.read(documentsProvider.notifier).refresh(),
              ),
            ),
            data: (docs) {
              if (docs.isEmpty) {
                return SliverFillRemaining(
                  child: isSearchActive
                      ? const DocumentSearchEmptyState()
                      : DocumentEmptyState(
                          onAdd: () => context.push(AppRoutes.documentsUpload),
                        ),
                );
              }
              return SliverPadding(
                padding: AppPadding.screen,
                sliver: SliverList.separated(
                  itemCount: docs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSizes.sm),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    if (isSearchActive) {
                      return DocumentSearchResultCard(
                        document: doc,
                        snippet: notifier.snippetFor(doc.id),
                      );
                    }
                    return DocumentCard(document: doc);
                  },
                ),
              );
            },
          ),

          // Bottom safe-area breathing room.
          const SliverToBoxAdapter(child: SizedBox(height: AppSizes.xl)),
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

  @override
  Widget build(BuildContext context) {
    final documentsState = ref.watch(documentsProvider);
    final categoriesState = ref.watch(documentCategoriesProvider);
    final notifier = ref.read(documentsProvider.notifier);
    final isSearchActive = notifier.isSearchActive;

    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.deepNavy,
        foregroundColor: AppColors.textInverse,
        onPressed: () => context.push(AppRoutes.documentsUpload),
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
                _SortButton(
                  isIOS: false,
                  onSortSelected: (order) =>
                      ref.read(documentsProvider.notifier).setSortOrder(order),
                ),
              ],
            ),

            // Search bar — debounced 300ms, PRO badge for free users.
            SliverToBoxAdapter(
              child: DocumentSearchBar(
                onChanged: (query) {
                  ref.read(documentsProvider.notifier).setSearchQuery(query);
                },
              ),
            ),

            // Filter chips — visible but inactive while search is active.
            SliverToBoxAdapter(
              child: _FilterRow(
                categoriesState: categoriesState,
                selectedCategoryId: _selectedCategoryId,
                onCategorySelected: (id) {
                  setState(() => _selectedCategoryId = id);
                  ref.read(documentsProvider.notifier).setCategory(id);
                },
              ),
            ),

            // Document list body.
            documentsState.when(
              loading: () => const SliverFillRemaining(
                child: DocumentListSkeleton(),
              ),
              error: (e, _) => SliverFillRemaining(
                child: ErrorView(
                  message: "Couldn't load documents.",
                  onRetry: () =>
                      ref.read(documentsProvider.notifier).refresh(),
                ),
              ),
              data: (docs) {
                if (docs.isEmpty) {
                  return SliverFillRemaining(
                    child: isSearchActive
                        ? const DocumentSearchEmptyState()
                        : DocumentEmptyState(
                            onAdd: () => context.push(AppRoutes.documentsUpload),
                          ),
                  );
                }
                return SliverPadding(
                  padding: AppPadding.screen,
                  sliver: SliverList.separated(
                    itemCount: docs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSizes.sm),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      if (isSearchActive) {
                        return DocumentSearchResultCard(
                          document: doc,
                          snippet: notifier.snippetFor(doc.id),
                        );
                      }
                      return DocumentCard(document: doc);
                    },
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSizes.xl)),
          ],
        ),
      ),
    );
  }
}

// ── Filter chips ──────────────────────────────────────────────────────────────

/// Horizontally scrollable row of category filter chips.
///
/// The first chip is always "All" which clears the active filter.
/// Remaining chips come from [documentCategoriesProvider].
/// The filter row remains visible during search but is inactive.
class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.categoriesState,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  final AsyncValue<List<DocumentCategory>> categoriesState;
  final String? selectedCategoryId;
  final void Function(String? id) onCategorySelected;

  @override
  Widget build(BuildContext context) {
    // Use .value (Riverpod v3) — falls back to empty list on loading/error.
    final categories = categoriesState.value ?? [];

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: AppPadding.screenHorizontal,
        children: [
          // "All" chip always shown first.
          _FilterChip(
            label: 'All',
            isSelected: selectedCategoryId == null,
            onTap: () => onCategorySelected(null),
          ),
          ...categories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(left: AppSizes.sm),
              child: _FilterChip(
                label: cat.name,
                isSelected: selectedCategoryId == cat.id,
                onTap: () => onCategorySelected(cat.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.deepNavy : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.deepNavy : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? AppColors.textInverse : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ── Sort button ───────────────────────────────────────────────────────────────

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
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _showIOSSortSheet(context),
        child: const Icon(CupertinoIcons.sort_down),
      );
    }

    return PopupMenuButton<DocumentSortOrder>(
      icon: const Icon(Icons.sort),
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
