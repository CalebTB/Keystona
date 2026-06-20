import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_sizes.dart';

/// 3-segment pill toggle: Pairs | All | Unpaired.
///
/// [activeSegment] must be one of: 'pairs', 'all', 'unpaired'.
class PhotosViewToggle extends StatelessWidget {
  const PhotosViewToggle({
    super.key,
    required this.pairCount,
    required this.allCount,
    required this.unpairedCount,
    required this.activeSegment,
    required this.onSegmentChanged,
  });

  final int pairCount;
  final int allCount;
  final int unpairedCount;
  final String activeSegment;
  final ValueChanged<String> onSegmentChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(100),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            _Segment(
              label: 'Pairs',
              count: pairCount,
              active: activeSegment == 'pairs',
              onTap: () => onSegmentChanged('pairs'),
            ),
            _Segment(
              label: 'All',
              count: allCount,
              active: activeSegment == 'all',
              onTap: () => onSegmentChanged('all'),
            ),
            _Segment(
              label: 'Unpaired',
              count: unpairedCount,
              active: activeSegment == 'unpaired',
              onTap: () => onSegmentChanged('unpaired'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: active ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(97),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.deepNavy.withValues(alpha: 0.08),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.w500,
                  color: active
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  height: 1.2,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                '$count',
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
