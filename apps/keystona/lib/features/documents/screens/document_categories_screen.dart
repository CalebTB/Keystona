import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_docs_a.dart';
import '../../../core/theme/aurora_motion.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_sizes.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/aurora/aurora_pressable.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../../core/widgets/upgrade_sheet.dart';
import '../../../services/providers/service_providers.dart';
import '../categories_copy.dart';
import '../models/category_icons.dart';
import '../models/category_lists.dart';
import '../models/document_category.dart';
import '../providers/docs_tab_provider.dart';
import '../providers/document_categories_provider.dart';
import '../providers/documents_provider.dart';
import '../widgets/category_form_sheet.dart' show CategoryFormSheet;
import '../widgets/categories/categories_skeleton.dart';
import '../widgets/categories/category_add_section.dart';
import '../widgets/categories/category_list_card.dart';
import '../widgets/categories/premium_badge.dart';
import '../widgets/categories/standard_categories_card.dart';
import '../widgets/docs_scroll_page.dart';

/// "Your categories" (kit: DocCategories): make, rename, reorder and delete
/// custom document categories. Deleting never deletes documents; they move to
/// a standard category.
class DocumentCategoriesScreen extends ConsumerStatefulWidget {
  const DocumentCategoriesScreen({super.key});

  @override
  ConsumerState<DocumentCategoriesScreen> createState() =>
      _DocumentCategoriesScreenState();
}

class _DocumentCategoriesScreenState
    extends ConsumerState<DocumentCategoriesScreen> {
  final TextEditingController _name = TextEditingController();
  String _icon = CategoryIcons.defaultKey;

  /// The category whose delete panel is open, and where its documents go.
  String? _confirmingId;
  String? _moveToId;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _hasName => _name.text.trim().isNotEmpty;

  /// Other views show category names and counts; they refetch after a change.
  void _refreshDocumentViews() {
    ref.invalidate(documentCategoryCountsProvider);
    ref.invalidate(docsTabProvider);
    ref.invalidate(documentsProvider);
  }

  Future<void> _refresh() async {
    ref.invalidate(documentCategoriesProvider);
    ref.invalidate(documentCategoryCountsProvider);
    try {
      await ref.read(documentCategoriesProvider.future);
    } catch (_) {
      // The error state is shown by build().
    }
  }

  void _back() =>
      context.canPop() ? context.pop() : context.go(AppRoutes.documents);

  Future<void> _add(CategoryLists lists) async {
    if (!ref.read(isPremiumProvider)) {
      await UpgradeSheet.show(context, config: CategoriesCopy.premiumSheet);
      return;
    }
    final name = _name.text.trim();
    if (name.isEmpty || !lists.canAddMore) return;
    final notifier = ref.read(documentCategoriesProvider.notifier);
    try {
      await notifier.create(name: name, icon: _icon);
      if (!mounted) return;
      setState(_name.clear);
    } catch (_) {
      if (mounted) SnackbarService.showError(context, CategoriesCopy.addFailed);
    }
  }

  void _toggleDelete(DocumentCategory category, CategoryLists lists) {
    setState(() {
      final open = _confirmingId == category.id;
      _confirmingId = open ? null : category.id;
      _moveToId = lists.defaultMoveTarget?.id;
    });
  }

  Future<void> _confirmDelete(DocumentCategory category) async {
    final notifier = ref.read(documentCategoriesProvider.notifier);
    final moveToId = _moveToId;
    setState(() => _confirmingId = null);
    try {
      final deleted = await notifier.deleteCategory(
        category.id,
        moveToId: moveToId,
      );
      _refreshDocumentViews();
      if (!mounted) return;
      SnackbarService.showUndo(
        context,
        message: CategoriesCopy.deleted,
        subtitle: category.name,
        duration: AuroraDurations.undoDelete,
        onUndo: () async {
          try {
            await notifier.restoreCategory(deleted);
            _refreshDocumentViews();
          } catch (_) {
            // The screen may have closed; the next refresh shows the truth.
          }
        },
      );
    } catch (_) {
      if (mounted) {
        SnackbarService.showError(context, CategoriesCopy.deleteFailed);
      }
    }
  }

  Future<void> _edit(DocumentCategory category) {
    final notifier = ref.read(documentCategoriesProvider.notifier);
    return CategoryFormSheet.show(
      context,
      category: category,
      onSave: (name, icon) async {
        await notifier.updateCategory(
          category.id,
          name: name,
          icon: icon,
          color: category.color,
        );
        _refreshDocumentViews();
      },
    );
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    final notifier = ref.read(documentCategoriesProvider.notifier);
    try {
      await notifier.reorderCustom(oldIndex, newIndex);
    } catch (_) {
      if (mounted) {
        SnackbarService.showError(context, CategoriesCopy.reorderFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(documentCategoriesProvider);
    final data = categories.value;

    return Scaffold(
      backgroundColor: AuroraColors.paper,
      body: DocsScrollPage(
        onRefresh: _refresh,
        topPadding: AuroraSpacing.screenPadTop,
        fillRemaining: data == null,
        child: data != null
            ? _body(context, CategoryLists(data))
            : categories.hasError
            ? ErrorView(
                message: CategoriesCopy.loadError,
                onRetry: () => ref.invalidate(documentCategoriesProvider),
              )
            : const CategoriesSkeleton(),
      ),
    );
  }

  Widget _body(BuildContext context, CategoryLists lists) {
    final a = context.aurora;
    final isPremium = ref.watch(isPremiumProvider);
    final counts = ref.watch(documentCategoryCountsProvider).value ?? const {};
    final gap = SizedBox(height: a.of(AuroraSpacing.space9));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BackLink(onTap: _back),
        SizedBox(height: a.of(AuroraSpacing.space1)),
        const _Header(),
        SizedBox(height: a.of(AuroraSpacing.space6)),
        Text(CategoriesCopy.intro, style: AuroraDocsAType.intro),
        gap,
        Text(
          CategoriesCopy.yours(lists.custom.length, CategoryLists.maxCustom),
          style: AuroraType.label,
        ),
        if (lists.custom.isNotEmpty) ...[
          SizedBox(height: a.of(AuroraSpacing.space3)),
          CategoryListCard(
            categories: lists.custom,
            counts: counts,
            confirmingId: _confirmingId,
            moveTargets: [
              for (final c in lists.moveTargets) (id: c.id, name: c.name),
            ],
            selectedMoveId: _moveToId,
            onReorder: _reorder,
            onEdit: _edit,
            onDelete: (c) => _toggleDelete(c, lists),
            onPickMove: (id) => setState(() => _moveToId = id),
            onKeep: () => setState(() => _confirmingId = null),
            onConfirmDelete: _confirmDelete,
          ),
        ],
        gap,
        CategoryAddSection(
          controller: _name,
          icon: _icon,
          canAdd: !isPremium || (_hasName && lists.canAddMore),
          onNameChanged: (_) => setState(() {}),
          onIconSelected: (key) => setState(() => _icon = key),
          onAdd: () => _add(lists),
        ),
        gap,
        StandardCategoriesCard(names: [for (final c in lists.standard) c.name]),
      ],
    );
  }
}

class _BackLink extends StatelessWidget {
  const _BackLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Align(
      alignment: Alignment.centerLeft,
      child: AuroraPressable(
        onTap: onTap,
        semanticLabel: CategoriesCopy.back,
        enforceTouchTarget: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chevron_left,
              size: a.of(AuroraIconSizes.xl),
              color: AuroraColors.ink,
            ),
            Flexible(
              child: Text(
                CategoriesCopy.back,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AuroraDocsAType.back,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: a.of(AuroraSpacing.space2),
          runSpacing: a.of(AuroraSpacing.space1),
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(CategoriesCopy.eyebrow, style: AuroraType.label),
            const PremiumBadge(),
          ],
        ),
        SizedBox(height: a.of(AuroraSpacing.space2)),
        Text(CategoriesCopy.title, style: AuroraDocsAType.pageTitle),
      ],
    );
  }
}
