import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_home_c.dart';
import '../../../../core/theme/aurora_home_shared.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../models/item_photo_type.dart';
import '../../models/item_photos_state.dart';
import '../shared/item_photo_tile.dart';
import 'item_photo_image.dart';

/// The four-up row of thumbnails under the viewer, each with its tag. The
/// chosen one is outlined in ink.
class ItemPhotoThumbs extends StatelessWidget {
  const ItemPhotoThumbs({
    super.key,
    required this.photos,
    required this.selected,
    required this.onSelect,
  });

  final ItemPhotos photos;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = a.of(AuroraSpacing.space3);
    return GridView.count(
      crossAxisCount: AuroraHomeCSizes.photoColumns,
      mainAxisSpacing: gap,
      crossAxisSpacing: gap,
      childAspectRatio: AuroraHomeSizes.tileAspect,
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < photos.count; i++)
          ItemPhotoTile(
            key: ValueKey(photos.photos[i].id),
            tag: ItemPhotoType.fromValue(photos.photos[i].photoType).tag,
            aspectRatio: AuroraHomeSizes.tileAspect,
            selected: i == selected,
            onTap: () => onSelect(i),
            image: photos.urlOf(photos.photos[i]) == null
                ? null
                : ItemPhotoImage(url: photos.urlOf(photos.photos[i])!),
          ),
      ],
    );
  }
}
