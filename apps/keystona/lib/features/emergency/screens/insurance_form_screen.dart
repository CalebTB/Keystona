import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../models/insurance_policy.dart';
import '../providers/emergency_hub_provider.dart';
import '../widgets/document_link_picker.dart';

// ── Policy type catalog ───────────────────────────────────────────────────────

abstract final class PolicyTypes {
  static const all = [
    (value: 'homeowners', label: 'Homeowners'),
    (value: 'flood', label: 'Flood'),
    (value: 'earthquake', label: 'Earthquake'),
    (value: 'umbrella', label: 'Umbrella'),
    (value: 'home_warranty', label: 'Home Warranty'),
  ];

  static String labelFor(String value) =>
      all.firstWhere((p) => p.value == value, orElse: () => (value: value, label: value)).label;
}

// ── Main screen ───────────────────────────────────────────────────────────────

class InsuranceFormScreen extends ConsumerStatefulWidget {
  const InsuranceFormScreen({super.key, this.existingPolicy});

  final InsurancePolicy? existingPolicy;

  @override
  ConsumerState<InsuranceFormScreen> createState() =>
      _InsuranceFormScreenState();
}

class _InsuranceFormScreenState extends ConsumerState<InsuranceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _carrierController;
  late final TextEditingController _policyNumberController;
  late final TextEditingController _coverageController;
  late final TextEditingController _deductibleController;
  late final TextEditingController _premiumController;
  late final TextEditingController _agentNameController;
  late final TextEditingController _agentPhoneController;
  late final TextEditingController _agentEmailController;
  late final TextEditingController _claimsPhoneController;

  late String _policyType;
  DateTime? _effectiveDate;
  DateTime? _expirationDate;
  String? _linkedDocumentId;
  String? _linkedDocumentName;

  bool _saving = false;
  bool _deleting = false;

  bool get _isEditing => widget.existingPolicy != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existingPolicy;
    _policyType = p?.policyType ?? 'homeowners';
    _effectiveDate = p?.effectiveDate;
    _expirationDate = p?.expirationDate;
    _linkedDocumentId = p?.linkedDocumentId;

    _carrierController = TextEditingController(text: p?.carrier ?? '');
    _policyNumberController =
        TextEditingController(text: p?.policyNumber ?? '');
    _coverageController = TextEditingController(
      text: p?.coverageAmount != null ? _formatAmount(p!.coverageAmount!) : '',
    );
    _deductibleController = TextEditingController(
      text: p?.deductible != null ? _formatAmount(p!.deductible!) : '',
    );
    _premiumController = TextEditingController(
      text: p?.premiumAnnual != null ? _formatAmount(p!.premiumAnnual!) : '',
    );
    _agentNameController = TextEditingController(text: p?.agentName ?? '');
    _agentPhoneController = TextEditingController(text: p?.agentPhone ?? '');
    _agentEmailController = TextEditingController(text: p?.agentEmail ?? '');
    _claimsPhoneController = TextEditingController(text: p?.claimsPhone ?? '');
  }

  @override
  void dispose() {
    _carrierController.dispose();
    _policyNumberController.dispose();
    _coverageController.dispose();
    _deductibleController.dispose();
    _premiumController.dispose();
    _agentNameController.dispose();
    _agentPhoneController.dispose();
    _agentEmailController.dispose();
    _claimsPhoneController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) => amount.toInt().toString();

  double? _parseCurrency(String raw) {
    final cleaned = raw.replaceAll('\$', '').replaceAll(',', '').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  String _toDateColumn(DateTime dt) => dt.toIso8601String().split('T')[0];

  // ── Policy type picker ────────────────────────────────────────────────────

  Future<void> _pickPolicyType(BuildContext context) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: const Text('Policy Type'),
          actions: PolicyTypes.all
              .map(
                (opt) => CupertinoActionSheetAction(
                  onPressed: () {
                    setState(() => _policyType = opt.value);
                    Navigator.of(ctx, rootNavigator: true).pop();
                  },
                  child: Text(opt.label),
                ),
              )
              .toList(),
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
            child: const Text('Cancel'),
          ),
        ),
      );
    } else {
      await showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AuroraSpacing.space7),
                child: Text('Policy Type', style: AuroraType.h3),
              ),
              const Divider(height: 1),
              ...PolicyTypes.all.map(
                (opt) => ListTile(
                  title: Text(opt.label),
                  trailing: _policyType == opt.value
                      ? Icon(Icons.check, color: AuroraColors.ink)
                      : null,
                  onTap: () {
                    setState(() => _policyType = opt.value);
                    Navigator.of(ctx).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // ── Date pickers ──────────────────────────────────────────────────────────

  Future<void> _pickDate(BuildContext context, {required bool isEffective}) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final initial = (isEffective ? _effectiveDate : _expirationDate) ?? DateTime.now();

    if (isIOS) {
      DateTime picked = initial;
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (ctx) => Material(
          type: MaterialType.transparency,
          child: Container(
            height: 300,
            color: AuroraColors.paper,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () =>
                          Navigator.of(ctx, rootNavigator: true).pop(),
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () {
                        setState(() {
                          if (isEffective) {
                            _effectiveDate = picked;
                          } else {
                            _expirationDate = picked;
                          }
                        });
                        Navigator.of(ctx, rootNavigator: true).pop();
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initial,
                    onDateTimeChanged: (dt) => picked = dt,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      final result = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (!mounted) return;
      if (result != null) {
        setState(() {
          if (isEffective) {
            _effectiveDate = result;
          } else {
            _expirationDate = result;
          }
        });
      }
    }
  }

  // ── Document link picker ──────────────────────────────────────────────────

  Future<void> _pickDocument(BuildContext context) async {
    final result = await showDocumentLinkPicker(context);
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _linkedDocumentId = result.id;
        _linkedDocumentName = result.name;
      });
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = <String, dynamic>{
      'policy_type': _policyType,
      'carrier': _carrierController.text.trim(),
      if (_policyNumberController.text.trim().isNotEmpty)
        'policy_number': _policyNumberController.text.trim(),
      if (_parseCurrency(_coverageController.text) != null)
        'coverage_amount': _parseCurrency(_coverageController.text),
      if (_parseCurrency(_deductibleController.text) != null)
        'deductible': _parseCurrency(_deductibleController.text),
      if (_parseCurrency(_premiumController.text) != null)
        'premium_annual': _parseCurrency(_premiumController.text),
      if (_agentNameController.text.trim().isNotEmpty)
        'agent_name': _agentNameController.text.trim(),
      if (_agentPhoneController.text.trim().isNotEmpty)
        'agent_phone': _agentPhoneController.text.trim(),
      if (_agentEmailController.text.trim().isNotEmpty)
        'agent_email': _agentEmailController.text.trim(),
      if (_claimsPhoneController.text.trim().isNotEmpty)
        'claims_phone': _claimsPhoneController.text.trim(),
      if (_effectiveDate != null)
        'effective_date': _toDateColumn(_effectiveDate!),
      if (_expirationDate != null)
        'expiration_date': _toDateColumn(_expirationDate!),
      if (_linkedDocumentId != null) 'linked_document_id': _linkedDocumentId,
    };

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final successMsg = _isEditing ? 'Policy updated.' : 'Policy added.';

    try {
      final notifier = ref.read(emergencyHubProvider.notifier);
      if (_isEditing) {
        await notifier.updateInsurance(widget.existingPolicy!.id, data);
      } else {
        await notifier.addInsurance(data);
      }
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(successMsg),
            backgroundColor: AuroraColors.limeDeep,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      router.pop();
    } catch (_) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("Couldn't save the policy. Please try again."),
            backgroundColor: AuroraColors.coral,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _delete(BuildContext context) async {
    await ConfirmDialog.show(
      context,
      title: 'Delete Policy',
      message:
          'This will permanently remove this insurance policy. This cannot be undone.',
      confirmLabel: 'Delete',
      onConfirm: () => _confirmDelete(context),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    setState(() => _deleting = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final notifier = ref.read(emergencyHubProvider.notifier);
      await notifier.deleteInsurance(widget.existingPolicy!.id);
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Policy deleted.'),
            backgroundColor: AuroraColors.limeDeep,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      router.pop();
      router.pop();
    } catch (_) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("Couldn't delete the policy. Please try again."),
            backgroundColor: AuroraColors.coral,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final title = _isEditing ? 'Edit Policy' : 'Add Policy';

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(title),
          trailing: _saving
              ? const CupertinoActivityIndicator()
              : CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _save(context),
                  child: const Text('Save'),
                ),
        ),
        child: SafeArea(
          child: _FormBody(
            formKey: _formKey,
            policyType: _policyType,
            onPickPolicyType: () => _pickPolicyType(context),
            carrierController: _carrierController,
            policyNumberController: _policyNumberController,
            coverageController: _coverageController,
            deductibleController: _deductibleController,
            premiumController: _premiumController,
            agentNameController: _agentNameController,
            agentPhoneController: _agentPhoneController,
            agentEmailController: _agentEmailController,
            claimsPhoneController: _claimsPhoneController,
            effectiveDate: _effectiveDate,
            expirationDate: _expirationDate,
            onPickEffectiveDate: () => _pickDate(context, isEffective: true),
            onPickExpirationDate: () => _pickDate(context, isEffective: false),
            linkedDocumentName: _linkedDocumentName,
            onPickDocument: () => _pickDocument(context),
            onClearDocument: () => setState(() {
              _linkedDocumentId = null;
              _linkedDocumentName = null;
            }),
            isEditing: _isEditing,
            onDelete: _deleting ? null : () => _delete(context),
            onSave: _saving ? null : () => _save(context),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AuroraColors.paper,
      appBar: AppBar(
        backgroundColor: AuroraColors.paper,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(title, style: AuroraType.h3),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: AuroraSpacing.space7),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: () => _save(context),
              child: Text(
                'Save',
                style: AuroraType.bodyLg.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AuroraColors.ink,
                ),
              ),
            ),
        ],
      ),
      body: _FormBody(
        formKey: _formKey,
        policyType: _policyType,
        onPickPolicyType: () => _pickPolicyType(context),
        carrierController: _carrierController,
        policyNumberController: _policyNumberController,
        coverageController: _coverageController,
        deductibleController: _deductibleController,
        premiumController: _premiumController,
        agentNameController: _agentNameController,
        agentPhoneController: _agentPhoneController,
        agentEmailController: _agentEmailController,
        claimsPhoneController: _claimsPhoneController,
        effectiveDate: _effectiveDate,
        expirationDate: _expirationDate,
        onPickEffectiveDate: () => _pickDate(context, isEffective: true),
        onPickExpirationDate: () => _pickDate(context, isEffective: false),
        linkedDocumentName: _linkedDocumentName,
        onPickDocument: () => _pickDocument(context),
        onClearDocument: () => setState(() {
          _linkedDocumentId = null;
          _linkedDocumentName = null;
        }),
        isEditing: _isEditing,
        onDelete: _deleting ? null : () => _delete(context),
        onSave: _saving ? null : () => _save(context),
      ),
    );
  }
}

// ── Shared form body ──────────────────────────────────────────────────────────

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.formKey,
    required this.policyType,
    required this.onPickPolicyType,
    required this.carrierController,
    required this.policyNumberController,
    required this.coverageController,
    required this.deductibleController,
    required this.premiumController,
    required this.agentNameController,
    required this.agentPhoneController,
    required this.agentEmailController,
    required this.claimsPhoneController,
    required this.effectiveDate,
    required this.expirationDate,
    required this.onPickEffectiveDate,
    required this.onPickExpirationDate,
    required this.linkedDocumentName,
    required this.onPickDocument,
    required this.onClearDocument,
    required this.isEditing,
    required this.onDelete,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final String policyType;
  final VoidCallback onPickPolicyType;
  final TextEditingController carrierController;
  final TextEditingController policyNumberController;
  final TextEditingController coverageController;
  final TextEditingController deductibleController;
  final TextEditingController premiumController;
  final TextEditingController agentNameController;
  final TextEditingController agentPhoneController;
  final TextEditingController agentEmailController;
  final TextEditingController claimsPhoneController;
  final DateTime? effectiveDate;
  final DateTime? expirationDate;
  final VoidCallback onPickEffectiveDate;
  final VoidCallback onPickExpirationDate;
  final String? linkedDocumentName;
  final VoidCallback onPickDocument;
  final VoidCallback onClearDocument;
  final bool isEditing;
  final VoidCallback? onDelete;
  final VoidCallback? onSave;

  String _formatDate(DateTime dt) => DateFormat('MM/dd/yyyy').format(dt);

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(AuroraSpacing.screenPadH),
        children: [
          _SectionLabel('Policy Type'),
          const SizedBox(height: AuroraSpacing.space1),
          _TappableField(
            label: PolicyTypes.labelFor(policyType),
            onTap: onPickPolicyType,
          ),
          const SizedBox(height: AuroraSpacing.space7),

          _SectionLabel('Insurance Company *'),
          const SizedBox(height: AuroraSpacing.space1),
          TextFormField(
            controller: carrierController,
            decoration: _inputDecoration('e.g. State Farm'),
            textCapitalization: TextCapitalization.words,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Carrier is required' : null,
          ),
          const SizedBox(height: AuroraSpacing.space7),

          _SectionLabel('Policy Number'),
          const SizedBox(height: AuroraSpacing.space1),
          TextFormField(
            controller: policyNumberController,
            decoration: _inputDecoration('e.g. HO-123456789'),
          ),
          const SizedBox(height: AuroraSpacing.space7),

          _SectionLabel('Coverage & Costs'),
          const SizedBox(height: AuroraSpacing.space1),
          Row(
            children: [
              Flexible(
                child: TextFormField(
                  controller: coverageController,
                  decoration: _inputDecoration('Coverage (\$)'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AuroraSpacing.space3),
              Flexible(
                child: TextFormField(
                  controller: deductibleController,
                  decoration: _inputDecoration('Deductible (\$)'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: AuroraSpacing.space3),
          TextFormField(
            controller: premiumController,
            decoration: _inputDecoration('Annual Premium (\$)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AuroraSpacing.space7),

          _SectionLabel('Policy Dates'),
          const SizedBox(height: AuroraSpacing.space1),
          Row(
            children: [
              Flexible(
                child: _TappableField(
                  label: effectiveDate != null
                      ? _formatDate(effectiveDate!)
                      : 'Effective date',
                  placeholder: effectiveDate == null,
                  onTap: onPickEffectiveDate,
                ),
              ),
              const SizedBox(width: AuroraSpacing.space3),
              Flexible(
                child: _TappableField(
                  label: expirationDate != null
                      ? _formatDate(expirationDate!)
                      : 'Expiration date',
                  placeholder: expirationDate == null,
                  onTap: onPickExpirationDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: AuroraSpacing.space7),

          _SectionLabel('Claims Phone'),
          const SizedBox(height: AuroraSpacing.space1),
          TextFormField(
            controller: claimsPhoneController,
            decoration: _inputDecoration('e.g. 1-800-555-0100'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AuroraSpacing.space7),

          _SectionLabel('Agent'),
          const SizedBox(height: AuroraSpacing.space1),
          TextFormField(
            controller: agentNameController,
            decoration: _inputDecoration('Agent name'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AuroraSpacing.space3),
          Row(
            children: [
              Flexible(
                child: TextFormField(
                  controller: agentPhoneController,
                  decoration: _inputDecoration('Agent phone'),
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: AuroraSpacing.space3),
              Flexible(
                child: TextFormField(
                  controller: agentEmailController,
                  decoration: _inputDecoration('Agent email'),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ],
          ),
          const SizedBox(height: AuroraSpacing.space7),

          _SectionLabel('Policy Document'),
          const SizedBox(height: AuroraSpacing.space1),
          if (linkedDocumentName != null)
            _LinkedDocumentRow(name: linkedDocumentName!, onClear: onClearDocument)
          else
            _TappableField(
              label: 'Link PDF from Document Vault',
              onTap: onPickDocument,
              icon: Icons.attach_file_outlined,
            ),
          const SizedBox(height: AuroraSpacing.space10),

          if (isEditing) ...[
            OutlinedButton(
              onPressed: onDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: AuroraColors.coral,
                side: const BorderSide(color: AuroraColors.coral),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Delete Policy',
                style: AuroraType.bodyLg.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AuroraColors.coral,
                ),
              ),
            ),
            const SizedBox(height: AuroraSpacing.space10),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AuroraType.body.copyWith(color: AuroraColors.inkSecondary),
        filled: true,
        fillColor: AuroraColors.paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AuroraSpacing.space7,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AuroraColors.inkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AuroraColors.inkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AuroraColors.ink, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AuroraColors.coral),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AuroraColors.coral, width: 1.5),
        ),
      );
}

// ── Private helpers ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
      );
}

class _TappableField extends StatelessWidget {
  const _TappableField({
    required this.label,
    required this.onTap,
    this.placeholder = false,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final bool placeholder;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: AuroraSpacing.space7),
        decoration: BoxDecoration(
          color: AuroraColors.paper,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AuroraColors.inkBorder),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 24, color: AuroraColors.inkSecondary),
              const SizedBox(width: AuroraSpacing.space3),
            ],
            Expanded(
              child: Text(
                label,
                style: AuroraType.body.copyWith(
                  color: placeholder
                      ? AuroraColors.inkSecondary
                      : AuroraColors.ink,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 24,
              color: AuroraColors.inkSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkedDocumentRow extends StatelessWidget {
  const _LinkedDocumentRow({required this.name, required this.onClear});

  final String name;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: AuroraSpacing.space7),
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AuroraColors.inkBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.picture_as_pdf_outlined,
            size: 24,
            color: AuroraColors.ink,
          ),
          const SizedBox(width: AuroraSpacing.space3),
          Expanded(
            child: Text(
              name,
              style: AuroraType.body,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: const Icon(
              Icons.close,
              size: 24,
              color: AuroraColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
