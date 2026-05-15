import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// Horizontally-scrollable type filter chip row for the photos curated grid.
///
/// Chips: All | Before | After | Progress | Inspiration | Issue
/// [activeFilter] = null means "All". Tapping an active chip deselects it.
class PhotosGridFilterChips extends StatelessWidget {
  const PhotosGridFilterChips({
    super.key,
    required this.activeFilter,
    required this.onChanged,
  });

  final String? activeFilter;
  final ValueChanged<String?> onChanged;

  static const _types = [
    (value: 'before',      label: 'Before'),
    (value: 'after',       label: 'After'),
    (value: 'progress',    label: 'Progress'),
    (value: 'inspiration', label: 'Inspiration'),
    (value: 'issue',       label: 'Issue'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs,
      ),
      child: Row(
        children: [
          _Chip(
            label: 'All',
            selected: activeFilter == null,
            onTap: () => onChanged(null),
          ),
          for (final t in _types) ...[
            const SizedBox(width: 6),
            _Chip(
              label: t.label,
              selected: activeFilter == t.value,
              onTap: () => onChanged(
                activeFilter == t.value ? null : t.value,
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
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.xs + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.deepNavy : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: selected ? AppColors.deepNavy : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
