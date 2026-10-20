import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_shared.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import 'item_photo_tile.dart';

/// The top of a system or appliance detail: eyebrow with a status chip, the
/// name, "model · location", and the hero photo with its count badge.
class ItemHero extends StatelessWidget {
  const ItemHero({
    super.key,
    required this.eyebrow,
    required this.title,
    this.statusChip,
    this.subtitle,
    this.photoTag,
    this.photoImage,
    this.photoBadge,
    this.onPhotoBadgeTap,
    this.onPhotoTap,
  });

  /// "HVAC · SYSTEM".
  final String eyebrow;
  final String title;

  /// Usually a `StatusChip` ("HEALTHY").
  final Widget? statusChip;

  /// "Northline NF95-080B · Basement utility room".
  final String? subtitle;

  /// Corner tag on the photo ("UNIT").
  final String? photoTag;

  /// The picture; the grid placeholder shows without one.
  final Widget? photoImage;

  /// "4 PHOTOS".
  final String? photoBadge;
  final VoidCallback? onPhotoBadgeTap;
  final VoidCallback? onPhotoTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: a.of(AuroraSpacing.space2),
          runSpacing: a.of(AuroraSpacing.space1),
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(eyebrow.toUpperCase(), style: AuroraType.label),
            ?statusChip,
          ],
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        Text(title, style: AuroraHomeType.itemTitle),
        if (subtitle != null) ...[
          SizedBox(height: a.of(AuroraSpacing.space3)),
          Text(
            subtitle!,
            style: AuroraType.bodyLg.copyWith(color: AuroraColors.inkSubtle),
          ),
        ],
        SizedBox(height: a.of(AuroraSpacing.space8)),
        ItemPhotoTile(
          tag: photoTag,
          image: photoImage,
          aspectRatio: AuroraHomeSizes.heroAspect,
          onTap: onPhotoTap,
          badgeLabel: photoBadge,
          onBadgeTap: onPhotoBadgeTap,
        ),
      ],
    );
  }
}
