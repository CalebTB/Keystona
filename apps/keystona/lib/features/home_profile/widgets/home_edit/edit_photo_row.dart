import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_a.dart';
import '../../../../core/theme/aurora_home_shared.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../home_edit_copy.dart';
import '../shared/dashed_border.dart';
import '../shared/item_photo_tile.dart';

/// The cover photo (with its COVER badge) and a dashed tile that picks a new
/// one. A freshly picked [localPhoto] shows before it is uploaded.
class EditPhotoRow extends StatelessWidget {
  const EditPhotoRow({
    super.key,
    required this.onPick,
    this.photoUrl,
    this.localPhoto,
  });

  final String? photoUrl;
  final File? localPhoto;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final url = photoUrl;
    final local = localPhoto;
    final hasPhoto = local != null || url != null;
    final Widget? image = local != null
        ? Image.file(local, fit: BoxFit.cover)
        : url != null
        ? CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            errorWidget: (_, _, _) => const SizedBox.shrink(),
          )
        : null;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: a.of(AuroraSpacing.space3),
        children: [
          Expanded(
            flex: AuroraHomeASizes.editCoverFlex,
            child: Stack(
              children: [
                ItemPhotoTile(
                  tag: HomeEditCopy.coverTag,
                  aspectRatio: AuroraHomeASizes.editCoverAspect,
                  image: image,
                ),
                Positioned(
                  top: a.of(AuroraSpacing.space3),
                  right: a.of(AuroraSpacing.space3),
                  child: const _CoverBadge(),
                ),
              ],
            ),
          ),
          Expanded(
            flex: AuroraHomeASizes.editAddFlex,
            child: _AddTile(
              label: hasPhoto ? HomeEditCopy.changePhoto : HomeEditCopy.addPhoto,
              onTap: onPick,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverBadge extends StatelessWidget {
  const _CoverBadge();

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: a.symmetric(
        horizontal: AuroraSpacing.space3,
        vertical: AuroraSpacing.space1,
      ),
      decoration: const BoxDecoration(
        color: AuroraColors.ink,
        borderRadius: AuroraRadius.full,
      ),
      child: Text(
        HomeEditCopy.cover,
        style: AuroraHomeType.tag.copyWith(color: AuroraColors.paper),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: label,
      child: DashedBorder(
        borderRadius: AuroraRadius.lg,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: a.minControl(AuroraSizes.minTouch),
          ),
          child: Center(
            child: Padding(
              padding: a.all(AuroraSpacing.space3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_camera_outlined,
                    size: a.of(AuroraIconSizes.lg),
                    color: AuroraColors.inkSecondary,
                  ),
                  SizedBox(height: a.of(AuroraSpacing.space2)),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AuroraHomeType.tag.copyWith(
                      color: AuroraColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
