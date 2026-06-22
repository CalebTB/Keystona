import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/aurora_colors.dart';
import '../../../../../core/theme/aurora_typography.dart';
import '../../../../../core/theme/aurora_spacing.dart';

import '../../../models/project_photo.dart';
import '../../../providers/project_detail_provider.dart';
import '../../../providers/project_photos_provider.dart';
import 'photo_grid_tile.dart';
import 'photos_grid_filter_chips.dart';
import 'photos_grid_skeleton.dart';
import 'photos_summary_strip.dart';


/// Full-screen curated photo grid for a project.
///
/// [viewSource]: 'all' | 'unpaired' | 'pairs' — controls which photos are shown.
/// [photoTypeFilter]: pre-set type filter (overrides internal chip selection when non-null).
class PhotosCuratedGrid extends ConsumerStatefulWidget {
  const PhotosCuratedGrid({
    super.key,
    required this.projectId,
    this.viewSource = 'all',
    this.onPhotoTap,
    this.onChainTap,
    this.onLinkTap,
  });

  final String projectId;

  /// 'all' | 'unpaired' | 'pairs'
  final String viewSource;

  /// Called when user taps a photo tile body.
  final void Function(ProjectPhoto photo, List<ProjectPhoto> all)? onPhotoTap;

  /// Called when user taps the chain icon on a paired photo.
  final void Function(ProjectPhoto photo, List<ProjectPhoto> all)? onChainTap;

  /// Called when user taps the add-link icon on an unpaired before/after photo.
  final void Function(ProjectPhoto photo, List<ProjectPhoto> all)? onLinkTap;

  @override
  ConsumerState<PhotosCuratedGrid> createState() => _PhotosCuratedGridState();
}

class _PhotosCuratedGridState extends ConsumerState<PhotosCuratedGrid> {
  String? _activeTypeFilter;

  @override
  Widget build(BuildContext context) {
    final asyncPhotos = ref.watch(projectPhotosProvider(widget.projectId));
    final asyncProject = ref.watch(projectDetailProvider(widget.projectId));

    return asyncPhotos.when(
      loading: () => const PhotosGridSkeleton(),
      error: (_, _) => _ErrorBody(
        onRetry: () => ref.invalidate(projectPhotosProvider(widget.projectId)),
      ),
      data: (all) {
        final projectName = asyncProject.value?.name;
        final filtered = _applyFilters(all);
        final pairIds = all
            .where((p) => p.pairId != null)
            .map((p) => p.pairId!)
            .toSet();
        final pairCount = pairIds.length;
        final unpairedCount =
            all.where((p) => p.pairId == null).length;
        final latestDate =
            all.isEmpty ? null : all.first.createdAt;

        return CustomScrollView(
          slivers: [
            // ── Eyebrow + heading ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AuroraSpacing.space7,
                  AuroraSpacing.space7,
                  AuroraSpacing.space7,
                  AuroraSpacing.space1,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: const BoxDecoration(
                            color: AuroraColors.coral,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          '${projectName != null ? '$projectName · ' : ''}${all.length} photo${all.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AuroraColors.inkSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your journey',
                      style: GoogleFonts.fraunces(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                        color: AuroraColors.ink,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Type filter chips (hidden for 'unpaired' view) ──────────────
            if (widget.viewSource != 'unpaired')
              SliverToBoxAdapter(
                child: PhotosGridFilterChips(
                  activeFilter: _activeTypeFilter,
                  onChanged: (f) => setState(() => _activeTypeFilter = f),
                ),
              ),

            // ── Summary strip ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AuroraSpacing.space3,
                  bottom: AuroraSpacing.space3,
                ),
                child: PhotosSummaryStrip(
                  pairCount: pairCount,
                  unpairedCount: unpairedCount,
                  latestDate: latestDate,
                  total: all.length,
                ),
              ),
            ),

            // ── Grid or empty ───────────────────────────────────────────────
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyFilterState(
                  hasTypeFilter: _activeTypeFilter != null,
                  onClear: () => setState(() => _activeTypeFilter = null),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AuroraSpacing.space7,
                  0,
                  AuroraSpacing.space7,
                  AuroraSpacing.space7,
                ),
                sliver: SliverGrid.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    // Slightly taller than square — works well for photo grids.
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, index) {
                    final photo = filtered[index];
                    return PhotoGridTile(
                      photo: photo,
                      onTap: () =>
                          widget.onPhotoTap?.call(photo, all),
                      onChainTap: () =>
                          widget.onChainTap?.call(photo, all),
                      onLinkTap: widget.onLinkTap != null
                          ? () => widget.onLinkTap!.call(photo, all)
                          : null,
                    );
                  },
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 48.0 + AuroraSpacing.space10),
            ),
          ],
        );
      },
    );
  }

  List<ProjectPhoto> _applyFilters(List<ProjectPhoto> all) {
    List<ProjectPhoto> base;
    switch (widget.viewSource) {
      case 'unpaired':
        base = all.where((p) => p.pairId == null).toList();
      case 'pairs':
        base = all.where((p) => p.pairId != null).toList();
      default:
        base = all;
    }

    if (_activeTypeFilter != null) {
      base =
          base.where((p) => p.photoType == _activeTypeFilter).toList();
    }

    return base;
  }

}

// ── Supporting private widgets ────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 48.0, color: AuroraColors.coral),
          const SizedBox(height: AuroraSpacing.space7),
          Text("Couldn't load photos",
              style: AuroraType.h3, textAlign: TextAlign.center),
          const SizedBox(height: AuroraSpacing.space9),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AuroraColors.ink,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyFilterState extends StatelessWidget {
  const _EmptyFilterState({
    required this.hasTypeFilter,
    required this.onClear,
  });

  final bool hasTypeFilter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AuroraSpacing.screenPadH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 48.0,
              color: AuroraColors.inkTertiary,
            ),
            const SizedBox(height: AuroraSpacing.space7),
            Text(
              hasTypeFilter
                  ? 'No photos match this filter'
                  : 'No photos yet',
              style: AuroraType.h3,
              textAlign: TextAlign.center,
            ),
            if (hasTypeFilter) ...[
              const SizedBox(height: AuroraSpacing.space3),
              TextButton(
                onPressed: onClear,
                child: Text(
                  'Clear filter',
                  style: AuroraType.body.copyWith(
                    color: AuroraColors.ink,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
