import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_home_a.dart';
import '../../home_profile_copy.dart';
import '../shared/item_photo_tile.dart';

/// The cover photo, with the "FRONT OF HOUSE" tag. The blueprint grid shows
/// when there is no photo (or it cannot load).
class ProfileCover extends StatelessWidget {
  const ProfileCover({super.key, this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    return ItemPhotoTile(
      tag: HomeProfileCopy.coverTag,
      aspectRatio: AuroraHomeASizes.coverAspect,
      image: url == null
          ? null
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => const SizedBox.shrink(),
            ),
    );
  }
}
