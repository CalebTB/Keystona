import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/system.dart';
import '../models/system_detail.dart';
import '../providers/system_detail_provider.dart';
import '../widgets/system_photo_strip.dart';

/// System Detail screen — lives at `/home/systems/:systemId`.
///
/// Shows all system fields, attached photos, and action buttons (edit, delete).
///
/// Adaptive layout:
///   iOS  → [CupertinoPageScaffold] with [CupertinoNavigationBar]
///   Android → [Scaffold] with [AppBar]
class SystemDetailScreen extends ConsumerWidget {
  const SystemDetailScreen({super.key, required this.systemId});

  final String systemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return isIOS
        ? _IOSLayout(systemId: systemId)
        : _AndroidLayout(systemId: systemId);
  }
}

// ── iOS layout ─────────────────────────────────────────────────────────────────

class _IOSLayout extends ConsumerWidget {
  const _IOSLayout({required this.systemId});

  final String systemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(systemDetailProvider(systemId));

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        previousPageTitle: 'Systems',
        middle: detailAsync.maybeWhen(
          data: (d) => Text(d.system.name, overflow: TextOverflow.ellipsis),
          orElse: () => const Text('System'),
        ),
        trailing: detailAsync.maybeWhen(
          data: (_) => CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              final detail = detailAsync.value;
              if (detail != null) {
                context.push(
                  AppRoutes.homeSystemsAdd,
                  extra: detail.system,
                );
              }
            },
            child: const Text('Edit'),
          ),
          orElse: () => null,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: _DetailBody(systemId: systemId, detailAsync: detailAsync),
      ),
    );
  }
}

// ── Android layout ─────────────────────────────────────────────────────────────

class _AndroidLayout extends ConsumerWidget {
  const _AndroidLayout({required this.systemId});

  final String systemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(systemDetailProvider(systemId));

    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      appBar: AppBar(
        title: detailAsync.maybeWhen(
          data: (d) => Text(d.system.name, style: AppTextStyles.h3),
          orElse: () => Text('System', style: AppTextStyles.h3),
        ),
        backgroundColor: AppColors.warmOffWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (detailAsync.hasValue)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                final detail = detailAsync.value;
                if (detail != null) {
                  context.push(AppRoutes.homeSystemsAdd, extra: detail.system);
                }
              },
            ),
        ],
      ),
      body: _DetailBody(systemId: systemId, detailAsync: detailAsync),
    );
  }
}

// ── Detail body ────────────────────────────────────────────────────────────────

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.systemId, required this.detailAsync});

  final String systemId;
  final AsyncValue<SystemDetail> detailAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return detailAsync.when(
      loading: () => const _DetailSkeleton(),
      error: (_, _) => ErrorView(
        message: "Couldn't load system details.",
        onRetry: () => ref.invalidate(systemDetailProvider(systemId)),
      ),
      data: (detail) => _DetailContent(
        systemId: systemId,
        detail: detail,
      ),
    );
  }
}

// ── Skeleton ───────────────────────────────────────────────────────────────────

class _DetailSkeleton extends StatefulWidget {
  const _DetailSkeleton();

  @override
  State<_DetailSkeleton> createState() => _DetailSkeletonState();
}

class _DetailSkeletonState extends State<_DetailSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(_ctrl);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, _) => Opacity(
        opacity: _opacity.value,
        child: Padding(
          padding: AppPadding.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.md),
              _SkeletonBar(widthFactor: 0.6, height: 16),
              const SizedBox(height: AppSizes.sm),
              _SkeletonBar(widthFactor: 0.4, height: 12),
              const SizedBox(height: AppSizes.lg),
              _SkeletonBar(widthFactor: 1.0, height: 80),
              const SizedBox(height: AppSizes.md),
              _SkeletonBar(widthFactor: 1.0, height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.widthFactor, required this.height});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.gray200,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
      ),
    );
  }
}

// ── Main content ───────────────────────────────────────────────────────────────

class _DetailContent extends ConsumerStatefulWidget {
  const _DetailContent({required this.systemId, required this.detail});

  final String systemId;
  final SystemDetail detail;

  @override
  ConsumerState<_DetailContent> createState() => _DetailContentState();
}

class _DetailContentState extends ConsumerState<_DetailContent> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final system = widget.detail.system;
    final photos = widget.detail.photos;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSizes.sm),

                // ── Status badge ─────────────────────────────────────────────
                Padding(
                  padding: AppPadding.screenHorizontal,
                  child: _StatusBadge(status: system.status),
                ),
                const SizedBox(height: AppSizes.lg),

                // ── Classification section ───────────────────────────────────
                _SectionHeader(title: 'System Info'),
                _InfoRow(
                  label: 'Category',
                  value: system.category.label,
                ),
                _InfoRow(label: 'Type', value: system.systemType),
                if (system.brand != null)
                  _InfoRow(label: 'Brand', value: system.brand!),
                if (system.modelNumber != null)
                  _InfoRow(label: 'Model', value: system.modelNumber!),
                if (system.serialNumber != null)
                  _InfoRow(label: 'Serial #', value: system.serialNumber!),
                if (system.location != null)
                  _InfoRow(label: 'Location', value: system.location!),

                const _SectionDivider(),

                // ── Installation section ─────────────────────────────────────
                _SectionHeader(title: 'Installation'),
                if (system.installationDate != null)
                  _InfoRow(
                    label: 'Installed',
                    value: _formatDate(system.installationDate!),
                  ),
                if (system.installer != null)
                  _InfoRow(label: 'Installer', value: system.installer!),
                if (system.purchasePrice != null)
                  _InfoRow(
                    label: 'Purchase Price',
                    value:
                        '\$${NumberFormat('#,##0.00').format(system.purchasePrice!)}',
                  ),

                if (system.installationDate != null ||
                    system.installer != null ||
                    system.purchasePrice != null)
                  const _SectionDivider(),

                // ── Lifespan section ─────────────────────────────────────────
                if (system.expectedLifespanMin != null ||
                    system.expectedLifespanMax != null ||
                    system.lifespanOverride != null) ...[
                  _SectionHeader(title: 'Lifespan'),
                  if (system.lifespanOverride != null)
                    _InfoRow(
                      label: 'Expected',
                      value: '${system.lifespanOverride} years (custom)',
                    )
                  else if (system.expectedLifespanMin != null &&
                      system.expectedLifespanMax != null)
                    _InfoRow(
                      label: 'Expected',
                      value:
                          '${system.expectedLifespanMin}–${system.expectedLifespanMax} years',
                    ),
                  if (system.estimatedReplacementCost != null)
                    _InfoRow(
                      label: 'Replacement Cost',
                      value:
                          '\$${NumberFormat('#,##0').format(system.estimatedReplacementCost!)}',
                    ),
                  const _SectionDivider(),
                ],

                // ── Warranty section ─────────────────────────────────────────
                if (system.warrantyExpiration != null ||
                    system.warrantyProvider != null) ...[
                  _SectionHeader(title: 'Warranty'),
                  if (system.warrantyExpiration != null)
                    _InfoRow(
                      label: 'Expires',
                      value: _formatDate(system.warrantyExpiration!),
                    ),
                  if (system.warrantyProvider != null)
                    _InfoRow(
                      label: 'Provider',
                      value: system.warrantyProvider!,
                    ),
                  const _SectionDivider(),
                ],

                // ── Notes ────────────────────────────────────────────────────
                if (system.notes != null && system.notes!.isNotEmpty) ...[
                  _SectionHeader(title: 'Notes'),
                  Padding(
                    padding: AppPadding.screenHorizontal,
                    child: Text(
                      system.notes!,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  const _SectionDivider(),
                ],

                // ── Photos ────────────────────────────────────────────────────
                _SectionHeader(title: 'Photos'),
                const SizedBox(height: AppSizes.sm),
                SystemPhotoStrip(
                  photos: photos,
                  onAddPhoto: _pickPhoto,
                ),
                const SizedBox(height: AppSizes.xl),
              ],
            ),
          ),
        ),

        // ── Delete button ──────────────────────────────────────────────────
        _DeleteBar(
          isDeleting: _deleting,
          onDelete: _confirmDelete,
        ),
      ],
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _pickPhoto() async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final source = await _PhotoSourceSheet.show(context, isIOS: isIOS);
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final notifier = ref.read(systemDetailProvider(widget.systemId).notifier);

    final XFile? photo = source == ImageSource.camera
        ? await picker.pickImage(source: ImageSource.camera, imageQuality: 85)
        : await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

    if (photo == null || !mounted) return;

    try {
      await notifier.uploadPhoto(photo);
      if (mounted) {
        SnackbarService.showSuccess(context, 'Photo added.');
      }
    } catch (_) {
      if (mounted) {
        SnackbarService.showError(context, "Couldn't upload photo. Try again.");
      }
    }
  }

  Future<void> _confirmDelete() async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final confirmed = await _DeleteConfirmSheet.show(
      context,
      systemName: widget.detail.system.name,
      isIOS: isIOS,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref
          .read(systemDetailProvider(widget.systemId).notifier)
          .deleteSystem();
      if (!mounted) return;
      context.pop();
    } catch (_) {
      if (!mounted) return;
      SnackbarService.showError(context, "Couldn't delete system. Try again.");
      setState(() => _deleting = false);
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('MMMM d, y').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}

// ── Section helpers ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.md,
        AppSizes.screenPadding,
        AppSizes.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.divider,
      indent: AppSizes.screenPadding,
      endIndent: AppSizes.screenPadding,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenPadding,
        vertical: 6,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ItemStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ItemStatus.active => ('Active', AppColors.success),
      ItemStatus.needsRepair => ('Needs Repair', AppColors.warning),
      ItemStatus.replaced => ('Replaced', AppColors.textSecondary),
      ItemStatus.removed => ('Removed', AppColors.textDisabled),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }
}

// ── Delete bar ─────────────────────────────────────────────────────────────────

class _DeleteBar extends StatelessWidget {
  const _DeleteBar({required this.isDeleting, required this.onDelete});

  final bool isDeleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.md,
        AppSizes.screenPadding,
        AppSizes.screenPadding + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isIOS ? CupertinoColors.systemBackground : AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SizedBox(
        height: 44,
        child: OutlinedButton.icon(
          onPressed: isDeleting ? null : onDelete,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
          ),
          icon: isDeleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.error,
                  ),
                )
              : const Icon(Icons.delete_outline, size: 18),
          label: Text(
            isDeleting ? 'Removing…' : 'Remove System',
            style: AppTextStyles.bodyMediumSemibold.copyWith(
              color: isDeleting ? AppColors.textDisabled : AppColors.error,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Photo source sheet ─────────────────────────────────────────────────────────

class _PhotoSourceSheet {
  static Future<ImageSource?> show(
    BuildContext context, {
    required bool isIOS,
  }) async {
    if (isIOS) {
      return showCupertinoModalPopup<ImageSource>(
        context: context,
        builder: (_) => CupertinoActionSheet(
          title: const Text('Add Photo'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true)
                      .pop(ImageSource.camera),
              child: const Text('Take Photo'),
            ),
            CupertinoActionSheetAction(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true)
                      .pop(ImageSource.gallery),
              child: const Text('Choose from Library'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: false,
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Cancel'),
          ),
        ),
      );
    }

    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSizes.sm),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Take Photo'),
            onTap: () => context.pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from Library'),
            onTap: () => context.pop(ImageSource.gallery),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + AppSizes.sm),
        ],
      ),
    );
  }
}

// ── Delete confirm sheet ───────────────────────────────────────────────────────

class _DeleteConfirmSheet {
  static Future<bool?> show(
    BuildContext context, {
    required String systemName,
    required bool isIOS,
  }) async {
    if (isIOS) {
      return showCupertinoModalPopup<bool>(
        context: context,
        builder: (_) => CupertinoActionSheet(
          title: const Text('Remove System'),
          message: Text(
            '"$systemName" will be removed from your home profile. '
            'This cannot be undone.',
          ),
          actions: [
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop(true),
              child: const Text('Remove System'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(false),
            child: const Text('Cancel'),
          ),
        ),
      );
    }

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove System'),
        content: Text(
          '"$systemName" will be removed from your home profile. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => ctx.pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
