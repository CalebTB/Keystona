import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_motion.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/widgets/aurora/aurora_sheet.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/photo_picker.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../../core/widgets/task_generation_sheet.dart';
import '../../../core/widgets/upgrade_sheet.dart';
import '../../../services/providers/service_providers.dart';
import '../../emergency/widgets/document_link_picker.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../appliance_copy.dart';
import '../item_copy.dart';
import '../lifespan/appliance_lifespan.dart';
import '../models/appliance.dart';
import '../models/appliance_form_data.dart';
import '../models/appliance_specs.dart';
import '../models/appliance_suggestion.dart';
import '../models/form_photo.dart';
import '../models/item_photo_type.dart';
import '../models/item_ref.dart';
import '../models/scan_prefill.dart';
import '../providers/appliances_provider.dart';
import '../providers/item_photos_provider.dart';
import '../widgets/appliance_form/appliance_form_controllers.dart';
import '../widgets/appliance_form/appliance_form_footer.dart';
import '../widgets/appliance_form/appliance_form_header.dart';
import '../widgets/appliance_form/appliance_identification_section.dart';
import '../widgets/appliance_form/appliance_identity_section.dart';
import '../widgets/appliance_form/appliance_more_details_section.dart';
import '../widgets/appliance_form/appliance_photos_section.dart';
import '../widgets/appliance_form/appliance_purchase_section.dart';
import '../widgets/appliance_form/appliance_scan_banner.dart';
import '../widgets/appliance_form/appliance_specs_section.dart';
import '../widgets/item/item_page.dart';
import '../widgets/item/item_top_bar.dart';

/// Add an appliance (kit: AddAppliance), and the same form to edit one.
///
/// - Add: nothing passed, a [prefill] from the label scan, or a [suggestion]
///   from the list's "Often forgotten" chips.
/// - Edit: pass [existing]. No scan banner, a "More details" section and
///   Delete (with a 10 second Undo).
class ApplianceFormScreen extends ConsumerStatefulWidget {
  const ApplianceFormScreen({
    super.key,
    this.existing,
    this.prefill,
    this.suggestion,
  });

  final Appliance? existing;
  final ScanPrefill? prefill;
  final ApplianceSuggestion? suggestion;

  @override
  ConsumerState<ApplianceFormScreen> createState() =>
      _ApplianceFormScreenState();
}

class _ApplianceFormScreenState extends ConsumerState<ApplianceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ApplianceFormControllers _c;

  ApplianceCategory _category = ApplianceCategory.other;
  ItemStatus _status = ItemStatus.active;
  bool _hasWarranty = false;
  String? _warrantyDocId;
  bool _specsOpen = false;
  String? _type;
  bool _energyStar = false;
  final List<FormPhoto> _photos = [];
  bool _saving = false;

  /// What the scan read, by field; a field wears the "from scan" edge while
  /// it still holds this.
  final Map<String, String> _scanned = {};
  int _scanFieldCount = 0;

  Appliance? get _existing => widget.existing;
  bool get _isEditing => _existing != null;

  @override
  void initState() {
    super.initState();
    final e = _existing;
    _c = ApplianceFormControllers(existing: e)..addListener(_changed);
    if (e != null) {
      final specs = ApplianceSpecs.fromJson(e.specifications);
      _category = e.category;
      _status = e.status;
      _hasWarranty =
          e.warrantyExpiration != null || (e.warrantyProvider ?? '').isNotEmpty;
      _warrantyDocId = e.linkedWarrantyDocId;
      _type = specs.type;
      _energyStar = specs.energyStar;
    }
    final s = widget.suggestion;
    if (s != null) {
      _c.name.text = s.name;
      _category = s.category;
    }
    final scan = widget.prefill;
    if (scan != null && e == null) _applyScan(scan);
  }

  void _changed() => setState(() {});

  void _applyScan(ScanPrefill scan) {
    final r = scan.result;
    var count = 0;
    void read(String key, TextEditingController c, String? value) {
      final v = value?.trim();
      if (v == null || v.isEmpty) return;
      c.text = v;
      _scanned[key] = v;
      count++;
    }

    read(ApplianceIdentificationSection.brandKey, _c.brand, r.brand);
    read(ApplianceIdentificationSection.modelKey, _c.model, r.modelNumber);
    read(ApplianceIdentificationSection.serialKey, _c.serial, r.serialNumber);
    final name = r.name?.trim();
    if (name != null && name.isNotEmpty) {
      _c.name.text = name;
      count++;
    }
    final cat = ApplianceCategory.values
        .where((c) => c.value == r.category)
        .firstOrNull;
    if (cat != null) {
      _category = cat;
      count++;
    }
    final specs = ApplianceSpecs.fromScanNotes(r.notes);
    if (specs.capacity != null) {
      _c.capacity.text = specs.capacityNumber;
      _scanned[_capacityKey] = specs.capacityNumber;
      count++;
    }
    if (specs.type != null) {
      _type = specs.type;
      _scanned[_typeKey] = specs.type!;
      count++;
    }
    if (specs.energyStar) {
      _energyStar = true;
      _scanned[_energyKey] = _energyKey;
      count++;
    }
    _photos.add(FormPhoto(scan.photo, ItemPhotoType.label));
    _scanFieldCount = count;
  }

  static const String _capacityKey = 'capacity';
  static const String _typeKey = 'type';
  static const String _energyKey = 'energy';

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Set<String> get _fromScan => {
    for (final e in _scanned.entries)
      if (_current(e.key) == e.value) e.key,
  };

  String? _current(String key) => switch (key) {
    ApplianceIdentificationSection.brandKey => _c.brand.text.trim(),
    ApplianceIdentificationSection.modelKey => _c.model.text.trim(),
    ApplianceIdentificationSection.serialKey => _c.serial.text.trim(),
    _capacityKey => _c.capacity.text.trim(),
    _typeKey => _type,
    _energyKey => _energyStar ? _energyKey : null,
    _ => null,
  };

  ApplianceFormData _data() => ApplianceFormData(
    category: _category,
    name: _c.name.text,
    brand: _c.brand.text,
    model: _c.model.text,
    serial: _c.serial.text,
    color: _c.color.text,
    price: _c.price.text,
    retailer: _c.retailer.text,
    purchaseDate: _c.purchaseDate.text,
    hasWarranty: _hasWarranty,
    warrantyProvider: _c.warrantyProvider.text,
    warrantyExpires: _c.warrantyExpires.text,
    linkedWarrantyDocId: _warrantyDocId,
    specs: ApplianceSpecs(
      capacity: ApplianceSpecs.capacityFromInput(_c.capacity.text),
      type: _type,
      energyStar: _energyStar,
    ),
    location: _c.location.text,
    status: _status,
    lifespan: _c.lifespan.text,
    notes: _c.notes.text,
  );

  // ─── Navigation ───────────────────────────────────────────────────────────

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.homeAppliances);
    }
  }

  void _rescan() =>
      context.pushReplacement(AppRoutes.homeScan, extra: ItemKind.appliance);

  // ─── Pickers ──────────────────────────────────────────────────────────────

  Future<void> _pickCategory() async {
    final choice = await AuroraSheet.actionSheet(
      context,
      title: ApplianceCopy.category,
      actions: [
        for (final c in ApplianceCategory.values)
          AuroraSheetAction(label: c.label),
      ],
    );
    if (choice != null) {
      setState(() => _category = ApplianceCategory.values[choice]);
    }
  }

  Future<void> _pickStatus() async {
    final choice = await AuroraSheet.actionSheet(
      context,
      title: ApplianceCopy.status,
      actions: [
        for (final s in ItemStatus.values) AuroraSheetAction(label: s.label),
      ],
    );
    if (choice != null) setState(() => _status = ItemStatus.values[choice]);
  }

  Future<void> _linkWarranty() async {
    final doc = await showDocumentLinkPicker(context);
    if (doc != null && mounted) setState(() => _warrantyDocId = doc.id);
  }

  // ─── Photos ───────────────────────────────────────────────────────────────

  int get _slots {
    final premium = ref.read(isPremiumProvider);
    if (!premium) return kFreeItemPhotoLimit;
    return _photos.length < kFreeItemPhotoLimit
        ? kFreeItemPhotoLimit
        : _photos.length + 1;
  }

  Future<void> _addPhoto() async {
    if (!ref.read(isPremiumProvider) && _photos.length >= kFreeItemPhotoLimit) {
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
    final file = await PhotoPicker.showPicker(context);
    if (file == null || !mounted) return;
    setState(
      () => _photos.add(FormPhoto(XFile(file.path), ItemPhotoType.unit)),
    );
  }

  Future<void> _openPhoto(int index) async {
    final choice = await AuroraSheet.actionSheet(
      context,
      title: ApplianceCopy.photos,
      actions: [
        AuroraSheetAction(label: ApplianceCopy.photoRemove, destructive: true),
      ],
    );
    if (choice == 0 && mounted) setState(() => _photos.removeAt(index));
  }

  // ─── Save ─────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final data = _data();
    if (!data.canSave) return;
    setState(() => _saving = true);
    final notifier = ref.read(appliancesProvider.notifier);
    try {
      final existing = _existing;
      if (existing != null) {
        await notifier.updateAppliance(
          existing.id,
          data.toFields(existing: existing),
        );
        if (!mounted) return;
        SnackbarService.showSuccess(context, ApplianceCopy.updated);
        context.pop();
        return;
      }
      final life =
          widget.prefill?.result.estimatedLifespanYears ??
          ApplianceLifespanDefaults.years(data.name, data.category);
      final id = await notifier.addAppliance(
        data.toFields(defaultLifespanYears: life),
      );
      await _uploadPhotos(id);
      if (!mounted) return;
      if (widget.prefill != null) await _offerTasks(id, data);
      if (!mounted) return;
      context.pushReplacement(
        AppRoutes.homeApplianceDetail.replaceFirst(':applianceId', id),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarService.showError(context, ApplianceCopy.saveError);
    }
  }

  /// The photos are secondary: a failed one never blocks the save.
  Future<void> _uploadPhotos(String id) async {
    final repository = ref.read(itemPhotosRepositoryProvider);
    for (final p in _photos) {
      try {
        await repository.add(ItemRef.appliance(id), p.file, p.type);
      } catch (_) {
        // Add it again from the appliance's Photos screen.
      }
    }
  }

  /// Offers the suggested upkeep tasks before leaving the form.
  Future<void> _offerTasks(String id, ApplianceFormData data) async {
    try {
      final saved = await ref.read(appliancesRepositoryProvider).get(id);
      if (saved == null || !mounted) return;
      await showTaskGenerationSheet(
        context: context,
        ref: ref,
        itemName: data.name.trim(),
        brand: data.brand.trim(),
        category: data.category.value,
        formType: 'appliance',
        linkedApplianceId: id,
        propertyId: saved.propertyId,
      );
    } catch (_) {
      // Suggestions are a bonus; the appliance is already saved.
    }
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> _delete() async {
    final existing = _existing;
    if (existing == null) return;
    final notifier = ref.read(appliancesProvider.notifier);
    final container = ProviderScope.containerOf(context);
    final toast = Navigator.of(context, rootNavigator: true).context;
    final sure = await ConfirmDialog.show(
      context,
      title: ApplianceCopy.deleteTitle,
      message: ApplianceCopy.deleteBody(existing.name),
      confirmLabel: ApplianceCopy.deleteConfirm,
      onConfirm: () {},
    );
    if (sure != true || !mounted) return;
    try {
      await notifier.softDelete(existing.id);
    } catch (_) {
      if (toast.mounted) {
        SnackbarService.showError(toast, ApplianceCopy.deleteError);
      }
      return;
    }
    if (!mounted) return;
    context.go(AppRoutes.homeAppliances);
    if (!toast.mounted) return;
    SnackbarService.showUndo(
      toast,
      message: ApplianceCopy.deleted(existing.name),
      duration: AuroraDurations.undoDelete,
      onUndo: () => _restore(container, toast, existing.id),
    );
  }

  Future<void> _restore(
    ProviderContainer container,
    BuildContext toast,
    String id,
  ) async {
    try {
      await container.read(appliancesProvider.notifier).restore(id);
    } catch (_) {
      if (toast.mounted) {
        SnackbarService.showError(toast, ApplianceCopy.restoreError);
      }
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.space8));
    final scanned = _fromScan;
    final hasScan = widget.prefill != null && !_isEditing;
    final premium = ref.watch(isPremiumProvider);
    final photoNote = premium
        ? ApplianceCopy.premiumNote
        : [
            ApplianceCopy.freeNote,
            if (hasScan) ApplianceCopy.labelSaved,
          ].join(' · ');
    return ItemPage(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ItemTopBar(
              backLabel: _isEditing
                  ? ApplianceCopy.cancel
                  : hasScan
                  ? ApplianceCopy.backToScan
                  : ApplianceCopy.backToList,
              onBack: _back,
            ),
            SizedBox(height: a.of(AuroraSpacing.space3)),
            ApplianceFormHeader(
              eyebrow: _isEditing
                  ? ApplianceCopy.editEyebrow
                  : ApplianceCopy.addEyebrow,
              title: _isEditing
                  ? ApplianceCopy.editTitle(_existing!.name)
                  : ApplianceCopy.addTitle,
            ),
            gap,
            if (hasScan) ...[
              ApplianceScanBanner(
                fieldCount: _scanFieldCount,
                onRescan: _rescan,
              ),
              gap,
            ],
            ApplianceIdentitySection(
              category: _category,
              name: _c.name,
              onPickCategory: _pickCategory,
            ),
            ApplianceIdentificationSection(
              brand: _c.brand,
              model: _c.model,
              serial: _c.serial,
              color: _c.color,
              fromScan: scanned,
            ),
            AppliancePurchaseSection(
              price: _c.price,
              retailer: _c.retailer,
              purchaseDate: _c.purchaseDate,
              hasWarranty: _hasWarranty,
              onWarranty: (v) => setState(() => _hasWarranty = v),
              warrantyProvider: _c.warrantyProvider,
              warrantyExpires: _c.warrantyExpires,
              linkedDocName: _warrantyDocId == null
                  ? null
                  : ApplianceCopy.warrantyDocFallback,
              onLinkWarranty: _linkWarranty,
            ),
            ApplianceSpecsSection(
              expanded: _specsOpen,
              onToggle: () => setState(() => _specsOpen = !_specsOpen),
              scannedCount: const [_capacityKey, _typeKey, _energyKey]
                  .where(_scanned.containsKey)
                  .length,
              capacity: _c.capacity,
              capacityFromScan: scanned.contains(_capacityKey),
              type: _type,
              typeFromScan: scanned.contains(_typeKey),
              showType: _category == ApplianceCategory.laundry,
              onType: (t) => setState(() => _type = t),
              energyStar: _energyStar,
              energyFromScan: scanned.contains(_energyKey),
              onEnergyStar: (v) => setState(() => _energyStar = v),
            ),
            if (_isEditing)
              ApplianceMoreDetailsSection(
                location: _c.location,
                status: _status,
                onPickStatus: _pickStatus,
                lifespan: _c.lifespan,
                notes: _c.notes,
              )
            else
              AppliancePhotosSection(
                photos: _photos,
                slots: _slots,
                note: photoNote,
                onAdd: _addPhoto,
                onOpen: _openPhoto,
              ),
            gap,
            ApplianceFormFooter(
              saveLabel: _isEditing ? ApplianceCopy.saveEdit : ApplianceCopy.save,
              onCancel: _back,
              onSave: _data().canSave ? _save : null,
              saving: _saving,
              onDelete: _isEditing ? _delete : null,
            ),
          ],
        ),
      ),
    );
  }
}
