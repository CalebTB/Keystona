import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/item_photo.dart';

/// Horizontal photo strip shown on the System Detail screen.
///
/// Displays existing photos with captions and an "Add Photo" tile.
/// Each photo is 80×80 with [CachedNetworkImage] and a skeleton placeholder.
class SystemPhotoStrip extends StatelessWidget {
  const SystemPhotoStrip({
    super.key,
    required this.photos,
    required this.onAddPhoto,
    this.photoUrlBuilder,
  });

  final List<ItemPhoto> photos;
  final VoidCallback onAddPhoto;

  /// Converts a storage [filePath] to a signed URL for display.
  /// When null, the photo path is shown as-is (dev/stub mode).
  final String Function(String filePath)? photoUrlBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
        itemCount: photos.length + 1, // +1 for the "Add" tile.
        separatorBuilder: (_, _) => const SizedBox(width: AppSizes.sm),
        itemBuilder: (context, index) {
          if (index == photos.length) {
            return _AddPhotoTile(onTap: onAddPhoto);
          }
          return _PhotoTile(
            photo: photos[index],
            photoUrlBuilder: photoUrlBuilder,
          );
        },
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo, this.photoUrlBuilder});

  final ItemPhoto photo;
  final String Function(String)? photoUrlBuilder;

  @override
  Widget build(BuildContext context) {
    final url = photoUrlBuilder?.call(photo.filePath) ?? photo.filePath;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(
          width: 80,
          height: 80,
          color: AppColors.gray200,
        ),
        errorWidget: (_, _, _) => Container(
          width: 80,
          height: 80,
          color: AppColors.gray100,
          child: const Icon(
            Icons.broken_image_outlined,
            color: AppColors.textDisabled,
            size: 32,
          ),
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_photo_alternate_outlined,
                size: 28, color: AppColors.textSecondary),
            const SizedBox(height: 2),
            Text(
              'Add',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
