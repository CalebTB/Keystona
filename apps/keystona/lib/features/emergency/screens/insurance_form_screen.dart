import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/aurora/aurora.dart';
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
      all
          .firstWhere((p) => p.value == value,
              orElse: () => (value: value, label: value))
          .label;
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
                      ? Icon(Icons.check, color: AuroraColors.cobalt)
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

  Future<void> _pickDate(BuildContext context,
      {required bool isEffective}) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final initial =
        (isEffective ? _effectiveDate : _expirationDate) ?? DateTime.now();

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
        backgroundColor: AuroraColors.paper,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: AuroraColors.paper,
          middle: Text(title),
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
            onPickExpirationDate: () =>
                _pickDate(context, isEffective: false),
            linkedDocumentName: _linkedDocumentName,
            onPickDocument: () => _pickDocument(context),
            onClearDocument: () => setState(() {
              _linkedDocumentId = null;
              _linkedDocumentName = null;
            }),
            isEditing: _isEditing,
            saving: _saving,
            deleting: _deleting,
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
        saving: _saving,
        deleting: _deleting,
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
    required this.saving,
    required this.deleting,
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
  final bool saving;
  final bool deleting;
  final VoidCallback? onDelete;
  final VoidCallback? onSave;

  String _formatDate(DateTime dt) => DateFormat('MM/dd/yyyy').format(dt);

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AuroraSpacing.screenPadH,
          vertical: AuroraSpacing.screenPadTop,
        ),
        children: [
          // ── Policy Info ────────────────────────────────────────────────────
          AuroraFormSection(
            title: 'Policy Info',
            children: [
              AuroraSelectField(
                label: 'Policy Type',
                value: PolicyTypes.labelFor(policyType),
                onTap: onPickPolicyType,
              ),
              AuroraTextField(
                label: 'Insurance Company',
                required: true,
                controller: carrierController,
                hintText: 'e.g. State Farm',
                keyboardType: TextInputType.text,
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Carrier is required'
                        : null,
              ),
              AuroraTextField(
                label: 'Policy Number',
                controller: policyNumberController,
                hintText: 'e.g. HO-123456789',
              ),
            ],
          ),

          // ── Coverage & Costs ───────────────────────────────────────────────
          AuroraFormSection(
            title: 'Coverage & Costs',
            isOptional: true,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AuroraTextField(
                      label: 'Coverage (\$)',
                      controller: coverageController,
                      hintText: '300000',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: AuroraSpacing.space3),
                  Expanded(
                    child: AuroraTextField(
                      label: 'Deductible (\$)',
                      controller: deductibleController,
                      hintText: '1000',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              AuroraTextField(
                label: 'Annual Premium (\$)',
                controller: premiumController,
                hintText: '2400',
                keyboardType: TextInputType.number,
              ),
            ],
          ),

          // ── Policy Dates ───────────────────────────────────────────────────
          AuroraFormSection(
            title: 'Policy Dates',
            isOptional: true,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AuroraSelectField(
                      label: 'Effective Date',
                      value: effectiveDate != null
                          ? _formatDate(effectiveDate!)
                          : null,
                      placeholder: 'Select date',
                      onTap: onPickEffectiveDate,
                    ),
                  ),
                  const SizedBox(width: AuroraSpacing.space3),
                  Expanded(
                    child: AuroraSelectField(
                      label: 'Expiration Date',
                      value: expirationDate != null
                          ? _formatDate(expirationDate!)
                          : null,
                      placeholder: 'Select date',
                      onTap: onPickExpirationDate,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Claims Contact ─────────────────────────────────────────────────
          AuroraFormSection(
            title: 'Claims Contact',
            isOptional: true,
            children: [
              AuroraTextField(
                label: 'Claims Phone',
                controller: claimsPhoneController,
                hintText: 'e.g. 1-800-555-0100',
                keyboardType: TextInputType.phone,
              ),
            ],
          ),

          // ── Agent ──────────────────────────────────────────────────────────
          AuroraFormSection(
            title: 'Agent',
            isOptional: true,
            children: [
              AuroraTextField(
                label: 'Agent Name',
                controller: agentNameController,
                hintText: 'Agent name',
                keyboardType: TextInputType.name,
              ),
              Row(
                children: [
                  Expanded(
                    child: AuroraTextField(
                      label: 'Agent Phone',
                      controller: agentPhoneController,
                      hintText: 'Phone',
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: AuroraSpacing.space3),
                  Expanded(
                    child: AuroraTextField(
                      label: 'Agent Email',
                      controller: agentEmailController,
                      hintText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Policy Document ────────────────────────────────────────────────
          AuroraFormSection(
            title: 'Policy Document',
            isOptional: true,
            children: [
              if (linkedDocumentName != null)
                _LinkedDocumentRow(
                    name: linkedDocumentName!, onClear: onClearDocument)
              else
                AuroraSelectField(
                  label: 'Linked Document',
                  placeholder: 'Link PDF from Document Vault',
                  value: null,
                  onTap: onPickDocument,
                  suffix: const Icon(
                    Icons.attach_file_outlined,
                    size: 18,
                    color: AuroraColors.inkTertiary,
                  ),
                ),
            ],
          ),

          const SizedBox(height: AuroraSpacing.space10),

          // ── Save CTA ───────────────────────────────────────────────────────
          SaveButton(
            label: isEditing ? 'Save Changes' : 'Add Policy',
            onPressed: onSave,
            loading: saving,
            expand: true,
          ),

          if (isEditing) ...[
            const SizedBox(height: AuroraSpacing.space3),
            GhostButton(
              label: deleting ? 'Deleting…' : 'Delete Policy',
              onPressed: onDelete,
            ),
          ],

          const SizedBox(height: AuroraSpacing.space10),
        ],
      ),
    );
  }
}

// ── Linked document row ───────────────────────────────────────────────────────

class _LinkedDocumentRow extends StatelessWidget {
  const _LinkedDocumentRow({required this.name, required this.onClear});

  final String name;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AuroraSpacing.space7),
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.md,
        border: Border.all(color: AuroraColors.inkBorder, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.picture_as_pdf_outlined,
            size: 20,
            color: AuroraColors.cobalt,
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
              size: 20,
              color: AuroraColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
