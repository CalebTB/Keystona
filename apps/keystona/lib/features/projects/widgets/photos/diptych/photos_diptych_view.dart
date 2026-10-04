import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/aurora_colors.dart';
import '../../../../../core/theme/aurora_typography.dart';

import '../../../models/project_photo.dart';
import '../shared/photo_type_tag.dart';
import '../../../../../core/theme/aurora_radius.dart';

const Color _kCardSurface = AuroraColors.paper;
const Color _kCardBorder = AuroraColors.inkBorder;
const Color _kRoomTagText = AuroraColors.inkSecondary;
const Color _kCaptionColor = AuroraColors.inkSecondary;

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
                        color: AuroraColors.coral,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${projectName.toUpperCase()} · THE TRANSFORMATION',
                        style: AuroraType.label.copyWith(color: AuroraColors.inkSecondary, height: 1.2),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // H1
                Text(
                  'Before & after.',
                  style: AuroraType.h1.copyWith(color: AuroraColors.ink, height: 1.05),
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
                      color: AuroraColors.inkTertiary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No before & after pairs yet',
                      style: AuroraType.h3,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload a before and after photo, then pair them to see the transformation.',
                      style: AuroraType.body
                          .copyWith(color: AuroraColors.inkSecondary),
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
        borderRadius: AuroraRadius.lg,
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
                    style: AuroraType.bodyLg.copyWith(fontWeight: FontWeight.w600, color: AuroraColors.ink),
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
                      color: AuroraColors.inkTertiary,
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
                style: AuroraType.body.copyWith(color: _kCaptionColor, height: 1.5),
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
                  style: AuroraType.label.copyWith(color: AuroraColors.inkSecondary),
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
                        color: AuroraColors.coral,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'SLIDE COMPARE',
                        style: AuroraType.label.copyWith(color: AuroraColors.coral),
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
                      const ColoredBox(color: AuroraColors.butter),
                  errorWidget: (_, _, _) =>
                      const ColoredBox(color: AuroraColors.butter),
                )
              : const ColoredBox(color: AuroraColors.butter),

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
              style: AuroraType.labelSm.copyWith(color: AuroraColors.paper),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small mono chip showing the room tag label.
class _RoomTagChip extends StatelessWidget {
  const _RoomTagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AuroraColors.butter,
        borderRadius: AuroraRadius.xs,
      ),
      child: Text(
        label.toUpperCase(),
        style: AuroraType.labelSm.copyWith(color: _kRoomTagText),
      ),
    );
  }
}
