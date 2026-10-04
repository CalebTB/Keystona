import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/theme/aurora_spacing.dart';

import '../models/project_journal_note.dart';
import '../../../core/theme/aurora_radius.dart';

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
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.md,
        border: Border.all(color: AuroraColors.inkBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0 - 1),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AuroraSpacing.space7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                          // Title
                          if (_hasTitle) ...[
                            Text(
                              note.title!,
                              style: AuroraType.h3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AuroraSpacing.space1),
                          ],

                          // Content preview
                          Text(
                            note.content,
                            style: _hasTitle
                                ? AuroraType.bodySm.copyWith(
                                    color: AuroraColors.inkSecondary,
                                  )
                                : AuroraType.body.copyWith(
                                    color: AuroraColors.ink,
                                  ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Footer: date + phase badge
                          const SizedBox(height: AuroraSpacing.space3),
                          Row(
                            children: [
                              Text(
                                _dateFmt.format(note.noteDate),
                                style: AuroraType.bodySm.copyWith(
                                  color: AuroraColors.inkSecondary,
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
        horizontal: AuroraSpacing.space3,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AuroraColors.cobaltDim,
        borderRadius: AuroraRadius.full,
      ),
      child: Text(
        name,
        style: AuroraType.label.copyWith(
          color: AuroraColors.cobalt,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
