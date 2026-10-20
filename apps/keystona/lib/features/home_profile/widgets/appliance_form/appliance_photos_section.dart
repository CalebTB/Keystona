import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_c.dart';
import '../../../../core/theme/aurora_home_shared.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_form_section.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../appliance_copy.dart';
import '../../models/form_photo.dart';
import '../shared/dashed_border.dart';
import '../shared/item_photo_tile.dart';

/// PHOTOS (optional): the label photo from the scan, the ones added so far
/// and dashed "+" slots up to [slots]. Tapping a photo opens [onOpen].
class AppliancePhotosSection extends StatelessWidget {
  const AppliancePhotosSection({
    super.key,
    required this.photos,
    required this.slots,
    required this.note,
    required this.onAdd,
    required this.onOpen,
  });

  final List<FormPhoto> photos;

  /// How many tiles to draw (filled and empty).
  final int slots;

  /// "FREE PLAN · 4 PHOTOS · THE LABEL PHOTO IS SAVED FOR YOU".
  final String note;
  final VoidCallback onAdd;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = a.of(AuroraSpacing.space3);
    return AuroraFormSection(
      title: ApplianceCopy.photos,
      isOptional: true,
      children: [
        GridView.count(
          crossAxisCount: AuroraHomeCSizes.photoColumns,
          mainAxisSpacing: gap,
          crossAxisSpacing: gap,
          childAspectRatio: AuroraHomeSizes.tileAspect,
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < slots; i++)
              if (i < photos.length)
                ItemPhotoTile(
                  key: ValueKey(photos[i].file.path),
                  tag: photos[i].type.tag,
                  aspectRatio: AuroraHomeSizes.tileAspect,
                  image: Image.file(
                    File(photos[i].file.path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                  onTap: () => onOpen(i),
                )
              else
                _EmptySlot(onTap: onAdd),
          ],
        ),
        Text(
          note,
          style: AuroraType.meta.copyWith(color: AuroraColors.inkHelper),
        ),
      ],
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: ApplianceCopy.addPhotoSemantics,
      child: DashedBorder(
        borderRadius: AuroraRadius.lg,
        child: Center(
          child: Icon(
            Icons.add,
            size: a.of(AuroraIconSizes.md),
            color: AuroraColors.inkSecondary,
          ),
        ),
      ),
    );
  }
}
