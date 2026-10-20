import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_b.dart';
import '../../../../core/theme/aurora_home_shared.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_form_section.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../forms/form_photo.dart';
import '../../systems_copy.dart';
import '../shared/dashed_border.dart';
import '../shared/item_photo_tile.dart';

/// PHOTOS: the label picture (when scanned), the photos added so far and an
/// add slot, four to a row, with the plan caption under them.
class SystemPhotosSection extends StatelessWidget {
  const SystemPhotosSection({
    super.key,
    required this.photos,
    required this.premium,
    required this.onAdd,
    required this.onPhotoTap,
  });

  final List<FormPhoto> photos;
  final bool premium;
  final VoidCallback onAdd;
  final ValueChanged<FormPhoto> onPhotoTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    const columns = AuroraHomeBSizes.photoColumns;
    final slots = photos.length + 1 < columns ? columns : photos.length + 1;
    final rows = (slots / columns).ceil();
    final gap = SizedBox(width: a.of(AuroraSpacing.space3));
    return AuroraFormSection(
      title: SystemsCopy.sectionPhotos,
      isOptional: true,
      children: [
        Column(
          children: [
            for (var r = 0; r < rows; r++) ...[
              if (r > 0) SizedBox(height: a.of(AuroraSpacing.space3)),
              Row(
                children: [
                  for (var c = 0; c < columns; c++) ...[
                    if (c > 0) gap,
                    Expanded(child: _slot(r * columns + c)),
                  ],
                ],
              ),
            ],
          ],
        ),
        Text(
          premium
              ? SystemsCopy.photosCaptionPremium
              : SystemsCopy.photosCaptionFree,
          style: AuroraType.helper,
        ),
      ],
    );
  }

  Widget _slot(int index) {
    if (index < photos.length) {
      final photo = photos[index];
      return ItemPhotoTile(
        aspectRatio: AuroraHomeSizes.tileAspect,
        tag: photo.isLabel ? SystemsCopy.labelTag : null,
        image: Image.file(
          File(photo.file.path),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        onTap: photo.isLabel ? null : () => onPhotoTap(photo),
      );
    }
    if (index == photos.length) return _AddSlot(onTap: onAdd);
    return const SizedBox.shrink();
  }
}

class _AddSlot extends StatelessWidget {
  const _AddSlot({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: SystemsCopy.addPhoto,
      enforceTouchTarget: true,
      child: AspectRatio(
        aspectRatio: AuroraHomeSizes.tileAspect,
        child: DashedBorder(
          borderRadius: AuroraRadius.md,
          child: Center(
            child: Icon(
              Icons.add,
              size: a.of(AuroraHomeBSizes.photoAddGlyph),
              color: AuroraColors.inkTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
