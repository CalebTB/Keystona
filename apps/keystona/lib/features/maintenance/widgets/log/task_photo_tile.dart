import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../models/completion_photo.dart';

/// A picked photo in the grid, with its Before / After badge and a remove
/// control. Fills the square its parent gives it.
class TaskPhotoTile extends StatelessWidget {
  const TaskPhotoTile({
    super.key,
    required this.path,
    required this.onRemove,
    this.kind,
  });

  /// Local file path of the picked photo.
  final String path;
  final PhotoKind? kind;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: AuroraRadius.md,
          child: Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(
              color: AuroraColors.inkBorder,
              child: Icon(
                Icons.image_outlined,
                color: AuroraColors.inkSecondary,
              ),
            ),
          ),
        ),
        if (kind != null)
          Positioned(
            left: a.of(AuroraSpacing.space1),
            bottom: a.of(AuroraSpacing.space1),
            child: _Badge(kind: kind!),
          ),
        Positioned(
          top: 0,
          right: 0,
          child: AuroraPressable(
            onTap: onRemove,
            semanticLabel: 'Remove photo',
            enforceTouchTarget: true,
            child: Container(
              padding: a.all(AuroraSpacing.space1),
              decoration: const BoxDecoration(
                color: AuroraColors.paper,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: a.of(AuroraTasksB.photoRemoveGlyph),
                color: AuroraColors.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.kind});

  final PhotoKind kind;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final after = kind == PhotoKind.after;
    final fg = after ? AuroraColors.olive : AuroraColors.inkBody;
    return Container(
      padding: a.symmetric(
        horizontal: AuroraSpacing.space1,
        vertical: AuroraTasksB.hairlineGap,
      ),
      decoration: BoxDecoration(
        color: after ? AuroraColors.lime : AuroraColors.paper,
        borderRadius: AuroraRadius.full,
        border: after
            ? null
            : Border.all(
                color: AuroraColors.inkBorderStrong,
                width: AuroraBorders.regular,
              ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            after ? Icons.check : Icons.radio_button_unchecked,
            size: a.of(AuroraSharedSizes.pillCheck),
            color: fg,
          ),
          SizedBox(width: a.of(AuroraSpacing.space1)),
          Text(
            (after ? 'After' : 'Before').toUpperCase(),
            style: AuroraTasksBType.photoBadge.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
