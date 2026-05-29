import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../models/project_photo.dart';
import '../shared/photo_type_tag.dart';

const Color _kCardSurface = Color(0xFFF5F2EC);
const Color _kCardBorder = Color(0xFFDDD6CC);
const Color _kRoomTagText = Color(0xFF6B7E6D);
const Color _kCaptionColor = Color(0xFF6B6560);

/// A before/after pair resolved from grouped photos.
class _Pair {
  const _Pair({required this.before, required this.after});
  final ProjectPhoto before;
  final ProjectPhoto after;
}

/// Pairs view — shows all matched before/after diptych cards for a project.
///
/// Pass [photos] (all photos for the project) and [projectName] for the eyebrow
/// header. Call [onCompareTap] when the user taps the slide-compare CTA.
/// Call [onMoreTap] when the user taps the ••• menu on a pair card.
class PhotosDiptychView extends StatelessWidget {
  const PhotosDiptychView({
    super.key,
    required this.photos,
    required this.projectName,
    required this.onCompareTap,
    this.onMoreTap,
  });

  final List<ProjectPhoto> photos;
  final String projectName;
  final void Function(ProjectPhoto before, ProjectPhoto after) onCompareTap;
  final void Function(ProjectPhoto before, ProjectPhoto after)? onMoreTap;

  List<_Pair> _buildPairs() {
    // Group by pairId — only photos with a non-null pairId participate.
    final Map<String, List<ProjectPhoto>> groups = {};
    for (final p in photos) {
      if (p.pairId == null) continue;
      groups.putIfAbsent(p.pairId!, () => []).add(p);
    }

    final pairs = <_Pair>[];
    for (final group in groups.values) {
      final before =
          group.where((p) => p.photoType == 'before').firstOrNull;
      final after =
          group.where((p) => p.photoType == 'after').firstOrNull;
      if (before == null || after == null) continue;
      pairs.add(_Pair(before: before, after: after));
    }

    // Newest first (by before photo creation date).
    pairs.sort(
      (a, b) => b.before.createdAt.compareTo(a.before.createdAt),
    );
    return pairs;
  }

  @override
  Widget build(BuildContext context) {
    final pairs = _buildPairs();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // ── Eyebrow + heading ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Eyebrow row: accent dot + label
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${projectName.toUpperCase()} · THE TRANSFORMATION',
                        style: const TextStyle(
                          fontFamily: 'IBMPlexMono',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          height: 1.2,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // H1
                Text(
                  'Before & after.',
                  style: GoogleFonts.fraunces(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                    height: 1.05,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // ── Empty state ────────────────────────────────────────────────────────
        if (pairs.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.compare_outlined,
                      size: 48,
                      color: AppColors.gray400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No before & after pairs yet',
                      style: AppTextStyles.h3,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload a before and after photo, then pair them to see the transformation.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          // ── Pair cards ───────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList.separated(
              itemCount: pairs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final pair = pairs[index];
                return _PairCard(
                  before: pair.before,
                  after: pair.after,
                  onCompare: () => onCompareTap(pair.before, pair.after),
                  onMore: onMoreTap != null
                      ? () => onMoreTap!(pair.before, pair.after)
                      : null,
                );
              },
            ),
          ),
      ],
    );
  }
}

/// A single before/after diptych card.
class _PairCard extends StatelessWidget {
  const _PairCard({
    required this.before,
    required this.after,
    required this.onCompare,
    this.onMore,
  });

  final ProjectPhoto before;
  final ProjectPhoto after;
  final VoidCallback onCompare;
  final VoidCallback? onMore;

  String _cardTitle() {
    final tag = before.roomTag ?? after.roomTag;
    if (tag == null || tag.isEmpty) return 'Before & After';
    // Title-case the room tag.
    return tag
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _formatDate(DateTime dt) =>
      DateFormat('MMM d').format(dt).toUpperCase();

  int _daysElapsed() =>
      after.createdAt.difference(before.createdAt).inDays.abs();

  @override
  Widget build(BuildContext context) {
    final roomTag = before.roomTag ?? after.roomTag;

    return Container(
      decoration: BoxDecoration(
        color: _kCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCardBorder),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                if (roomTag != null && roomTag.isNotEmpty) ...[
                  _RoomTagChip(label: roomTag),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    _cardTitle(),
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: onMore,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: AppColors.gray400,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Photos row ────────────────────────────────────────────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _PhotoTile(photo: before, date: _formatDate(before.createdAt))),
                const SizedBox(width: 2),
                Expanded(child: _PhotoTile(photo: after, date: _formatDate(after.createdAt))),
              ],
            ),
          ),

          // ── Quote section (caption) ───────────────────────────────────────
          if ((before.caption ?? after.caption)?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Text(
                '“${before.caption ?? after.caption}”',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: _kCaptionColor,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // ── Stats row ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Days elapsed
                Text(
                  '${_daysElapsed()} days',
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                // Slide compare CTA
                GestureDetector(
                  onTap: onCompare,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.compare_arrows_rounded,
                        size: 14,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'SLIDE COMPARE',
                        style: TextStyle(
                          fontFamily: 'IBMPlexMono',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Square photo tile with a type badge and date stamp.
class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo, required this.date});

  final ProjectPhoto photo;
  final String date;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photo or placeholder
          (photo.signedUrl != null && photo.signedUrl!.isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: photo.signedUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      const ColoredBox(color: Color(0xFFD0C8BC)),
                  errorWidget: (_, _, _) =>
                      const ColoredBox(color: Color(0xFFD0C8BC)),
                )
              : const ColoredBox(color: Color(0xFFD0C8BC)),

          // Type badge — top-left
          Positioned(
            top: 8,
            left: 8,
            child: PhotoTypeTag(photoType: photo.photoType),
          ),

          // Date stamp — bottom-right
          Positioned(
            bottom: 8,
            right: 8,
            child: Text(
              date,
              style: const TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small IBMPlexMono chip showing the room tag label.
class _RoomTagChip extends StatelessWidget {
  const _RoomTagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEAE2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: _kRoomTagText,
        ),
      ),
    );
  }
}
