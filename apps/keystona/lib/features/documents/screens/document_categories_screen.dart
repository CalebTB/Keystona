import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../models/document_category.dart';
import '../providers/document_categories_provider.dart';
import '../widgets/category_form_sheet.dart';
import '../widgets/category_list_skeleton.dart';

/// Screen for managing document categories.
///
/// Accessible from the Documents overflow menu. Displays read-only system
/// categories and editable custom categories. Users can create, rename,
/// recolor, and delete custom categories from this screen.
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

  void _openCreate(BuildContext context) =>
      showCategoryFormSheet(context);
}

// ── Android layout ────────────────────────────────────────────────────────────

class _AndroidCategoriesLayout extends ConsumerWidget {
  const _AndroidCategoriesLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(documentCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      appBar: AppBar(
        title: Text('Categories', style: AppTextStyles.h3),
        backgroundColor: AppColors.warmOffWhite,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.deepNavy,
        foregroundColor: AppColors.textInverse,
        onPressed: () => showCategoryFormSheet(context),
        child: const Icon(Icons.add),
      ),
      body: categoriesState.when(
        loading: () => const CategoryListSkeleton(),
        error: (e, _) => ErrorView(
          message: "Couldn't load categories.",
          onRetry: () => ref.invalidate(documentCategoriesProvider),
        ),
        data: (categories) => _CategoryList(categories: categories),
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
      padding: AppPadding.screen,
      children: [
        // ── System categories (read-only) ──────────────────────────────────
        _SectionHeader(label: 'System'),
        ...system.map((cat) => _CategoryRow(category: cat)),

        const SizedBox(height: AppSizes.lg),

        // ── Custom categories ──────────────────────────────────────────────
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
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
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
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xl),
      child: Column(
        children: [
          const Icon(
            Icons.folder_outlined,
            size: AppSizes.iconXl,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'No custom categories yet',
            style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Tap + to create your first custom category.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
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
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Container(
        height: AppSizes.cardMinHeight,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const SizedBox(width: AppSizes.md),

            // Color dot with icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _fromHex(category.color),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CategoryIcons.forKey(category.icon),
                size: AppSizes.iconSm,
                color: Colors.white,
              ),
            ),

            const SizedBox(width: AppSizes.md),

            // Category name
            Expanded(
              child: Text(
                category.name,
                style: AppTextStyles.bodyMediumSemibold,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Action buttons (custom categories only)
            if (!category.isSystem) ...[
              if (isIOS) ...[
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                  onPressed: () => _openEdit(context),
                  child: const Icon(
                    CupertinoIcons.pencil,
                    size: AppSizes.iconMd,
                    color: AppColors.deepNavy,
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.only(
                    left: AppSizes.xs,
                    right: AppSizes.md,
                  ),
                  onPressed: () => _confirmDelete(context, ref),
                  child: const Icon(
                    CupertinoIcons.trash,
                    size: AppSizes.iconMd,
                    color: AppColors.error,
                  ),
                ),
              ] else ...[
                IconButton(
                  onPressed: () => _openEdit(context),
                  icon: const Icon(Icons.edit_outlined),
                  color: AppColors.deepNavy,
                  iconSize: AppSizes.iconMd,
                ),
                IconButton(
                  onPressed: () => _confirmDelete(context, ref),
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.error,
                  iconSize: AppSizes.iconMd,
                  padding: const EdgeInsets.only(right: AppSizes.md),
                ),
              ],
            ] else
              const SizedBox(width: AppSizes.md),
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
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
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
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
