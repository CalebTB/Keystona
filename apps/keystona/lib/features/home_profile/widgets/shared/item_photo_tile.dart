import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_shared.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// A photo with a blueprint-grid placeholder behind it, a corner [tag]
/// ("UNIT", "LABEL", "FRONT OF HOUSE") and an optional count badge
/// ("4 PHOTOS") at the top right.
///
/// Pass the picture as [image] (a `CachedNetworkImage` or `Image.file`); with
/// none, the grid shows. [aspectRatio] is width / height: the hero uses
/// `AuroraHomeSizes.heroAspect`, grid thumbnails
/// `AuroraHomeSizes.tileAspect`.
class ItemPhotoTile extends StatelessWidget {
  const ItemPhotoTile({
    super.key,
    this.tag,
    this.image,
    this.aspectRatio = AuroraHomeSizes.heroAspect,
    this.selected = false,
    this.onTap,
    this.badgeLabel,
    this.badgeIcon = Icons.photo_camera_outlined,
    this.onBadgeTap,
  });

  final String? tag;
  final Widget? image;
  final double aspectRatio;

  /// Outlines the tile in ink (the chosen thumbnail).
  final bool selected;
  final VoidCallback? onTap;

  /// "4 PHOTOS".
  final String? badgeLabel;
  final IconData badgeIcon;
  final VoidCallback? onBadgeTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final inset = a.of(AuroraSpacing.space4);
    final tile = AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: AuroraRadius.xl,
          border: Border.all(
            color: selected ? AuroraColors.ink : AuroraColors.cobaltBorder,
            width: selected ? AuroraBorders.emphasis : AuroraBorders.regular,
          ),
        ),
        child: ClipRRect(
          borderRadius: AuroraRadius.xl,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _GridPainter(
                  cell: a.of(AuroraHomeSizes.gridCell),
                  line: AuroraHomeSizes.gridLineWidth,
                ),
              ),
              ?image,
              if (tag != null)
                Positioned(
                  left: inset,
                  bottom: inset,
                  right: inset,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: _Pill(text: tag!),
                  ),
                ),
              if (badgeLabel != null)
                Positioned(
                  right: inset,
                  top: inset,
                  child: AuroraPressable(
                    onTap: onBadgeTap,
                    semanticLabel: badgeLabel,
                    enforceTouchTarget: true,
                    child: _Pill(text: badgeLabel!, icon: badgeIcon),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (onTap == null) return tile;
    return AuroraPressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: tag,
      child: tile,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      constraints: BoxConstraints(
        minHeight: icon == null ? 0 : a.of(AuroraHomeSizes.badgeHeight),
      ),
      padding: a.symmetric(
        horizontal: AuroraSpacing.space4,
        vertical: AuroraSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.full,
        border: Border.all(
          color: AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: a.of(AuroraIconSizes.xs),
              color: AuroraColors.ink,
            ),
            SizedBox(width: a.of(AuroraSpacing.space1)),
          ],
          Flexible(
            child: Text(
              text.toUpperCase(),
              style: AuroraHomeType.tag.copyWith(
                color: icon == null ? AuroraColors.inkSubtle : AuroraColors.ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.cell, required this.line});

  final double cell;
  final double line;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AuroraHomeColors.gridLine
      ..strokeWidth = line;
    for (var x = 0.0; x < size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.cell != cell || old.line != line;
}
