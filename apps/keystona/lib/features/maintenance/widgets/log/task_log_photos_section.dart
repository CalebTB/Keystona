import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../models/task_log_draft.dart';
import '../shared/task_section_label.dart';
import 'task_photo_slot.dart';
import 'task_photo_tile.dart';

/// "Photos": a grid of four across. The first two photos are the before and
/// the after; empty slots (at least one) invite another.
class TaskLogPhotosSection extends StatelessWidget {
  const TaskLogPhotosSection({
    super.key,
    required this.photos,
    required this.onAdd,
    required this.onRemove,
  });

  final List<LogPhoto> photos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = a.of(AuroraSpacing.space3);
    final columns = AuroraTasksB.photoColumns;
    final slots = photos.length < AuroraTasksB.photoMinSlots
        ? AuroraTasksB.photoMinSlots
        : photos.length + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TaskSectionLabel(
          title: 'Photos',
          trailing: Text(
            'Before & after help at resale'.toUpperCase(),
            textAlign: TextAlign.right,
            style: AuroraType.meta.copyWith(color: AuroraColors.inkSecondary),
          ),
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        LayoutBuilder(
          builder: (context, constraints) {
            final side = (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var i = 0; i < slots; i++)
                  SizedBox.square(
                    dimension: side,
                    child: i < photos.length
                        ? TaskPhotoTile(
                            path: photos[i].path,
                            badge: TaskPhotoBadge.forIndex(i),
                            onRemove: () => onRemove(i),
                          )
                        : TaskPhotoSlot(onTap: onAdd),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
