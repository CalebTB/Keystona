import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// [CachedNetworkImage] wrapper for project photos.
///
/// Accepts a [signedUrl] — pass the URL pre-computed by the provider's
/// [Future.wait] signed-URL batch. Falls back to a warm-fill placeholder
/// while loading and a broken-image icon on error.
class PhotoThumb extends StatelessWidget {
  const PhotoThumb({
    super.key,
    required this.signedUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String? signedUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final url = signedUrl;

    if (url == null || url.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: AppColors.surfaceVariant,
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.gray400,
            size: 24,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, _) => Container(
        width: width,
        height: height,
        color: AppColors.surfaceVariant,
      ),
      errorWidget: (_, _, _) => Container(
        width: width,
        height: height,
        color: AppColors.surfaceVariant,
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: AppColors.gray400,
            size: 24,
          ),
        ),
      ),
    );
  }
}
