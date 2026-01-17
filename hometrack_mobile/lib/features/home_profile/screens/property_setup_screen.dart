import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hometrack_mobile/features/home_profile/models/property.dart';
import 'package:hometrack_mobile/features/home_profile/models/property_result.dart';
import 'package:hometrack_mobile/features/home_profile/providers/property_providers.dart';

class PropertySetupScreen extends ConsumerStatefulWidget {
  final Property? existingProperty;

  const PropertySetupScreen({
    super.key,
    this.existingProperty,
  });

  @override
  ConsumerState<PropertySetupScreen> createState() =>
      _PropertySetupScreenState();
}

class _PropertySetupScreenState extends ConsumerState<PropertySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _squareFootageController = TextEditingController();
  final _yearBuiltController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _lotSizeController = TextEditingController();

  PropertyType? _selectedPropertyType;
  bool _isLoading = false;

  // US States list
  static const List<String> _usStates = [
    'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
    'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
    'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
    'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
    'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY',
    'DC'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingProperty != null) {
      _populateFields(widget.existingProperty!);
    }
  }

  void _populateFields(Property property) {
    _addressController.text = property.address;
    _cityController.text = property.city;
    _stateController.text = property.state;
    _zipCodeController.text = property.zipCode;
    _squareFootageController.text =
        property.squareFootage?.toString() ?? '';
    _yearBuiltController.text = property.yearBuilt?.toString() ?? '';
    _bedroomsController.text = property.bedrooms?.toString() ?? '';
    _bathroomsController.text = property.bathrooms?.toString() ?? '';
    _lotSizeController.text = property.lotSize?.toString() ?? '';
    _selectedPropertyType = property.propertyType;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _squareFootageController.dispose();
    _yearBuiltController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _lotSizeController.dispose();
    super.dispose();
  }

  String? _validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your property address';
    }
    if (value.length > 500) {
      return 'Address must be 500 characters or less';
    }
    return null;
  }

  String? _validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the city';
    }
    if (value.length > 255) {
      return 'City name must be 255 characters or less';
    }
    return null;
  }

  String? _validateState(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the state';
    }
    final upperValue = value.toUpperCase();
    if (upperValue.length != 2) {
      return 'State must be 2 characters (e.g., CA)';
    }
    if (!_usStates.contains(upperValue)) {
      return 'Please enter a valid US state code';
    }
    return null;
  }

  String? _validateZipCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the ZIP code';
    }
    // Remove any non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length != 5 && digitsOnly.length != 9) {
      return 'ZIP code must be 5 or 9 digits';
    }
    return null;
  }

  String? _validateSquareFootage(String? value) {
    if (value == null || value.isEmpty) return null;
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return 'Please enter a valid number';
    }
    if (intValue < 1 || intValue > 1000000) {
      return 'Square footage must be between 1 and 1,000,000';
    }
    return null;
  }

  String? _validateYearBuilt(String? value) {
    if (value == null || value.isEmpty) return null;
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return 'Please enter a valid year';
    }
    final currentYear = DateTime.now().year;
    if (intValue < 1600 || intValue > currentYear + 5) {
      return 'Year must be between 1600 and ${currentYear + 5}';
    }
    return null;
  }

  String? _validateBedrooms(String? value) {
    if (value == null || value.isEmpty) return null;
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return 'Please enter a valid number';
    }
    if (intValue < 0 || intValue > 50) {
      return 'Bedrooms must be between 0 and 50';
    }
    return null;
  }

  String? _validateBathrooms(String? value) {
    if (value == null || value.isEmpty) return null;
    final doubleValue = double.tryParse(value);
    if (doubleValue == null) {
      return 'Please enter a valid number';
    }
    if (doubleValue < 0 || doubleValue > 50) {
      return 'Bathrooms must be between 0 and 50';
    }
    return null;
  }

  String? _validateLotSize(String? value) {
    if (value == null || value.isEmpty) return null;
    final doubleValue = double.tryParse(value);
    if (doubleValue == null) {
      return 'Please enter a valid number';
    }
    if (doubleValue < 0 || doubleValue > 10000000) {
      return 'Lot size must be between 0 and 10,000,000 acres';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final propertyService = ref.read(propertyServiceProvider);

    // Parse optional integer fields
    final squareFootage = _squareFootageController.text.isEmpty
        ? null
        : int.tryParse(_squareFootageController.text);
    final yearBuilt = _yearBuiltController.text.isEmpty
        ? null
        : int.tryParse(_yearBuiltController.text);
    final bedrooms = _bedroomsController.text.isEmpty
        ? null
        : int.tryParse(_bedroomsController.text);
    final bathrooms = _bathroomsController.text.isEmpty
        ? null
        : double.tryParse(_bathroomsController.text);
    final lotSize = _lotSizeController.text.isEmpty
        ? null
        : double.tryParse(_lotSizeController.text);

    final PropertyResult<Property> result;

    if (widget.existingProperty != null) {
      // Update existing property
      result = await propertyService.updateProperty(
        id: widget.existingProperty!.id,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim().toUpperCase(),
        zipCode: _zipCodeController.text.trim().replaceAll(RegExp(r'\D'), ''),
        squareFootage: squareFootage,
        yearBuilt: yearBuilt,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        lotSize: lotSize,
        propertyType: _selectedPropertyType,
      );
    } else {
      // Create new property
      result = await propertyService.createProperty(
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim().toUpperCase(),
        zipCode: _zipCodeController.text.trim().replaceAll(RegExp(r'\D'), ''),
        squareFootage: squareFootage,
        yearBuilt: yearBuilt,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        lotSize: lotSize,
        propertyType: _selectedPropertyType,
      );
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    switch (result) {
      case PropertySuccess(:final data):
        // Refresh the properties list
        ref.read(refreshPropertiesProvider)();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingProperty != null
                ? 'Property updated successfully'
                : 'Property created successfully'),
          ),
        );
        Navigator.of(context).pop(data);

      case PropertyFailure(:final error):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingProperty != null
            ? 'Edit Property'
            : 'Add Property'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Required fields section
                Text(
                  'Property Address',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _addressController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Street Address *',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                  validator: _validateAddress,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _cityController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'City *',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  validator: _validateCity,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _stateController,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(2),
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'State *',
                    hintText: 'CA',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  validator: _validateState,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _zipCodeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'ZIP Code *',
                    hintText: '12345',
                    prefixIcon: Icon(Icons.pin_drop_outlined),
                  ),
                  validator: _validateZipCode,
                ),
                const SizedBox(height: 32),

                // Optional fields section
                Text(
                  'Property Details (Optional)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<PropertyType>(
                  initialValue: _selectedPropertyType,
                  decoration: const InputDecoration(
                    labelText: 'Property Type',
                    prefixIcon: Icon(Icons.villa_outlined),
                  ),
                  items: PropertyType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedPropertyType = value);
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _squareFootageController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Square Footage',
                    hintText: '2000',
                    prefixIcon: Icon(Icons.square_foot_outlined),
                  ),
                  validator: _validateSquareFootage,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _yearBuiltController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Year Built',
                    hintText: '2000',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  validator: _validateYearBuilt,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _bedroomsController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Bedrooms',
                          hintText: '3',
                          prefixIcon: Icon(Icons.bed_outlined),
                        ),
                        validator: _validateBedrooms,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _bathroomsController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Bathrooms',
                          hintText: '2.5',
                          prefixIcon: Icon(Icons.bathroom_outlined),
                        ),
                        validator: _validateBathrooms,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _lotSizeController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Lot Size (acres)',
                    hintText: '0.25',
                    prefixIcon: Icon(Icons.landscape_outlined),
                  ),
                  validator: _validateLotSize,
                ),
                const SizedBox(height: 32),

                FilledButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.existingProperty != null
                          ? 'Update Property'
                          : 'Add Property'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
