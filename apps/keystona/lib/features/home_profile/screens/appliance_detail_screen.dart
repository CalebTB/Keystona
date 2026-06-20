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
import '../models/appliance.dart';
import '../models/appliance_detail.dart';
import '../providers/appliance_detail_provider.dart';
import '../widgets/system_photo_strip.dart';

class ApplianceDetailScreen extends ConsumerWidget {
  const ApplianceDetailScreen({super.key, required this.applianceId});
  final String applianceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final detailState = ref.watch(applianceDetailProvider(applianceId));
    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          previousPageTitle: 'Appliances',
          middle: detailState.maybeWhen(
            data: (d) =>
                Text(d.appliance.name, overflow: TextOverflow.ellipsis),
            orElse: () => const Text('Appliance'),
          ),
          trailing: detailState.maybeWhen(
            data: (d) => CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.push(
                AppRoutes.homeAppliancesAdd,
                extra: d.appliance,
              ),
              child: const Text('Edit'),
            ),
            orElse: () => null,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: _Body(
            applianceId: applianceId,
            detailState: detailState,
            isIOS: true,
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      appBar: AppBar(
        backgroundColor: AppColors.warmOffWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: detailState.maybeWhen(
          data: (d) => Text(d.appliance.name, style: AppTextStyles.h3),
          orElse: () => Text('Appliance', style: AppTextStyles.h3),
        ),
        actions: [
          detailState.maybeWhen(
            data: (d) => TextButton(
              onPressed: () => context.push(
                AppRoutes.homeAppliancesAdd,
                extra: d.appliance,
              ),
              child: const Text('Edit'),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: _Body(
        applianceId: applianceId,
        detailState: detailState,
        isIOS: false,
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.applianceId,
    required this.detailState,
    required this.isIOS,
  });
  final String applianceId;
  final AsyncValue<ApplianceDetail> detailState;
  final bool isIOS;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return detailState.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => ErrorView(
        message: "Couldn't load appliance details.",
        onRetry: () =>
            ref.read(applianceDetailProvider(applianceId).notifier).refresh(),
      ),
      data: (detail) => _Content(
        detail: detail,
        applianceId: applianceId,
        isIOS: isIOS,
      ),
    );
  }
}

class _Content extends ConsumerStatefulWidget {
  const _Content({
    required this.detail,
    required this.applianceId,
    required this.isIOS,
  });
  final ApplianceDetail detail;
  final String applianceId;
  final bool isIOS;

  @override
  ConsumerState<_Content> createState() => _ContentState();
}

class _ContentState extends ConsumerState<_Content> {
  bool _deleting = false;

  Future<void> _pickPhoto() async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    ImageSource? source;
    if (isIOS) {
      source = await showCupertinoModalPopup<ImageSource>(
        context: context,
        builder: (_) => CupertinoActionSheet(
          title: const Text('Add Photo'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context, rootNavigator: true)
                  .pop(ImageSource.camera),
              child: const Text('Take Photo'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context, rootNavigator: true)
                  .pop(ImageSource.gallery),
              child: const Text('Choose from Library'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: false,
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(null),
            child: const Text('Cancel'),
          ),
        ),
      );
    } else {
      source = ImageSource.gallery;
    }
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final notifier =
        ref.read(applianceDetailProvider(widget.detail.appliance.id).notifier);
    final photo = await picker.pickImage(source: source, imageQuality: 85);
    if (photo == null || !mounted) return;

    try {
      await notifier.uploadPhoto(photo);
      if (mounted) SnackbarService.showSuccess(context, 'Photo added.');
    } catch (_) {
      if (mounted) {
        SnackbarService.showError(context, "Couldn't upload photo. Try again.");
      }
    }
  }

  Future<void> _confirmDelete() async {
    bool confirmed = false;
    if (widget.isIOS) {
      final r = await showCupertinoDialog<bool>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Delete Appliance'),
          content: Text(
            'Delete "${widget.detail.appliance.name}"? This cannot be undone.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop(false),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      confirmed = r ?? false;
    } else {
      final r = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete Appliance'),
          content: Text(
            'Delete "${widget.detail.appliance.name}"? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style:
                  TextButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      confirmed = r ?? false;
    }
    if (!confirmed || !mounted) return;
    setState(() => _deleting = true);
    try {
      final notifier =
          ref.read(applianceDetailProvider(widget.applianceId).notifier);
      await notifier.softDelete();
      if (!mounted) return;
      context.pop();
    } catch (_) {
      if (!mounted) return;
      SnackbarService.showError(context, 'Failed to delete appliance.');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.detail.appliance;
    final tasksAsync = ref.watch(maintenanceTasksProvider);

    // Derive task counts for the quick-action row.
    final allTasks = tasksAsync.value ?? <MaintenanceTask>[];
    final linkedTasks = allTasks
        .where((t) =>
            t.linkedApplianceId == a.id &&
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

    final photoCount = widget.detail.photos.length;

    // Parse notes into spec rows (lines containing ":").
    final specRows = _parseSpecRows(a.notes);

    final icon = _applianceIcon(a.category);
    final categoryColor = _applianceCategoryColor(a.category);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Dark Hero Card ──────────────────────────────────────────
              _HeroCard(
                icon: icon,
                categoryColor: categoryColor,
                name: a.name,
                brand: a.brand,
                modelNumber: a.modelNumber,
                purchaseDateStr: a.purchaseDate,
                lifespanYears: a.lifespanOverride,
                purchasePrice: a.purchasePrice,
              ),

              // ── 2. Warranty Callout Card ───────────────────────────────────
              if (a.warrantyExpiration != null || a.warrantyProvider != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _WarrantyCalloutCard(
                    warrantyExpiration: a.warrantyExpiration,
                    warrantyProvider: a.warrantyProvider,
                    linkedWarrantyDocId: a.linkedWarrantyDocId,
                  ),
                ),

              // ── 3. Quick-Action Row ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _QuickActionRow(
                  taskCount: taskCount,
                  dueCount: dueCount,
                  docCount: a.linkedWarrantyDocId != null ? 1 : 0,
                  photoCount: photoCount,
                  linkedWarrantyDocId: a.linkedWarrantyDocId,
                  onAddPhoto: _pickPhoto,
                  applianceId: a.id,
                  applianceName: a.name,
                ),
              ),

              // ── 4 + 5. Identification Card ─────────────────────────────────
              _SectionLabel2('IDENTIFICATION'),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _InfoCard2(rows: [
                  if (a.brand != null) _InfoRow2Data('Brand', a.brand!),
                  if (a.modelNumber != null)
                    _InfoRow2Data('Model', a.modelNumber!, copyable: true),
                  if (a.serialNumber != null)
                    _InfoRow2Data('Serial', a.serialNumber!, copyable: true),
                  if (a.location != null)
                    _InfoRow2Data('Location', a.location!),
                  if (a.color != null) _InfoRow2Data('Color', a.color!),
                ]),
              ),

              // ── 6. Specifications Card (parsed notes) ──────────────────────
              if (specRows.isNotEmpty) ...[
                _SectionLabel2('SPECIFICATIONS'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: _InfoCard2(
                    rows: specRows
                        .map((r) => _InfoRow2Data(r.$1, r.$2))
                        .toList(),
                  ),
                ),
              ],

              // ── 7. Photos section ──────────────────────────────────────────
              _SectionLabel2('PHOTOS'),
              SystemPhotoStrip(
                photos: widget.detail.photos,
                onAddPhoto: _pickPhoto,
                photoUrlBuilder: (path) =>
                    widget.detail.photoUrls[path] ?? path,
              ),
              const SizedBox(height: AppSizes.xl),

              // ── 8. Delete button ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenPadding),
                child: OutlinedButton(
                  onPressed: _deleting ? null : _confirmDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize:
                        const Size.fromHeight(AppSizes.buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusSm),
                    ),
                  ),
                  child: _deleting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.error,
                          ),
                        )
                      : const Text('Delete Appliance'),
                ),
              ),
              const SizedBox(height: AppSizes.xl),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

IconData _applianceIcon(ApplianceCategory cat) => switch (cat) {
      ApplianceCategory.kitchen => Icons.kitchen_outlined,
      ApplianceCategory.laundry => Icons.local_laundry_service_outlined,
      ApplianceCategory.climate => Icons.ac_unit_outlined,
      ApplianceCategory.cleaning => Icons.cleaning_services_outlined,
      ApplianceCategory.outdoor => Icons.yard_outlined,
      ApplianceCategory.bathroom => Icons.bathtub_outlined,
      ApplianceCategory.other => Icons.devices_other_outlined,
    };

Color _applianceCategoryColor(ApplianceCategory cat) => switch (cat) {
      ApplianceCategory.kitchen => AppColors.teal,
      ApplianceCategory.laundry => AppColors.slate,
      ApplianceCategory.climate => AppColors.sandAmber,
      ApplianceCategory.cleaning => AppColors.olive,
      ApplianceCategory.outdoor => AppColors.sand,
      ApplianceCategory.bathroom => AppColors.amber,
      ApplianceCategory.other => AppColors.gray400,
    };

/// Parse notes into (label, value) pairs by splitting lines on first ":".
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

// ── Private Widgets ────────────────────────────────────────────────────────────

/// Dark hero card — stats header for the detail screen.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.icon,
    required this.categoryColor,
    required this.name,
    this.brand,
    this.modelNumber,
    this.purchaseDateStr,
    this.lifespanYears,
    this.purchasePrice,
  });

  final IconData icon;
  final Color categoryColor;
  final String name;
  final String? brand;
  final String? modelNumber;
  final String? purchaseDateStr;
  final int? lifespanYears;
  final double? purchasePrice;

  @override
  Widget build(BuildContext context) {
    final (healthLabel, healthColor, ageLabel) =
        _computeHealth(purchaseDateStr, lifespanYears);
    final eyebrow =
        '${healthLabel.toUpperCase()} · $ageLabel'.toUpperCase();

    // Stat values
    final boughtVal = purchasePrice != null
        ? NumberFormat.currency(symbol: '\$', decimalDigits: 0)
            .format(purchasePrice!)
        : '—';

    final pctVal = _lifespanPct(purchaseDateStr, lifespanYears);
    final pctStr = pctVal != null ? '${pctVal.round()}%' : '—';

    final yearsLeft = _yearsLeft(purchaseDateStr, lifespanYears);
    final untilEndStr = yearsLeft != null
        ? '${yearsLeft.toStringAsFixed(0)} yr'
        : '—';

    final subtitle = [?brand, ?modelNumber].join(' · ');

    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding, 0, AppSizes.screenPadding, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowXs,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg - 1.5),
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
                // Category icon container
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
                        name,
                        style: AppTextStyles.headlineMedium.copyWith(
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
          // Stats row — subtle category tint separates it from the info above
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
                  if (purchasePrice != null) ...[
                    Expanded(
                      child: _StatCell(label: 'BOUGHT', value: boughtVal),
                    ),
                    VerticalDivider(
                        color: categoryColor.withAlpha(50),
                        width: 1,
                        thickness: 1),
                  ],
                  Expanded(
                    child: _StatCell(label: 'LIFESPAN', value: pctStr),
                  ),
                  VerticalDivider(
                      color: categoryColor.withAlpha(50),
                      width: 1,
                      thickness: 1),
                  Expanded(
                    child: _StatCell(label: 'UNTIL END', value: untilEndStr),
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});
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

class _WarrantyCalloutCard extends StatelessWidget {
  const _WarrantyCalloutCard({
    this.warrantyExpiration,
    this.warrantyProvider,
    this.linkedWarrantyDocId,
  });
  final String? warrantyExpiration;
  final String? warrantyProvider;
  final String? linkedWarrantyDocId;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, expiryCaption) =
        _warrantyStatus(warrantyExpiration);
    return GestureDetector(
      onTap: linkedWarrantyDocId != null
          ? () => context.push(
                AppRoutes.documentDetail
                    .replaceFirst(':documentId', linkedWarrantyDocId!),
              )
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.oliveDim,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: AppColors.olive.withAlpha(51), // 0.2 opacity
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
            if (linkedWarrantyDocId != null)
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({
    required this.taskCount,
    required this.dueCount,
    required this.docCount,
    required this.photoCount,
    required this.onAddPhoto,
    required this.applianceId,
    required this.applianceName,
    this.linkedWarrantyDocId,
  });
  final int taskCount;
  final int dueCount;
  final int docCount;
  final int photoCount;
  final VoidCallback onAddPhoto;
  final String applianceId;
  final String applianceName;
  final String? linkedWarrantyDocId;

  @override
  Widget build(BuildContext context) {
    final taskSub = dueCount > 0
        ? '$taskCount · $dueCount due'
        : '$taskCount';
    final docSub = docCount > 0 ? '$docCount linked' : 'None';
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
              child: _QuickActionCell(
                icon: Icons.task_alt_outlined,
                label: 'Tasks',
                subtitle: taskSub,
                onTap: () => context.push(
                  '/home/appliances/$applianceId/tasks',
                  extra: applianceName,
                ),
              ),
            ),
            VerticalDivider(
              color: AppColors.border,
              width: 1,
              thickness: 1,
            ),
            Expanded(
              child: _QuickActionCell(
                icon: Icons.description_outlined,
                label: 'Docs',
                subtitle: docSub,
                onTap: linkedWarrantyDocId != null
                    ? () => context.push(
                          AppRoutes.documentDetail.replaceFirst(
                              ':documentId', linkedWarrantyDocId!),
                        )
                    : null,
              ),
            ),
            VerticalDivider(
              color: AppColors.border,
              width: 1,
              thickness: 1,
            ),
            Expanded(
              child: _QuickActionCell(
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

class _QuickActionCell extends StatelessWidget {
  const _QuickActionCell({
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

/// Section label with dot prefix.
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
          Text(
            title,
            style: AppTextStyles.monoSection,
          ),
        ],
      ),
    );
  }
}

/// Data holder for an info card row.
class _InfoRow2Data {
  const _InfoRow2Data(this.label, this.value, {this.copyable = false});
  final String label;
  final String value;
  final bool copyable;
}

/// iOS-style bordered info card with label/value rows and animated copy feedback.
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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

/// Returns (healthLabel, healthColor, ageLabel).
(String, Color, String) _computeHealth(
    String? purchaseDateStr, int? lifespanYears) {
  if (purchaseDateStr == null) {
    return ('Good', AppColors.darkTextSecondary, '—');
  }
  final DateTime purchase;
  try {
    purchase = DateTime.parse(purchaseDateStr);
  } catch (_) {
    return ('Good', AppColors.darkTextSecondary, '—');
  }
  final ageYears =
      DateTime.now().difference(purchase).inDays / 365.25;
  final ageLabel =
      '${ageYears.toStringAsFixed(1)} yr old';

  if (lifespanYears == null || lifespanYears <= 0) {
    return ('Good', AppColors.darkTextSecondary, ageLabel);
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

double? _lifespanPct(String? purchaseDateStr, int? lifespanYears) {
  if (purchaseDateStr == null || lifespanYears == null || lifespanYears <= 0) {
    return null;
  }
  try {
    final purchase = DateTime.parse(purchaseDateStr);
    final ageYears =
        DateTime.now().difference(purchase).inDays / 365.25;
    return (ageYears / lifespanYears * 100).clamp(0, 999);
  } catch (_) {
    return null;
  }
}

double? _yearsLeft(String? purchaseDateStr, int? lifespanYears) {
  if (purchaseDateStr == null || lifespanYears == null || lifespanYears <= 0) {
    return null;
  }
  try {
    final purchase = DateTime.parse(purchaseDateStr);
    final ageYears =
        DateTime.now().difference(purchase).inDays / 365.25;
    final left = lifespanYears - ageYears;
    return left < 0 ? 0 : left;
  } catch (_) {
    return null;
  }
}

/// Returns (statusLabel, caption) for the warranty callout.
(String, String) _warrantyStatus(String? warrantyExpirationStr) {
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
    final yearsLeft = (diff.inDays / 365.25);
    final label = yearsLeft < 1
        ? '< 1 yr remaining'
        : '${yearsLeft.round()} yrs remaining';
    return ('Active · $label', 'Expires $fmt');
  }
}
