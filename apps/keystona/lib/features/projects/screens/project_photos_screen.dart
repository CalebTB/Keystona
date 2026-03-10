import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/project_photo.dart';
import '../providers/project_photos_provider.dart';
import '../widgets/photo_grid_item.dart';
import '../widgets/photo_upload_type_sheet.dart';
import '../widgets/photos_skeleton.dart';
import 'photo_comparison_screen.dart';

/// Photo gallery for a single project.
///
/// Route: /projects/:projectId/photos
class ProjectPhotosScreen extends ConsumerStatefulWidget {
  const ProjectPhotosScreen({super.key, required this.projectId});
  final String projectId;

  @override
  ConsumerState<ProjectPhotosScreen> createState() =>
      _ProjectPhotosScreenState();
}

class _ProjectPhotosScreenState
    extends ConsumerState<ProjectPhotosScreen> {
  String? _activeFilter;
  bool _uploading = false;

  Future<void> _upload() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
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
      SnackbarService.showError(
          context, 'Upload failed. Please try again.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _addAfter(
      BuildContext ctx, String beforeId) async {
    // Pick photo from library first.
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (picked == null) return;
    if (!ctx.mounted) return;

    setState(() => _uploading = true);
    final notifier =
        ref.read(projectPhotosProvider(widget.projectId).notifier);
    try {
      // Upload as "after" type and capture the new photo's ID.
      final newId = await notifier.uploadPhoto(
        file: picked,
        photoType: 'after',
      );
      // Auto-pair with the before photo.
      await notifier.pairPhotos(beforeId, newId);
      if (!ctx.mounted) return;
      SnackbarService.showSuccess(ctx, 'After photo added and paired!');
    } catch (_) {
      if (!ctx.mounted) return;
      SnackbarService.showError(ctx, 'Upload failed. Please try again.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _confirmDelete(
      BuildContext ctx, ProjectPhoto photo) async {
    final isIOS = Theme.of(ctx).platform == TargetPlatform.iOS;
    bool confirmed = false;

    if (isIOS) {
      await showCupertinoDialog<void>(
        context: ctx,
        builder: (dlg) => CupertinoAlertDialog(
          title: const Text('Delete Photo'),
          content: const Text('This cannot be undone.'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(dlg).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                confirmed = true;
                Navigator.of(dlg).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    } else {
      confirmed = await showDialog<bool>(
            context: ctx,
            builder: (dlg) => AlertDialog(
              title: const Text('Delete Photo'),
              content: const Text('This cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dlg).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dlg).pop(true),
                  child:
                      Text('Delete', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          ) ??
          false;
    }

    if (!confirmed || !ctx.mounted) return;

    final notifier =
        ref.read(projectPhotosProvider(widget.projectId).notifier);
    try {
      await notifier.deletePhoto(photo.id, photo.storagePath);
      if (!ctx.mounted) return;
      SnackbarService.showSuccess(ctx, 'Photo deleted.');
    } catch (_) {
      if (!ctx.mounted) return;
      SnackbarService.showError(ctx, 'Could not delete photo.');
    }
  }

  void _onTapPhoto(
      BuildContext ctx, ProjectPhoto photo, List<ProjectPhoto> all) {
    if (photo.pairId != null) {
      final partner = all
          .where((p) => p.pairId == photo.pairId && p.id != photo.id)
          .firstOrNull;
      if (partner != null) {
        final before = photo.photoType == 'before' ? photo : partner;
        final after = photo.photoType == 'after' ? photo : partner;
        Navigator.of(ctx).push(MaterialPageRoute(
          builder: (_) => PhotoComparisonScreen(
            beforePhoto: before,
            afterPhoto: after,
          ),
        ));
        return;
      }
    }
    Navigator.of(ctx).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _PhotoViewer(photo: photo),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final asyncPhotos =
        ref.watch(projectPhotosProvider(widget.projectId));
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    Widget body = asyncPhotos.when(
      loading: () => const PhotosSkeleton(),
      error: (_, _) => _ErrorState(
        onRetry: () =>
            ref.invalidate(projectPhotosProvider(widget.projectId)),
      ),
      data: (photos) {
        final filtered = _activeFilter == null
            ? photos
            : photos.where((p) => p.photoType == _activeFilter).toList();

        return Column(
          children: [
            // Filter chips.
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md, vertical: AppSizes.xs),
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _activeFilter == null,
                    onTap: () => setState(() => _activeFilter = null),
                  ),
                  ...PhotoTypes.all.map((t) => Padding(
                        padding: const EdgeInsets.only(left: AppSizes.xs),
                        child: _FilterChip(
                          label: t.label,
                          selected: _activeFilter == t.value,
                          onTap: () => setState(() =>
                              _activeFilter =
                                  _activeFilter == t.value ? null : t.value),
                        ),
                      )),
                ],
              ),
            ),

            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(onAdd: _upload)
                  : RefreshIndicator(
                      onRefresh: () async => ref
                          .read(projectPhotosProvider(widget.projectId)
                              .notifier)
                          .refresh(),
                      child: GridView.builder(
                        padding: AppPadding.screen,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: AppSizes.xs,
                          crossAxisSpacing: AppSizes.xs,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final p = filtered[i];
                          return PhotoGridItem(
                            photo: p,
                            onTap: () => _onTapPhoto(ctx, p, photos),
                            onAddAfter: () => _addAfter(ctx, p.id),
                            onDelete: () => _confirmDelete(ctx, p),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );

    final fab = _uploading
        ? const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator())
        : FloatingActionButton(
            onPressed: _upload,
            backgroundColor: AppColors.deepNavy,
            child: const Icon(Icons.add_a_photo, color: Colors.white),
          );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Photos'),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              body,
              Positioned(
                bottom: 24,
                right: 16,
                child: fab,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Photos')),
      body: body,
      floatingActionButton: fab,
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm + 4, vertical: AppSizes.xs),
        decoration: BoxDecoration(
          color: selected ? AppColors.deepNavy : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: selected ? AppColors.deepNavy : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

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
            Icon(Icons.photo_library_outlined,
                size: AppSizes.iconXl, color: AppColors.gray400),
            const SizedBox(height: AppSizes.md),
            Text('Document your project',
                style: AppTextStyles.h3, textAlign: TextAlign.center),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Add before, after, and progress photos to track your renovation journey.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.xl),
            FilledButton(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.deepNavy,
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.deepNavy),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Simple full-screen photo viewer for unpaired photos.
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
          photo.roomTag ?? PhotoTypes.labelFor(photo.photoType),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: photo.signedUrl != null
          ? InteractiveViewer(
              child: Center(child: Image.network(photo.signedUrl!,
                  fit: BoxFit.contain)),
            )
          : const Center(
              child: Icon(Icons.broken_image_outlined,
                  color: Colors.white, size: 48)),
    );
  }
}

