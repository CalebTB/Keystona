import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_motion.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/widgets/aurora/aurora_button.dart';
import '../../../core/widgets/aurora/aurora_sheet.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../../core/widgets/task_generation_sheet.dart';
import '../../../core/widgets/upgrade_sheet.dart';
import '../../../services/providers/service_providers.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../forms/form_photo.dart';
import '../forms/system_form_controller.dart';
import '../models/scan_prefill.dart';
import '../models/system.dart';
import '../models/system_template.dart';
import '../providers/scan_providers.dart';
import '../providers/system_detail_provider.dart';
import '../providers/system_repositories_provider.dart';
import '../providers/systems_provider.dart';
import '../systems_copy.dart';
import '../widgets/system_form/scan_banner.dart';
import '../widgets/system_form/system_basics_section.dart';
import '../widgets/system_form/system_form_footer.dart';
import '../widgets/system_form/system_form_header.dart';
import '../widgets/system_form/system_form_page.dart';
import '../widgets/system_form/system_identification_section.dart';
import '../widgets/system_form/system_install_section.dart';
import '../widgets/system_form/system_more_details_section.dart';
import '../widgets/system_form/system_photos_section.dart';

/// Add a system (kit: AddSystem) and its edit mode. Route:
/// `/home/systems/add`, with [existingSystem] for edit, [prefill] from a scan
/// or [template] from a suggestion chip.
class SystemFormScreen extends ConsumerStatefulWidget {
  const SystemFormScreen({
    super.key,
    this.existingSystem,
    this.prefill,
    this.template,
  });

  /// Reads a route's `extra`: an [ItemFormArgs] (edit and/or scan), a
  /// [SystemTemplate] (suggestion chip), a bare [HomeSystem], or nothing.
  factory SystemFormScreen.fromExtra(Object? extra) => switch (extra) {
    ItemFormArgs(:final existingSystem, :final prefill) => SystemFormScreen(
      existingSystem: existingSystem,
      prefill: prefill,
    ),
    final SystemTemplate t => SystemFormScreen(template: t),
    final HomeSystem s => SystemFormScreen(existingSystem: s),
    _ => const SystemFormScreen(),
  };

  final HomeSystem? existingSystem;
  final ScanPrefill? prefill;
  final SystemTemplate? template;

  @override
  ConsumerState<SystemFormScreen> createState() => _SystemFormScreenState();
}

class _SystemFormScreenState extends ConsumerState<SystemFormScreen> {
  late final SystemFormController _form;
  Future<List<SuggestedTask>>? _tasks;
  bool _saving = false;

  bool get _editing => widget.existingSystem != null;

  @override
  void initState() {
    super.initState();
    _form = SystemFormController(
      existing: widget.existingSystem,
      prefill: widget.prefill,
      template: widget.template,
    );
    // Suggestions start loading as soon as a scan fills the form, so they are
    // ready by the time Save is tapped.
    if (widget.prefill != null) {
      _tasks = prefetchItemTasks(
        itemName: _form.name.text.trim(),
        brand: _form.brand.text.trim(),
        category: _form.category.value,
        formType: 'system',
      );
    }
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  void _back() {
    if (_editing) {
      context.pop();
      return;
    }
    _rescan();
  }

  void _rescan() {
    if (!(ref.read(isOnlineProvider).value ?? true)) {
      SnackbarService.showInfo(context, SystemsCopy.scanOffline);
      return;
    }
    context.pushReplacement(AppRoutes.homeScan, extra: ScanKind.system);
  }

  void _cancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.homeSystems);
    }
  }

  Future<void> _addPhoto() async {
    final premium = ref.read(isPremiumProvider);
    if (!premium && _form.photos.length >= kFreeItemPhotoLimit) {
      await UpgradeSheet.show(
        context,
        config: const UpgradeSheetConfig(
          headline: SystemsCopy.photoLimitHeadline,
          reason: SystemsCopy.photoLimitReason,
          features: SystemsCopy.photoLimitFeatures,
          triggerKey: SystemsCopy.photoLimitKey,
        ),
      );
      return;
    }
    final source = ref.read(photoSourceProvider);
    final choice = await AuroraSheet.actionSheet(
      context,
      title: SystemsCopy.photoSheet,
      actions: const [
        AuroraSheetAction(
          label: SystemsCopy.photoTake,
          icon: Icons.photo_camera_outlined,
        ),
        AuroraSheetAction(
          label: SystemsCopy.photoChoose,
          icon: Icons.photo_library_outlined,
        ),
      ],
    );
    if (choice == null) return;
    final file = await source(
      choice == 0 ? ImageSource.camera : ImageSource.gallery,
    );
    if (file != null && mounted) _form.addPhoto(FormPhoto(file: file));
  }

  Future<void> _photoTapped(FormPhoto photo) async {
    final choice = await AuroraSheet.actionSheet(
      context,
      title: SystemsCopy.photoRemove,
      actions: const [
        AuroraSheetAction(label: SystemsCopy.photoRemove, destructive: true),
      ],
    );
    if (choice == 0) _form.removePhoto(photo);
  }

  Future<void> _save() async {
    if (_saving || !_form.canSave || _form.priceInvalid) return;
    setState(() => _saving = true);
    try {
      if (_editing) {
        await _saveEdit();
      } else {
        await _saveNew();
      }
    } catch (_) {
      if (!mounted) return;
      SnackbarService.showError(context, SystemsCopy.saveFailed);
      setState(() => _saving = false);
    }
  }

  Future<void> _saveEdit() async {
    final id = widget.existingSystem!.id;
    await ref.read(systemDetailProvider(id).notifier).updateSystem(_form.toRow());
    if (!mounted) return;
    SnackbarService.showSuccess(context, SystemsCopy.updated);
    context.pop();
  }

  Future<void> _saveNew() async {
    // Everything needed after the awaits is read first: the screen may close.
    final systems = ref.read(systemsProvider.notifier);
    final photos = ref.read(systemPhotosRepositoryProvider);
    final online = ref.read(isOnlineProvider).value ?? true;
    final id = await systems.addSystem(_form.toRow());
    var photoFailed = false;
    for (final p in _form.photos) {
      try {
        await photos.upload(id, p.file, photoType: p.photoType);
      } catch (_) {
        photoFailed = true;
      }
    }
    if (!mounted) return;
    if (_form.addTasks && online) await _reviewTasks(id);
    if (!mounted) return;
    if (photoFailed) {
      SnackbarService.showWarning(context, SystemsCopy.photoFailed);
    } else {
      SnackbarService.showSuccess(context, SystemsCopy.added);
    }
    context.pushReplacement(
      AppRoutes.homeSystemDetail.replaceFirst(':systemId', id),
    );
  }

  /// "Review your reminders" for the new system. The system is already saved,
  /// so nothing here may fail the save: any error just skips the sheet.
  Future<void> _reviewTasks(String systemId) async {
    try {
      final brief = await ref.read(propertyBriefProvider.future);
      if (!mounted || brief == null) return;
      // Shown before leaving: the context must still be alive.
      await showTaskGenerationSheet(
        context: context,
        ref: ref,
        itemName: _form.name.text.trim(),
        brand: _form.brand.text.trim(),
        category: _form.category.value,
        formType: 'system',
        linkedSystemId: systemId,
        propertyId: brief.id,
        prefetchedFuture: _tasks,
      );
    } catch (_) {
      // Tasks can be added later from the system's task list.
    }
  }

  Future<void> _delete() async {
    final system = widget.existingSystem!;
    final notifier = ref.read(systemsProvider.notifier);
    final container = ProviderScope.containerOf(context);
    final confirmed = await ConfirmDialog.show(
      context,
      title: SystemsCopy.deleteTitle(system.name),
      message: SystemsCopy.deleteBody,
      confirmLabel: SystemsCopy.deleteConfirm,
      onConfirm: () {},
    );
    if (confirmed != true || !mounted) return;
    try {
      await notifier.deleteSystem(system.id);
    } catch (_) {
      if (mounted) {
        SnackbarService.showError(context, SystemsCopy.deleteFailed);
      }
      return;
    }
    if (!mounted) return;
    SnackbarService.showUndo(
      context,
      message: SystemsCopy.deleted,
      duration: AuroraDurations.undoDelete,
      onUndo: () => container
          .read(systemsProvider.notifier)
          .restoreSystem(system.id)
          .catchError((_) {}),
    );
    context.go(AppRoutes.homeSystems);
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final online = ref.watch(isOnlineProvider).value ?? true;
    final premium = ref.watch(isPremiumProvider);
    final gap = SizedBox(height: a.of(AuroraSpacing.space9));
    return SystemFormPage(
      child: ListenableBuilder(
        listenable: _form,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SystemFormHeader(
              backLabel: systemFormBackLabel(
                editing: _editing,
                name: widget.existingSystem?.name,
              ),
              onBack: _back,
              eyebrow: _editing
                  ? SystemsCopy.eyebrowEdit
                  : SystemsCopy.eyebrowNew,
              title: _editing
                  ? SystemsCopy.titleEdit(widget.existingSystem!.name)
                  : SystemsCopy.titleNew,
            ),
            if (!_editing && _form.scan.count > 0) ...[
              SizedBox(height: a.of(AuroraSpacing.space8)),
              ScanBanner(count: _form.scan.count, onRescan: _rescan),
            ],
            SizedBox(height: a.of(AuroraSpacing.space8)),
            SystemBasicsSection(form: _form),
            SystemIdentificationSection(
              form: _form,
              onRescan: _editing ? null : _rescan,
            ),
            SystemInstallSection(
              form: _form,
              online: online,
              showTasksSwitch: !_editing,
              onOfflineTasks: () =>
                  SnackbarService.showInfo(context, SystemsCopy.addTasksOffline),
            ),
            if (_editing)
              SystemMoreDetailsSection(form: _form)
            else
              SystemPhotosSection(
                photos: _form.photos,
                premium: premium,
                onAdd: _addPhoto,
                onPhotoTap: _photoTapped,
              ),
            gap,
            SystemFormFooter(
              saveLabel: _editing ? SystemsCopy.saveEdit : SystemsCopy.saveNew,
              saving: _saving,
              onCancel: _cancel,
              onSave: _form.canSave && !_form.priceInvalid ? _save : null,
            ),
            if (_editing) ...[
              SizedBox(height: a.of(AuroraSpacing.space8)),
              SecondaryButton(
                label: SystemsCopy.delete,
                onPressed: _saving ? null : _delete,
                expand: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
