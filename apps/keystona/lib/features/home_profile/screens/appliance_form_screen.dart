import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/appliance.dart';
import '../providers/appliance_detail_provider.dart';
import '../providers/appliances_provider.dart';

class ApplianceFormScreen extends ConsumerStatefulWidget {
  const ApplianceFormScreen({super.key, this.existingAppliance});
  final Appliance? existingAppliance;

  @override
  ConsumerState<ApplianceFormScreen> createState() =>
      _ApplianceFormScreenState();
}

class _ApplianceFormScreenState extends ConsumerState<ApplianceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _serialCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _warrantyProviderCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _lifespanCtrl;
  late final TextEditingController _replacementCostCtrl;

  // Enum state
  late ApplianceCategory _category;
  late ItemStatus _status;

  // Date state
  String? _purchaseDate;
  String? _warrantyExpiration;

  bool _saving = false;

  bool get _isEditing => widget.existingAppliance != null;

  @override
  void initState() {
    super.initState();
    final a = widget.existingAppliance;
    _nameCtrl = TextEditingController(text: a?.name ?? '');
    _brandCtrl = TextEditingController(text: a?.brand ?? '');
    _modelCtrl = TextEditingController(text: a?.modelNumber ?? '');
    _serialCtrl = TextEditingController(text: a?.serialNumber ?? '');
    _locationCtrl = TextEditingController(text: a?.location ?? '');
    _colorCtrl = TextEditingController(text: a?.color ?? '');
    _warrantyProviderCtrl =
        TextEditingController(text: a?.warrantyProvider ?? '');
    _notesCtrl = TextEditingController(text: a?.notes ?? '');
    _priceCtrl = TextEditingController(
      text: a?.purchasePrice != null
          ? a!.purchasePrice!.toStringAsFixed(2)
          : '',
    );
    _lifespanCtrl = TextEditingController(
      text: a?.lifespanOverride?.toString() ?? '',
    );
    _replacementCostCtrl = TextEditingController(
      text: a?.estimatedReplacementCost != null
          ? a!.estimatedReplacementCost!.toStringAsFixed(2)
          : '',
    );
    _category = a?.category ?? ApplianceCategory.other;
    _status = a?.status ?? ItemStatus.active;
    _purchaseDate = a?.purchaseDate;
    _warrantyExpiration = a?.warrantyExpiration;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _serialCtrl.dispose();
    _locationCtrl.dispose();
    _colorCtrl.dispose();
    _warrantyProviderCtrl.dispose();
    _notesCtrl.dispose();
    _priceCtrl.dispose();
    _lifespanCtrl.dispose();
    _replacementCostCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildFields() {
    return {
      'category': _category.value,
      'appliance_type': _category.value,
      'name': _nameCtrl.text.trim(),
      'status': _status.value,
      if (_brandCtrl.text.trim().isNotEmpty) 'brand': _brandCtrl.text.trim(),
      if (_modelCtrl.text.trim().isNotEmpty)
        'model': _modelCtrl.text.trim(),
      if (_serialCtrl.text.trim().isNotEmpty)
        'serial_number': _serialCtrl.text.trim(),
      if (_locationCtrl.text.trim().isNotEmpty)
        'location': _locationCtrl.text.trim(),
      if (_colorCtrl.text.trim().isNotEmpty) 'color': _colorCtrl.text.trim(),
      if (_warrantyProviderCtrl.text.trim().isNotEmpty)
        'warranty_provider': _warrantyProviderCtrl.text.trim(),
      if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
      if (_priceCtrl.text.trim().isNotEmpty)
        'purchase_price': double.tryParse(_priceCtrl.text.trim()),
      if (_lifespanCtrl.text.trim().isNotEmpty)
        'lifespan_override': int.tryParse(_lifespanCtrl.text.trim()),
      if (_replacementCostCtrl.text.trim().isNotEmpty)
        'estimated_replacement_cost':
            double.tryParse(_replacementCostCtrl.text.trim()),
      if (_purchaseDate != null) 'purchase_date': _purchaseDate,
      if (_warrantyExpiration != null)
        'warranty_expiration': _warrantyExpiration,
    };
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final fields = _buildFields();
    try {
      if (_isEditing) {
        final notifier = ref.read(
          applianceDetailProvider(widget.existingAppliance!.id).notifier,
        );
        await notifier.updateAppliance(fields);
      } else {
        await ref.read(appliancesProvider.notifier).addAppliance(fields);
      }
      if (!mounted) return;
      SnackbarService.showSuccess(
        context,
        _isEditing ? 'Appliance updated.' : 'Appliance added.',
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      SnackbarService.showError(
        context,
        _isEditing
            ? 'Failed to update appliance.'
            : 'Failed to add appliance.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Date picker helpers ────────────────────────────────────────────────────

  Future<void> _pickPurchaseDate(BuildContext context) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      await _showIOSDatePicker(
        context,
        initial: _purchaseDate != null
            ? DateTime.tryParse(_purchaseDate!) ?? DateTime.now()
            : DateTime.now(),
        onSelected: (d) => setState(
          () => _purchaseDate = _formatDate(d),
        ),
      );
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: _purchaseDate != null
            ? DateTime.tryParse(_purchaseDate!) ?? DateTime.now()
            : DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        setState(() => _purchaseDate = _formatDate(picked));
      }
    }
  }

  Future<void> _pickWarrantyExpiration(BuildContext context) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      await _showIOSDatePicker(
        context,
        initial: _warrantyExpiration != null
            ? DateTime.tryParse(_warrantyExpiration!) ?? DateTime.now()
            : DateTime.now(),
        onSelected: (d) => setState(
          () => _warrantyExpiration = _formatDate(d),
        ),
      );
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: _warrantyExpiration != null
            ? DateTime.tryParse(_warrantyExpiration!) ?? DateTime.now()
            : DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        setState(() => _warrantyExpiration = _formatDate(picked));
      }
    }
  }

  Future<void> _showIOSDatePicker(
    BuildContext context, {
    required DateTime initial,
    required ValueChanged<DateTime> onSelected,
  }) async {
    DateTime picked = initial;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Container(
        height: 260,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('Cancel'),
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                ),
                CupertinoButton(
                  child: const Text('Done'),
                  onPressed: () {
                    onSelected(picked);
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initial,
                onDateTimeChanged: (d) => picked = d,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── iOS enum picker ────────────────────────────────────────────────────────

  Future<void> _pickCategoryIOS(BuildContext context) async {
    final result = await showCupertinoModalPopup<ApplianceCategory>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Select Category'),
        actions: ApplianceCategory.values
            .map(
              (c) => CupertinoActionSheetAction(
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(c),
                child: Text(c.label),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (result != null) setState(() => _category = result);
  }

  Future<void> _pickStatusIOS(BuildContext context) async {
    final result = await showCupertinoModalPopup<ItemStatus>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Select Status'),
        actions: ItemStatus.values
            .map(
              (s) => CupertinoActionSheetAction(
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(s),
                child: Text(s.label),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (result != null) setState(() => _status = result);
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final title = _isEditing ? 'Edit Appliance' : 'Add Appliance';

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          previousPageTitle: _isEditing ? 'Appliance' : 'Appliances',
          middle: Text(title),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _saving ? null : _save,
            child: _saving
                ? const CupertinoActivityIndicator()
                : const Text('Save'),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Form(
            key: _formKey,
            child: _FormBody(
              isIOS: true,
              category: _category,
              status: _status,
              purchaseDate: _purchaseDate,
              warrantyExpiration: _warrantyExpiration,
              nameCtrl: _nameCtrl,
              brandCtrl: _brandCtrl,
              modelCtrl: _modelCtrl,
              serialCtrl: _serialCtrl,
              locationCtrl: _locationCtrl,
              colorCtrl: _colorCtrl,
              warrantyProviderCtrl: _warrantyProviderCtrl,
              notesCtrl: _notesCtrl,
              priceCtrl: _priceCtrl,
              lifespanCtrl: _lifespanCtrl,
              replacementCostCtrl: _replacementCostCtrl,
              onCategoryChanged: (v) => setState(() => _category = v),
              onStatusChanged: (v) => setState(() => _status = v),
              onPickPurchaseDate: () => _pickPurchaseDate(context),
              onClearPurchaseDate: () => setState(() => _purchaseDate = null),
              onPickWarrantyExpiration: () => _pickWarrantyExpiration(context),
              onClearWarrantyExpiration: () =>
                  setState(() => _warrantyExpiration = null),
              onPickCategoryIOS: () => _pickCategoryIOS(context),
              onPickStatusIOS: () => _pickStatusIOS(context),
            ),
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
        title: Text(title, style: AppTextStyles.h3),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.deepNavy,
                    ),
                  )
                : Text(
                    'Save',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.deepNavy),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: _FormBody(
          isIOS: false,
          category: _category,
          status: _status,
          purchaseDate: _purchaseDate,
          warrantyExpiration: _warrantyExpiration,
          nameCtrl: _nameCtrl,
          brandCtrl: _brandCtrl,
          modelCtrl: _modelCtrl,
          serialCtrl: _serialCtrl,
          locationCtrl: _locationCtrl,
          colorCtrl: _colorCtrl,
          warrantyProviderCtrl: _warrantyProviderCtrl,
          notesCtrl: _notesCtrl,
          priceCtrl: _priceCtrl,
          lifespanCtrl: _lifespanCtrl,
          replacementCostCtrl: _replacementCostCtrl,
          onCategoryChanged: (v) => setState(() => _category = v),
          onStatusChanged: (v) => setState(() => _status = v),
          onPickPurchaseDate: () => _pickPurchaseDate(context),
          onClearPurchaseDate: () => setState(() => _purchaseDate = null),
          onPickWarrantyExpiration: () => _pickWarrantyExpiration(context),
          onClearWarrantyExpiration: () =>
              setState(() => _warrantyExpiration = null),
          onPickCategoryIOS: () => _pickCategoryIOS(context),
          onPickStatusIOS: () => _pickStatusIOS(context),
        ),
      ),
    );
  }
}

// ── Shared form body ─────────────────────────────────────────────────────────

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.isIOS,
    required this.category,
    required this.status,
    required this.purchaseDate,
    required this.warrantyExpiration,
    required this.nameCtrl,
    required this.brandCtrl,
    required this.modelCtrl,
    required this.serialCtrl,
    required this.locationCtrl,
    required this.colorCtrl,
    required this.warrantyProviderCtrl,
    required this.notesCtrl,
    required this.priceCtrl,
    required this.lifespanCtrl,
    required this.replacementCostCtrl,
    required this.onCategoryChanged,
    required this.onStatusChanged,
    required this.onPickPurchaseDate,
    required this.onClearPurchaseDate,
    required this.onPickWarrantyExpiration,
    required this.onClearWarrantyExpiration,
    required this.onPickCategoryIOS,
    required this.onPickStatusIOS,
  });

  final bool isIOS;
  final ApplianceCategory category;
  final ItemStatus status;
  final String? purchaseDate;
  final String? warrantyExpiration;
  final TextEditingController nameCtrl;
  final TextEditingController brandCtrl;
  final TextEditingController modelCtrl;
  final TextEditingController serialCtrl;
  final TextEditingController locationCtrl;
  final TextEditingController colorCtrl;
  final TextEditingController warrantyProviderCtrl;
  final TextEditingController notesCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController lifespanCtrl;
  final TextEditingController replacementCostCtrl;
  final ValueChanged<ApplianceCategory> onCategoryChanged;
  final ValueChanged<ItemStatus> onStatusChanged;
  final VoidCallback onPickPurchaseDate;
  final VoidCallback onClearPurchaseDate;
  final VoidCallback onPickWarrantyExpiration;
  final VoidCallback onClearWarrantyExpiration;
  final VoidCallback onPickCategoryIOS;
  final VoidCallback onPickStatusIOS;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppPadding.screen,
      children: [
        // ── Category & Identity ────────────────────────────────────────────
        const _SectionLabel(label: 'Category & Identity'),
        _PickerField(
          label: 'Category',
          value: category.label,
          onTap: isIOS ? onPickCategoryIOS : null,
          trailing: isIOS
              ? null
              : DropdownButtonHideUnderline(
                  child: DropdownButton<ApplianceCategory>(
                    value: category,
                    onChanged: (v) {
                      if (v != null) onCategoryChanged(v);
                    },
                    items: ApplianceCategory.values
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.label),
                          ),
                        )
                        .toList(),
                  ),
                ),
        ),
        const SizedBox(height: AppSizes.sm),
        _TextField(
          controller: nameCtrl,
          label: 'Name',
          hint: 'e.g. Samsung Refrigerator',
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Name is required' : null,
        ),
        const SizedBox(height: AppSizes.sm),
        _TextField(
          controller: brandCtrl,
          label: 'Brand',
          hint: 'e.g. Samsung',
        ),
        const SizedBox(height: AppSizes.sm),
        _TextField(
          controller: modelCtrl,
          label: 'Model Number',
          hint: 'e.g. RF28R7351SR',
        ),
        const SizedBox(height: AppSizes.sm),
        _TextField(
          controller: serialCtrl,
          label: 'Serial Number',
          hint: 'Optional',
        ),
        const SizedBox(height: AppSizes.md),

        // ── Location & Status ──────────────────────────────────────────────
        const _SectionLabel(label: 'Location & Status'),
        _TextField(
          controller: locationCtrl,
          label: 'Location',
          hint: 'e.g. Kitchen, Laundry Room',
        ),
        const SizedBox(height: AppSizes.sm),
        _TextField(
          controller: colorCtrl,
          label: 'Color',
          hint: 'e.g. Stainless Steel',
        ),
        const SizedBox(height: AppSizes.sm),
        _PickerField(
          label: 'Status',
          value: status.label,
          onTap: isIOS ? onPickStatusIOS : null,
          trailing: isIOS
              ? null
              : DropdownButtonHideUnderline(
                  child: DropdownButton<ItemStatus>(
                    value: status,
                    onChanged: (v) {
                      if (v != null) onStatusChanged(v);
                    },
                    items: ItemStatus.values
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.label),
                          ),
                        )
                        .toList(),
                  ),
                ),
        ),
        const SizedBox(height: AppSizes.md),

        // ── Purchase ───────────────────────────────────────────────────────
        const _SectionLabel(label: 'Purchase'),
        _DateField(
          label: 'Purchase Date',
          value: purchaseDate,
          onTap: onPickPurchaseDate,
          onClear: onClearPurchaseDate,
        ),
        const SizedBox(height: AppSizes.sm),
        _TextField(
          controller: priceCtrl,
          label: 'Purchase Price',
          hint: '0.00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefix: '\$',
        ),
        const SizedBox(height: AppSizes.md),

        // ── Lifespan ───────────────────────────────────────────────────────
        const _SectionLabel(label: 'Lifespan'),
        _TextField(
          controller: lifespanCtrl,
          label: 'Expected Lifespan (years)',
          hint: 'e.g. 12',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSizes.sm),
        _TextField(
          controller: replacementCostCtrl,
          label: 'Estimated Replacement Cost',
          hint: '0.00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefix: '\$',
        ),
        const SizedBox(height: AppSizes.md),

        // ── Warranty ───────────────────────────────────────────────────────
        const _SectionLabel(label: 'Warranty'),
        _DateField(
          label: 'Warranty Expiration',
          value: warrantyExpiration,
          onTap: onPickWarrantyExpiration,
          onClear: onClearWarrantyExpiration,
        ),
        const SizedBox(height: AppSizes.sm),
        _TextField(
          controller: warrantyProviderCtrl,
          label: 'Warranty Provider',
          hint: 'e.g. Extended Warranty Co.',
        ),
        const SizedBox(height: AppSizes.md),

        // ── Notes ──────────────────────────────────────────────────────────
        const _SectionLabel(label: 'Notes'),
        _TextField(
          controller: notesCtrl,
          label: 'Notes',
          hint: 'Any additional notes about this appliance...',
          maxLines: 4,
        ),
        const SizedBox(height: AppSizes.xl),
      ],
    );
  }
}

// ── Form sub-widgets ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Text(
        label,
        style: AppTextStyles.h4,
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.prefix,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.deepNavy, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    if (trailing != null) {
      // Android: show inline dropdown
      return InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.xs,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
        child: trailing!,
      );
    }
    // iOS: tappable row that opens action sheet
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(value, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ?? 'Select date',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.clear,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              )
            else
              Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}
