import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/maintenance_task.dart';

/// "Coming this week" peek section below the tip card.
///
/// Shows up to 5 upcoming tasks with date, category dot, and name.
/// Returns [SizedBox.shrink] when [tasks] is empty.
class UpcomingPeek extends StatelessWidget {
  const UpcomingPeek({super.key, required this.tasks});

  final List<MaintenanceTask> tasks;

  static final _dateFmt = DateFormat('MMM d');

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    final shown = tasks.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMING THIS WEEK',
          style: AppTextStyles.monoSection,
        ),
        const SizedBox(height: 10),
        ...shown.asMap().entries.map((entry) {
          final i = entry.key;
          final task = entry.value;
          return Column(
            children: [
              if (i > 0)
                const Divider(
                  color: AppColors.warmFill,
                  height: 1,
                  thickness: 1,
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(
                        _dateFmt.format(task.dueDate.toLocal()),
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _categoryColor(task.category.toLowerCase()),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.name,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  static Color _categoryColor(String cat) {
    if (cat == 'hvac' || cat == 'heating' || cat == 'cooling') {
      return AppColors.slate;
    } else if (cat == 'plumbing' || cat == 'water') {
      return AppColors.teal;
    } else if (cat == 'electrical') {
      return AppColors.sand;
    } else if (cat == 'safety' || cat == 'security') {
      return AppColors.sandAmber;
    } else if (cat == 'exterior' || cat == 'roofing' || cat == 'landscaping') {
      return AppColors.olive;
    } else if (cat == 'interior' || cat == 'kitchen' || cat == 'bathroom') {
      return AppColors.plum;
    }
    return AppColors.textSecondary;
  }
}
