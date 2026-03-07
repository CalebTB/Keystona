import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/utility_shutoff.dart';
import '../providers/emergency_hub_provider.dart';
import '../widgets/circuit_directory_editor.dart';
import '../widgets/shutoff_detail_skeleton.dart';

// ── Valve type options ────────────────────────────────────────────────────────

/// Valid values for the `valve_type` column on water and gas shutoffs.
abstract final class _ValveTypes {
  static const all = [
    (value: 'gate', label: 'Gate Valve'),
    (value: 'ball', label: 'Ball Valve'),
    (value: 'butterfly', label: 'Butterfly Valve'),
    (value: 'other', label: 'Other'),
  ];

}

/// Valid values for the `turn_direction` column.
abstract final class _TurnDirections {
  static const all = [
    (value: 'clockwise', label: 'Clockwise'),
    (value: 'counter_clockwise', label: 'Counter-clockwise'),
  ];
}

// ── Main screen ───────────────────────────────────────────────────────────────

/// Setup / edit screen for a single utility shutoff (water, gas, or electrical).
///
/// Parameterized by [utilityType] — the same screen is reused for all three
/// utility types; field visibility is driven by the type.
///
/// Loading: fetches existing record in [initState], shows [ShutoffDetailSkeleton]
/// while pending.
/// Error: shown via a snackbar; form stays accessible so the user can still
/// attempt to save.
/// Empty: form fields start blank when no record exists yet.
class ShutoffDetailScreen extends ConsumerStatefulWidget {
  const ShutoffDetailScreen({super.key, required this.utilityType});

  /// One of 'water', 'gas', or 'electrical'.
  final String utilityType;

  @override
  ConsumerState<ShutoffDetailScreen> createState() =>
      _ShutoffDetailScreenState();
}

class _ShutoffDetailScreenState extends ConsumerState<ShutoffDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Controllers ───────────────────────────────────────────────────────────

  late final TextEditingController _locationController;
  late final TextEditingController _gasPhoneController;
  late final TextEditingController _breakerLocationController;
  late final TextEditingController _breakerAmperageController;
  late final TextEditingController _toolsController;
  late final TextEditingController _instructionsController;

  // ── Local state ───────────────────────────────────────────────────────────

  /// True while the initial fetch is running.
  bool _loading = true;

  /// True while the save operation is in progress.
  bool _saving = false;

  String? _valveType;
  String? _turnDirection;

  /// Circuit directory entries — only used for electrical.
  Map<String, String> _circuitDirectory = {};

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController();
    _gasPhoneController = TextEditingController();
    _breakerLocationController = TextEditingController();
    _breakerAmperageController = TextEditingController();
    _toolsController = TextEditingController();
    _instructionsController = TextEditingController();
    _loadExisting();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _gasPhoneController.dispose();
    _breakerLocationController.dispose();
    _breakerAmperageController.dispose();
    _toolsController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadExisting() async {
    try {
      final notifier = ref.read(emergencyHubProvider.notifier);
      final shutoff = await notifier.getShutoff(widget.utilityType);
      if (!mounted) return;

      if (shutoff != null) {
        _populateFrom(shutoff);
      }
    } catch (_) {
      if (!mounted) return;
      SnackbarService.showError(
        context,
        'Could not load shutoff details. You can still fill in and save.',
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _populateFrom(UtilityShutoff shutoff) {
    _locationController.text = shutoff.locationDescription;
    _instructionsController.text = shutoff.specialInstructions ?? '';
    _toolsController.text = shutoff.toolsRequired.join('\n');

    if (widget.utilityType == 'water' || widget.utilityType == 'gas') {
      _valveType = shutoff.valveType;
      _turnDirection = shutoff.turnDirection;
    }

    if (widget.utilityType == 'gas') {
      _gasPhoneController.text = shutoff.gasCompanyPhone ?? '';
    }

    if (widget.utilityType == 'electrical') {
      _breakerLocationController.text = shutoff.mainBreakerLocation ?? '';
      _breakerAmperageController.text =
          shutoff.mainBreakerAmperage?.toString() ?? '';
      // circuitDirectory on the model is List<Map<String, dynamic>>.
      // Convert to Map<String, String> for the editor.
      _circuitDirectory = {
        for (final entry in shutoff.circuitDirectory)
          (entry['number'] as String? ?? ''): (entry['label'] as String? ?? ''),
      };
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;

    setState(() => _saving = true);

    final notifier = ref.read(emergencyHubProvider.notifier);

    try {
      final tools = _toolsController.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final data = <String, dynamic>{
        'utility_type': widget.utilityType,
        'location_description': _locationController.text.trim(),
        'special_instructions': _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
        'tools_required': tools,
        'is_complete': true,
      };

      if (widget.utilityType == 'water' || widget.utilityType == 'gas') {
        data['valve_type'] = _valveType;
        data['turn_direction'] = _turnDirection;
      }

      if (widget.utilityType == 'gas') {
        final phone = _gasPhoneController.text.trim();
        data['gas_company_phone'] = phone.isEmpty ? null : phone;
      }

      if (widget.utilityType == 'electrical') {
        final ampText = _breakerAmperageController.text.trim();
        data['main_breaker_location'] =
            _breakerLocationController.text.trim().isEmpty
                ? null
                : _breakerLocationController.text.trim();
        data['main_breaker_amperage'] =
            ampText.isEmpty ? null : int.tryParse(ampText);

        // Convert Map<String, String> to List<Map<String, dynamic>> for
        // the JSONB column expected by the model.
        final circuitList = _circuitDirectory.entries
            .where((e) => e.key.isNotEmpty)
            .map((e) => {'number': e.key, 'label': e.value})
            .toList();
        data['circuit_directory'] = circuitList;
      }

      await notifier.saveShutoff(data);
      if (!mounted) return;

      SnackbarService.showSuccess(
        context,
        '${widget.utilityType.utilityLabel} saved successfully.',
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      SnackbarService.showError(
        context,
        'Could not save shutoff details. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final title = widget.utilityType.utilityLabel;

    if (_loading) {
      return isIOS
          ? CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(middle: Text(title)),
              child: SafeArea(
                bottom: false,
                child: const ShutoffDetailSkeleton(),
              ),
            )
          : Scaffold(
              backgroundColor: AppColors.warmOffWhite,
              appBar: AppBar(
                title: Text(title, style: AppTextStyles.h3),
                backgroundColor: AppColors.warmOffWhite,
                scrolledUnderElevation: 0,
                elevation: 0,
              ),
              body: const ShutoffDetailSkeleton(),
            );
    }

    return isIOS
        ? _IOSLayout(
            title: title,
            formKey: _formKey,
            utilityType: widget.utilityType,
            locationController: _locationController,
            gasPhoneController: _gasPhoneController,
            breakerLocationController: _breakerLocationController,
            breakerAmperageController: _breakerAmperageController,
            toolsController: _toolsController,
            instructionsController: _instructionsController,
            valveType: _valveType,
            turnDirection: _turnDirection,
            circuitDirectory: _circuitDirectory,
            saving: _saving,
            onValveTypeChanged: (v) => setState(() => _valveType = v),
            onTurnDirectionChanged: (v) => setState(() => _turnDirection = v),
            onCircuitDirectoryChanged: (m) =>
                setState(() => _circuitDirectory = m),
            onSave: _save,
          )
        : _AndroidLayout(
            title: title,
            formKey: _formKey,
            utilityType: widget.utilityType,
            locationController: _locationController,
            gasPhoneController: _gasPhoneController,
            breakerLocationController: _breakerLocationController,
            breakerAmperageController: _breakerAmperageController,
            toolsController: _toolsController,
            instructionsController: _instructionsController,
            valveType: _valveType,
            turnDirection: _turnDirection,
            circuitDirectory: _circuitDirectory,
            saving: _saving,
            onValveTypeChanged: (v) => setState(() => _valveType = v),
            onTurnDirectionChanged: (v) => setState(() => _turnDirection = v),
            onCircuitDirectoryChanged: (m) =>
                setState(() => _circuitDirectory = m),
            onSave: _save,
          );
  }
}

// ── iOS layout ─────────────────────────────────────────────────────────────────

class _IOSLayout extends StatelessWidget {
  const _IOSLayout({
    required this.title,
    required this.formKey,
    required this.utilityType,
    required this.locationController,
    required this.gasPhoneController,
    required this.breakerLocationController,
    required this.breakerAmperageController,
    required this.toolsController,
    required this.instructionsController,
    required this.valveType,
    required this.turnDirection,
    required this.circuitDirectory,
    required this.saving,
    required this.onValveTypeChanged,
    required this.onTurnDirectionChanged,
    required this.onCircuitDirectoryChanged,
    required this.onSave,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final String utilityType;
  final TextEditingController locationController;
  final TextEditingController gasPhoneController;
  final TextEditingController breakerLocationController;
  final TextEditingController breakerAmperageController;
  final TextEditingController toolsController;
  final TextEditingController instructionsController;
  final String? valveType;
  final String? turnDirection;
  final Map<String, String> circuitDirectory;
  final bool saving;
  final ValueChanged<String?> onValveTypeChanged;
  final ValueChanged<String?> onTurnDirectionChanged;
  final ValueChanged<Map<String, String>> onCircuitDirectoryChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(title),
        trailing: saving
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onSave,
                child: Text(
                  'Save',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.deepNavy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
      child: SafeArea(
        bottom: false,
        child: _FormBody(
          formKey: formKey,
          utilityType: utilityType,
          locationController: locationController,
          gasPhoneController: gasPhoneController,
          breakerLocationController: breakerLocationController,
          breakerAmperageController: breakerAmperageController,
          toolsController: toolsController,
          instructionsController: instructionsController,
          valveType: valveType,
          turnDirection: turnDirection,
          circuitDirectory: circuitDirectory,
          saving: saving,
          isIOS: true,
          onValveTypeChanged: onValveTypeChanged,
          onTurnDirectionChanged: onTurnDirectionChanged,
          onCircuitDirectoryChanged: onCircuitDirectoryChanged,
          onSave: onSave,
          showSaveButton: false,
        ),
      ),
    );
  }
}

// ── Android layout ────────────────────────────────────────────────────────────

class _AndroidLayout extends StatelessWidget {
  const _AndroidLayout({
    required this.title,
    required this.formKey,
    required this.utilityType,
    required this.locationController,
    required this.gasPhoneController,
    required this.breakerLocationController,
    required this.breakerAmperageController,
    required this.toolsController,
    required this.instructionsController,
    required this.valveType,
    required this.turnDirection,
    required this.circuitDirectory,
    required this.saving,
    required this.onValveTypeChanged,
    required this.onTurnDirectionChanged,
    required this.onCircuitDirectoryChanged,
    required this.onSave,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final String utilityType;
  final TextEditingController locationController;
  final TextEditingController gasPhoneController;
  final TextEditingController breakerLocationController;
  final TextEditingController breakerAmperageController;
  final TextEditingController toolsController;
  final TextEditingController instructionsController;
  final String? valveType;
  final String? turnDirection;
  final Map<String, String> circuitDirectory;
  final bool saving;
  final ValueChanged<String?> onValveTypeChanged;
  final ValueChanged<String?> onTurnDirectionChanged;
  final ValueChanged<Map<String, String>> onCircuitDirectoryChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      appBar: AppBar(
        title: Text(title, style: AppTextStyles.h3),
        backgroundColor: AppColors.warmOffWhite,
        scrolledUnderElevation: 0,
        elevation: 0,
        actions: [
          if (saving)
            const Padding(
              padding: EdgeInsets.only(right: AppSizes.md),
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
              onPressed: onSave,
              child: Text(
                'Save',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.deepNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _FormBody(
        formKey: formKey,
        utilityType: utilityType,
        locationController: locationController,
        gasPhoneController: gasPhoneController,
        breakerLocationController: breakerLocationController,
        breakerAmperageController: breakerAmperageController,
        toolsController: toolsController,
        instructionsController: instructionsController,
        valveType: valveType,
        turnDirection: turnDirection,
        circuitDirectory: circuitDirectory,
        saving: saving,
        isIOS: false,
        onValveTypeChanged: onValveTypeChanged,
        onTurnDirectionChanged: onTurnDirectionChanged,
        onCircuitDirectoryChanged: onCircuitDirectoryChanged,
        onSave: onSave,
        showSaveButton: true,
      ),
    );
  }
}

// ── Shared form body ──────────────────────────────────────────────────────────

/// The actual form content, shared between iOS and Android layouts.
///
/// [showSaveButton] drives whether a bottom save button is rendered —
/// iOS puts Save in the nav bar trailing slot; Android uses the app bar action.
class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.formKey,
    required this.utilityType,
    required this.locationController,
    required this.gasPhoneController,
    required this.breakerLocationController,
    required this.breakerAmperageController,
    required this.toolsController,
    required this.instructionsController,
    required this.valveType,
    required this.turnDirection,
    required this.circuitDirectory,
    required this.saving,
    required this.isIOS,
    required this.onValveTypeChanged,
    required this.onTurnDirectionChanged,
    required this.onCircuitDirectoryChanged,
    required this.onSave,
    required this.showSaveButton,
  });

  final GlobalKey<FormState> formKey;
  final String utilityType;
  final TextEditingController locationController;
  final TextEditingController gasPhoneController;
  final TextEditingController breakerLocationController;
  final TextEditingController breakerAmperageController;
  final TextEditingController toolsController;
  final TextEditingController instructionsController;
  final String? valveType;
  final String? turnDirection;
  final Map<String, String> circuitDirectory;
  final bool saving;
  final bool isIOS;
  final ValueChanged<String?> onValveTypeChanged;
  final ValueChanged<String?> onTurnDirectionChanged;
  final ValueChanged<Map<String, String>> onCircuitDirectoryChanged;
  final VoidCallback onSave;
  final bool showSaveButton;

  bool get _isWater => utilityType == 'water';
  bool get _isGas => utilityType == 'gas';
  bool get _isElectrical => utilityType == 'electrical';
  bool get _hasValve => _isWater || _isGas;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: AppPadding.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSizes.sm),

            // ── Setup instructions banner ──────────────────────────────────
            _InfoBanner(utilityType: utilityType),
            const SizedBox(height: AppSizes.lg),

            // ── General section ────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.location_on_outlined,
              label: 'Location',
            ),
            const SizedBox(height: AppSizes.sm),
            _FormField(
              controller: locationController,
              label: 'Location Description',
              hint: _locationHint,
              isIOS: isIOS,
              maxLines: 2,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please describe where to find the shutoff';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Valve / shutoff type section (water + gas) ─────────────────
            if (_hasValve) ...[
              _SectionHeader(
                icon: Icons.settings_outlined,
                label: 'Valve Details',
              ),
              const SizedBox(height: AppSizes.sm),
              _EnumPickerField(
                label: 'Valve Type',
                value: valveType,
                options: _ValveTypes.all
                    .map((v) => (value: v.value, label: v.label))
                    .toList(),
                isIOS: isIOS,
                onChanged: onValveTypeChanged,
                context: context,
              ),
              const SizedBox(height: AppSizes.sm),
              _EnumPickerField(
                label: 'Turn Direction to Close',
                value: turnDirection,
                options: _TurnDirections.all
                    .map((v) => (value: v.value, label: v.label))
                    .toList(),
                isIOS: isIOS,
                onChanged: onTurnDirectionChanged,
                context: context,
              ),
              const SizedBox(height: AppSizes.lg),
            ],

            // ── Gas-specific ───────────────────────────────────────────────
            if (_isGas) ...[
              _SectionHeader(
                icon: Icons.phone_outlined,
                label: 'Gas Company',
              ),
              const SizedBox(height: AppSizes.sm),
              _FormField(
                controller: gasPhoneController,
                label: 'Gas Company Emergency Phone',
                hint: 'e.g. 1-800-555-0123',
                isIOS: isIOS,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSizes.lg),
            ],

            // ── Electrical-specific ────────────────────────────────────────
            if (_isElectrical) ...[
              _SectionHeader(
                icon: Icons.electrical_services_outlined,
                label: 'Main Breaker Panel',
              ),
              const SizedBox(height: AppSizes.sm),
              _FormField(
                controller: breakerLocationController,
                label: 'Panel Location',
                hint: 'e.g. Basement utility room, north wall',
                isIOS: isIOS,
                maxLines: 2,
              ),
              const SizedBox(height: AppSizes.sm),
              _FormField(
                controller: breakerAmperageController,
                label: 'Main Breaker Amperage',
                hint: 'e.g. 200',
                isIOS: isIOS,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
                    return 'Enter a whole number (e.g. 200)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.lg),

              // Circuit directory editor.
              CircuitDirectoryEditor(
                initialValue: circuitDirectory,
                onChanged: onCircuitDirectoryChanged,
              ),
              const SizedBox(height: AppSizes.lg),
            ],

            // ── Tools required ─────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.build_outlined,
              label: 'Tools Required',
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              'One tool per line.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            _FormField(
              controller: toolsController,
              label: 'Tools',
              hint: 'e.g. Adjustable wrench\nFlashlight',
              isIOS: isIOS,
              maxLines: 4,
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Special instructions ───────────────────────────────────────
            _SectionHeader(
              icon: Icons.info_outline,
              label: 'Special Instructions',
            ),
            const SizedBox(height: AppSizes.sm),
            _FormField(
              controller: instructionsController,
              label: 'Instructions',
              hint: 'Any notes for yourself or emergency responders',
              isIOS: isIOS,
              maxLines: 4,
            ),

            // Bottom save button — only shown on Android.
            if (showSaveButton) ...[
              const SizedBox(height: AppSizes.xl),
              _SaveButton(saving: saving, onSave: onSave),
            ],

            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }

  String get _locationHint => switch (utilityType) {
        'water' => 'e.g. Basement utility room, behind water heater',
        'gas' => 'e.g. Right side of house, yellow valve near meter',
        'electrical' => 'e.g. Garage, left of entry door',
        _ => 'Where is the shutoff located?',
      };
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppSizes.iconSm, color: AppColors.deepNavy),
        const SizedBox(width: AppSizes.xs),
        Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.deepNavy,
          ),
        ),
      ],
    );
  }
}

// ── Info banner ───────────────────────────────────────────────────────────────

/// Contextual tip shown at the top of each utility type's form.
class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.utilityType});
  final String utilityType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppPadding.card,
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: AppSizes.iconSm, color: AppColors.info),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              _tip,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }

  String get _tip => switch (utilityType) {
        'water' =>
          'In a plumbing emergency, shut off water at the main valve to stop flooding. Know the location before an emergency occurs.',
        'gas' =>
          'If you smell gas, do NOT use any switches or electronics. Leave immediately and call your gas company from outside.',
        'electrical' =>
          'Turning off the main breaker cuts power to the entire home. Individual circuit breakers control specific areas.',
        _ => 'Keep this information updated so you are prepared in an emergency.',
      };
}

// ── Adaptive form field ───────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.isIOS,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isIOS;
  final int maxLines;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSizes.xs),
        if (isIOS)
          _IOSFormField(
            controller: controller,
            hint: hint,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
          )
        else
          _AndroidFormField(
            controller: controller,
            hint: hint,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
          ),
      ],
    );
  }
}

class _IOSFormField extends StatelessWidget {
  const _IOSFormField({
    required this.controller,
    required this.hint,
    required this.maxLines,
    required this.keyboardType,
    required this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    // Wrap in FormField to participate in form validation.
    return FormField<String>(
      initialValue: controller.text,
      validator: validator,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoTextField(
            controller: controller,
            placeholder: hint,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: (v) => field.didChange(v),
            padding: const EdgeInsets.all(AppSizes.sm),
            style: AppTextStyles.bodyMedium,
            placeholderStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDisabled,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(
                color: field.hasError ? AppColors.error : AppColors.border,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
          ),
          if (field.hasError) ...[
            const SizedBox(height: AppSizes.xs),
            Text(
              field.errorText!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _AndroidFormField extends StatelessWidget {
  const _AndroidFormField({
    required this.controller,
    required this.hint,
    required this.maxLines,
    required this.keyboardType,
    required this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textDisabled,
        ),
        contentPadding: AppPadding.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: BorderSide(color: AppColors.deepNavy, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
    );
  }
}

// ── Enum picker field ─────────────────────────────────────────────────────────

/// Adaptive dropdown/picker for enum values.
///
/// iOS: taps open a [CupertinoActionSheet].
/// Android: uses a [DropdownButtonFormField].
class _EnumPickerField extends StatelessWidget {
  const _EnumPickerField({
    required this.label,
    required this.value,
    required this.options,
    required this.isIOS,
    required this.onChanged,
    required this.context,
  });

  final String label;
  final String? value;
  final List<({String value, String label})> options;
  final bool isIOS;
  final ValueChanged<String?> onChanged;
  // context passed in so the CupertinoActionSheet can be presented.
  final BuildContext context;

  String get _displayLabel =>
      value == null ? 'Select...' : options.firstWhere((o) => o.value == value, orElse: () => (value: value!, label: value!)).label;

  @override
  Widget build(BuildContext outerContext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSizes.xs),
        if (isIOS)
          _IOSPickerTile(
            displayLabel: _displayLabel,
            hasValue: value != null,
            onTap: () => _showIOSPicker(outerContext),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: value,
            items: options
                .map(
                  (o) => DropdownMenuItem(
                    value: o.value,
                    child: Text(o.label, style: AppTextStyles.bodyMedium),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                borderSide: BorderSide(color: AppColors.deepNavy, width: 1.5),
              ),
              filled: true,
              fillColor: AppColors.surface,
            ),
          ),
      ],
    );
  }

  Future<void> _showIOSPicker(BuildContext ctx) async {
    await showCupertinoModalPopup<void>(
      context: ctx,
      builder: (_) => CupertinoActionSheet(
        title: Text(label),
        actions: options
            .map(
              (o) => CupertinoActionSheetAction(
                onPressed: () {
                  onChanged(o.value);
                  Navigator.of(ctx, rootNavigator: true).pop();
                },
                child: Text(o.label),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

class _IOSPickerTile extends StatelessWidget {
  const _IOSPickerTile({
    required this.displayLabel,
    required this.hasValue,
    required this.onTap,
  });

  final String displayLabel;
  final bool hasValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppSizes.inputHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              displayLabel,
              style: AppTextStyles.bodyMedium.copyWith(
                color: hasValue ? AppColors.textPrimary : AppColors.textDisabled,
              ),
            ),
            Icon(
              CupertinoIcons.chevron_down,
              size: AppSizes.iconSm,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Save button (Android only) ────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.saving, required this.onSave});
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight,
      child: FilledButton(
        onPressed: saving ? null : onSave,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.deepNavy,
          disabledBackgroundColor: AppColors.deepNavy.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
        ),
        child: saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textInverse,
                ),
              )
            : Text(
                'Save',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.textInverse,
                ),
              ),
      ),
    );
  }
}
