import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/document_category.dart';
import '../models/document_type.dart';
import '../providers/document_categories_provider.dart';
import '../providers/document_types_provider.dart';
import '../providers/document_upload_provider.dart';

/// Step 1 of the upload wizard — category and optional document type selection.
///
/// Shows a scrollable list of [DocumentCategory] tiles. After selecting a
/// category, document types for that category expand inline. Tapping a type
/// (or tapping "Skip" on the type list) advances to step 2.
class UploadCategoryStep extends ConsumerStatefulWidget {
  const UploadCategoryStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  ConsumerState<UploadCategoryStep> createState() =>
      _UploadCategoryStepState();
}

class _UploadCategoryStepState extends ConsumerState<UploadCategoryStep> {
  String? _expandedCategoryId;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync =
        ref.watch(documentCategoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Choose a category', style: AppTextStyles.h3),
        const SizedBox(height: AppSizes.xs),
        Text(
          'What kind of document is this?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        Expanded(
          child: categoriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(
              child: Text(
                'Could not load categories.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            data: (categories) => ListView.separated(
              itemCount: categories.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSizes.xs),
              itemBuilder: (context, i) => _CategoryTile(
                category: categories[i],
                isExpanded: _expandedCategoryId == categories[i].id,
                onSelect: (cat) {
                  setState(() {
                    _expandedCategoryId =
                        _expandedCategoryId == cat.id ? null : cat.id;
                  });
                  // Select category; document type will be picked from
                  // the expanded sub-list or skipped.
                  ref
                      .read(documentUploadProvider.notifier)
                      .selectCategory(cat.id);
                },
                onTypeSelected: (cat, type) {
                  ref
                      .read(documentUploadProvider.notifier)
                      .selectCategory(cat.id, documentTypeId: type.id);
                  ref
                      .read(documentUploadProvider.notifier)
                      .advanceToMetadata();
                  widget.onNext();
                },
                onSkipType: (cat) {
                  ref
                      .read(documentUploadProvider.notifier)
                      .selectCategory(cat.id);
                  ref
                      .read(documentUploadProvider.notifier)
                      .advanceToMetadata();
                  widget.onNext();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Category tile ─────────────────────────────────────────────────────────────

class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({
    required this.category,
    required this.isExpanded,
    required this.onSelect,
    required this.onTypeSelected,
    required this.onSkipType,
  });

  final DocumentCategory category;
  final bool isExpanded;
  final ValueChanged<DocumentCategory> onSelect;
  final void Function(DocumentCategory, DocumentType) onTypeSelected;
  final ValueChanged<DocumentCategory> onSkipType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _parseColor(category.color);

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.md,
          border: Border.all(
            color: isExpanded ? color : AppColors.border,
            width: isExpanded ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              // Custom categories have no document types — tap goes straight
              // to the next step without expanding.
              onTap: () => category.isSystem
                  ? onSelect(category)
                  : onSkipType(category),
              borderRadius: AppRadius.md,
              child: Padding(
                padding: AppPadding.card,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: AppRadius.sm,
                      ),
                      child: Icon(
                        _categoryIcon(category.icon),
                        color: color,
                        size: AppSizes.iconMd,
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Text(
                        category.name,
                        style: AppTextStyles.bodyMediumSemibold,
                      ),
                    ),
                    // Only system categories have document types to expand into.
                    if (category.isSystem)
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                      ),
                  ],
                ),
              ),
            ),
            if (isExpanded && category.isSystem) ...[
              const Divider(height: 1, indent: AppSizes.md, endIndent: AppSizes.md),
              _TypeList(
                category: category,
                onTypeSelected: onTypeSelected,
                onSkip: onSkipType,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    final sanitised = hex.replaceAll('#', '');
    if (sanitised.length != 6) return AppColors.deepNavy;
    final value = int.tryParse('FF$sanitised', radix: 16);
    return value != null ? Color(value) : AppColors.deepNavy;
  }

  IconData _categoryIcon(String icon) {
    switch (icon) {
      case 'insurance':
        return Icons.shield_outlined;
      case 'warranty':
        return Icons.workspace_premium_outlined;
      case 'deed':
        return Icons.home_work_outlined;
      case 'tax':
        return Icons.receipt_long_outlined;
      case 'permit':
        return Icons.approval_outlined;
      case 'manual':
        return Icons.menu_book_outlined;
      case 'invoice':
        return Icons.receipt_outlined;
      case 'contract':
        return Icons.handshake_outlined;
      default:
        return Icons.folder_outlined;
    }
  }
}

// ── Document type sub-list ────────────────────────────────────────────────────

class _TypeList extends ConsumerWidget {
  const _TypeList({
    required this.category,
    required this.onTypeSelected,
    required this.onSkip,
  });

  final DocumentCategory category;
  final void Function(DocumentCategory, DocumentType) onTypeSelected;
  final ValueChanged<DocumentCategory> onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(documentTypesProvider(category.id));

    return typesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSizes.md),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => _SkipRow(onSkip: () => onSkip(category)),
      data: (types) {
        if (types.isEmpty) {
          // No types for this category — advance immediately.
          WidgetsBinding.instance.addPostFrameCallback(
            (ts) => onSkip(category),
          );
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...types.map(
              (type) => ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.xs,
                ),
                title: Text(type.name, style: AppTextStyles.bodyMedium),
                subtitle: type.description != null
                    ? Text(
                        type.description!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      )
                    : null,
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                onTap: () => onTypeSelected(category, type),
              ),
            ),
            _SkipRow(onSkip: () => onSkip(category)),
          ],
        );
      },
    );
  }
}

class _SkipRow extends StatelessWidget {
  const _SkipRow({required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.xs,
        AppSizes.md,
        AppSizes.sm,
      ),
      child: TextButton(
        onPressed: onSkip,
        child: Text(
          'Skip — just use category',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
