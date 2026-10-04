import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/aurora/aurora.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/utility_shutoff.dart';
import '../providers/emergency_hub_provider.dart';
import '../widgets/circuit_directory_editor.dart';
import '../widgets/shutoff_detail_skeleton.dart';

// ── Valve type options ────────────────────────────────────────────────────────

abstract final class _ValveTypes {
  static const all = [
    (value: 'gate', label: 'Gate Valve'),
    (value: 'ball', label: 'Ball Valve'),
    (value: 'butterfly', label: 'Butterfly Valve'),
    (value: 'other', label: 'Other'),
  ];
}

abstract final class _TurnDirections {
  static const all = [
    (value: 'clockwise', label: 'Clockwise'),
    (value: 'counter_clockwise', label: 'Counter-clockwise'),
  ];
}

// ── Main screen ───────────────────────────────────────────────────────────────

class ShutoffDetailScreen extends ConsumerStatefulWidget {
  const ShutoffDetailScreen({super.key, required this.utilityType});

  final String utilityType;

  @override
  ConsumerState<ShutoffDetailScreen> createState() =>
      _ShutoffDetailScreenState();
}

class _ShutoffDetailScreenState extends ConsumerState<ShutoffDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _locationController;
  late final TextEditingController _gasPhoneController;
  late final TextEditingController _breakerLocationController;
  late final TextEditingController _breakerAmperageController;
  late final TextEditingController _toolsController;
  late final TextEditingController _instructionsController;

  bool _loading = true;
  bool _saving = false;
  bool _isComplete = false;

  String? _valveType;
  String? _turnDirection;
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
      if (shutoff != null) _populateFrom(shutoff);
    } catch (_) {
      if (!mounted) return;
      SnackbarService.showError(
        context,
        'Could not load shutoff details. You can still fill in and save.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _populateFrom(UtilityShutoff shutoff) {
    _locationController.text = shutoff.locationDescription;
    _instructionsController.text = shutoff.specialInstructions ?? '';
    _toolsController.text = shutoff.toolsRequired.join('\n');
    _isComplete = shutoff.isComplete;

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
      if (mounted) setState(() => _saving = false);
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
              backgroundColor: AuroraColors.paper,
              navigationBar: CupertinoNavigationBar(
                middle: Text(title),
                backgroundColor: AuroraColors.paper,
              ),
              child: const SafeArea(
                bottom: false,
                child: ShutoffDetailSkeleton(),
              ),
            )
          : Scaffold(
              backgroundColor: AuroraColors.paper,
              appBar: AppBar(
                title: Text(title, style: AuroraType.h3),
                backgroundColor: AuroraColors.paper,
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
            isComplete: _isComplete,
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
            isComplete: _isComplete,
            onValveTypeChanged: (v) => setState(() => _valveType = v),
            onTurnDirectionChanged: (v) => setState(() => _turnDirection = v),
            onCircuitDirectoryChanged: (m) =>
                setState(() => _circuitDirectory = m),
            onSave: _save,
          );
  }
}

// ── iOS layout ────────────────────────────────────────────────────────────────

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
    required this.isComplete,
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
  final bool isComplete;
  final ValueChanged<String?> onValveTypeChanged;
  final ValueChanged<String?> onTurnDirectionChanged;
  final ValueChanged<Map<String, String>> onCircuitDirectoryChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AuroraColors.paper,
      navigationBar: CupertinoNavigationBar(
        middle: Text(title),
        backgroundColor: AuroraColors.paper,
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
          isComplete: isComplete,
          isIOS: true,
          onValveTypeChanged: onValveTypeChanged,
          onTurnDirectionChanged: onTurnDirectionChanged,
          onCircuitDirectoryChanged: onCircuitDirectoryChanged,
          onSave: onSave,
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
    required this.isComplete,
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
  final bool isComplete;
  final ValueChanged<String?> onValveTypeChanged;
  final ValueChanged<String?> onTurnDirectionChanged;
  final ValueChanged<Map<String, String>> onCircuitDirectoryChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuroraColors.paper,
      appBar: AppBar(
        title: Text(title, style: AuroraType.h3),
        backgroundColor: AuroraColors.paper,
        scrolledUnderElevation: 0,
        elevation: 0,
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
        isComplete: isComplete,
        isIOS: false,
        onValveTypeChanged: onValveTypeChanged,
        onTurnDirectionChanged: onTurnDirectionChanged,
        onCircuitDirectoryChanged: onCircuitDirectoryChanged,
        onSave: onSave,
      ),
    );
  }
}

// ── Shared form body ──────────────────────────────────────────────────────────

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
    required this.isComplete,
    required this.isIOS,
    required this.onValveTypeChanged,
    required this.onTurnDirectionChanged,
    required this.onCircuitDirectoryChanged,
    required this.onSave,
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
  final bool isComplete;
  final bool isIOS;
  final ValueChanged<String?> onValveTypeChanged;
  final ValueChanged<String?> onTurnDirectionChanged;
  final ValueChanged<Map<String, String>> onCircuitDirectoryChanged;
  final VoidCallback onSave;

  bool get _isWater => utilityType == 'water';
  bool get _isGas => utilityType == 'gas';
  bool get _isElectrical => utilityType == 'electrical';
  bool get _hasValve => _isWater || _isGas;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AuroraSpacing.screenPadH,
          vertical: AuroraSpacing.screenPadTop,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status pill ────────────────────────────────────────────────
            _StatusPill(isComplete: isComplete),
            const SizedBox(height: AuroraSpacing.space5),

            // ── Info banner ────────────────────────────────────────────────
            _InfoBanner(utilityType: utilityType),
            const SizedBox(height: AuroraSpacing.space3),

            // ── Location ───────────────────────────────────────────────────
            AuroraFormSection(
              title: 'Location',
              children: [
                AuroraTextField(
                  label: 'Location Description',
                  required: true,
                  controller: locationController,
                  hintText: _locationHint,
                  maxLines: 3,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please describe where to find the shutoff';
                    }
                    return null;
                  },
                ),
              ],
            ),

            // ── Valve Details ──────────────────────────────────────────────
            if (_hasValve) ...[
              AuroraFormSection(
                title: 'Valve Details',
                isOptional: true,
                children: [
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
                ],
              ),
            ],

            // ── Gas Company ────────────────────────────────────────────────
            if (_isGas) ...[
              AuroraFormSection(
                title: 'Gas Company',
                isOptional: true,
                children: [
                  AuroraTextField(
                    label: 'Emergency Phone',
                    controller: gasPhoneController,
                    hintText: 'e.g. 1-800-555-0123',
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ],

            // ── Electrical ─────────────────────────────────────────────────
            if (_isElectrical) ...[
              AuroraFormSection(
                title: 'Main Breaker Panel',
                isOptional: true,
                children: [
                  AuroraTextField(
                    label: 'Panel Location',
                    controller: breakerLocationController,
                    hintText: 'e.g. Basement utility room, north wall',
                    maxLines: 2,
                  ),
                  AuroraTextField(
                    label: 'Main Breaker Amperage',
                    controller: breakerAmperageController,
                    hintText: 'e.g. 200',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
                        return 'Enter a whole number (e.g. 200)';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: AuroraSpacing.space8),
              CircuitDirectoryEditor(
                initialValue: circuitDirectory,
                onChanged: onCircuitDirectoryChanged,
              ),
            ],

            // ── Tools Required ─────────────────────────────────────────────
            AuroraFormSection(
              title: 'Tools Required',
              isOptional: true,
              children: [
                AuroraTextField(
                  label: 'Tools',
                  controller: toolsController,
                  hintText: 'e.g. Adjustable wrench\nFlashlight',
                  helperText: 'One tool per line',
                  maxLines: 4,
                ),
              ],
            ),

            // ── Special Instructions ───────────────────────────────────────
            AuroraFormSection(
              title: 'Special Instructions',
              isOptional: true,
              children: [
                AuroraTextField(
                  label: 'Instructions',
                  controller: instructionsController,
                  hintText: 'Any notes for yourself or emergency responders',
                  maxLines: 4,
                ),
              ],
            ),

            const SizedBox(height: AuroraSpacing.space10),

            // ── Save CTA ───────────────────────────────────────────────────
            SaveButton(
              label: 'Save Shutoff Info',
              onPressed: saving ? null : onSave,
              loading: saving,
              expand: true,
            ),

            const SizedBox(height: AuroraSpacing.space10),
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

// ── Status pill ───────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isComplete});
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isComplete ? AuroraColors.limeDim : AuroraColors.coralDim,
        borderRadius: AuroraRadius.full,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isComplete ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 13,
            color: isComplete ? AuroraColors.limeDeep : AuroraColors.coral,
          ),
          const SizedBox(width: 5),
          Text(
            isComplete ? 'COMPLETE' : 'INCOMPLETE',
            style: AuroraType.labelSm.copyWith(
              color: isComplete ? AuroraColors.limeDeep : AuroraColors.coral,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info banner ───────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.utilityType});
  final String utilityType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AuroraSpacing.space5),
      decoration: BoxDecoration(
        color: AuroraColors.cobaltDim,
        borderRadius: AuroraRadius.md,
        border: Border.all(color: AuroraColors.cobalt.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: AuroraColors.cobalt),
          const SizedBox(width: AuroraSpacing.space3),
          Expanded(
            child: Text(
              _tip,
              style: AuroraType.bodySm.copyWith(color: AuroraColors.cobaltDeep),
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
        _ =>
          'Keep this information updated so you are prepared in an emergency.',
      };
}

// ── Enum picker field ─────────────────────────────────────────────────────────

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
  final BuildContext context;

  String get _displayLabel => value == null
      ? 'Select...'
      : options
          .firstWhere((o) => o.value == value,
              orElse: () => (value: value!, label: value!))
          .label;

  @override
  Widget build(BuildContext outerContext) {
    if (isIOS) {
      return AuroraSelectField(
        label: label,
        value: value != null ? _displayLabel : null,
        placeholder: 'Select...',
        onTap: () => _showIOSPicker(outerContext),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: AuroraType.label.copyWith(color: AuroraColors.inkSecondary),
        ),
        const SizedBox(height: AuroraSpacing.space1),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: options
              .map(
                (o) => DropdownMenuItem(
                  value: o.value,
                  child: Text(o.label, style: AuroraType.body),
                ),
              )
              .toList(),
          onChanged: onChanged,
          style: AuroraType.body,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AuroraSpacing.space7,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: AuroraRadius.md,
              borderSide: const BorderSide(color: AuroraColors.inkBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AuroraRadius.md,
              borderSide:
                  const BorderSide(color: AuroraColors.inkBorder, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AuroraRadius.md,
              borderSide: const BorderSide(color: AuroraColors.coral, width: 2),
            ),
            filled: true,
            fillColor: AuroraColors.paper,
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
