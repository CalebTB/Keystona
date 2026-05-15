import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../../services/providers/service_providers.dart';
import '../../../services/supabase_service.dart';
import '../models/home_profile_overview.dart';
import '../providers/home_profile_provider.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const String _kBucket = 'property-photos';

const List<({String label, String value})> _kPropertyTypes = [
  (label: 'Single Family', value: 'single_family'),
  (label: 'Condo', value: 'condo'),
  (label: 'Townhouse', value: 'townhouse'),
  (label: 'Multi-Family', value: 'multi_family'),
  (label: 'Mobile Home', value: 'mobile_home'),
  (label: 'Other', value: 'other'),
];

const List<({String label, String subtitle, int? value})> _kClimateZones = [
  (label: 'Zone 1', subtitle: 'Hot-humid', value: 1),
  (label: 'Zone 2', subtitle: 'Hot-dry', value: 2),
  (label: 'Zone 3', subtitle: 'Warm-humid', value: 3),
  (label: 'Zone 4', subtitle: 'Mixed-humid', value: 4),
  (label: 'Zone 5', subtitle: 'Cold', value: 5),
  (label: 'Zone 6', subtitle: 'Cold', value: 6),
  (label: 'Zone 7', subtitle: 'Very Cold', value: 7),
  (label: 'Zone 8', subtitle: 'Subarctic', value: 8),
  (label: "I don't know", subtitle: '', value: null),
];

const int _kOptionalFieldCount = 8;

// ── Card decoration ───────────────────────────────────────────────────────────

const BoxDecoration _kCardDecoration = BoxDecoration(
  color: AppColors.cardBackground,
  borderRadius: BorderRadius.all(Radius.circular(AppSizes.radiusMd)),
  border: Border.fromBorderSide(
    BorderSide(color: AppColors.border, width: 1.5),
  ),
);

const BoxDecoration _kClimateCardDecoration = BoxDecoration(
  color: AppColors.oliveDim,
  borderRadius: BorderRadius.all(Radius.circular(AppSizes.radiusMd)),
  border: Border.fromBorderSide(
    BorderSide(color: Color(0x225A7050), width: 1.5),
  ),
);

// ── Main screen ───────────────────────────────────────────────────────────────

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
  final _priceController = TextEditingController();

  // ── Selected values ──────────────────────────────────────────────────────────

  DateTime? _purchaseDate;

  String? _selectedPropertyType;
  int? _selectedClimateZone;

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
    if (overview != null) _populateFrom(overview);
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
    _bathroomsController.text = p.bathrooms != null ? _fmtNum(p.bathrooms!) : '';
    _selectedPropertyType = p.propertyType;
    _selectedClimateZone = p.climateZone;
    _existingPhotoPath = p.exteriorPhotoPath;
    _existingPhotoSignedUrl = overview.exteriorPhotoSignedUrl;
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
    _priceController.dispose();
    super.dispose();
  }

  // ── Completion nudge ──────────────────────────────────────────────────────────

  int get _filledOptional {
    int n = 0;
    if (_address2Controller.text.trim().isNotEmpty) n++;
    if (_selectedPropertyType != null) n++;
    if (_yearBuiltController.text.trim().isNotEmpty) n++;
    if (_squareFeetController.text.trim().isNotEmpty) n++;
    if (_bedroomsController.text.trim().isNotEmpty) n++;
    if (_bathroomsController.text.trim().isNotEmpty) n++;
    if (_selectedClimateZone != null) n++;
    if (_localPhoto != null || _existingPhotoPath != null) n++;
    return n;
  }

  // ── Actions ───────────────────────────────────────────────────────────────────

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (picked == null || !mounted) return;
    setState(() => _localPhoto = File(picked.path));
  }

  void _showZonePicker() {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      showCupertinoModalPopup<void>(
        context: context,
        builder: (_) => CupertinoActionSheet(
          title: const Text('Climate Zone'),
          actions: _kClimateZones.map((z) {
            final label = z.value != null
                ? '${z.label} · ${z.subtitle}'
                : z.label;
            return CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                setState(() => _selectedClimateZone = z.value);
              },
              isDefaultAction: z.value == _selectedClimateZone,
              child: Text(label),
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Cancel'),
          ),
        ),
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _kClimateZones.map((z) {
              final label = z.value != null
                  ? '${z.label} · ${z.subtitle}'
                  : z.label;
              return ListTile(
                title: Text(label),
                selected: z.value == _selectedClimateZone,
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() => _selectedClimateZone = z.value);
                },
              );
            }).toList(),
          ),
        ),
      );
    }
  }

  Future<void> _showPurchaseDatePicker() async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      DateTime picked = _purchaseDate ?? DateTime.now();
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (_) => Material(
          type: MaterialType.transparency,
          child: Container(
            height: 300,
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
                        setState(() => _purchaseDate = picked);
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: picked,
                    maximumDate: DateTime.now(),
                    onDateTimeChanged: (dt) => picked = dt,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: _purchaseDate ?? DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );
      if (picked != null) setState(() => _purchaseDate = picked);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
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
        if (_priceController.text.trim().isNotEmpty)
          'purchase_price': num.parse(_priceController.text.trim()),
        if (_purchaseDate != null)
          'purchase_date': _purchaseDate!.toIso8601String().split('T')[0],
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
      backgroundColor: AppColors.warmOffWhite,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.warmOffWhite,
        border: null,
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
      backgroundColor: AppColors.warmOffWhite,
      appBar: AppBar(
        backgroundColor: AppColors.warmOffWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Edit Property'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _saving ? null : () => context.pop(),
        ),
        actions: [
          if (_saveSuccess)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.check_circle, color: Colors.green, size: 22),
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

  Widget _loadingBody() =>
      const Center(child: CupertinoActivityIndicator());

  Widget _formBody() {
    final zoneData = _selectedClimateZone != null
        ? _kClimateZones.where((z) => z.value == _selectedClimateZone).firstOrNull
        : null;

    return Form(
      key: _formKey,
      onChanged: () => setState(() {}),
      child: ListView(
        padding: AppPadding.screen.copyWith(top: AppSizes.md),
        children: [
          // ── Cover photo ───────────────────────────────────────────────────
          _PhotoSlot(
            localFile: _localPhoto,
            signedUrl: _existingPhotoSignedUrl,
            onTap: _pickPhoto,
          ),

          const SizedBox(height: AppSizes.md),

          // ── Completion nudge ──────────────────────────────────────────────
          _CompletionBar(
            filled: _filledOptional,
            total: _kOptionalFieldCount,
          ),

          const SizedBox(height: AppSizes.xl),

          // ╔══════════════════════════════════════════════════════════════════╗
          // ║  IDENTITY — Where is it?                                        ║
          // ╚══════════════════════════════════════════════════════════════════╝
          _SectionHeader(
            dot: AppColors.accent,
            eyebrow: 'IDENTITY',
            title: 'Where is it?',
          ),

          const SizedBox(height: AppSizes.md),

          // Address
          _FieldCard(
            label: 'ADDRESS',
            child: TextFormField(
              controller: _addressController,
              style: AppTextStyles.bodyLarge,
              decoration: _fieldDecoration('123 Main St'),
              textCapitalization: TextCapitalization.words,
              maxLength: 500,
              buildCounter: _noCounter,
              validator: Validators.required,
            ),
          ),

          const SizedBox(height: AppSizes.cardGap),

          // Unit / Apt / Suite
          _FieldCard(
            label: 'UNIT / APT / SUITE',
            child: TextFormField(
              controller: _address2Controller,
              style: AppTextStyles.bodyLarge,
              decoration: _fieldDecoration('Optional'),
              textCapitalization: TextCapitalization.words,
            ),
          ),

          const SizedBox(height: AppSizes.cardGap),

          // City / State / ZIP row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _FieldCard(
                  label: 'CITY',
                  child: TextFormField(
                    controller: _cityController,
                    style: AppTextStyles.bodyLarge,
                    decoration: _fieldDecoration('Austin'),
                    textCapitalization: TextCapitalization.words,
                    validator: Validators.required,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.cardGap),
              Expanded(
                flex: 2,
                child: _FieldCard(
                  label: 'STATE',
                  child: TextFormField(
                    controller: _stateController,
                    style: AppTextStyles.bodyLarge,
                    decoration: _fieldDecoration('TX'),
                    maxLength: 2,
                    buildCounter: _noCounter,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
                    ],
                    validator: Validators.required,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.cardGap),
              Expanded(
                flex: 3,
                child: _FieldCard(
                  label: 'ZIP',
                  child: TextFormField(
                    controller: _zipController,
                    style: AppTextStyles.bodyLarge,
                    decoration: _fieldDecoration('78701'),
                    maxLength: 5,
                    buildCounter: _noCounter,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (!RegExp(r'^\d{5}$').hasMatch(v.trim())) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ],
          ),

          // Climate zone card (shown when zone is set)
          if (zoneData != null) ...[
            const SizedBox(height: AppSizes.cardGap),
            _ClimateZoneCard(
              zoneLabel: zoneData.label,
              zoneSub: zoneData.subtitle,
              onTap: _showZonePicker,
            ),
          ] else ...[
            const SizedBox(height: AppSizes.cardGap),
            _SetClimateZoneHint(onTap: _showZonePicker),
          ],

          const SizedBox(height: AppSizes.xl),

          // ╔══════════════════════════════════════════════════════════════════╗
          // ║  SPECS — About the house                                        ║
          // ╚══════════════════════════════════════════════════════════════════╝
          _SectionHeader(
            dot: AppColors.olive,
            eyebrow: 'SPECS',
            title: 'About the house',
          ),

          const SizedBox(height: AppSizes.md),

          // Property type dropdown
          _FieldCard(
            label: 'PROPERTY TYPE',
            child: DropdownButton<String>(
              value: _selectedPropertyType,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              hint: Text(
                'Select',
                style: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.textTertiary),
              ),
              style: AppTextStyles.bodyLarge,
              icon: const Icon(Icons.keyboard_arrow_down,
                  size: 18, color: AppColors.textTertiary),
              items: _kPropertyTypes
                  .map((t) => DropdownMenuItem<String>(
                        value: t.value,
                        child: Text(t.label),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedPropertyType = v),
            ),
          ),

          const SizedBox(height: AppSizes.cardGap),

          // Year Built / Square Feet
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FieldCard(
                  label: 'YEAR BUILT',
                  child: TextFormField(
                    controller: _yearBuiltController,
                    style: AppTextStyles.bodyLarge,
                    decoration: _fieldDecoration('e.g. 2005'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: Validators.year,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.cardGap),
              Expanded(
                child: _FieldCard(
                  label: 'SQUARE FEET',
                  child: TextFormField(
                    controller: _squareFeetController,
                    style: AppTextStyles.bodyLarge,
                    decoration: _fieldDecoration('e.g. 2,200'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      return Validators.positiveNumber(v);
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.cardGap),

          // Bed / Bath
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FieldCard(
                  label: 'BED',
                  child: TextFormField(
                    controller: _bedroomsController,
                    style: AppTextStyles.bodyLarge,
                    decoration: _fieldDecoration('3'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      return Validators.positiveNumber(v);
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.cardGap),
              Expanded(
                child: _FieldCard(
                  label: 'BATH',
                  child: TextFormField(
                    controller: _bathroomsController,
                    style: AppTextStyles.bodyLarge,
                    decoration: _fieldDecoration('2.5'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      return Validators.positiveNumber(v);
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.xl),

          // ╔══════════════════════════════════════════════════════════════════╗
          // ║  PURCHASE — Optional history                                    ║
          // ╚══════════════════════════════════════════════════════════════════╝
          _SectionHeader(
            dot: AppColors.sandAmber,
            eyebrow: 'PURCHASE',
            title: 'Optional history',
          ),

          const SizedBox(height: AppSizes.sm),

          Text(
            'Adds context for the Home History Report. Stays private.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),

          const SizedBox(height: AppSizes.md),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _showPurchaseDatePicker,
                  child: _FieldCard(
                    label: 'PURCHASE DATE',
                    child: Text(
                      _purchaseDate != null
                          ? DateFormat('MMM d, yyyy').format(_purchaseDate!)
                          : '—',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: _purchaseDate != null
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.cardGap),
              Expanded(
                child: _FieldCard(
                  label: 'PRICE',
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        r'$',
                        style: AppTextStyles.bodyLarge
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          style: AppTextStyles.bodyLarge,
                          decoration: _fieldDecoration('0'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }
}

// ── Decoration helper ─────────────────────────────────────────────────────────

InputDecoration _fieldDecoration(String hint) => InputDecoration(
      isDense: true,
      filled: true,
      fillColor: AppColors.cardBackground,
      contentPadding: const EdgeInsets.only(top: 2),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      hintText: hint,
      hintStyle: AppTextStyles.bodyLarge.copyWith(
        color: AppColors.textTertiary,
      ),
      errorStyle: TextStyle(
        fontSize: 10,
        color: AppColors.accent,
        height: 1.4,
      ),
    );

Widget? Function(BuildContext, {required int currentLength, required bool isFocused, required int? maxLength})
    get _noCounter => (_, {required currentLength, required isFocused, required maxLength}) => null;

// ── Supporting widgets ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.dot,
    required this.eyebrow,
    required this.title,
  });

  final Color dot;
  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              eyebrow,
              style: AppTextStyles.monoSection,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(title, style: AppTextStyles.displaySmall),
      ],
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _kCardDecoration,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.monoSection),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _ClimateZoneCard extends StatelessWidget {
  const _ClimateZoneCard({
    required this.zoneLabel,
    required this.zoneSub,
    required this.onTap,
  });

  final String zoneLabel;
  final String zoneSub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: _kClimateCardDecoration,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.olive.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.thermostat_outlined,
                size: 18,
                color: AppColors.olive,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CLIMATE ZONE',
                    style: AppTextStyles.monoSection
                        .copyWith(color: AppColors.olive),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$zoneLabel · $zoneSub',
                    style: AppTextStyles.bodyMediumSemibold
                        .copyWith(color: AppColors.olive),
                  ),
                ],
              ),
            ),
            Text(
              'Change',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.olive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetClimateZoneHint extends StatelessWidget {
  const _SetClimateZoneHint({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: _kCardDecoration,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Icon(
              Icons.thermostat_outlined,
              size: 16,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: 8),
            Text(
              'Set climate zone',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textTertiary),
            ),
            const Spacer(),
            const Icon(
              Icons.keyboard_arrow_right,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
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
  const _PhotoSlot({required this.onTap, this.localFile, this.signedUrl});

  final VoidCallback onTap;
  final File? localFile;
  final String? signedUrl;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = localFile != null || signedUrl != null;

    Widget image;
    if (localFile != null) {
      image = Image.file(localFile!, fit: BoxFit.cover);
    } else if (signedUrl != null) {
      image = CachedNetworkImage(
        imageUrl: signedUrl!,
        fit: BoxFit.cover,
        placeholder: (_, _) => const Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.textSecondary),
        ),
        errorWidget: (_, _, _) => _placeholder(),
      );
    } else {
      image = _placeholder();
    }

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Stack(
          children: [
            AspectRatio(aspectRatio: 16 / 9, child: image),
            Positioned.fill(
              child: Container(
                color: hasPhoto
                    ? Colors.black.withValues(alpha: 0.22)
                    : Colors.transparent,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
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

  Widget _placeholder() => Container(
        color: AppColors.darkBackground,
        child: const Center(
          child: Icon(Icons.home_outlined,
              size: 48, color: AppColors.textTertiary),
        ),
      );
}
