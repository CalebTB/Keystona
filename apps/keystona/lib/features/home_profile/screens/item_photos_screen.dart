import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_home_c.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/aurora/aurora_sheet.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/photo_picker.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../../core/widgets/upgrade_sheet.dart';
import '../../../services/providers/service_providers.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../item_copy.dart';
import '../models/item_photo.dart';
import '../models/item_photo_type.dart';
import '../models/item_ref.dart';
import '../providers/item_photos_provider.dart';
import '../providers/item_summary_provider.dart';
import '../widgets/item/item_header.dart';
import '../widgets/item/item_page.dart';
import '../widgets/item/item_skeleton.dart';
import '../widgets/item/item_top_bar.dart';
import '../widgets/item_photos/item_photo_full_screen.dart';
import '../widgets/item_photos/item_photo_limit_card.dart';
import '../widgets/item_photos/item_photo_thumbs.dart';
import '../widgets/item_photos/item_photo_tips.dart';
import '../widgets/item_photos/item_photo_viewer.dart';
import 'package:intl/intl.dart';

/// A system's or appliance's photos: the big viewer, thumbnails, the plan
/// limit and what is worth photographing (kit: ItemPhotos). Routes:
/// `/home/systems/:systemId/photos`, `/home/appliances/:applianceId/photos`.
class ItemPhotosScreen extends ConsumerStatefulWidget {
  const ItemPhotosScreen({super.key, required this.item});

  final ItemRef item;

  @override
  ConsumerState<ItemPhotosScreen> createState() => _ItemPhotosScreenState();
}

class _ItemPhotosScreenState extends ConsumerState<ItemPhotosScreen> {
  int _selected = 0;
  bool _busy = false;

  ItemRef get _item => widget.item;

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(
        _item.isSystem
            ? AppRoutes.homeSystemDetail.replaceFirst(':systemId', _item.id)
            : AppRoutes.homeApplianceDetail.replaceFirst(
                ':applianceId',
                _item.id,
              ),
      );
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(itemPhotosProvider(_item));
    await ref.read(itemPhotosProvider(_item).future);
  }

  Future<void> _add(int count) async {
    if (_busy) return;
    if (!ref.read(isPremiumProvider) && count >= kFreeItemPhotoLimit) {
      await UpgradeSheet.show(
        context,
        config: const UpgradeSheetConfig(
          headline: ItemCopy.upgradeHeadline,
          reason: ItemCopy.upgradeReason,
          features: ItemCopy.upgradeFeatures,
          triggerKey: ItemCopy.upgradeKey,
        ),
      );
      return;
    }
    final notifier = ref.read(itemPhotosProvider(_item).notifier);
    final file = await PhotoPicker.showPicker(context);
    if (file == null || !mounted) return;
    final choice = await AuroraSheet.actionSheet(
      context,
      title: ItemCopy.photoOfWhat,
      actions: [
        for (final t in ItemPhotoType.values) AuroraSheetAction(label: t.tag),
      ],
    );
    if (choice == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await notifier.add(XFile(file.path), ItemPhotoType.values[choice]);
      if (mounted) setState(() => _selected = count);
    } catch (_) {
      if (mounted) SnackbarService.showError(context, ItemCopy.photoError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _actions(ItemPhoto photo) async {
    final choice = await AuroraSheet.actionSheet(
      context,
      title: ItemCopy.photosTitle,
      actions: [AuroraSheetAction(label: ItemCopy.removePhoto, destructive: true)],
    );
    if (choice != 0 || !mounted) return;
    final notifier = ref.read(itemPhotosProvider(_item).notifier);
    final sure = await ConfirmDialog.show(
      context,
      title: ItemCopy.removePhotoTitle,
      message: ItemCopy.removePhotoBody,
      confirmLabel: ItemCopy.removeConfirm,
      onConfirm: () {},
    );
    if (sure != true || !mounted) return;
    try {
      await notifier.remove(photo);
      if (!mounted) return;
      setState(() => _selected = 0);
      SnackbarService.showSuccess(context, ItemCopy.photoRemoved);
    } catch (_) {
      if (mounted) SnackbarService.showError(context, ItemCopy.removeError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(itemSummaryProvider(_item));
    final photos = ref.watch(itemPhotosProvider(_item));
    final premium = ref.watch(isPremiumProvider);
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.space7));
    final back = ItemTopBar(
      backLabel: summary.value?.name ?? ItemCopy.back,
      onBack: _back,
    );

    if (photos.hasError || summary.hasError) {
      return ItemPage(
        onRefresh: _refresh,
        fill: ErrorView(
          message: ItemCopy.loadError,
          onRetry: () {
            ref.invalidate(itemPhotosProvider(_item));
            ref.invalidate(itemSummaryProvider(_item));
          },
        ),
        child: back,
      );
    }
    final info = summary.value;
    final data = photos.value;
    if (summary.hasValue && info == null) {
      return ItemPage(
        fill: const EmptyState(
          icon: Icons.search_off_outlined,
          title: ItemCopy.notFoundTitle,
          subtitle: ItemCopy.notFoundBody,
        ),
        child: back,
      );
    }
    if (info == null || data == null) {
      return ItemPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            back,
            gap,
            const ItemSkeleton(
              heights: [
                AuroraHomeCSizes.skeletonHero,
                AuroraHomeCSizes.skeletonCard,
                AuroraHomeCSizes.skeletonCard,
              ],
            ),
          ],
        ),
      );
    }

    final header = ItemHeader(eyebrow: info.eyebrow, title: ItemCopy.photosTitle);
    if (data.count == 0) {
      return ItemPage(
        onRefresh: _refresh,
        fill: EmptyState(
          icon: Icons.photo_camera_outlined,
          title: ItemCopy.photosEmptyTitle,
          subtitle: ItemCopy.photosEmptyBody(info),
          actionLabel: ItemCopy.addPhoto,
          onAction: () => _add(0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [back, gap, header],
        ),
      );
    }

    final index = _selected.clamp(0, data.count - 1);
    final photo = data.photos[index];
    final type = ItemPhotoType.fromValue(photo.photoType);
    final url = data.urlOf(photo);
    final caption = (photo.caption?.trim().isNotEmpty ?? false)
        ? photo.caption!.trim()
        : ItemCopy.defaultCaption(type.value);
    final meta =
        '${DateFormat.yMMM().format(photo.createdAt.toLocal())} · ${type.tag}'
            .toUpperCase();

    return ItemPage(
      onRefresh: _refresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ItemTopBar(
            backLabel: info.name,
            onBack: _back,
            trailing: Text(
              ItemCopy.positionOf(index + 1, data.count),
              style: AuroraType.rowDate.copyWith(color: AuroraColors.inkSecondary),
            ),
          ),
          gap,
          header,
          gap,
          ItemPhotoViewer(
            tag: type.tag,
            url: url,
            onExpand: () {
              if (url != null) ItemPhotoFullScreen.show(context, url);
            },
            onStep: (d) =>
                setState(() => _selected = (index + d) % data.count),
            onLongPress: () => _actions(photo),
          ),
          SizedBox(height: a.of(AuroraSpacing.space5)),
          Text(caption, style: AuroraType.h2),
          SizedBox(height: a.of(AuroraSpacing.space1)),
          Text(meta, style: AuroraType.meta),
          gap,
          ItemPhotoThumbs(
            photos: data,
            selected: index,
            onSelect: (i) => setState(() => _selected = i),
          ),
          gap,
          ItemPhotoLimitCard(
            title: premium
                ? ItemCopy.premiumPhotos(data.count)
                : ItemCopy.freePhotos(data.count, kFreeItemPhotoLimit),
            note: premium ? ItemCopy.premiumPhotosNote : ItemCopy.freePhotosNote,
            busy: _busy,
            onAdd: () => _add(data.count),
          ),
          gap,
          ItemPhotoTips(
            tips: ItemPhotoGuidance.forKind(_item.kind),
            have: {
              for (final p in data.photos) ItemPhotoType.fromValue(p.photoType),
            },
          ),
        ],
      ),
    );
  }
}
