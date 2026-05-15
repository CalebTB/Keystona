import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// Filter chip row for the contractors ledger.
///
/// Chips: All | Outstanding | Paid | Rated
/// Active chip highlights with [AppColors.deepNavy].
/// Tapping the active chip clears the filter (returns null).
class LedgerFilterChips extends StatelessWidget {
  const LedgerFilterChips({
    super.key,
    required this.activeFilter,
    required this.onChanged,
  });

  final String? activeFilter;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      child: Row(
        children: [
          _Chip(
            label: 'All',
            selected: activeFilter == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: AppSizes.xs),
          _Chip(
            label: 'Outstanding',
            selected: activeFilter == 'outstanding',
            onTap: () => onChanged(
              activeFilter == 'outstanding' ? null : 'outstanding',
            ),
          ),
          const SizedBox(width: AppSizes.xs),
          _Chip(
            label: 'Paid',
            selected: activeFilter == 'paid',
            onTap: () => onChanged(
              activeFilter == 'paid' ? null : 'paid',
            ),
          ),
          const SizedBox(width: AppSizes.xs),
          _Chip(
            label: 'Rated',
            selected: activeFilter == 'rated',
            onTap: () => onChanged(
              activeFilter == 'rated' ? null : 'rated',
            ),
          ),
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
