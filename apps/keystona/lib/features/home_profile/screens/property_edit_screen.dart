import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../../services/providers/service_providers.dart';
import '../../../services/supabase_service.dart';
import '../models/home_profile_overview.dart';
import '../providers/home_profile_provider.dart';

const String _kBucket = 'property-photos';

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

/// Optional fields we track for the completion nudge (8 total).
const int _kOptionalFieldCount = 8;

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

  // ── Photo state ───────────────────────────────────────────────────────────────

  File? _localPhoto;
  String? _existingPhotoPath;
  String? _existingPhotoSignedUrl;

  // ── UI state ─────────────────────────────────────────────────────────────────

  bool _saving = false;
  bool _saveSuccess = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final overview = ref.read(homeProfileProvider).value;
    if (overview != null) {
      _populateFrom(overview);
    }
  }

  void _populateFrom(HomeProfileOverview overview) {
    final p = overview.property;
    _addressController.text = p.addressLine1;
    _address2Controller.text = p.addressLine2 ?? '';
    _cityController.text = p.city;
    _stateController.text = p.state;
    _zipController.text = p.zipCode;
    _yearBuiltController.text = p.yearBuilt?.toString() ?? '';
    _squareFeetController.text = p.squareFeet?.toString() ?? '';
    _bedroomsController.text = p.bedrooms != null ? _fmtNum(p.bedrooms!) : '';
    _bathroomsController.text =
        p.bathrooms != null ? _fmtNum(p.bathrooms!) : '';
    _selectedPropertyType = p.propertyType;
    _existingPhotoPath = p.exteriorPhotoPath;
    _existingPhotoSignedUrl = overview.exteriorPhotoSignedUrl;
    if (p.climateZone != null) {
      _selectedClimateZone = p.climateZone;
      _climateZoneDropdownValue = p.climateZone!.toString();
    }
    _initialized = true;
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

  // ── Completion nudge ──────────────────────────────────────────────────────────

  int get _filledOptional {
    int count = 0;
    if (_address2Controller.text.trim().isNotEmpty) count++;
    if (_selectedPropertyType != null) count++;
    if (_yearBuiltController.text.trim().isNotEmpty) count++;
    if (_squareFeetController.text.trim().isNotEmpty) count++;
    if (_bedroomsController.text.trim().isNotEmpty) count++;
    if (_bathroomsController.text.trim().isNotEmpty) count++;
    if (_selectedClimateZone != null) count++;
    if (_localPhoto != null || _existingPhotoPath != null) count++;
    return count;
  }

  // ── Photo picker ──────────────────────────────────────────────────────────────

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() => _localPhoto = File(picked.path));
  }

  // ── Save ──────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
      // Upload new photo if one was picked.
      String? newPhotoPath;
      if (_localPhoto != null) {
        final user = SupabaseService.client.auth.currentUser;
        if (user != null) {
          final ext = _localPhoto!.path.split('.').last;
          final path = '${user.id}/${const Uuid().v4()}.$ext';
          newPhotoPath = await ref
              .read(storageServiceProvider)
              .uploadFile(bucket: _kBucket, path: path, file: _localPhoto!);
        }
      }

      final data = <String, dynamic>{
        'address_line1': _addressController.text.trim(),
        'address_line2': _address2Controller.text.trim().isEmpty
            ? null
            : _address2Controller.text.trim(),
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
        'exterior_photo_path': newPhotoPath ?? _existingPhotoPath,
      };

      final notifier = ref.read(homeProfileProvider.notifier);
      await notifier.updateProperty(data);

      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveSuccess = true;
      });

      // Brief success moment before dismissing.
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarService.showError(context, 'Could not save. Please try again.');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      final overview = ref.watch(homeProfileProvider).value;
      if (overview != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _populateFrom(overview));
        });
      }
    }

    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return isIOS ? _buildIOS() : _buildAndroid();
  }

  // ── iOS layout ────────────────────────────────────────────────────────────────

  Widget _buildIOS() {
    Widget trailing;
    if (_saveSuccess) {
      trailing = const Icon(
        CupertinoIcons.checkmark_alt_circle_fill,
        color: CupertinoColors.activeGreen,
        size: 22,
      );
    } else if (_saving) {
      trailing = const CupertinoActivityIndicator();
    } else {
      trailing = CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _save,
        child: const Text(
          'Save',
          style: TextStyle(
            color: CupertinoColors.activeBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _saving ? null : () => context.pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: _saving
                  ? CupertinoColors.inactiveGray
                  : CupertinoColors.activeBlue,
            ),
          ),
        ),
        middle: const Text('Edit Property'),
        trailing: trailing,
      ),
      child: SafeArea(
        bottom: false,
        child: _initialized ? _formBody() : _loadingBody(),
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
          onPressed: _saving ? null : () => context.pop(),
        ),
        actions: [
          if (_saveSuccess)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.check_circle, color: Colors.green),
            )
          else if (_saving)
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
            TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: _initialized ? _formBody() : _loadingBody(),
    );
  }

  // ── Shared body ───────────────────────────────────────────────────────────────

  Widget _loadingBody() => const Center(child: CupertinoActivityIndicator());

  Widget _formBody() {
    return Form(
      key: _formKey,
      onChanged: () => setState(() {}), // rebuild to update completion count
      child: ListView(
        padding: AppPadding.screen,
        children: [
          const SizedBox(height: AppSizes.sm),

          // ── Exterior photo slot ─────────────────────────────────────────────
          _PhotoSlot(
            localFile: _localPhoto,
            signedUrl: _existingPhotoSignedUrl,
            onTap: _pickPhoto,
          ),

          const SizedBox(height: AppSizes.md),

          // ── Completion nudge ────────────────────────────────────────────────
          _CompletionBar(filled: _filledOptional, total: _kOptionalFieldCount),

          const SizedBox(height: AppSizes.lg),

          // ── Address section ─────────────────────────────────────────────────
          const _SectionLabel('Address'),
          const SizedBox(height: AppSizes.sm),

          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(labelText: 'Street Address'),
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

          const SizedBox(height: AppSizes.lg),

          // ── Property details section ────────────────────────────────────────
          const _SectionLabel('Property Details'),
          const SizedBox(height: AppSizes.sm),

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

          const SizedBox(height: AppSizes.lg),

          // ── Climate section ─────────────────────────────────────────────────
          const _SectionLabel('Climate'),
          const SizedBox(height: AppSizes.sm),

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
        ],
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _CompletionBar extends StatelessWidget {
  const _CompletionBar({required this.filled, required this.total});
  final int filled;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = filled / total;
    final isComplete = filled == total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 4,
            backgroundColor: AppColors.warmInset,
            valueColor: AlwaysStoppedAnimation<Color>(
              isComplete ? AppColors.olive : AppColors.sand,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          isComplete
              ? 'Profile complete'
              : '$filled of $total optional fields filled',
          style: TextStyle(
            fontSize: 11,
            color: isComplete ? AppColors.olive : AppColors.textTertiary,
            fontWeight: isComplete ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.onTap,
    this.localFile,
    this.signedUrl,
  });

  final VoidCallback onTap;
  final File? localFile;
  final String? signedUrl;

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (localFile != null) {
      image = Image.file(localFile!, fit: BoxFit.cover);
    } else if (signedUrl != null) {
      image = CachedNetworkImage(
        imageUrl: signedUrl!,
        fit: BoxFit.cover,
        placeholder: (_, _) => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.textSecondary,
          ),
        ),
        errorWidget: (_, _, _) => _placeholder(),
      );
    } else {
      image = _placeholder();
    }

    final hasPhoto = localFile != null || signedUrl != null;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Stack(
          children: [
            AspectRatio(aspectRatio: 16 / 9, child: image),
            // Edit overlay
            Positioned.fill(
              child: Container(
                color: hasPhoto
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.transparent,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.camera_alt_outlined,
                            size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          hasPhoto ? 'Change Photo' : 'Add Cover Photo',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.warmFill,
      child: const Center(
        child: Icon(
          Icons.home_outlined,
          size: 48,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
