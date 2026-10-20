import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A photo from its signed link, filling the space it is given. Nothing
/// shows while it loads or if it fails, so the tile's grid placeholder stays
/// visible.
class ItemPhotoImage extends StatelessWidget {
  const ItemPhotoImage({super.key, required this.url, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      fadeInDuration: Duration.zero,
      placeholder: (_, _) => const SizedBox.shrink(),
      errorWidget: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
