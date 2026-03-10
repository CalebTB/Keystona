import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/project_journal_note.dart';

/// Card displaying a single project journal note.
///
/// Shows: title (bold, if present), content (plain text, max 4 lines),
/// date, and an optional phase badge when [phaseName] is provided.
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

  static final _dateFmt = DateFormat('EEEE, MMMM d');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date + phase badge row ───────────────────────────────────
            Row(
              children: [
                Text(
                  _dateFmt.format(note.noteDate),
                  style: AppTextStyles.caption,
                ),
                if (phaseName != null) ...[
                  const SizedBox(width: AppSizes.xs),
                  _PhaseBadge(name: phaseName!),
                ],
              ],
            ),
            // ── Title (if present) ───────────────────────────────────────
            if (note.title != null && note.title!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.xs),
              Text(
                note.title!,
                style: AppTextStyles.bodyMediumSemibold,
              ),
            ],
            // ── Content ──────────────────────────────────────────────────
            const SizedBox(height: AppSizes.xs),
            Text(
              note.content,
              style: AppTextStyles.bodyMedium,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
        color: AppColors.deepNavy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        name,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.deepNavy,
        ),
      ),
    );
  }
}
