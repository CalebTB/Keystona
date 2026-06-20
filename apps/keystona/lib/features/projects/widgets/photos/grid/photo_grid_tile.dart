import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../models/project_photo.dart';
import '../shared/photo_thumb.dart';
import '../shared/photo_type_tag.dart';

/// Single tile in the curated photo grid.
///
/// Tapping the tile body calls [onTap].
/// Tapping the chain icon calls [onChainTap] (when paired).
/// Tapping the add-link icon calls [onLinkTap] (when unpaired before/after).
class PhotoGridTile extends StatelessWidget {
  const PhotoGridTile({
    super.key,
    required this.photo,
    required this.onTap,
    required this.onChainTap,
    this.onLinkTap,
  });

  final ProjectPhoto photo;
  final VoidCallback onTap;
  final VoidCallback onChainTap;
  final VoidCallback? onLinkTap;

  static final _dateFmt = DateFormat('MMM d');

  String _captionText() {
    final hasRoom = photo.roomTag != null && photo.roomTag!.isNotEmpty;
    final now = DateTime.now();
    final diff = now.difference(photo.createdAt).inDays;
    final isRecent = diff <= 7;
    final dateStr = _dateFmt.format(photo.createdAt);

    if (hasRoom && isRecent) return '$dateStr · ${photo.roomTag}';
    if (hasRoom) return photo.roomTag!;
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    final isPaired = photo.pairId != null;
    final isIssue = photo.photoType == 'issue';
    final captionText = _captionText();

    Widget imageStack = Stack(
      fit: StackFit.expand,
      children: [
        // ── Base image ──────────────────────────────────────────────────
        PhotoThumb(signedUrl: photo.signedUrl),

        // ── Type tag (top-left) ─────────────────────────────────────────
        Positioned(
          top: 6,
          left: 6,
          child: PhotoTypeTag(photoType: photo.photoType),
        ),

        // ── Pair chain icon (top-right) ─────────────────────────────────
        if (isPaired)
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onChainTap,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: 24,
                    height: 24,
                    color: AppColors.photoGridOverlayPair,
                    child: const Icon(
                      Icons.link,
                      color: AppColors.textInverse,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ),
          )
        else if (onLinkTap != null &&
            (photo.photoType == 'before' || photo.photoType == 'after'))
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onLinkTap,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: 24,
                    height: 24,
                    color: AppColors.photoGridOverlayLink,
                    child: const Icon(
                      Icons.add_link,
                      color: AppColors.textInverse,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // ── Caption gradient overlay (bottom) ───────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [AppColors.photoGridOverlayGradient, Colors.transparent],
                stops: [0.0, 1.0],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 12, 6, 6),
              child: Text(
                captionText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: AppColors.photoGridCaptionText,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    Widget clipped = ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: imageStack,
    );

    // Wrap with issue border.
    if (isIssue) {
      clipped = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.accent, width: 2),
        ),
        child: clipped,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: clipped,
    );
  }
}
