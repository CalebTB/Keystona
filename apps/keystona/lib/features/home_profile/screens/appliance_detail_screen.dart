import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/appliance_detail.dart';
import '../models/item_photo.dart';
import '../providers/appliance_detail_provider.dart';

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
      loading: () => const Center(child: CircularProgressIndicator()),
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
    return CustomScrollView(
      slivers: [
        if (widget.detail.photos.isNotEmpty)
          SliverToBoxAdapter(
            child: _PhotoStrip(photos: widget.detail.photos),
          ),
        SliverPadding(
          padding: AppPadding.screen,
          sliver: SliverList.list(
            children: [
              _Section(
                title: 'Appliance Info',
                children: [
                  _InfoRow(label: 'Category', value: a.category.label),
                  _InfoRow(label: 'Name', value: a.name),
                  if (a.brand != null)
                    _InfoRow(label: 'Brand', value: a.brand!),
                  if (a.modelNumber != null)
                    _InfoRow(label: 'Model', value: a.modelNumber!),
                  if (a.serialNumber != null)
                    _InfoRow(label: 'Serial Number', value: a.serialNumber!),
                  if (a.location != null)
                    _InfoRow(label: 'Location', value: a.location!),
                  if (a.color != null)
                    _InfoRow(label: 'Color', value: a.color!),
                  _InfoRow(label: 'Status', value: a.status.label),
                ],
              ),
              if (a.purchaseDate != null || a.purchasePrice != null) ...[
                const SizedBox(height: AppSizes.md),
                _Section(
                  title: 'Purchase',
                  children: [
                    if (a.purchaseDate != null)
                      _InfoRow(label: 'Date', value: a.purchaseDate!),
                    if (a.purchasePrice != null)
                      _InfoRow(
                        label: 'Price',
                        value:
                            '\$${a.purchasePrice!.toStringAsFixed(2)}',
                      ),
                  ],
                ),
              ],
              if (a.lifespanOverride != null) ...[
                const SizedBox(height: AppSizes.md),
                _Section(
                  title: 'Lifespan',
                  children: [
                    _InfoRow(
                      label: 'Expected Lifespan',
                      value: '${a.lifespanOverride} years',
                    ),
                  ],
                ),
              ],
              if (a.warrantyExpiration != null ||
                  a.warrantyProvider != null) ...[
                const SizedBox(height: AppSizes.md),
                _Section(
                  title: 'Warranty',
                  children: [
                    if (a.warrantyExpiration != null)
                      _InfoRow(
                        label: 'Expires',
                        value: a.warrantyExpiration!,
                      ),
                    if (a.warrantyProvider != null)
                      _InfoRow(
                        label: 'Provider',
                        value: a.warrantyProvider!,
                      ),
                  ],
                ),
              ],
              if (a.notes != null && a.notes!.isNotEmpty) ...[
                const SizedBox(height: AppSizes.md),
                _Section(
                  title: 'Notes',
                  children: [
                    Text(
                      a.notes!,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSizes.xl),
              OutlinedButton(
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
              const SizedBox(height: AppSizes.xl),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.md,
              AppSizes.md,
              AppSizes.md,
              AppSizes.xs,
            ),
            child: Text(title, style: AppTextStyles.h4),
          ),
          const Divider(height: 1),
          Padding(
            padding: AppPadding.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMediumSemibold),
          ),
        ],
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.photos});
  final List<ItemPhoto> photos;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: AppPadding.screenHorizontal,
        itemCount: photos.length,
        itemBuilder: (context, _) => Container(
          width: 120,
          height: 120,
          margin: const EdgeInsets.only(right: AppSizes.sm),
          decoration: BoxDecoration(
            color: AppColors.gray200,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Icon(
            Icons.image_outlined,
            color: AppColors.gray400,
            size: 36,
          ),
        ),
      ),
    );
  }
}
