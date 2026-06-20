import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // ── Pair creation ─────────────────────────────────────────────────────────

  void _showPairPicker(ProjectPhoto photo, List<ProjectPhoto> all) {
    final oppositeType = photo.photoType == 'before' ? 'after' : 'before';
    final candidates = all
        .where((p) => p.pairId == null && p.photoType == oppositeType)
        .toList();

    if (candidates.isEmpty) {
      SnackbarService.showWarning(
        context,
        'No unpaired $oppositeType photos to pair with.',
      );
      return;
    }

    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      showCupertinoModalPopup<void>(
        context: context,
        builder: (ctx) => _PairPickerSheet(
          source: photo,
          candidates: candidates,
          onSelected: (candidate) async {
            Navigator.of(ctx, rootNavigator: true).pop();
            final beforeId =
                photo.photoType == 'before' ? photo.id : candidate.id;
            final afterId =
                photo.photoType == 'after' ? photo.id : candidate.id;
            final notifier =
                ref.read(projectPhotosProvider(widget.projectId).notifier);
            try {
              await notifier.pairPhotos(beforeId, afterId);
              if (!mounted) return;
              SnackbarService.showSuccess(context, 'Photos paired!');
            } catch (_) {
              if (!mounted) return;
              SnackbarService.showError(context, 'Failed to pair photos.');
            }
          },
        ),
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => _PairPickerSheet(
          source: photo,
          candidates: candidates,
          onSelected: (candidate) async {
            Navigator.of(ctx).pop();
            final beforeId =
                photo.photoType == 'before' ? photo.id : candidate.id;
            final afterId =
                photo.photoType == 'after' ? photo.id : candidate.id;
            final notifier =
                ref.read(projectPhotosProvider(widget.projectId).notifier);
            try {
              await notifier.pairPhotos(beforeId, afterId);
              if (!mounted) return;
              SnackbarService.showSuccess(context, 'Photos paired!');
            } catch (_) {
              if (!mounted) return;
              SnackbarService.showError(context, 'Failed to pair photos.');
            }
          },
        ),
      );
    }
  }

  // ── Pair edit / manage ────────────────────────────────────────────────────

  void _showPairEditSheet(ProjectPhoto before, ProjectPhoto after) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final notifier =
        ref.read(projectPhotosProvider(widget.projectId).notifier);

    if (isIOS) {
      showCupertinoModalPopup<void>(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx, rootNavigator: true).pop();
                _showPairEditForm(before, after);
              },
              child: const Text('Edit Details'),
            ),
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(ctx, rootNavigator: true).pop();
                try {
                  await notifier.unpairPhotos(before.id, after.id);
                  if (!mounted) return;
                  SnackbarService.showSuccess(context, 'Pair removed.');
                } catch (_) {
                  if (!mounted) return;
                  SnackbarService.showError(context, 'Failed to unpair.');
                }
              },
              child: const Text('Unpair Photos'),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.of(ctx, rootNavigator: true).pop();
                try {
                  await notifier.deletePhoto(before.id, before.storagePath);
                  await notifier.deletePhoto(after.id, after.storagePath);
                  if (!mounted) return;
                  SnackbarService.showSuccess(context, 'Pair deleted.');
                } catch (_) {
                  if (!mounted) return;
                  SnackbarService.showError(context, 'Failed to delete pair.');
                }
              },
              child: const Text('Delete Pair'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
            child: const Text('Cancel'),
          ),
        ),
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Details'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showPairEditForm(before, after);
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_off_outlined),
                title: const Text('Unpair Photos'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  try {
                    await notifier.unpairPhotos(before.id, after.id);
                    if (!mounted) return;
                    SnackbarService.showSuccess(context, 'Pair removed.');
                  } catch (_) {
                    if (!mounted) return;
                    SnackbarService.showError(context, 'Failed to unpair.');
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.error),
                title: Text('Delete Pair',
                    style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  try {
                    await notifier.deletePhoto(before.id, before.storagePath);
                    await notifier.deletePhoto(after.id, after.storagePath);
                    if (!mounted) return;
                    SnackbarService.showSuccess(context, 'Pair deleted.');
                  } catch (_) {
                    if (!mounted) return;
                    SnackbarService.showError(
                        context, 'Failed to delete pair.');
                  }
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showPairEditForm(ProjectPhoto before, ProjectPhoto after) {
    final notifier =
        ref.read(projectPhotosProvider(widget.projectId).notifier);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => _PairEditFormSheet(
        before: before,
        after: after,
        onSave: (roomTag, caption) async {
          Navigator.of(ctx, rootNavigator: true).pop();
          try {
            await notifier.updatePhoto(before.id,
                roomTag: roomTag, caption: caption);
            await notifier.updatePhoto(after.id,
                roomTag: roomTag, caption: caption);
            if (!mounted) return;
            SnackbarService.showSuccess(context, 'Details updated.');
          } catch (_) {
            if (!mounted) return;
            SnackbarService.showError(context, 'Failed to save changes.');
          }
        },
      ),
    );
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

  Future<void> _onRefresh() async {
    ref.invalidate(projectPhotosProvider(widget.projectId));
    ref.invalidate(projectDetailProvider(widget.projectId));
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
                onMoreTap: _showPairEditSheet,
              )
            : PhotosCuratedGrid(
                projectId: widget.projectId,
                viewSource: _activeSegment,
                onPhotoTap: _onPhotoTap,
                onChainTap: _onChainTap,
                onLinkTap: _showPairPicker,
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
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: body,
          ),
        ),
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
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: body,
      ),
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
                backgroundColor: AppColors.accent,
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

// ── Pair picker sheet ─────────────────────────────────────────────────────────

/// Bottom sheet showing unpaired photos of the opposite type to pair with.
class _PairPickerSheet extends StatelessWidget {
  const _PairPickerSheet({
    required this.source,
    required this.candidates,
    required this.onSelected,
  });

  final ProjectPhoto source;
  final List<ProjectPhoto> candidates;
  final void Function(ProjectPhoto candidate) onSelected;

  @override
  Widget build(BuildContext context) {
    final oppositeType = source.photoType == 'before' ? 'after' : 'before';
    return Material(
      type: MaterialType.transparency,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.55,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Choose $oppositeType photo to pair',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepNavy,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                    child: const Icon(Icons.close, size: 20, color: AppColors.gray500),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.gray200),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: candidates.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 72, color: AppColors.gray200),
                itemBuilder: (context, i) {
                  final photo = candidates[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: (photo.signedUrl != null &&
                                photo.signedUrl!.isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: photo.signedUrl!,
                                fit: BoxFit.cover,
                              )
                            : const ColoredBox(color: AppColors.gray400),
                      ),
                    ),
                    title: Text(
                      photo.roomTag?.isNotEmpty == true
                          ? photo.roomTag!
                          : photo.photoType,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '${photo.photoType.toUpperCase()} · ${photo.createdAt.month}/${photo.createdAt.day}/${photo.createdAt.year}',
                      style: const TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 10,
                        color: AppColors.gray500,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.gray500),
                    onTap: () => onSelected(photo),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ── Pair edit form sheet ───────────────────────────────────────────────────────

/// Modal form for editing room tag and caption on a before/after pair.
class _PairEditFormSheet extends StatefulWidget {
  const _PairEditFormSheet({
    required this.before,
    required this.after,
    required this.onSave,
  });

  final ProjectPhoto before;
  final ProjectPhoto after;
  final void Function(String roomTag, String caption) onSave;

  @override
  State<_PairEditFormSheet> createState() => _PairEditFormSheetState();
}

class _PairEditFormSheetState extends State<_PairEditFormSheet> {
  late final TextEditingController _roomTagCtrl;
  late final TextEditingController _captionCtrl;

  @override
  void initState() {
    super.initState();
    final tag = widget.before.roomTag ?? widget.after.roomTag ?? '';
    final caption = widget.before.caption ?? widget.after.caption ?? '';
    _roomTagCtrl = TextEditingController(text: tag);
    _captionCtrl = TextEditingController(text: caption);
  }

  @override
  void dispose() {
    _roomTagCtrl.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle + header
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 4),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Edit pair details',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepNavy,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.of(context, rootNavigator: true).pop(),
                      child: const Icon(Icons.close,
                          size: 20, color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.gray200),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Room / Area'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _roomTagCtrl,
                      decoration: _inputDecoration('e.g. Living Room'),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel('Caption'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _captionCtrl,
                      decoration: _inputDecoration(
                          'Describe the transformation…'),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                      minLines: 2,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => widget.onSave(
                          _roomTagCtrl.text.trim(),
                          _captionCtrl.text.trim(),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.deepNavy,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textDisabled,
          fontSize: 14,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.deepNavy, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.gray50,
      );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: AppColors.textSecondary,
        ),
      );
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
                      strokeWidth: 2,
                      color: AppColors.darkTextSecondary,
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
