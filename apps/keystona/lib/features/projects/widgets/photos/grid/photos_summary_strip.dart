import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_text_styles.dart';

// accent: #B85638
const Color _kAccent = Color(0xFFB85638);

/// 3-cell summary strip: Pairs | Unpaired | Latest.
///
/// Hidden when [total] < 3.
class PhotosSummaryStrip extends StatelessWidget {
  const PhotosSummaryStrip({
    super.key,
    required this.pairCount,
    required this.unpairedCount,
    required this.latestDate,
    required this.total,
  });

  final int pairCount;
  final int unpairedCount;
  final DateTime? latestDate;
  final int total;

  String _latestLabel() {
    if (latestDate == null) return '—';
    final now = DateTime.now();
    final diff = now.difference(latestDate!).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 30) return '${diff}d ago';
    final months = (diff / 30).floor();
    if (months < 12) return '${months}mo ago';
    return '${(months / 12).floor()}y ago';
  }

  @override
  Widget build(BuildContext context) {
    if (total < 3) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      child: Row(
        children: [
          _Cell(label: 'Pairs', value: '$pairCount'),
          const SizedBox(width: AppSizes.xs),
          _Cell(
            label: 'Unpaired',
            value: '$unpairedCount',
            valueColor: unpairedCount > 0 ? _kAccent : null,
          ),
          const SizedBox(width: AppSizes.xs),
          _Cell(label: 'Latest', value: _latestLabel()),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm + 1,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 9,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTextStyles.labelMedium.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
