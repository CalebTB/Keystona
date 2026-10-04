import 'package:flutter/material.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_typography.dart';
import '../models/project_photo.dart';
import '../../../core/theme/aurora_radius.dart';

/// Single photo tile in the project photos grid.
///
/// Shows a type badge and pair indicator. Unpaired "before" photos show
/// an "Add after →" prompt at the bottom.
class PhotoGridItem extends StatelessWidget {
  const PhotoGridItem({
    super.key,
    required this.photo,
    required this.onTap,
    required this.onAddAfter,
    required this.onDelete,
  });

  final ProjectPhoto photo;
  final VoidCallback onTap;
  final VoidCallback onAddAfter;
  final VoidCallback onDelete;

  bool get _needsAfter =>
      photo.photoType == 'before' && photo.pairId == null;

  @override
  Widget build(BuildContext context) {
    final colors = PhotoTypes.colorFor(photo.photoType);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photo.
          ClipRRect(
            borderRadius: AuroraRadius.sm,
            child: photo.signedUrl != null
                ? Image.network(
                    photo.signedUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFFEEEDF2),
                      child: const Icon(Icons.broken_image_outlined,
                          color: AuroraColors.inkTertiary),
                    ),
                  )
                : Container(color: const Color(0xFFEEEDF2)),
          ),

          // Type badge.
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius:
                    AuroraRadius.full,
              ),
              child: Text(
                PhotoTypes.labelFor(photo.photoType),
                style: AuroraType.label
                    .copyWith(color: colors.foreground, fontSize: 9),
              ),
            ),
          ),

          // Paired indicator.
          if (photo.pairId != null)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AuroraColors.lime.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.compare, size: 10, color: AuroraColors.paper),
              ),
            ),

          // "Add after" prompt for unpaired before photos.
          if (_needsAfter)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: onAddAfter,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: AuroraColors.ink.withValues(alpha: 0.8),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(8.0)),
                  ),
                  child: Text(
                    'Add after →',
                    style: AuroraType.label
                        .copyWith(color: AuroraColors.paper, fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
