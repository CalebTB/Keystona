import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/maintenance_task.dart';

/// A single task row in the agenda view for the selected day.
///
/// Shows time column (always "Anytime"), category icon, task name,
/// meta row, and a quick-complete tap circle.
class AgendaTaskCard extends StatelessWidget {
  const AgendaTaskCard({
    super.key,
    required this.task,
    required this.onQuickComplete,
  });

  final MaintenanceTask task;
  final VoidCallback onQuickComplete;

  @override
  Widget build(BuildContext context) {
    final categoryStyle = _categoryStyle(task.category.toLowerCase());

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D2A2420),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {}, // detail navigation handled by screen layer
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Time column ──────────────────────────────────────────────
              SizedBox(
                width: 56,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Any',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      Text(
                        'time',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Vertical divider ──────────────────────────────────────────
              Container(
                width: 1.5,
                height: 56,
                color: AppColors.warmFill,
              ),
              // ── Body ──────────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      // Category icon container
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: categoryStyle.bgColor,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          categoryStyle.icon,
                          size: 18,
                          color: categoryStyle.iconColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Info column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    task.category,
                                    style: AppTextStyles.monoLabel.copyWith(
                                      color: AppColors.textTertiary,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _DiyProBadge(diyOrPro: task.diyOrPro),
                                if (task.estimatedMinutes != null) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '~${task.estimatedMinutes}min',
                                    style: AppTextStyles.monoLabel.copyWith(
                                      color: AppColors.textTertiary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Quick-complete circle
                      GestureDetector(
                        onTap: onQuickComplete,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.border,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static _CategoryStyle _categoryStyle(String cat) {
    if (cat == 'hvac' || cat == 'heating' || cat == 'cooling') {
      return const _CategoryStyle(
        icon: Icons.air,
        iconColor: AppColors.slate,
        bgColor: AppColors.slateDim,
      );
    } else if (cat == 'plumbing' || cat == 'water') {
      return const _CategoryStyle(
        icon: Icons.water_drop_outlined,
        iconColor: AppColors.teal,
        bgColor: AppColors.tealDim,
      );
    } else if (cat == 'electrical') {
      return const _CategoryStyle(
        icon: Icons.bolt_outlined,
        iconColor: AppColors.sand,
        bgColor: AppColors.sandDim,
      );
    } else if (cat == 'safety' || cat == 'security') {
      return const _CategoryStyle(
        icon: Icons.security_outlined,
        iconColor: AppColors.sandAmber,
        bgColor: AppColors.sandDim,
      );
    } else if (cat == 'exterior' || cat == 'roofing' || cat == 'landscaping') {
      return const _CategoryStyle(
        icon: Icons.park_outlined,
        iconColor: AppColors.olive,
        bgColor: AppColors.oliveDim,
      );
    } else if (cat == 'interior' ||
        cat == 'kitchen' ||
        cat == 'bathroom') {
      return const _CategoryStyle(
        icon: Icons.home_outlined,
        iconColor: AppColors.plum,
        bgColor: AppColors.plumDim,
      );
    }
    return const _CategoryStyle(
      icon: Icons.build_outlined,
      iconColor: AppColors.textSecondary,
      bgColor: AppColors.warmFill,
    );
  }
}

// ── Category style record ──────────────────────────────────────────────────

class _CategoryStyle {
  const _CategoryStyle({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
}

// ── DIY/PRO badge ──────────────────────────────────────────────────────────

class _DiyProBadge extends StatelessWidget {
  const _DiyProBadge({required this.diyOrPro});

  final DiyOrPro diyOrPro;

  @override
  Widget build(BuildContext context) {
    final isPro = diyOrPro == DiyOrPro.professional;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: isPro ? AppColors.slateDim : AppColors.oliveDim,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isPro ? 'PRO' : 'DIY',
        style: GoogleFonts.ibmPlexMono(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: isPro ? AppColors.slate : AppColors.olive,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
