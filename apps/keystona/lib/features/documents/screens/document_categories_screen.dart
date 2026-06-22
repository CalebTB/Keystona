import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/error_view.dart';
import '../models/document_category.dart';
import '../providers/document_categories_provider.dart';
import '../widgets/category_form_sheet.dart';
import '../widgets/category_list_skeleton.dart';

/// Screen for managing document categories.
///
/// Accessible from the Documents overflow menu. Displays read-only system
/// categories and editable custom categories.
class DocumentCategoriesScreen extends ConsumerWidget {
  const DocumentCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return isIOS
        ? const _IOSCategoriesLayout()
        : const _AndroidCategoriesLayout();
  }
}

// ── iOS layout ────────────────────────────────────────────────────────────────

class _IOSCategoriesLayout extends ConsumerWidget {
  const _IOSCategoriesLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(documentCategoriesProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Categories'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _openCreate(context),
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async => ref.invalidate(documentCategoriesProvider),
            ),
            if (categoriesState.isLoading)
              const SliverFillRemaining(child: CategoryListSkeleton())
            else if (categoriesState.hasError)
              SliverFillRemaining(
                child: ErrorView(
                  message: "Couldn't load categories.",
                  onRetry: () => ref.invalidate(documentCategoriesProvider),
                ),
              )
            else
              SliverToBoxAdapter(
                child: _CategoryList(categories: categoriesState.value ?? []),
              ),
          ],
        ),
      ),
    );
  }

  void _openCreate(BuildContext context) => showCategoryFormSheet(context);
}

// ── Android layout ────────────────────────────────────────────────────────────

class _AndroidCategoriesLayout extends ConsumerWidget {
  const _AndroidCategoriesLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(documentCategoriesProvider);

    return Scaffold(
      backgroundColor: AuroraColors.paper,
      appBar: AppBar(
        title: Text('Categories', style: AuroraType.h3),
        backgroundColor: AuroraColors.paper,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AuroraColors.coral,
        foregroundColor: Colors.white,
        onPressed: () => showCategoryFormSheet(context),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(documentCategoriesProvider),
        child: categoriesState.when(
          loading: () => const CategoryListSkeleton(),
          error: (e, _) => ErrorView(
            message: "Couldn't load categories.",
            onRetry: () => ref.invalidate(documentCategoriesProvider),
          ),
          data: (categories) => _CategoryList(categories: categories),
        ),
      ),
    );
  }
}

// ── Category list ─────────────────────────────────────────────────────────────

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.categories});

  final List<DocumentCategory> categories;

  @override
  Widget build(BuildContext context) {
    final system = categories.where((c) => c.isSystem).toList();
    final custom = categories.where((c) => !c.isSystem).toList();

    return ListView(
      padding: const EdgeInsets.all(AuroraSpacing.screenPadH),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _SectionHeader(label: 'System'),
        ...system.map((cat) => _CategoryRow(category: cat)),
        const SizedBox(height: AuroraSpacing.space7),
        _SectionHeader(label: 'Custom'),
        if (custom.isEmpty) const _EmptyCustomCategories(),
        ...custom.map((cat) => _CategoryRow(category: cat)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AuroraSpacing.space3),
      child: Text(
        label.toUpperCase(),
        style: AuroraType.labelSm.copyWith(
          color: AuroraColors.inkSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyCustomCategories extends StatelessWidget {
  const _EmptyCustomCategories();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AuroraSpacing.space8),
      child: Column(
        children: [
          const Icon(
            Icons.folder_outlined,
            size: 48,
            color: AuroraColors.inkTertiary,
          ),
          const SizedBox(height: AuroraSpacing.space5),
          Text(
            'No custom categories yet',
            style: AuroraType.bodySm.copyWith(
              fontWeight: FontWeight.w600,
              color: AuroraColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AuroraSpacing.space1),
          Text(
            'Tap + to create your first custom category.',
            style: AuroraType.body.copyWith(color: AuroraColors.inkSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Category row ──────────────────────────────────────────────────────────────

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow({required this.category});

  final DocumentCategory category;

  static Color _fromHex(String hex) {
    final clean = hex.replaceFirst('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Padding(
      padding: const EdgeInsets.only(bottom: AuroraSpacing.space3),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          color: AuroraColors.paper,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border: Border.all(color: AuroraColors.inkBorder),
        ),
        child: Row(
          children: [
            const SizedBox(width: AuroraSpacing.space5),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _fromHex(category.color),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CategoryIcons.forKey(category.icon),
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AuroraSpacing.space5),
            Expanded(
              child: Text(
                category.name,
                style: AuroraType.body.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!category.isSystem) ...[
              if (isIOS) ...[
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AuroraSpacing.space3,
                  ),
                  onPressed: () => _openEdit(context),
                  child: const Icon(
                    CupertinoIcons.pencil,
                    size: 20,
                    color: AuroraColors.ink,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.only(
                    left: AuroraSpacing.space1,
                    right: AuroraSpacing.space5,
                  ),
                  onPressed: () => _confirmDelete(context, ref),
                  child: const Icon(
                    CupertinoIcons.trash,
                    size: 20,
                    color: AuroraColors.coral,
                  ),
                ),
              ] else ...[
                IconButton(
                  onPressed: () => _openEdit(context),
                  icon: const Icon(Icons.edit_outlined),
                  color: AuroraColors.ink,
                  iconSize: 20,
                ),
                IconButton(
                  onPressed: () => _confirmDelete(context, ref),
                  icon: const Icon(Icons.delete_outline),
                  color: AuroraColors.coral,
                  iconSize: 20,
                  padding: const EdgeInsets.only(right: AuroraSpacing.space5),
                ),
              ],
            ] else
              const SizedBox(width: AuroraSpacing.space5),
          ],
        ),
      ),
    );
  }

  void _openEdit(BuildContext context) =>
      showCategoryFormSheet(context, existing: category);

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    bool confirmed = false;

    if (isIOS) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Delete Category'),
          content: const Text(
            'Documents in this category will be moved to Uncategorized. Continue?',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                confirmed = true;
                Navigator.of(ctx).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Category'),
          content: const Text(
            'Documents in this category will be moved to Uncategorized. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                confirmed = true;
                Navigator.of(ctx).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: AuroraColors.coral,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }

    if (!confirmed) return;
    if (!context.mounted) return;

    try {
      await ref
          .read(documentCategoriesProvider.notifier)
          .deleteCategory(category.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete category. Please try again.'),
            backgroundColor: AuroraColors.coral,
          ),
        );
      }
    }
  }
}
