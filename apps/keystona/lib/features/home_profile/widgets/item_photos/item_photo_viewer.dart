import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_c.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../item_copy.dart';
import '../shared/item_photo_tile.dart';
import 'item_photo_image.dart';

/// The big photo with its tag and the expand button at the bottom right.
/// Swiping left or right moves to the next or previous photo (wrapping), and
/// a long press opens the photo's actions.
class ItemPhotoViewer extends StatelessWidget {
  const ItemPhotoViewer({
    super.key,
    required this.tag,
    required this.url,
    required this.onExpand,
    required this.onStep,
    required this.onLongPress,
  });

  final String tag;
  final String? url;
  final VoidCallback onExpand;

  /// Called with 1 (next) or -1 (previous).
  final ValueChanged<int> onStep;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final inset = a.of(AuroraSpacing.space4);
    return GestureDetector(
      onLongPress: onLongPress,
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v.abs() < AuroraHomeCSizes.swipeVelocity) return;
        onStep(v < 0 ? 1 : -1);
      },
      child: Stack(
        children: [
          ItemPhotoTile(
            tag: tag,
            aspectRatio: AuroraHomeCSizes.viewerAspect,
            image: url == null ? null : ItemPhotoImage(url: url!),
          ),
          Positioned(
            right: inset,
            bottom: inset,
            child: AuroraPressable(
              onTap: onExpand,
              semanticLabel: ItemCopy.expandSemantics,
              enforceTouchTarget: true,
              child: Container(
                width: a.of(AuroraHomeCSizes.expandButton),
                height: a.of(AuroraHomeCSizes.expandButton),
                decoration: BoxDecoration(
                  color: AuroraColors.paper,
                  borderRadius: AuroraRadius.md,
                  border: Border.all(
                    color: AuroraColors.inkBorder,
                    width: AuroraBorders.regular,
                  ),
                ),
                child: Icon(
                  Icons.open_in_full,
                  size: a.of(AuroraIconSizes.sm),
                  color: AuroraColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
