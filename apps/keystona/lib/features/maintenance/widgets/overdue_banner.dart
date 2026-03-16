import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/maintenance_task.dart';

/// Overdue tasks banner displayed below the day header when overdue tasks exist.
///
/// Shows count, first 3 task names, and a chevron. Tapping is a no-op for now.
class OverdueBanner extends StatelessWidget {
  const OverdueBanner({super.key, required this.overdueTasks});

  final List<MaintenanceTask> overdueTasks;

  @override
  Widget build(BuildContext context) {
    if (overdueTasks.isEmpty) return const SizedBox.shrink();

    final count = overdueTasks.length;
    final title = '$count task${count > 1 ? 's' : ''} overdue';
    final names = overdueTasks
        .take(3)
        .map((t) => t.name)
        .join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentDim,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FB85638), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (names.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    names,
                    style: AppTextStyles.monoLabel.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }
}
