import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/aurora/aurora.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../providers/onboarding_provider.dart';

/// Property type options for the dropdown.
const List<({String label, String value})> _kPropertyTypes = [
  (label: 'Single Family', value: 'single_family'),
  (label: 'Condo', value: 'condo'),
  (label: 'Townhouse', value: 'townhouse'),
  (label: 'Multi-Family', value: 'multi_family'),
  (label: 'Mobile Home', value: 'mobile_home'),
  (label: 'Other', value: 'other'),
];

/// Climate zone options — 1-8 plus an unknown entry (null value).
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

/// Screen 2 of onboarding — collects property details.
///
/// All fields are optional except address, city, state, ZIP, and year built.
/// On success navigates to [AppRoutes.onboardingTrial].
/// The "Skip" app bar action bypasses the form entirely.
class PropertySetupScreen extends ConsumerStatefulWidget {
  const PropertySetupScreen({super.key});

  @override
  ConsumerState<PropertySetupScreen> createState() =>
      _PropertySetupScreenState();
}

class _PropertySetupScreenState extends ConsumerState<PropertySetupScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Controllers ───────────────────────────────────────────────────────────────
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _yearBuiltController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _purchasePriceController = TextEditingController();

  // ── Selected values ────────────────────────────────────────────────────────────
  String? _selectedPropertyType;
  int? _selectedClimateZone;
  String? _climateZoneDropdownValue;

  bool _detectingClimateZone = false;
  bool _saving = false;

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _yearBuiltController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _purchasePriceController.dispose();
    super.dispose();
  }

  Future<void> _detectClimateZone(String zip) async {
    if (zip.length != 5) return;

    setState(() => _detectingClimateZone = true);

    final zone = await _lookupClimateZoneFromZip(zip);

    if (!mounted) return;
    setState(() {
      _detectingClimateZone = false;
      if (zone != null) {
        _selectedClimateZone = zone;
        _climateZoneDropdownValue = zone.toString();
      }
    });
  }

  /// Stub lookup — returns null until the Edge Function is wired in Phase 6.
  Future<int?> _lookupClimateZoneFromZip(String zip) async {
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    final data = <String, dynamic>{
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim().toUpperCase(),
      'zip_code': _zipController.text.trim(),
      if (_selectedPropertyType != null) 'property_type': _selectedPropertyType,
      if (_yearBuiltController.text.trim().isNotEmpty)
        'year_built': int.parse(_yearBuiltController.text.trim()),
      if (_bedroomsController.text.trim().isNotEmpty)
        'bedrooms': num.parse(_bedroomsController.text.trim()),
      if (_bathroomsController.text.trim().isNotEmpty)
        'bathrooms': num.parse(_bathroomsController.text.trim()),
      if (_purchasePriceController.text.trim().isNotEmpty)
        'purchase_price': num.parse(_purchasePriceController.text.trim()),
      if (_selectedClimateZone != null) 'climate_zone': _selectedClimateZone,
    };

    final notifier = ref.read(propertyProvider.notifier);
    await notifier.saveProperty(data);

    if (!mounted) return;

    final asyncState = ref.read(propertyProvider);
    setState(() => _saving = false);

    asyncState.when(
      loading: () {},
      error: (error, _) {
        SnackbarService.showError(
          context,
          'Could not save your property. Please try again.',
        );
      },
      data: (_) => context.go(AppRoutes.onboardingTrial),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Your Home',
      actions: [
        GhostButton(
          label: 'Skip',
          onPressed: () => context.go(AppRoutes.onboardingTrial),
        ),
      ],
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AuroraSpacing.screenPadH,
            AuroraSpacing.screenPadTop,
            AuroraSpacing.screenPadH,
            AuroraSpacing.space10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Address ──────────────────────────────────────────────────
              AuroraFormSection(
                title: 'Address',
                children: [
                  _buildField(
                    label: 'Street Address',
                    isRequired: true,
                    child: TextFormField(
                      controller: _addressController,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 500,
                      style: AuroraType.body,
                      cursorColor: AuroraColors.coral,
                      decoration: _inputDecoration('123 Main St'),
                      validator: Validators.required,
                    ),
                  ),
                  _buildField(
                    label: 'City',
                    isRequired: true,
                    child: TextFormField(
                      controller: _cityController,
                      textCapitalization: TextCapitalization.words,
                      style: AuroraType.body,
                      cursorColor: AuroraColors.coral,
                      decoration: _inputDecoration('San Francisco'),
                      validator: Validators.required,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        flex: 2,
                        child: _buildField(
                          label: 'State',
                          isRequired: true,
                          child: TextFormField(
                            controller: _stateController,
                            maxLength: 2,
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp('[a-zA-Z]'),
                              ),
                            ],
                            style: AuroraType.body,
                            cursorColor: AuroraColors.coral,
                            decoration: _inputDecoration('CA'),
                            validator: Validators.required,
                          ),
                        ),
                      ),
                      const SizedBox(width: AuroraSpacing.space3),
                      Flexible(
                        flex: 3,
                        child: _buildField(
                          label: 'ZIP Code',
                          isRequired: true,
                          child: TextFormField(
                            controller: _zipController,
                            maxLength: 5,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onEditingComplete: () =>
                                _detectClimateZone(_zipController.text),
                            style: AuroraType.body,
                            cursorColor: AuroraColors.coral,
                            decoration: _inputDecoration('94105'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              if (!RegExp(r'^\d{5}$').hasMatch(value.trim())) {
                                return 'Enter a 5-digit ZIP';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // ── Property details ──────────────────────────────────────────
              AuroraFormSection(
                title: 'Property Details',
                isOptional: true,
                children: [
                  // Property type — native DropdownButtonFormField styled to Aurora
                  _buildField(
                    label: 'Property Type',
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedPropertyType,
                      decoration: _inputDecoration('Select type'),
                      icon: const Icon(
                        Icons.chevron_right,
                        size: 14,
                        color: AuroraColors.inkTertiary,
                      ),
                      style: AuroraType.body,
                      dropdownColor: AuroraColors.paper,
                      items: _kPropertyTypes
                          .map(
                            (t) => DropdownMenuItem<String>(
                              value: t.value,
                              child: Text(t.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedPropertyType = value),
                    ),
                  ),
                  _buildField(
                    label: 'Year Built',
                    child: TextFormField(
                      controller: _yearBuiltController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: AuroraType.body,
                      cursorColor: AuroraColors.coral,
                      decoration: _inputDecoration('1985'),
                      validator: Validators.year,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: _buildField(
                          label: 'Bedrooms',
                          child: TextFormField(
                            controller: _bedroomsController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: AuroraType.body,
                            cursorColor: AuroraColors.coral,
                            decoration: _inputDecoration('3'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null;
                              }
                              return Validators.positiveNumber(value);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: AuroraSpacing.space3),
                      Flexible(
                        child: _buildField(
                          label: 'Bathrooms',
                          child: TextFormField(
                            controller: _bathroomsController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                            ],
                            style: AuroraType.body,
                            cursorColor: AuroraColors.coral,
                            decoration: _inputDecoration('2'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null;
                              }
                              return Validators.positiveNumber(value);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // ── Purchase & climate ────────────────────────────────────────
              AuroraFormSection(
                title: 'Financial & Climate',
                isOptional: true,
                children: [
                  _buildField(
                    label: 'Purchase Price',
                    child: TextFormField(
                      controller: _purchasePriceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      style: AuroraType.body,
                      cursorColor: AuroraColors.coral,
                      decoration: _inputDecoration(r'$450,000').copyWith(
                        prefixText: r'$ ',
                        prefixStyle: AuroraType.body,
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildField(
                          label: 'Climate Zone',
                          child: DropdownButtonFormField<String>(
                            key: ValueKey(_climateZoneDropdownValue),
                            initialValue: _climateZoneDropdownValue,
                            decoration: _inputDecoration('Select zone'),
                            icon: const Icon(
                              Icons.chevron_right,
                              size: 14,
                              color: AuroraColors.inkTertiary,
                            ),
                            style: AuroraType.body,
                            dropdownColor: AuroraColors.paper,
                            items: _kClimateZones
                                .map(
                                  (z) => DropdownMenuItem<String>(
                                    value: z.value?.toString() ?? 'unknown',
                                    child: Text(z.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (rawValue) {
                              setState(() {
                                if (rawValue == null ||
                                    rawValue == 'unknown') {
                                  _selectedClimateZone = null;
                                  _climateZoneDropdownValue = 'unknown';
                                } else {
                                  _selectedClimateZone =
                                      int.tryParse(rawValue);
                                  _climateZoneDropdownValue = rawValue;
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      if (_detectingClimateZone) ...[
                        const SizedBox(width: AuroraSpacing.space3),
                        const Padding(
                          padding: EdgeInsets.only(top: 28),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AuroraColors.cobalt,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AuroraSpacing.space10),

              // ── Save & Continue — cobalt SaveButton (form save) ───────────
              SaveButton(
                label: 'Save & Continue',
                onPressed: _save,
                loading: _saving,
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

InputDecoration _inputDecoration(String hint) => InputDecoration(
      isDense: true,
      filled: true,
      fillColor: AuroraColors.paper,
      hintText: hint,
      hintStyle: AuroraType.body.copyWith(color: AuroraColors.inkTertiary),
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.space7,
        vertical: AuroraSpacing.space5,
      ),
      border: OutlineInputBorder(
        borderRadius: AuroraRadius.md,
        borderSide: const BorderSide(color: AuroraColors.inkBorder, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AuroraRadius.md,
        borderSide: const BorderSide(color: AuroraColors.inkBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AuroraRadius.md,
        borderSide: const BorderSide(color: AuroraColors.coral, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AuroraRadius.md,
        borderSide: const BorderSide(color: AuroraColors.coral, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AuroraRadius.md,
        borderSide: const BorderSide(color: AuroraColors.coral, width: 2),
      ),
    );

/// Aurora-styled label above a raw TextFormField / DropdownButtonFormField.
Widget _buildField({
  required String label,
  required Widget child,
  bool isRequired = false,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (isRequired)
        RichText(
          text: TextSpan(
            text: label.toUpperCase(),
            style: AuroraType.label.copyWith(color: AuroraColors.inkSecondary),
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: AuroraColors.coral),
              ),
            ],
          ),
        )
      else
        Text(
          label.toUpperCase(),
          style: AuroraType.label.copyWith(color: AuroraColors.inkSecondary),
        ),
      const SizedBox(height: AuroraSpacing.space1),
      child,
    ],
  );
}
