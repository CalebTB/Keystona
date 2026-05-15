import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../models/project_document_link.dart';
import '../shared/document_link_type.dart';

/// Horizontal scrolling filter chips for the documents vault list.
///
/// Shows "All" plus one chip per link type that has at least one document.
/// [activeFilter] = null means all are shown.
class DocumentsListFilterChips extends StatelessWidget {
  const DocumentsListFilterChips({
    super.key,
    required this.links,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  final List<ProjectDocumentLink> links;
  final DocumentLinkType? activeFilter;
  final ValueChanged<DocumentLinkType?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    // Determine which types are present in the list (ordered by spec)
    final presentTypes = DocumentLinkType.values
        .where((t) => links.any((l) => l.linkType == t.name))
        .toList();

    if (presentTypes.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: [
          _Chip(
            label: 'All',
            selected: activeFilter == null,
            onTap: () => onFilterChanged(null),
          ),
          for (final type in presentTypes) ...[
            const SizedBox(width: 6),
            _Chip(
              label: type.pluralName,
              selected: activeFilter == type,
              onTap: () => onFilterChanged(
                activeFilter == type ? null : type,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.deepNavy : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: selected ? AppColors.deepNavy : AppColors.gray300,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
