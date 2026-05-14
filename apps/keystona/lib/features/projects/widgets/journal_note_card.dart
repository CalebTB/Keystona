import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/project_journal_note.dart';

/// Card displaying a single project journal note.
///
/// Layout: 4px sand left strip, title (when present) in bold at the top,
/// content preview below, footer row with short date and optional phase badge.
class JournalNoteCard extends StatelessWidget {
  const JournalNoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.phaseName,
  });

  final ProjectJournalNote note;
  final VoidCallback onTap;
  final String? phaseName;

  static final _dateFmt = DateFormat('EEE, MMM d');

  bool get _hasTitle => note.title != null && note.title!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd - 1),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Sand accent strip ────────────────────────────────────
                  Container(width: 4, color: AppColors.sand),

                  // ── Content ──────────────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.md),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          if (_hasTitle) ...[
                            Text(
                              note.title!,
                              style: AppTextStyles.bodyMediumSemibold,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSizes.xs),
                          ],

                          // Content preview
                          Text(
                            note.content,
                            style: _hasTitle
                                ? AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  )
                                : AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Footer: date + phase badge
                          const SizedBox(height: AppSizes.sm),
                          Row(
                            children: [
                              Text(
                                _dateFmt.format(note.noteDate),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (phaseName != null) ...[
                                const Spacer(),
                                _PhaseBadge(name: phaseName!),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhaseBadge extends StatelessWidget {
  const _PhaseBadge({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.slateDim,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        name,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.slate,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
