import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../providers/home_profile_provider.dart';

const List<({String label, String value})> _kPropertyTypes = [
  (label: 'Single Family', value: 'single_family'),
  (label: 'Condo', value: 'condo'),
  (label: 'Townhouse', value: 'townhouse'),
  (label: 'Multi-Family', value: 'multi_family'),
  (label: 'Mobile Home', value: 'mobile_home'),
  (label: 'Other', value: 'other'),
];

const List<({String label, int? value})> _kClimateZones = [
  (label: 'Climate Zone 1', value: 1),
  (label: 'Climate Zone 2', value: 2),
  (label: 'Climate Zone 3', value: 3),
  (label: 'Climate Zone 4', value: 4),
  (label: 'Climate Zone 5', value: 5),
  (label: 'Climate Zone 6', value: 6),
  (label: 'Climate Zone 7', value: 7),
  (label: 'Climate Zone 8', value: 8),
  (label: "I don't know", value: null),
];

class PropertyEditScreen extends ConsumerStatefulWidget {
  const PropertyEditScreen({super.key});

  @override
  ConsumerState<PropertyEditScreen> createState() => _PropertyEditScreenState();
}

class _PropertyEditScreenState extends ConsumerState<PropertyEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Controllers ──────────────────────────────────────────────────────────────

  final _addressController = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _yearBuiltController = TextEditingController();
  final _squareFeetController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();

  // ── Selected values ──────────────────────────────────────────────────────────

  String? _selectedPropertyType;
  int? _selectedClimateZone;
  String? _climateZoneDropdownValue;

  bool _saving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate from already-loaded provider (keepAlive keeps it in memory).
    final property = ref.read(homeProfileProvider).value?.property;
    if (property != null) {
      _addressController.text = property.addressLine1;
      _address2Controller.text = property.addressLine2 ?? '';
      _cityController.text = property.city;
      _stateController.text = property.state;
      _zipController.text = property.zipCode;
      _yearBuiltController.text = property.yearBuilt?.toString() ?? '';
      _squareFeetController.text = property.squareFeet?.toString() ?? '';
      _bedroomsController.text = property.bedrooms != null
          ? _fmtNum(property.bedrooms!)
          : '';
      _bathroomsController.text = property.bathrooms != null
          ? _fmtNum(property.bathrooms!)
          : '';
      _selectedPropertyType = property.propertyType;
      if (property.climateZone != null) {
        _selectedClimateZone = property.climateZone;
        _climateZoneDropdownValue = property.climateZone!.toString();
      }
      _initialized = true;
    }
  }

  static String _fmtNum(double n) =>
      n == n.truncateToDouble() ? n.toInt().toString() : '$n';

  @override
  void dispose() {
    _addressController.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _yearBuiltController.dispose();
    _squareFeetController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    super.dispose();
  }

  // ── Save ─────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final data = <String, dynamic>{
      'address_line1': _addressController.text.trim(),
      if (_address2Controller.text.trim().isNotEmpty)
        'address_line2': _address2Controller.text.trim()
      else
        'address_line2': null,
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim().toUpperCase(),
      'zip_code': _zipController.text.trim(),
      if (_selectedPropertyType != null) 'property_type': _selectedPropertyType,
      if (_yearBuiltController.text.trim().isNotEmpty)
        'year_built': int.parse(_yearBuiltController.text.trim()),
      if (_squareFeetController.text.trim().isNotEmpty)
        'square_feet': int.parse(_squareFeetController.text.trim()),
      if (_bedroomsController.text.trim().isNotEmpty)
        'bedrooms': num.parse(_bedroomsController.text.trim()),
      if (_bathroomsController.text.trim().isNotEmpty)
        'bathrooms': num.parse(_bathroomsController.text.trim()),
      'climate_zone': _selectedClimateZone,
    };

    final notifier = ref.read(homeProfileProvider.notifier);
    try {
      await notifier.updateProperty(data);
      if (!mounted) return;
      context.pop();
    } catch (_) {
      if (!mounted) return;
      SnackbarService.showError(context, 'Could not save. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // If provider wasn't loaded yet when we opened, wait for it.
    if (!_initialized) {
      final overview = ref.watch(homeProfileProvider).value;
      if (overview != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final p = overview.property;
          setState(() {
            _addressController.text = p.addressLine1;
            _address2Controller.text = p.addressLine2 ?? '';
            _cityController.text = p.city;
            _stateController.text = p.state;
            _zipController.text = p.zipCode;
            _yearBuiltController.text = p.yearBuilt?.toString() ?? '';
            _squareFeetController.text = p.squareFeet?.toString() ?? '';
            _bedroomsController.text =
                p.bedrooms != null ? _fmtNum(p.bedrooms!) : '';
            _bathroomsController.text =
                p.bathrooms != null ? _fmtNum(p.bathrooms!) : '';
            _selectedPropertyType = p.propertyType;
            if (p.climateZone != null) {
              _selectedClimateZone = p.climateZone;
              _climateZoneDropdownValue = p.climateZone!.toString();
            }
            _initialized = true;
          });
        });
      }
    }

    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return isIOS ? _buildIOS() : _buildAndroid();
  }

  // ── iOS layout ────────────────────────────────────────────────────────────────

  Widget _buildIOS() {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: const Text('Cancel'),
        ),
        middle: const Text('Edit Property'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _saving ? null : _save,
          child: _saving
              ? const CupertinoActivityIndicator()
              : Text(
                  'Save',
                  style: TextStyle(
                    color: _saving
                        ? CupertinoColors.inactiveGray
                        : CupertinoColors.activeBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppPadding.screen,
            children: _formFields(),
          ),
        ),
      ),
    );
  }

  // ── Android layout ────────────────────────────────────────────────────────────

  Widget _buildAndroid() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Property'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppPadding.screen,
          children: _formFields(),
        ),
      ),
    );
  }

  // ── Shared form fields ────────────────────────────────────────────────────────

  List<Widget> _formFields() {
    return [
      const SizedBox(height: AppSizes.sm),

      TextFormField(
        controller: _addressController,
        decoration: const InputDecoration(labelText: 'Address'),
        maxLength: 500,
        textCapitalization: TextCapitalization.words,
        validator: Validators.required,
      ),

      const SizedBox(height: AppSizes.md),

      TextFormField(
        controller: _address2Controller,
        decoration: const InputDecoration(
          labelText: 'Unit / Apt / Suite',
          hintText: 'Optional',
        ),
        textCapitalization: TextCapitalization.words,
      ),

      const SizedBox(height: AppSizes.md),

      TextFormField(
        controller: _cityController,
        decoration: const InputDecoration(labelText: 'City'),
        textCapitalization: TextCapitalization.words,
        validator: Validators.required,
      ),

      const SizedBox(height: AppSizes.md),

      // State + ZIP row
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: TextFormField(
              controller: _stateController,
              decoration: const InputDecoration(labelText: 'State'),
              maxLength: 2,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
              ],
              validator: Validators.required,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Flexible(
            flex: 3,
            child: TextFormField(
              controller: _zipController,
              decoration: const InputDecoration(labelText: 'ZIP Code'),
              maxLength: 5,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Required';
                if (!RegExp(r'^\d{5}$').hasMatch(value.trim())) {
                  return 'Enter a 5-digit ZIP';
                }
                return null;
              },
            ),
          ),
        ],
      ),

      const SizedBox(height: AppSizes.md),

      DropdownButtonFormField<String>(
        initialValue: _selectedPropertyType,
        decoration: const InputDecoration(labelText: 'Property Type'),
        items: _kPropertyTypes
            .map((t) => DropdownMenuItem<String>(
                  value: t.value,
                  child: Text(t.label),
                ))
            .toList(),
        onChanged: (v) => setState(() => _selectedPropertyType = v),
      ),

      const SizedBox(height: AppSizes.md),

      TextFormField(
        controller: _yearBuiltController,
        decoration: const InputDecoration(labelText: 'Year Built'),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: Validators.year,
      ),

      const SizedBox(height: AppSizes.md),

      TextFormField(
        controller: _squareFeetController,
        decoration: const InputDecoration(labelText: 'Square Feet'),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (value) {
          if (value == null || value.trim().isEmpty) return null;
          return Validators.positiveNumber(value);
        },
      ),

      const SizedBox(height: AppSizes.md),

      // Bedrooms + Bathrooms row
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: TextFormField(
              controller: _bedroomsController,
              decoration: const InputDecoration(labelText: 'Bedrooms'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                return Validators.positiveNumber(value);
              },
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Flexible(
            child: TextFormField(
              controller: _bathroomsController,
              decoration: const InputDecoration(labelText: 'Bathrooms'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                return Validators.positiveNumber(value);
              },
            ),
          ),
        ],
      ),

      const SizedBox(height: AppSizes.md),

      DropdownButtonFormField<String>(
        key: ValueKey(_climateZoneDropdownValue),
        initialValue: _climateZoneDropdownValue,
        decoration: const InputDecoration(labelText: 'Climate Zone'),
        items: _kClimateZones
            .map((z) => DropdownMenuItem<String>(
                  value: z.value?.toString() ?? 'unknown',
                  child: Text(z.label),
                ))
            .toList(),
        onChanged: (rawValue) {
          setState(() {
            if (rawValue == null || rawValue == 'unknown') {
              _selectedClimateZone = null;
              _climateZoneDropdownValue = 'unknown';
            } else {
              _selectedClimateZone = int.tryParse(rawValue);
              _climateZoneDropdownValue = rawValue;
            }
          });
        },
      ),

      const SizedBox(height: AppSizes.xl),
    ];
  }
}
