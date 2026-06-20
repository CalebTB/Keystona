import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../maintenance/models/maintenance_task.dart';
import '../../maintenance/providers/maintenance_tasks_provider.dart';
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

    final tasksAsync = ref.watch(maintenanceTasksProvider);
    final allTasks = tasksAsync.value ?? <MaintenanceTask>[];
    final linkedTasks = allTasks
        .where((t) =>
            t.linkedSystemId == system.id &&
            t.status != TaskStatus.completed &&
            t.status != TaskStatus.skipped)
        .toList();
    final taskCount = linkedTasks.length;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueCount = linkedTasks
        .where((t) =>
            !t.dueDate.isAfter(today) ||
            t.status == TaskStatus.overdue ||
            t.status == TaskStatus.due)
        .length;

    final photoCount = photos.length;

    // Parse notes into spec rows.
    final specRows = _parseSpecRows(system.notes);

    final icon = _systemIcon(system.category);
    final categoryColor = _systemCategoryColor(system.category);

    // Stats: Installed year / Lifespan % / Years left
    final installedVal = system.installationDate != null
        ? _yearFromDate(system.installationDate!)
        : '—';
    final effectiveLifespan = system.lifespanOverride ??
        (system.expectedLifespanMin != null && system.expectedLifespanMax != null
            ? ((system.expectedLifespanMin! + system.expectedLifespanMax!) / 2)
                .round()
            : null);
    final pctVal = _sysLifespanPct(system.installationDate, effectiveLifespan);
    final pctStr = pctVal != null ? '${pctVal.round()}%' : '—';
    final yearsLeft =
        _sysYearsLeft(system.installationDate, effectiveLifespan);
    final untilEndStr = yearsLeft != null
        ? '${yearsLeft.toStringAsFixed(0)} yr'
        : '—';

    // Hero health
    final (healthLabel, healthColor, ageLabel) =
        _computeSystemHealth(system.installationDate, effectiveLifespan);
    final eyebrow =
        '${healthLabel.toUpperCase()} · $ageLabel'.toUpperCase();

    final subtitle = [
      if (system.brand != null) system.brand!,
      if (system.modelNumber != null) system.modelNumber!,
    ].join(' · ');

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. Hero Card (white + category accent) ────────────
                    Container(
                      margin: const EdgeInsets.fromLTRB(
                          AppSizes.screenPadding, 0,
                          AppSizes.screenPadding, 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusLg),
                        border: Border.all(
                            color: AppColors.border, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadowXs,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                            AppSizes.radiusLg - 1.5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Colored top accent strip
                            Container(height: 3, color: categoryColor),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: categoryColor.withAlpha(28),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(icon, color: categoryColor, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        eyebrow,
                                        style: GoogleFonts.ibmPlexMono(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                          color: healthColor,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        system.name,
                                        style: AppTextStyles.headlineMedium
                                            .copyWith(
                                          color: AppColors.textPrimary,
                                          fontSize: 21,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (subtitle.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          subtitle,
                                          style: GoogleFonts.ibmPlexMono(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.textSecondary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Stats row with subtle category tint
                          Container(
                            decoration: BoxDecoration(
                              color: categoryColor.withAlpha(14),
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(AppSizes.radiusLg - 1.5),
                              ),
                              border: Border(
                                top: BorderSide(
                                  color: categoryColor.withAlpha(40),
                                  width: 1,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  if (system.installationDate != null) ...[
                                    Expanded(
                                      child: _StatCell2(
                                          label: 'INSTALLED',
                                          value: installedVal),
                                    ),
                                    VerticalDivider(
                                      color: categoryColor.withAlpha(50),
                                      width: 1,
                                      thickness: 1,
                                    ),
                                  ],
                                  Expanded(
                                    child: _StatCell2(
                                        label: 'LIFESPAN',
                                        value: pctStr),
                                  ),
                                  VerticalDivider(
                                    color: categoryColor.withAlpha(50),
                                    width: 1,
                                    thickness: 1,
                                  ),
                                  Expanded(
                                    child: _StatCell2(
                                        label: 'UNTIL END',
                                        value: untilEndStr),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ],
                        ),
                      ),
                    ),

                    // ── 2. Warranty Callout Card ───────────────────────────
                    if (system.warrantyExpiration != null ||
                        system.warrantyProvider != null)
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: _WarrantyCalloutCard2(
                          warrantyExpiration: system.warrantyExpiration,
                          warrantyProvider: system.warrantyProvider,
                        ),
                      ),

                    // ── 3. Quick-Action Row ────────────────────────────────
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: _QuickActionRow2(
                        taskCount: taskCount,
                        dueCount: dueCount,
                        photoCount: photoCount,
                        onAddPhoto: _pickPhoto,
                        systemId: system.id,
                        systemName: system.name,
                      ),
                    ),

                    // ── 4 + 5. Identification Card ─────────────────────────
                    _SectionLabel2('IDENTIFICATION'),
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: _InfoCard2(rows: [
                        if (system.brand != null)
                          _InfoRow2Data('Brand', system.brand!),
                        if (system.modelNumber != null)
                          _InfoRow2Data('Model', system.modelNumber!,
                              copyable: true),
                        if (system.serialNumber != null)
                          _InfoRow2Data('Serial', system.serialNumber!,
                              copyable: true),
                        if (system.location != null)
                          _InfoRow2Data('Location', system.location!),
                        if (system.installer != null)
                          _InfoRow2Data(
                              'Installer', system.installer!),
                      ]),
                    ),

                    // ── 6. Specifications Card (parsed notes) ──────────────
                    if (specRows.isNotEmpty) ...[
                      _SectionLabel2('SPECIFICATIONS'),
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: _InfoCard2(
                          rows: specRows
                              .map((r) => _InfoRow2Data(r.$1, r.$2))
                              .toList(),
                        ),
                      ),
                    ],

                    // ── 7. Photos section ──────────────────────────────────
                    _SectionLabel2('PHOTOS'),
                    SystemPhotoStrip(
                      photos: photos,
                      onAddPhoto: _pickPhoto,
                      photoUrlBuilder: (path) =>
                          widget.detail.photoUrls[path] ?? path,
                    ),
                    const SizedBox(height: AppSizes.xl),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Delete bar ──────────────────────────────────────────────────────
        _DeleteBar(
          isDeleting: _deleting,
          onDelete: _confirmDelete,
        ),
      ],
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

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

// ── New dashboard widgets (system-specific) ────────────────────────────────────

class _StatCell2 extends StatelessWidget {
  const _StatCell2({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyMediumSemibold.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _WarrantyCalloutCard2 extends StatelessWidget {
  const _WarrantyCalloutCard2({
    this.warrantyExpiration,
    this.warrantyProvider,
  });
  final String? warrantyExpiration;
  final String? warrantyProvider;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, expiryCaption) =
        _warrantyStatus2(warrantyExpiration);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.oliveDim,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.olive.withAlpha(51),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.olive.withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.olive,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MANUFACTURER WARRANTY',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusLabel,
                  style: AppTextStyles.bodyMediumSemibold,
                ),
                if (expiryCaption.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    expiryCaption,
                    style: AppTextStyles.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionRow2 extends StatelessWidget {
  const _QuickActionRow2({
    required this.taskCount,
    required this.dueCount,
    required this.photoCount,
    required this.onAddPhoto,
    required this.systemId,
    required this.systemName,
  });
  final int taskCount;
  final int dueCount;
  final int photoCount;
  final VoidCallback onAddPhoto;
  final String systemId;
  final String systemName;

  @override
  Widget build(BuildContext context) {
    final taskSub =
        dueCount > 0 ? '$taskCount · $dueCount due' : '$taskCount';
    const docSub = 'None';
    final photoSub = photoCount > 0 ? '$photoCount photo${photoCount == 1 ? '' : 's'}' : '+ Add';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _QuickActionCell2(
                icon: Icons.task_alt_outlined,
                label: 'Tasks',
                subtitle: taskSub,
                onTap: () => context.push(
                  '/home/systems/$systemId/tasks',
                  extra: systemName,
                ),
              ),
            ),
            VerticalDivider(
              color: AppColors.border,
              width: 1,
              thickness: 1,
            ),
            Expanded(
              child: _QuickActionCell2(
                icon: Icons.description_outlined,
                label: 'Docs',
                subtitle: docSub,
                onTap: null,
              ),
            ),
            VerticalDivider(
              color: AppColors.border,
              width: 1,
              thickness: 1,
            ),
            Expanded(
              child: _QuickActionCell2(
                icon: Icons.photo_camera_outlined,
                label: 'Photos',
                subtitle: photoSub,
                onTap: onAddPhoto,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCell2 extends StatelessWidget {
  const _QuickActionCell2({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: AppColors.deepNavy),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.labelSmall),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel2 extends StatelessWidget {
  const _SectionLabel2(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.deepNavy,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(title, style: AppTextStyles.monoSection),
        ],
      ),
    );
  }
}

class _InfoRow2Data {
  const _InfoRow2Data(this.label, this.value, {this.copyable = false});
  final String label;
  final String value;
  final bool copyable;
}

class _InfoCard2 extends StatefulWidget {
  const _InfoCard2({required this.rows});
  final List<_InfoRow2Data> rows;

  @override
  State<_InfoCard2> createState() => _InfoCard2State();
}

class _InfoCard2State extends State<_InfoCard2> {
  int? _copiedIndex;

  void _handleCopy(int i) {
    Clipboard.setData(ClipboardData(text: widget.rows[i].value));
    setState(() => _copiedIndex = i);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _copiedIndex = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          for (var i = 0; i < widget.rows.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 0.5, indent: 0),
            GestureDetector(
              onTap: widget.rows[i].copyable ? () => _handleCopy(i) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 11),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        widget.rows[i].label,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.rows[i].value,
                        style: AppTextStyles.bodyMediumSemibold,
                      ),
                    ),
                    if (widget.rows[i].copyable)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _copiedIndex == i
                            ? const Icon(
                                Icons.check_circle,
                                key: ValueKey('check'),
                                size: 14,
                                color: AppColors.olive,
                              )
                            : const Icon(
                                Icons.copy_outlined,
                                key: ValueKey('copy'),
                                size: 14,
                                color: AppColors.textTertiary,
                              ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Pure helper functions ──────────────────────────────────────────────────────

IconData _systemIcon(SystemCategory cat) => switch (cat) {
      SystemCategory.hvac => Icons.hvac_outlined,
      SystemCategory.plumbing => Icons.plumbing_outlined,
      SystemCategory.electrical => Icons.electrical_services_outlined,
      SystemCategory.roofing => Icons.roofing_outlined,
      SystemCategory.foundation => Icons.foundation_outlined,
      SystemCategory.siding => Icons.home_outlined,
      SystemCategory.windowsDoors => Icons.window_outlined,
      SystemCategory.insulation => Icons.layers_outlined,
      SystemCategory.garage => Icons.garage_outlined,
      SystemCategory.other => Icons.handyman_outlined,
    };

Color _systemCategoryColor(SystemCategory cat) => switch (cat) {
      SystemCategory.hvac => AppColors.sandAmber,
      SystemCategory.plumbing => AppColors.teal,
      SystemCategory.electrical => AppColors.amber,
      SystemCategory.roofing => AppColors.slate,
      SystemCategory.foundation => AppColors.gray500,
      SystemCategory.siding => AppColors.sand,
      SystemCategory.windowsDoors => AppColors.olive,
      SystemCategory.insulation => AppColors.plum,
      SystemCategory.garage => AppColors.gray400,
      SystemCategory.other => AppColors.gray400,
    };

List<(String, String)> _parseSpecRows(String? notes) {
  if (notes == null || notes.isEmpty) return const [];
  final rows = <(String, String)>[];
  for (final line in notes.split('\n')) {
    final idx = line.indexOf(':');
    if (idx <= 0) continue;
    final label = line.substring(0, idx).trim();
    final value = line.substring(idx + 1).trim();
    if (label.isNotEmpty && value.isNotEmpty) {
      rows.add((label, value));
    }
  }
  return rows;
}

(String, Color, String) _computeSystemHealth(
    String? installDateStr, int? lifespanYears) {
  if (installDateStr == null) {
    return ('Good', AppColors.textSecondary, '—');
  }
  final DateTime install;
  try {
    install = DateTime.parse(installDateStr);
  } catch (_) {
    return ('Good', AppColors.textSecondary, '—');
  }
  final ageYears = DateTime.now().difference(install).inDays / 365.25;
  final ageLabel = '${ageYears.toStringAsFixed(1)} yr old';

  if (lifespanYears == null || lifespanYears <= 0) {
    return ('Good', AppColors.textTertiary, ageLabel);
  }
  final pct = ageYears / lifespanYears * 100;
  if (pct < 50) {
    return ('Healthy', AppColors.olive, ageLabel);
  } else if (pct <= 75) {
    return ('Aging', AppColors.sandAmber, ageLabel);
  } else {
    return ('Near End', AppColors.accent, ageLabel);
  }
}

String _yearFromDate(String dateStr) {
  try {
    return DateTime.parse(dateStr).year.toString();
  } catch (_) {
    return dateStr;
  }
}

double? _sysLifespanPct(String? installDateStr, int? lifespanYears) {
  if (installDateStr == null || lifespanYears == null || lifespanYears <= 0) {
    return null;
  }
  try {
    final install = DateTime.parse(installDateStr);
    final ageYears = DateTime.now().difference(install).inDays / 365.25;
    return (ageYears / lifespanYears * 100).clamp(0, 999);
  } catch (_) {
    return null;
  }
}

double? _sysYearsLeft(String? installDateStr, int? lifespanYears) {
  if (installDateStr == null || lifespanYears == null || lifespanYears <= 0) {
    return null;
  }
  try {
    final install = DateTime.parse(installDateStr);
    final ageYears = DateTime.now().difference(install).inDays / 365.25;
    final left = lifespanYears - ageYears;
    return left < 0 ? 0 : left;
  } catch (_) {
    return null;
  }
}

(String, String) _warrantyStatus2(String? warrantyExpirationStr) {
  if (warrantyExpirationStr == null) {
    return ('Warranty on file', '');
  }
  final DateTime expiry;
  try {
    expiry = DateTime.parse(warrantyExpirationStr);
  } catch (_) {
    return ('Warranty on file', warrantyExpirationStr);
  }
  final now = DateTime.now();
  final diff = expiry.difference(now);
  final fmt = DateFormat('MMM d, yyyy').format(expiry);
  if (diff.isNegative) {
    final yearsAgo = (diff.inDays.abs() / 365.25).round();
    final label = yearsAgo == 1 ? '1 yr ago' : '$yearsAgo yrs ago';
    return ('Expired · $label', 'Expired $fmt');
  } else {
    final yearsLeft = diff.inDays / 365.25;
    final label = yearsLeft < 1
        ? '< 1 yr remaining'
        : '${yearsLeft.round()} yrs remaining';
    return ('Active · $label', 'Expires $fmt');
  }
}
