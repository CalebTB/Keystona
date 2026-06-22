import 'package:flutter/material.dart';
import '../../../../../core/theme/aurora_colors.dart';
import '../../../../../core/theme/aurora_typography.dart';
import '../../../../../core/theme/aurora_spacing.dart';


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
        horizontal: AuroraSpacing.space7,
        vertical: AuroraSpacing.space1,
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
          horizontal: AuroraSpacing.space7,
          vertical: AuroraSpacing.space1 + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? AuroraColors.ink : AuroraColors.paper,
          borderRadius: BorderRadius.circular(999.0),
          border: Border.all(
            color: selected ? AuroraColors.ink : AuroraColors.inkBorder,
          ),
        ),
        child: Text(
          label,
          style: AuroraType.label.copyWith(
            color: selected ? Colors.white : AuroraColors.inkSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
