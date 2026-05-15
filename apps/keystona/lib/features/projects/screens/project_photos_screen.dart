import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/project_photo.dart';
import '../providers/project_detail_provider.dart';
import '../providers/project_photos_provider.dart';
import '../widgets/photo_upload_type_sheet.dart';
import '../widgets/photos/diptych/photos_diptych_view.dart';
import '../widgets/photos/grid/photos_curated_grid.dart';
import '../widgets/photos/grid/photos_grid_skeleton.dart';
import '../widgets/photos/shared/photos_view_toggle.dart';
import 'photo_comparison_screen.dart';

// accent: #B85638
const Color _kAccent = Color(0xFFB85638);

/// Photo gallery for a single project — wrapper + curated grid view.
///
/// Route: /projects/:projectId/photos
class ProjectPhotosScreen extends ConsumerStatefulWidget {
  const ProjectPhotosScreen({super.key, required this.projectId});
  final String projectId;

  @override
  ConsumerState<ProjectPhotosScreen> createState() =>
      _ProjectPhotosScreenState();
}

class _ProjectPhotosScreenState extends ConsumerState<ProjectPhotosScreen> {
  /// 'all' | 'pairs' | 'unpaired'
  String _activeSegment = 'all';
  bool _uploading = false;
  bool _segmentInitialized = false;

  // ── Upload / mutation helpers ─────────────────────────────────────────────

  Future<void> _pickAndUpload({ImageSource source = ImageSource.gallery}) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (picked == null) return;
    if (!mounted) return;

    final result = await showPhotoUploadTypeSheet(context);
    if (result == null) return;
    if (!mounted) return;

    setState(() => _uploading = true);
    final notifier =
        ref.read(projectPhotosProvider(widget.projectId).notifier);
    try {
      await notifier.uploadPhoto(
        file: picked,
        photoType: result.photoType,
        roomTag: result.roomTag,
      );
      if (!mounted) return;
      SnackbarService.showSuccess(context, 'Photo added.');
    } catch (_) {
      if (!mounted) return;
      SnackbarService.showError(context, 'Upload failed. Please try again.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _onPhotoTap(ProjectPhoto photo, List<ProjectPhoto> all) {
    if (photo.pairId != null) {
      final partner = all
          .where((p) => p.pairId == photo.pairId && p.id != photo.id)
          .firstOrNull;
      if (partner != null) {
        final before = photo.photoType == 'before' ? photo : partner;
        final after = photo.photoType == 'after' ? photo : partner;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PhotoComparisonScreen(
            beforePhoto: before,
            afterPhoto: after,
          ),
        ));
        return;
      }
    }
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _PhotoViewer(photo: photo),
    ));
  }

  void _onChainTap(ProjectPhoto photo, List<ProjectPhoto> all) {
    if (photo.pairId == null) return;
    final partner = all
        .where((p) => p.pairId == photo.pairId && p.id != photo.id)
        .firstOrNull;
    if (partner == null) return;
    final before = photo.photoType == 'before' ? photo : partner;
    final after = photo.photoType == 'after' ? photo : partner;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PhotoComparisonScreen(
        beforePhoto: before,
        afterPhoto: after,
      ),
    ));
  }

  void _showUploadActionSheet(BuildContext ctx) {
    final isIOS = Theme.of(ctx).platform == TargetPlatform.iOS;
    if (isIOS) {
      showCupertinoModalPopup<void>(
        context: ctx,
        builder: (_) => CupertinoActionSheet(
          title: const Text('Add Photo'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx, rootNavigator: true).pop();
                _pickAndUpload(source: ImageSource.camera);
              },
              child: const Text('Take Photo'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx, rootNavigator: true).pop();
                _pickAndUpload(source: ImageSource.gallery);
              },
              child: const Text('Choose from Library'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: false,
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
            child: const Text('Cancel'),
          ),
        ),
      );
    } else {
      showModalBottomSheet<void>(
        context: ctx,
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndUpload(source: ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Library'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndUpload(source: ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  // ── Default segment logic ─────────────────────────────────────────────────

  void _initializeSegment(List<ProjectPhoto> photos, String? projectStatus) {
    if (_segmentInitialized) return;
    _segmentInitialized = true;
    final pairIds = photos
        .where((p) => p.pairId != null)
        .map((p) => p.pairId!)
        .toSet();
    final hasPairs = pairIds.isNotEmpty;
    final isFinished = projectStatus == 'completed' ||
        projectStatus == 'cancelled';
    if (isFinished && hasPairs) {
      setState(() => _activeSegment = 'pairs');
    }
    // Otherwise stay on 'all'.
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final asyncPhotos = ref.watch(projectPhotosProvider(widget.projectId));
    final asyncProject = ref.watch(projectDetailProvider(widget.projectId));
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    // Initialize segment once data arrives.
    asyncPhotos.whenData((photos) {
      _initializeSegment(photos, asyncProject.value?.status);
    });

    final photos = asyncPhotos.value ?? [];
    final pairIds = photos
        .where((p) => p.pairId != null)
        .map((p) => p.pairId!)
        .toSet();
    final pairCount = pairIds.length;
    final unpairedCount =
        photos.where((p) => p.pairId == null).length;
    final hasPhotos = photos.isNotEmpty;

    final viewToggle = hasPhotos
        ? PhotosViewToggle(
            pairCount: pairCount,
            allCount: photos.length,
            unpairedCount: unpairedCount,
            activeSegment: _activeSegment,
            onSegmentChanged: (s) => setState(() => _activeSegment = s),
          )
        : const SizedBox.shrink();

    Widget body = asyncPhotos.when(
      loading: () => Column(
        children: [
          viewToggle,
          const Expanded(child: PhotosGridSkeleton()),
        ],
      ),
      error: (_, _) => _ErrorState(
        onRetry: () =>
            ref.invalidate(projectPhotosProvider(widget.projectId)),
      ),
      data: (data) {
        if (data.isEmpty) {
          return _EmptyState(onAdd: () => _showUploadActionSheet(context));
        }

        final activeView = _activeSegment == 'pairs'
            ? PhotosDiptychView(
                photos: data,
                projectName: asyncProject.value?.name ?? '',
                onCompareTap: (before, after) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => PhotoComparisonScreen(
                      beforePhoto: before,
                      afterPhoto: after,
                    ),
                  ));
                },
              )
            : PhotosCuratedGrid(
                projectId: widget.projectId,
                viewSource: _activeSegment,
                onPhotoTap: _onPhotoTap,
                onChainTap: _onChainTap,
              );

        return Column(
          children: [
            viewToggle,
            Expanded(child: activeView),
          ],
        );
      },
    );

    final trailingAction = _uploading
        ? const CupertinoActivityIndicator()
        : CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _showUploadActionSheet(context),
            child: const Icon(CupertinoIcons.add),
          );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Photos'),
          trailing: trailingAction,
        ),
        child: SafeArea(bottom: false, child: body),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photos'),
        actions: [
          if (_uploading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: const Icon(Icons.add_a_photo_outlined),
              onPressed: () => _showUploadActionSheet(context),
            ),
        ],
      ),
      body: body,
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppPadding.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: AppSizes.iconXl,
              color: AppColors.gray400,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'Document your progress',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Capture each phase of your project. Photos are saved to your project timeline.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.xl),
            FilledButton(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: _kAccent,
                padding: AppPadding.button,
              ),
              child: const Text('+ Add Photo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: AppSizes.iconXl, color: AppColors.error),
          const SizedBox(height: AppSizes.md),
          Text("Couldn't load photos",
              style: AppTextStyles.h3, textAlign: TextAlign.center),
          const SizedBox(height: AppSizes.lg),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.deepNavy),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Simple full-screen viewer for unpaired / single photos.
class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.photo});
  final ProjectPhoto photo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          photo.roomTag ?? photo.photoType,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: photo.signedUrl != null
          ? InteractiveViewer(
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: photo.signedUrl!,
                  fit: BoxFit.contain,
                  placeholder: (_, _) => const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white54,
                    ),
                  ),
                  errorWidget: (_, _, _) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            )
          : const Center(
              child: Icon(Icons.broken_image_outlined,
                  color: Colors.white, size: 48)),
    );
  }
}
