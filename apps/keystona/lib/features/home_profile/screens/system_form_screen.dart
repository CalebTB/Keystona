import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/system.dart';
import '../providers/system_detail_provider.dart';
import '../providers/systems_provider.dart';

/// Form screen for creating or editing a home system.
///
/// - Create mode: [existingSystem] = null. Inserts a new row on save
///   and triggers `generate-maintenance-tasks`.
/// - Edit mode: [existingSystem] supplied. Updates the existing row on save.
///
/// Route: `/home/systems/add` (create) or pushed with extra = [HomeSystem] (edit).
///
/// Adaptive layout:
///   iOS  → [CupertinoPageScaffold] with [CupertinoNavigationBar]
///   Android → [Scaffold] with [AppBar]
class SystemFormScreen extends ConsumerStatefulWidget {
  const SystemFormScreen({super.key, this.existingSystem});

  /// The system to edit, or null when creating a new system.
  final HomeSystem? existingSystem;

  @override
  ConsumerState<SystemFormScreen> createState() => _SystemFormScreenState();
}

class _SystemFormScreenState extends ConsumerState<SystemFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Controllers ─────────────────────────────────────────────────────────────

  late final TextEditingController _nameCtrl;
  late final TextEditingController _systemTypeCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _serialCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _installerCtrl;
  late final TextEditingController _purchasePriceCtrl;
  late final TextEditingController _lifespanMinCtrl;
  late final TextEditingController _lifespanMaxCtrl;
  late final TextEditingController _lifespanOverrideCtrl;
  late final TextEditingController _warrantyProviderCtrl;
  late final TextEditingController _replacementCostCtrl;
  late final TextEditingController _notesCtrl;

  // ── Local state ─────────────────────────────────────────────────────────────

  late SystemCategory _category;
  late ItemStatus _status;

  /// Installation date as "YYYY-MM-DD" string or null.
  String? _installationDate;

  /// Warranty expiration as "YYYY-MM-DD" string or null.
  String? _warrantyExpiration;

  bool _saving = false;

  // ── Helpers ─────────────────────────────────────────────────────────────────

  bool get _isEditing => widget.existingSystem != null;

  @override
  void initState() {
    super.initState();
    final s = widget.existingSystem;

    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _systemTypeCtrl = TextEditingController(text: s?.systemType ?? '');
    _brandCtrl = TextEditingController(text: s?.brand ?? '');
    _modelCtrl = TextEditingController(text: s?.modelNumber ?? '');
    _serialCtrl = TextEditingController(text: s?.serialNumber ?? '');
    _locationCtrl = TextEditingController(text: s?.location ?? '');
    _installerCtrl = TextEditingController(text: s?.installer ?? '');
    _purchasePriceCtrl = TextEditingController(
      text: s?.purchasePrice != null
          ? s!.purchasePrice!.toStringAsFixed(2)
          : '',
    );
    _lifespanMinCtrl = TextEditingController(
      text: s?.expectedLifespanMin?.toString() ?? '',
    );
    _lifespanMaxCtrl = TextEditingController(
      text: s?.expectedLifespanMax?.toString() ?? '',
    );
    _lifespanOverrideCtrl = TextEditingController(
      text: s?.lifespanOverride?.toString() ?? '',
    );
    _warrantyProviderCtrl =
        TextEditingController(text: s?.warrantyProvider ?? '');
    _replacementCostCtrl = TextEditingController(
      text: s?.estimatedReplacementCost != null
          ? s!.estimatedReplacementCost!.toStringAsFixed(2)
          : '',
    );
    _notesCtrl = TextEditingController(text: s?.notes ?? '');

    _category = s?.category ?? SystemCategory.hvac;
    _status = s?.status ?? ItemStatus.active;
    _installationDate = s?.installationDate;
    _warrantyExpiration = s?.warrantyExpiration;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _systemTypeCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _serialCtrl.dispose();
    _locationCtrl.dispose();
    _installerCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _lifespanMinCtrl.dispose();
    _lifespanMaxCtrl.dispose();
    _lifespanOverrideCtrl.dispose();
    _warrantyProviderCtrl.dispose();
    _replacementCostCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final title = _isEditing ? 'Edit System' : 'Add System';

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          previousPageTitle: _isEditing ? 'System' : 'Systems',
          middle: Text(title),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _saving ? null : () => context.pop(),
            child: const Text('Cancel'),
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _saving ? null : _handleSave,
            child: _saving
                ? const CupertinoActivityIndicator()
                : Text(
                    _isEditing ? 'Save' : 'Add',
                    style: const TextStyle(
                      color: AppColors.goldAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: _FormBody(
            formKey: _formKey,
            nameCtrl: _nameCtrl,
            systemTypeCtrl: _systemTypeCtrl,
            brandCtrl: _brandCtrl,
            modelCtrl: _modelCtrl,
            serialCtrl: _serialCtrl,
            locationCtrl: _locationCtrl,
            installerCtrl: _installerCtrl,
            purchasePriceCtrl: _purchasePriceCtrl,
            lifespanMinCtrl: _lifespanMinCtrl,
            lifespanMaxCtrl: _lifespanMaxCtrl,
            lifespanOverrideCtrl: _lifespanOverrideCtrl,
            warrantyProviderCtrl: _warrantyProviderCtrl,
            replacementCostCtrl: _replacementCostCtrl,
            notesCtrl: _notesCtrl,
            category: _category,
            status: _status,
            installationDate: _installationDate,
            warrantyExpiration: _warrantyExpiration,
            onCategoryChanged: (v) => setState(() => _category = v),
            onStatusChanged: (v) => setState(() => _status = v),
            onInstallationDateChanged: (v) =>
                setState(() => _installationDate = v),
            onWarrantyExpirationChanged: (v) =>
                setState(() => _warrantyExpiration = v),
            isIOS: true,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      appBar: AppBar(
        title: Text(title, style: AppTextStyles.h3),
        backgroundColor: AppColors.warmOffWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _saving ? null : () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _handleSave,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _isEditing ? 'Save' : 'Add',
                    style: AppTextStyles.bodyMediumSemibold.copyWith(
                      color: AppColors.deepNavy,
                    ),
                  ),
          ),
        ],
      ),
      body: _FormBody(
        formKey: _formKey,
        nameCtrl: _nameCtrl,
        systemTypeCtrl: _systemTypeCtrl,
        brandCtrl: _brandCtrl,
        modelCtrl: _modelCtrl,
        serialCtrl: _serialCtrl,
        locationCtrl: _locationCtrl,
        installerCtrl: _installerCtrl,
        purchasePriceCtrl: _purchasePriceCtrl,
        lifespanMinCtrl: _lifespanMinCtrl,
        lifespanMaxCtrl: _lifespanMaxCtrl,
        lifespanOverrideCtrl: _lifespanOverrideCtrl,
        warrantyProviderCtrl: _warrantyProviderCtrl,
        replacementCostCtrl: _replacementCostCtrl,
        notesCtrl: _notesCtrl,
        category: _category,
        status: _status,
        installationDate: _installationDate,
        warrantyExpiration: _warrantyExpiration,
        onCategoryChanged: (v) => setState(() => _category = v),
        onStatusChanged: (v) => setState(() => _status = v),
        onInstallationDateChanged: (v) =>
            setState(() => _installationDate = v),
        onWarrantyExpirationChanged: (v) =>
            setState(() => _warrantyExpiration = v),
        isIOS: false,
      ),
    );
  }

  // ── Save handler ─────────────────────────────────────────────────────────────

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    final data = <String, dynamic>{
      'category': _category.value,
      'system_type': _systemTypeCtrl.text.trim(),
      'name': _nameCtrl.text.trim(),
      'status': _status.value,
      if (_brandCtrl.text.isNotEmpty) 'brand': _brandCtrl.text.trim(),
      if (_modelCtrl.text.isNotEmpty) 'model': _modelCtrl.text.trim(),
      if (_serialCtrl.text.isNotEmpty)
        'serial_number': _serialCtrl.text.trim(),
      if (_locationCtrl.text.isNotEmpty) 'location': _locationCtrl.text.trim(),
      if (_installerCtrl.text.isNotEmpty)
        'installer': _installerCtrl.text.trim(),
      if (_purchasePriceCtrl.text.isNotEmpty)
        'purchase_price':
            double.tryParse(_purchasePriceCtrl.text.replaceAll(',', '')),
      if (_installationDate != null) 'installation_date': _installationDate,
      if (_lifespanMinCtrl.text.isNotEmpty)
        'expected_lifespan_min': int.tryParse(_lifespanMinCtrl.text),
      if (_lifespanMaxCtrl.text.isNotEmpty)
        'expected_lifespan_max': int.tryParse(_lifespanMaxCtrl.text),
      if (_lifespanOverrideCtrl.text.isNotEmpty)
        'lifespan_override': int.tryParse(_lifespanOverrideCtrl.text),
      if (_warrantyExpiration != null)
        'warranty_expiration': _warrantyExpiration,
      if (_warrantyProviderCtrl.text.isNotEmpty)
        'warranty_provider': _warrantyProviderCtrl.text.trim(),
      if (_replacementCostCtrl.text.isNotEmpty)
        'estimated_replacement_cost':
            double.tryParse(_replacementCostCtrl.text.replaceAll(',', '')),
      if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
    };

    try {
      if (_isEditing) {
        await ref
            .read(
              systemDetailProvider(widget.existingSystem!.id).notifier,
            )
            .updateSystem(data);
      } else {
        await ref.read(systemsProvider.notifier).addSystem(data);
      }

      if (!mounted) return;
      SnackbarService.showSuccess(
        context,
        _isEditing ? 'System updated.' : 'System added.',
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      SnackbarService.showError(
        context,
        _isEditing
            ? "Couldn't update system. Try again."
            : "Couldn't add system. Try again.",
      );
      setState(() => _saving = false);
    }
  }
}

// ── Form body (shared between iOS and Android) ────────────────────────────────

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.formKey,
    required this.nameCtrl,
    required this.systemTypeCtrl,
    required this.brandCtrl,
    required this.modelCtrl,
    required this.serialCtrl,
    required this.locationCtrl,
    required this.installerCtrl,
    required this.purchasePriceCtrl,
    required this.lifespanMinCtrl,
    required this.lifespanMaxCtrl,
    required this.lifespanOverrideCtrl,
    required this.warrantyProviderCtrl,
    required this.replacementCostCtrl,
    required this.notesCtrl,
    required this.category,
    required this.status,
    required this.installationDate,
    required this.warrantyExpiration,
    required this.onCategoryChanged,
    required this.onStatusChanged,
    required this.onInstallationDateChanged,
    required this.onWarrantyExpirationChanged,
    required this.isIOS,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController systemTypeCtrl;
  final TextEditingController brandCtrl;
  final TextEditingController modelCtrl;
  final TextEditingController serialCtrl;
  final TextEditingController locationCtrl;
  final TextEditingController installerCtrl;
  final TextEditingController purchasePriceCtrl;
  final TextEditingController lifespanMinCtrl;
  final TextEditingController lifespanMaxCtrl;
  final TextEditingController lifespanOverrideCtrl;
  final TextEditingController warrantyProviderCtrl;
  final TextEditingController replacementCostCtrl;
  final TextEditingController notesCtrl;
  final SystemCategory category;
  final ItemStatus status;
  final String? installationDate;
  final String? warrantyExpiration;
  final ValueChanged<SystemCategory> onCategoryChanged;
  final ValueChanged<ItemStatus> onStatusChanged;
  final ValueChanged<String?> onInstallationDateChanged;
  final ValueChanged<String?> onWarrantyExpirationChanged;
  final bool isIOS;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppSizes.screenPadding,
          right: AppSizes.screenPadding,
          top: AppSizes.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Required fields ───────────────────────────────────────────────
            _FormSectionLabel(label: 'Required'),

            // Category picker.
            _FieldLabel(label: 'Category'),
            _CategoryDropdown(
              value: category,
              onChanged: onCategoryChanged,
            ),
            const SizedBox(height: AppSizes.md),

            // Display name.
            _FieldLabel(label: 'Name'),
            _TextField(
              controller: nameCtrl,
              hint: 'e.g. Main Furnace',
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Name is required'
                  : null,
            ),
            const SizedBox(height: AppSizes.md),

            // System type.
            _FieldLabel(label: 'System Type'),
            _TextField(
              controller: systemTypeCtrl,
              hint: 'e.g. Gas Furnace, Central AC',
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'System type is required'
                  : null,
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Identification ────────────────────────────────────────────────
            _FormSectionLabel(label: 'Identification'),
            _FieldLabel(label: 'Brand'),
            _TextField(
              controller: brandCtrl,
              hint: 'e.g. Carrier, Rheem',
            ),
            const SizedBox(height: AppSizes.md),

            _FieldLabel(label: 'Model Number'),
            _TextField(
              controller: modelCtrl,
              hint: 'From the unit label',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-_\. ]')),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            _FieldLabel(label: 'Serial Number'),
            _TextField(
              controller: serialCtrl,
              hint: 'From the unit label',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-_]')),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            _FieldLabel(label: 'Location'),
            _TextField(
              controller: locationCtrl,
              hint: 'e.g. Basement, Attic, Garage',
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Installation ──────────────────────────────────────────────────
            _FormSectionLabel(label: 'Installation'),
            _FieldLabel(label: 'Installation Date'),
            _DatePickerField(
              value: installationDate,
              hint: 'Select date',
              onChanged: onInstallationDateChanged,
            ),
            const SizedBox(height: AppSizes.md),

            _FieldLabel(label: 'Installer'),
            _TextField(
              controller: installerCtrl,
              hint: 'Company or person who installed',
            ),
            const SizedBox(height: AppSizes.md),

            _FieldLabel(label: 'Purchase Price'),
            _TextField(
              controller: purchasePriceCtrl,
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Lifespan ──────────────────────────────────────────────────────
            _FormSectionLabel(label: 'Lifespan'),
            Row(
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(label: 'Min (years)'),
                      _TextField(
                        controller: lifespanMinCtrl,
                        hint: '10',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(label: 'Max (years)'),
                      _TextField(
                        controller: lifespanMaxCtrl,
                        hint: '20',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            _FieldLabel(label: 'Custom Lifespan Override (years)'),
            _TextField(
              controller: lifespanOverrideCtrl,
              hint: 'Overrides min/max average',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: AppSizes.md),

            _FieldLabel(label: 'Estimated Replacement Cost'),
            _TextField(
              controller: replacementCostCtrl,
              hint: '0',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Warranty ──────────────────────────────────────────────────────
            _FormSectionLabel(label: 'Warranty'),
            _FieldLabel(label: 'Warranty Expiration'),
            _DatePickerField(
              value: warrantyExpiration,
              hint: 'Select date',
              onChanged: onWarrantyExpirationChanged,
            ),
            const SizedBox(height: AppSizes.md),

            _FieldLabel(label: 'Warranty Provider'),
            _TextField(
              controller: warrantyProviderCtrl,
              hint: 'e.g. Carrier, HomeServe',
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Status ────────────────────────────────────────────────────────
            _FormSectionLabel(label: 'Status'),
            _StatusDropdown(
              value: status,
              onChanged: onStatusChanged,
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Notes ─────────────────────────────────────────────────────────
            _FormSectionLabel(label: 'Notes'),
            _TextField(
              controller: notesCtrl,
              hint: 'Any additional notes about this system',
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Form field helpers ────────────────────────────────────────────────────────

class _FormSectionLabel extends StatelessWidget {
  const _FormSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(label, style: AppTextStyles.labelLarge),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textDisabled,
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.deepNavy),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({required this.value, required this.onChanged});

  final SystemCategory value;
  final ValueChanged<SystemCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<SystemCategory>(
      initialValue: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.deepNavy),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
      ),
      items: SystemCategory.values
          .map(
            (c) => DropdownMenuItem(
              value: c,
              child: Text(c.label, style: AppTextStyles.bodyMedium),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.value, required this.onChanged});

  final ItemStatus value;
  final ValueChanged<ItemStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ItemStatus>(
      initialValue: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.deepNavy),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
      ),
      items: ItemStatus.values
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(s.label, style: AppTextStyles.bodyMedium),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

/// Tappable date field that shows a [showDatePicker] dialog.
///
/// DATE columns are stored as "YYYY-MM-DD" strings — the picker converts
/// between [DateTime] and the string format.
class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  final String? value;
  final String hint;
  final ValueChanged<String?> onChanged;

  String get _display {
    if (value == null) return hint;
    try {
      final dt = DateTime.parse(value!);
      return DateFormat('MMMM d, y').format(dt);
    } catch (_) {
      return value!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        height: AppSizes.inputHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _display,
                style: value != null
                    ? AppTextStyles.bodyMedium
                    : AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textDisabled,
                      ),
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final initial = value != null ? DateTime.tryParse(value!) ?? now : now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.deepNavy),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      // DATE column — send "YYYY-MM-DD" only, no time component.
      onChanged(picked.toIso8601String().split('T')[0]);
    }
  }
}
