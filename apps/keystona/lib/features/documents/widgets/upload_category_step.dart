import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../models/document_category.dart';
import '../models/document_type.dart';
import '../providers/document_categories_provider.dart';
import '../providers/document_types_provider.dart';
import '../providers/document_upload_provider.dart';
import '../widgets/category_form_sheet.dart';

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
        Text('Choose a category', style: AuroraType.h3),
        const SizedBox(height: AuroraSpacing.space1),
        Text(
          'What kind of document is this?',
          style: AuroraType.body.copyWith(
            color: AuroraColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AuroraSpacing.space7),
        Expanded(
          child: categoriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (e, st) => Center(
              child: Text(
                'Could not load categories.',
                style: AuroraType.body.copyWith(
                  color: AuroraColors.inkSecondary,
                ),
              ),
            ),
            data: (categories) => ListView.separated(
              itemCount: categories.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AuroraSpacing.space1),
              itemBuilder: (context, i) => _CategoryTile(
                category: categories[i],
                isExpanded: _expandedCategoryId == categories[i].id,
                onSelect: (cat) {
                  setState(() {
                    _expandedCategoryId =
                        _expandedCategoryId == cat.id ? null : cat.id;
                  });
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
          color: AuroraColors.paper,
          borderRadius: AuroraRadius.md,
          border: Border.all(
            color: isExpanded ? color : AuroraColors.inkBorder,
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
              borderRadius: AuroraRadius.md,
              child: Padding(
                padding: const EdgeInsets.all(AuroraSpacing.space6),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: AuroraRadius.sm,
                      ),
                      child: Icon(
                        CategoryIcons.forKey(category.icon),
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AuroraSpacing.space5),
                    Expanded(
                      child: Text(
                        category.name,
                        style: AuroraType.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Only system categories have document types to expand into.
                    if (category.isSystem)
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AuroraColors.inkSecondary,
                      ),
                  ],
                ),
              ),
            ),
            if (isExpanded && category.isSystem) ...[
              const Divider(
                height: 1,
                indent: AuroraSpacing.space5,
                endIndent: AuroraSpacing.space5,
              ),
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
    if (sanitised.length != 6) return AuroraColors.ink;
    final value = int.tryParse('FF$sanitised', radix: 16);
    return value != null ? Color(value) : AuroraColors.ink;
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
        padding: EdgeInsets.all(AuroraSpacing.space5),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
                  horizontal: AuroraSpacing.space5,
                  vertical: AuroraSpacing.space1,
                ),
                title: Text(type.name, style: AuroraType.body),
                subtitle: type.description != null
                    ? Text(
                        type.description!,
                        style: AuroraType.bodySm.copyWith(
                          color: AuroraColors.inkSecondary,
                        ),
                      )
                    : null,
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AuroraColors.inkSecondary,
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
        AuroraSpacing.space5,
        AuroraSpacing.space1,
        AuroraSpacing.space5,
        AuroraSpacing.space3,
      ),
      child: TextButton(
        onPressed: onSkip,
        child: Text(
          'Skip — just use category',
          style: AuroraType.bodySm.copyWith(
            fontWeight: FontWeight.w600,
            color: AuroraColors.inkSecondary,
          ),
        ),
      ),
    );
  }
}
