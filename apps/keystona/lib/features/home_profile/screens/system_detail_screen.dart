import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_home_b.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../maintenance/models/task_schedule.dart';
import '../../maintenance/providers/maintenance_tasks_provider.dart';
import '../../maintenance/widgets/actions/task_menu.dart';
import '../../maintenance/widgets/actions/task_quick_done.dart';
import '../../maintenance/widgets/reminders/reminders_centered_page.dart';
import '../../maintenance/widgets/reminders/reminders_page.dart';
import '../models/item_ref.dart';
import '../models/scan_prefill.dart';
import '../models/system.dart';
import '../models/system_detail.dart';
import '../models/system_document.dart';
import '../models/system_reading.dart';
import '../presenters/system_detail_view.dart';
import '../providers/item_service_log_provider.dart';
import '../providers/item_task_counts_provider.dart';
import '../providers/system_detail_provider.dart';
import '../providers/warranty_check.dart';
import '../systems_copy.dart';
import '../widgets/service/log_service_sheet.dart';
import '../widgets/shared/item_documents_card.dart';
import '../widgets/shared/item_hero.dart';
import '../widgets/shared/item_key_value_card.dart';
import '../widgets/system_detail/detail_section.dart';
import '../widgets/system_detail/detail_top_bar.dart';
import '../widgets/system_detail/system_detail_skeleton.dart';
import '../widgets/system_detail/system_history_section.dart';
import '../widgets/system_detail/system_lifespan_card.dart';
import '../widgets/system_detail/system_next_up.dart';
import '../widgets/system_detail/system_status_chip.dart';
import '../widgets/system_detail/system_warranty_card.dart';
import '../widgets/system_detail/warranty_check_card.dart';

/// System detail (kit: SystemDetail). Route: `/home/systems/:systemId`.
class SystemDetailScreen extends ConsumerStatefulWidget {
  const SystemDetailScreen({super.key, required this.systemId});

  final String systemId;

  @override
  ConsumerState<SystemDetailScreen> createState() => _SystemDetailScreenState();
}

class _SystemDetailScreenState extends ConsumerState<SystemDetailScreen> {
  bool _warrantyBusy = false;

  ItemRef get _item => ItemRef.system(widget.systemId);

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.homeSystems);
    }
  }

  String _route(String template) =>
      template.replaceFirst(':systemId', widget.systemId);

  Future<void> _refresh() async {
    ref
      ..invalidate(itemServiceLogProvider(_item))
      ..invalidate(systemDocumentsProvider(widget.systemId))
      ..invalidate(maintenanceTasksProvider);
    ref.invalidate(systemDetailProvider(widget.systemId));
    await ref.read(systemDetailProvider(widget.systemId).future);
  }

  void _edit(HomeSystem system) => context.push(
    AppRoutes.homeSystemsAdd,
    extra: ItemFormArgs(existingSystem: system),
  );

  Future<void> _toggleWarrantyCheck(HomeSystem system, DateTime ends) async {
    setState(() => _warrantyBusy = true);
    final tasks = ref.read(maintenanceTasksProvider).value ?? const [];
    final existing = WarrantyCheck.taskFor(tasks, system.id);
    try {
      if (existing != null) {
        await WarrantyCheck.remove(ref, existing.id);
      } else {
        await WarrantyCheck.add(
          ref,
          system: system,
          warrantyEnds: ends,
          taskName: SystemsCopy.warrantyCheckTask(system.name),
        );
      }
    } catch (_) {
      if (mounted) {
        SnackbarService.showError(context, SystemsCopy.warrantyCheckFailed);
      }
    }
    if (mounted) setState(() => _warrantyBusy = false);
  }

  void _openTask(String id) =>
      context.push(AppRoutes.maintenanceTaskDetail.replaceFirst(':taskId', id));

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(systemDetailProvider(widget.systemId));
    return detail.when(
      loading: () => RemindersPage(
        onRefresh: _refresh,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DetailTopBar(onBack: _back),
            SizedBox(height: context.aurora.of(AuroraSpacing.space5)),
            const SystemDetailSkeleton(),
          ],
        ),
      ),
      error: (_, _) => RemindersCenteredPage(
        backLabel: SystemsCopy.systemsBack,
        onBack: _back,
        child: ErrorView(
          message: SystemsCopy.loadDetailError,
          onRetry: () => ref.invalidate(systemDetailProvider(widget.systemId)),
        ),
      ),
      data: _content,
    );
  }

  Widget _content(SystemDetail detail) {
    final a = context.aurora;
    final system = detail.system;
    final today = TaskSchedule.dayOf(DateTime.now());
    final reading = system.reading(now: today);
    final tasks = SystemDetailView.openTasks(
      ref.watch(maintenanceTasksProvider).value ?? const [],
      system.id,
    );
    final taskTotal = ref.watch(itemTaskCountsProvider)[_item] ?? tasks.length;
    final log = ref.watch(itemServiceLogProvider(_item)).value ?? const [];
    final docs =
        ref.watch(systemDocumentsProvider(system.id)).value ??
        const <SystemDocument>[];
    final identification = SystemDetailView.identification(system);
    final history = SystemDetailView.history(system, log);
    final total = SystemDetailView.historyTotal(system, log);
    final nextUp = tasks
        .take(AuroraHomeBSizes.nextUpShown)
        .map((t) => SystemDetailView.nextUp(t, today))
        .toList();

    return RemindersPage(
      onRefresh: _refresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DetailTopBar(onBack: _back, onEdit: () => _edit(system)),
          SizedBox(height: a.of(AuroraSpacing.space5)),
          ItemHero(
            eyebrow: SystemsCopy.detailEyebrow(system.category),
            statusChip: SystemStatusChip(
              chip: SystemDetailView.chip(system, reading),
            ),
            title: system.name,
            subtitle: system.subtitle,
            photoTag: SystemDetailView.photoTag(detail.photos.heroType),
            photoImage: detail.photos.heroUrl == null
                ? null
                : CachedNetworkImage(
                    imageUrl: detail.photos.heroUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => const SizedBox.shrink(),
                  ),
            photoBadge: SystemsCopy.photosBadge(detail.photos.count),
            onPhotoBadgeTap: () =>
                context.push(_route(AppRoutes.homeSystemPhotos)),
            onPhotoTap: () => context.push(_route(AppRoutes.homeSystemPhotos)),
          ),
          DetailSection(
            label: SystemsCopy.lifespanSection,
            child: SystemLifespanCard(system: system, now: today),
          ),
          if (nextUp.isNotEmpty)
            DetailSection(
              label: '${SystemsCopy.nextUpSection} · ${nextUp.length}',
              child: SystemNextUp(
                entries: nextUp,
                allLabel: SystemsCopy.allTasks(taskTotal, system.category),
                onTap: _openTask,
                onToggle: (id) => TaskQuickDone.run(
                  context,
                  ref,
                  tasks.firstWhere((t) => t.id == id),
                ),
                onLongPress: (id) =>
                    TaskMenu.show(context, ref, tasks.firstWhere((t) => t.id == id)),
                onAll: () => context.push(_route(AppRoutes.homeSystemTasks)),
              ),
            ),
          ..._warranty(system, docs, today),
          if (identification.isNotEmpty)
            DetailSection(
              label: SystemsCopy.identificationSection,
              child: ItemKeyValueCard(rows: identification),
            ),
          DetailSection(
            label: SystemsCopy.historySection(history.length),
            trailing: total == null
                ? null
                : SystemsCopy.historyTotal(total.total, total.sinceYear),
            child: SystemHistoryBody(
              rows: history,
              onLog: () => LogServiceSheet.show(context, ref, _item),
            ),
          ),
          if (docs.isNotEmpty)
            DetailSection(
              label: '${SystemsCopy.documentsSection} · ${docs.length}',
              child: ItemDocumentsCard(
                rows: [for (final d in docs) SystemDetailView.document(d)],
                onTap: (id) => context.push(
                  AppRoutes.documentDetail.replaceFirst(':documentId', id),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _warranty(
    HomeSystem system,
    List<SystemDocument> docs,
    DateTime today,
  ) {
    final ends = system.warrantyEndsOn;
    if (ends == null) return const [];
    final a = context.aurora;
    final active = !ends.isBefore(today);
    final days = ends.difference(today).inDays;
    final docId = system.linkedWarrantyDocId;
    final doc = docs.where((d) => d.id == docId).firstOrNull;
    final checkTask = WarrantyCheck.taskFor(
      ref.watch(maintenanceTasksProvider).value ?? const [],
      system.id,
    );
    return [
      DetailSection(
        label: SystemsCopy.warrantySection,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SystemWarrantyCard(
              title: doc?.name ?? SystemsCopy.warrantyDefaultTitle,
              meta: SystemsCopy.warrantyMeta(
                system.warrantyProvider,
                ends,
                active,
              ),
              active: active,
              onTap: docId == null
                  ? null
                  : () => context.push(
                      AppRoutes.documentDetail.replaceFirst(
                        ':documentId',
                        docId,
                      ),
                    ),
            ),
            if (active && days <= AuroraHomeBSizes.warrantyCheckWindowDays) ...[
              SizedBox(height: a.of(AuroraSpacing.space5)),
              WarrantyCheckCard(
                daysLeft: days,
                ends: ends,
                addedDue: checkTask?.dueDate,
                busy: _warrantyBusy,
                onToggle: () => _toggleWarrantyCheck(system, ends),
              ),
            ],
          ],
        ),
      ),
    ];
  }
}
