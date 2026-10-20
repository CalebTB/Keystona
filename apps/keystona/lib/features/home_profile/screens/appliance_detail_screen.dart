import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_home_c.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../maintenance/models/maintenance_task.dart';
import '../../maintenance/providers/maintenance_tasks_provider.dart';
import '../../maintenance/providers/tasks_today_provider.dart';
import '../appliance_copy.dart';
import '../lifespan/appliance_lifespan.dart';
import '../models/appliance.dart';
import '../models/appliance_care_tips.dart';
import '../models/appliance_dates.dart';
import '../models/item_photo_type.dart';
import '../models/item_ref.dart';
import '../models/item_tasks.dart';
import '../models/scan_prefill.dart';
import '../models/appliance_warranty_check.dart';
import '../providers/appliance_detail_provider.dart';
import '../providers/item_data_providers.dart';
import '../providers/item_photos_provider.dart';
import '../providers/item_service_log_provider.dart';
import '../providers/appliance_warranty_check_actions.dart';
import '../widgets/appliance_detail/appliance_detail_mapper.dart';
import '../widgets/appliance_detail/appliance_health_chip.dart';
import '../widgets/appliance_detail/appliance_next_up.dart';
import '../widgets/appliance_detail/appliance_specs_card.dart';
import '../widgets/appliance_detail/appliance_warranty_callout.dart';
import '../widgets/item/item_page.dart';
import '../widgets/item/item_skeleton.dart';
import '../widgets/item/item_top_bar.dart';
import '../widgets/item/item_top_bar_action.dart';
import '../widgets/item_photos/item_photo_image.dart';
import '../widgets/service/log_service_sheet.dart';
import '../widgets/shared/dashed_action_button.dart';
import '../widgets/shared/item_documents_card.dart';
import '../widgets/shared/item_hero.dart';
import '../widgets/shared/item_history_timeline.dart';
import '../widgets/shared/item_key_value_card.dart';
import '../widgets/shared/item_lifespan_card.dart';
import '../widgets/shared/mono_section_label.dart';

/// One appliance: hero, lifespan, next tasks, warranty, purchase,
/// identification, specifications, history and documents (kit:
/// ApplianceDetail). Route: `/home/appliances/:applianceId`.
class ApplianceDetailScreen extends ConsumerStatefulWidget {
  const ApplianceDetailScreen({super.key, required this.applianceId});

  final String applianceId;

  @override
  ConsumerState<ApplianceDetailScreen> createState() =>
      _ApplianceDetailScreenState();
}

class _ApplianceDetailScreenState extends ConsumerState<ApplianceDetailScreen> {
  /// Tasks drawn under "Next up"; the pill says how many there are in all.
  static const int _nextUpShown = 2;

  bool _specsOpen = true;
  bool _checkBusy = false;

  ItemRef get _item => ItemRef.appliance(widget.applianceId);

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.homeAppliances);
    }
  }

  void _edit(Appliance a) => context.push(
    AppRoutes.homeAppliancesAdd,
    extra: ItemFormArgs(existingAppliance: a),
  );

  void _photos() => context.push(
    AppRoutes.homeAppliancePhotos.replaceFirst(
      ':applianceId',
      widget.applianceId,
    ),
  );

  void _allTasks() => context.push(
    AppRoutes.homeApplianceTasks.replaceFirst(':applianceId', widget.applianceId),
  );

  Future<void> _refresh() async {
    ref.invalidate(applianceDetailProvider(widget.applianceId));
    ref.invalidate(itemPhotosProvider(_item));
    ref.invalidate(itemServiceLogProvider(_item));
    await ref.read(maintenanceTasksProvider.notifier).refresh();
  }

  Future<void> _toggleCheck(
    Appliance a,
    DateTime ends,
    MaintenanceTask? existing,
    DateTime today,
  ) async {
    if (_checkBusy) return;
    setState(() => _checkBusy = true);
    try {
      if (existing != null) {
        await ApplianceWarrantyCheckActions.remove(ref, existing);
      } else {
        await ApplianceWarrantyCheckActions.add(ref, a, ApplianceWarrantyCheck.dueDate(ends, today));
      }
    } catch (_) {
      if (mounted) SnackbarService.showError(context, ApplianceCopy.checkError);
    } finally {
      if (mounted) setState(() => _checkBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(applianceDetailProvider(widget.applianceId));
    final back = ItemTopBar(backLabel: ApplianceCopy.detailBack, onBack: _back);
    final gap = SizedBox(height: context.aurora.of(AuroraSpacing.space8));

    if (detail.hasError) {
      return ItemPage(
        onRefresh: _refresh,
        fill: ErrorView(
          message: ApplianceCopy.detailLoadError,
          onRetry: () =>
              ref.invalidate(applianceDetailProvider(widget.applianceId)),
        ),
        child: back,
      );
    }
    if (detail.hasValue && detail.value == null) {
      return ItemPage(
        fill: const EmptyState(
          icon: Icons.search_off_outlined,
          title: ApplianceCopy.notFoundTitle,
          subtitle: ApplianceCopy.notFoundBody,
        ),
        child: back,
      );
    }
    final appliance = detail.value;
    if (appliance == null) {
      return ItemPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            back,
            gap,
            const ItemSkeleton(
              heights: [
                AuroraHomeCSizes.skeletonRow,
                AuroraHomeCSizes.skeletonHero,
                AuroraHomeCSizes.skeletonBlock,
              ],
            ),
          ],
        ),
      );
    }
    return ItemPage(
      onRefresh: _refresh,
      child: _Body(
        appliance: appliance,
        specsOpen: _specsOpen,
        checkBusy: _checkBusy,
        gap: gap,
        onBack: _back,
        onEdit: () => _edit(appliance),
        onPhotos: _photos,
        onAllTasks: _allTasks,
        onToggleSpecs: () => setState(() => _specsOpen = !_specsOpen),
        onToggleCheck: _toggleCheck,
        nextUpShown: _nextUpShown,
      ),
    );
  }
}

/// The loaded detail. Every section reads its own provider and falls back to
/// nothing, so a slow or failed one never hides the rest.
class _Body extends ConsumerWidget {
  const _Body({
    required this.appliance,
    required this.specsOpen,
    required this.checkBusy,
    required this.gap,
    required this.onBack,
    required this.onEdit,
    required this.onPhotos,
    required this.onAllTasks,
    required this.onToggleSpecs,
    required this.onToggleCheck,
    required this.nextUpShown,
  });

  final Appliance appliance;
  final bool specsOpen;
  final bool checkBusy;
  final Widget gap;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onPhotos;
  final VoidCallback onAllTasks;
  final VoidCallback onToggleSpecs;
  final Future<void> Function(Appliance, DateTime, MaintenanceTask?, DateTime)
  onToggleCheck;
  final int nextUpShown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aurora;
    final item = ItemRef.appliance(appliance.id);
    final today = ref.watch(tasksTodayProvider);
    final tasks = ref.watch(maintenanceTasksProvider).value ?? const [];
    final photos = ref.watch(itemPhotosProvider(item)).value;
    final log = ref.watch(itemServiceLogProvider(item)).value ?? const [];
    final docs =
        ref
            .watch(
              itemDocumentsProvider(
                ItemDocumentsQuery(
                  item,
                  warrantyDocId: appliance.linkedWarrantyDocId,
                ),
              ),
            )
            .value ??
        const [];

    final reading = appliance.lifespanReading(now: today);
    final open = ItemTasks.open(tasks, item);
    final ends = appliance.warrantyEndsOn;
    final check = ApplianceWarrantyCheck.existing(tasks, appliance.id);
    final bought = appliance.purchasedOn;
    final purchase = ApplianceDetailMapper.purchase(appliance);
    final identification = ApplianceDetailMapper.identification(appliance);
    final specs = ApplianceDetailMapper.specifications(appliance);
    final history = ApplianceDetailMapper.history(appliance, log);
    final docRows = ApplianceDetailMapper.documents(docs);
    final heroPhoto = photos?.photos
        .where((p) => ItemPhotoType.fromValue(p.photoType) == ItemPhotoType.unit)
        .firstOrNull ??
        photos?.photos.firstOrNull;
    final heroUrl = heroPhoto == null ? null : photos?.urlOf(heroPhoto);
    final location = appliance.location?.trim();
    final model = [
      [appliance.brand, appliance.modelNumber]
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .join(' '),
      if (location != null && location.isNotEmpty) location,
    ].where((s) => s.isNotEmpty).join(' · ');
    final yearsLeft = reading.yearsLeft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ItemTopBar(
          backLabel: ApplianceCopy.detailBack,
          onBack: onBack,
          trailing: ItemTopBarAction(
            label: ApplianceCopy.edit,
            onTap: onEdit,
          ),
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        ItemHero(
          eyebrow: ApplianceCopy.eyebrow(appliance),
          title: appliance.name,
          statusChip: ApplianceHealthChip(
            status: appliance.status,
            reading: reading,
          ),
          subtitle: model.isEmpty ? null : model,
          photoTag: ApplianceCopy.unitTag,
          photoImage: heroUrl == null ? null : ItemPhotoImage(url: heroUrl),
          photoBadge: (photos?.count ?? 0) == 0
              ? ApplianceCopy.addPhotoBadge
              : ApplianceCopy.photoBadge(photos!.count),
          onPhotoBadgeTap: onPhotos,
          onPhotoTap: onPhotos,
        ),
        if (ends != null && ApplianceWarrantyCheck.endsSoon(ends, today)) ...[
          gap,
          ApplianceWarrantyCallout(
            daysLeft: ApplianceWarrantyCheck.daysLeft(ends, today),
            endsOn: ends,
            checkDue: check?.dueDate,
            busy: checkBusy,
            onToggleCheck: () => onToggleCheck(appliance, ends, check, today),
          ),
        ],
        gap,
        const MonoSectionLabel(ApplianceCopy.lifespan),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        ItemLifespanCard(
          reading: reading,
          startLabel: bought == null ? null : ApplianceCopy.bought(bought),
          body: yearsLeft == null
              ? const TextSpan(text: ApplianceCopy.lifespanNeedsDate)
              : TextSpan(
                  children: [
                    TextSpan(
                      text: ApplianceCopy.lifespanBody(reading),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text: ' ${ApplianceCareTips.forAppliance(appliance)}',
                    ),
                  ],
                ),
        ),
        gap,
        MonoSectionLabel(
          ApplianceCopy.nextUpTitle(
            open.length < nextUpShown ? open.length : nextUpShown,
          ),
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        ApplianceNextUp(
          shown: open.take(nextUpShown).toList(),
          total: open.length,
          today: today,
          onAll: onAllTasks,
          onAdd: () => context.push(AppRoutes.maintenanceCreateFor(appliance.id)),
        ),
        if (purchase.isNotEmpty) ...[
          gap,
          const MonoSectionLabel(ApplianceCopy.purchaseTitle),
          SizedBox(height: a.of(AuroraSpacing.space3)),
          ItemKeyValueCard(rows: purchase),
        ],
        if (identification.isNotEmpty) ...[
          gap,
          const MonoSectionLabel(ApplianceCopy.identificationTitle),
          SizedBox(height: a.of(AuroraSpacing.space3)),
          ItemKeyValueCard(rows: identification),
        ],
        if (specs.isNotEmpty) ...[
          gap,
          ApplianceSpecsCard(
            rows: specs,
            expanded: specsOpen,
            onToggle: onToggleSpecs,
          ),
        ],
        gap,
        MonoSectionLabel(
          ApplianceCopy.historyTitle(history.length),
          trailing: ApplianceDetailMapper.historyTotal(appliance, log),
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        if (history.isNotEmpty) ...[
          ItemHistoryTimeline(rows: history),
          SizedBox(height: a.of(AuroraSpacing.space4)),
        ],
        DashedActionButton(
          icon: Icons.add,
          label: ApplianceCopy.logService,
          onTap: () => LogServiceSheet.show(context, ref, item),
        ),
        if (docRows.isNotEmpty) ...[
          gap,
          MonoSectionLabel(ApplianceCopy.documentsTitle(docRows.length)),
          SizedBox(height: a.of(AuroraSpacing.space3)),
          ItemDocumentsCard(
            rows: docRows,
            onTap: (id) => context.push(
              AppRoutes.documentDetail.replaceFirst(':documentId', id),
            ),
          ),
        ],
      ],
    );
  }
}
