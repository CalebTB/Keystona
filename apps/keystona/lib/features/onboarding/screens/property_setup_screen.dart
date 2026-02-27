import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../providers/onboarding_provider.dart';

/// Property type options for the dropdown.
///
/// Keys are display labels; values are Supabase enum strings.
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

  // ── Controllers ─────────────────────────────────────────────────────────────
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _yearBuiltController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _purchasePriceController = TextEditingController();

  // ── Selected values ──────────────────────────────────────────────────────────
  String? _selectedPropertyType;
  // null means "not yet resolved or user chose 'I don't know'"
  int? _selectedClimateZone;
  // sentinel to tell the dropdown that the "I don't know" option is selected
  // We track it as a String? in the DropdownButtonFormField to handle nulls.
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

  // ── ZIP → Climate Zone lookup (stub — real Edge Function wired in Phase 6) ──

  Future<void> _detectClimateZone(String zip) async {
    if (zip.length != 5) return;

    setState(() => _detectingClimateZone = true);

    // Stub: returns null; real lookup will call the Edge Function.
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
    // Phase 6: replace with Edge Function call.
    return null;
  }

  // ── Save ─────────────────────────────────────────────────────────────────────

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

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Your Home',
      actions: [
        TextButton(
          onPressed: () => context.go(AppRoutes.onboardingTrial),
          child: const Text('Skip'),
        ),
      ],
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Address ───────────────────────────────────────────────────
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLength: 500,
                textCapitalization: TextCapitalization.words,
                validator: Validators.required,
              ),

              const SizedBox(height: AppSizes.md),

              // ── City ──────────────────────────────────────────────────────
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
                textCapitalization: TextCapitalization.words,
                validator: Validators.required,
              ),

              const SizedBox(height: AppSizes.md),

              // ── State & ZIP in a row ───────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // State — 2-letter
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

                  // ZIP Code
                  Flexible(
                    flex: 3,
                    child: TextFormField(
                      controller: _zipController,
                      decoration: const InputDecoration(labelText: 'ZIP Code'),
                      maxLength: 5,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onEditingComplete: () =>
                          _detectClimateZone(_zipController.text),
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
                ],
              ),

              const SizedBox(height: AppSizes.md),

              // ── Property Type ─────────────────────────────────────────────
              DropdownButtonFormField<String>(
                initialValue: _selectedPropertyType,
                decoration:
                    const InputDecoration(labelText: 'Property Type'),
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

              const SizedBox(height: AppSizes.md),

              // ── Year Built ────────────────────────────────────────────────
              TextFormField(
                controller: _yearBuiltController,
                decoration: const InputDecoration(labelText: 'Year Built'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: Validators.year,
              ),

              const SizedBox(height: AppSizes.md),

              // ── Bedrooms & Bathrooms in a row ─────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: TextFormField(
                      controller: _bedroomsController,
                      decoration:
                          const InputDecoration(labelText: 'Bedrooms'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
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
                      decoration:
                          const InputDecoration(labelText: 'Bathrooms'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
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

              // ── Purchase Price ────────────────────────────────────────────
              TextFormField(
                controller: _purchasePriceController,
                decoration: const InputDecoration(
                  labelText: 'Purchase Price',
                  prefixText: r'$',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                // Optional field — no validator.
              ),

              const SizedBox(height: AppSizes.md),

              // ── Climate Zone ──────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      // ValueKey forces a rebuild when a ZIP lookup
                      // auto-selects the zone, updating the displayed value.
                      key: ValueKey(_climateZoneDropdownValue),
                      initialValue: _climateZoneDropdownValue,
                      decoration: const InputDecoration(
                        labelText: 'Climate Zone',
                      ),
                      items: _kClimateZones
                          .map(
                            (z) => DropdownMenuItem<String>(
                              // Use toString for non-null, sentinel 'unknown' for null.
                              value: z.value?.toString() ?? 'unknown',
                              child: Text(z.label),
                            ),
                          )
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
                  ),

                  if (_detectingClimateZone) ...[
                    const SizedBox(width: AppSizes.sm),
                    const Padding(
                      padding: EdgeInsets.only(top: 14),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: AppSizes.xl),

              // ── Save & Continue ───────────────────────────────────────────
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save & Continue'),
              ),

              const SizedBox(height: AppSizes.md),
            ],
          ),
        ),
      ),
    );
  }
}
