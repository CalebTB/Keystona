import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/theme/aurora_spacing.dart';

import '../../../core/widgets/snackbar_service.dart';
import '../../emergency/models/emergency_contact.dart';
import '../../emergency/providers/emergency_hub_provider.dart';
import '../models/project_contractor.dart';
import '../providers/project_contractors_provider.dart';
import '../../../core/widgets/aurora/aurora_sheet.dart';

/// Shows a form sheet to link an existing contact or create a new contractor.
Future<void> showContractorFormSheet({
  required BuildContext context,
  required String projectId,
  required WidgetRef ref,
  ProjectContractor? existingContractor,
}) async {
  final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

  if (isIOS) {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Material(
        type: MaterialType.transparency,
        child: _ContractorFormSheet(
          projectId: projectId,
          existingContractor: existingContractor,
          ref: ref,
        ),
      ),
    );
  } else {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ContractorFormSheet(
        projectId: projectId,
        existingContractor: existingContractor,
        ref: ref,
      ),
    );
  }
}

class _ContractorFormSheet extends StatefulWidget {
  const _ContractorFormSheet({
    required this.projectId,
    this.existingContractor,
    required this.ref,
  });

  final String projectId;
  final ProjectContractor? existingContractor;
  final WidgetRef ref;

  @override
  State<_ContractorFormSheet> createState() => _ContractorFormSheetState();
}

class _ContractorFormSheetState extends State<_ContractorFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _contractAmountCtrl = TextEditingController();
  final _amountPaidCtrl = TextEditingController();
  final _reviewCtrl = TextEditingController();

  String? _role;
  int? _rating;
  bool _saving = false;
  bool _isCreatingNew = false;

  // Link existing state.
  List<EmergencyContact> _availableContacts = [];
  bool _loadingContacts = false;
  EmergencyContact? _selectedContact;

  bool get _isEditing => widget.existingContractor != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existingContractor;
    if (c != null) {
      _nameCtrl.text = c.contactName;
      _role = c.role;
      _contractAmountCtrl.text =
          c.contractAmount != null ? c.contractAmount!.toStringAsFixed(2) : '';
      _amountPaidCtrl.text =
          c.amountPaid != null ? c.amountPaid!.toStringAsFixed(2) : '';
      _rating = c.rating;
      _reviewCtrl.text = c.reviewNotes ?? '';
    } else {
      _loadContacts();
    }
  }

  Future<void> _loadContacts() async {
    setState(() => _loadingContacts = true);
    try {
      final contacts = await widget.ref
          .read(emergencyHubProvider.notifier)
          .getContactsForPicker();
      if (mounted) {
        setState(() {
          _availableContacts = contacts;
          _loadingContacts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingContacts = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _contractAmountCtrl.dispose();
    _amountPaidCtrl.dispose();
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickRoleIOS() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Role'),
        actions: ContractorRoles.all
            .map((r) => CupertinoActionSheetAction(
                  onPressed: () {
                    setState(() => _role = r);
                    Navigator.of(ctx, rootNavigator: true).pop();
                  },
                  child: Text(
                    ContractorRoles.labelFor(r),
                    style: AuroraType.body.copyWith(
                      color: _role == r
                          ? AuroraColors.yellow
                          : AuroraColors.ink,
                      fontWeight: _role == r
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final notifier = widget.ref
        .read(projectContractorsProvider(widget.projectId).notifier);

    try {
      final linkData = <String, dynamic>{
        if (_role != null) 'role': _role,
        if (_contractAmountCtrl.text.trim().isNotEmpty)
          'contract_amount':
              double.tryParse(_contractAmountCtrl.text.trim()) ?? 0,
        if (_amountPaidCtrl.text.trim().isNotEmpty)
          'amount_paid': double.tryParse(_amountPaidCtrl.text.trim()) ?? 0,
        if (_rating != null) 'rating': _rating,
        if (_reviewCtrl.text.trim().isNotEmpty)
          'review_notes': _reviewCtrl.text.trim(),
      };

      if (_isEditing) {
        await notifier.updateContractor(
            widget.existingContractor!.id, linkData);
      } else if (_isCreatingNew) {
        final contactData = <String, dynamic>{
          'name': _nameCtrl.text.trim(),
          'category': 'other',
          if (_phoneCtrl.text.trim().isNotEmpty)
            'phone_primary': _phoneCtrl.text.trim(),
        };
        await notifier.createAndLink(contactData, linkData);
      } else if (_selectedContact != null) {
        await notifier.linkContact(_selectedContact!.id, linkData);
      } else {
        setState(() => _saving = false);
        return;
      }

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      SnackbarService.showSuccess(
        context,
        _isEditing ? 'Contractor updated.' : 'Contractor added.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarService.showError(context, 'Could not save. Please try again.');
    }
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            AuroraType.body.copyWith(color: AuroraColors.inkTertiary),
        border: OutlineInputBorder(
          borderRadius: AuroraRadius.md,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AuroraSpacing.space7,
          vertical: AuroraSpacing.space3,
        ),
        isDense: true,
      );

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomPad),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AuroraSheet.topRadius(context),
          ),
          padding: EdgeInsets.all(AuroraSpacing.screenPadH),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle.
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AuroraSpacing.space7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0DFEA),
                      borderRadius:
                          BorderRadius.circular(999.0),
                    ),
                  ),
                ),

                Text(
                  _isEditing ? 'Edit Contractor' : 'Add Contractor',
                  style: AuroraType.h3,
                ),
                const SizedBox(height: AuroraSpacing.space7),

                // Mode toggle (only when adding new).
                if (!_isEditing) ...[
                  Row(
                    children: [
                      _ModeChip(
                        label: 'Link existing',
                        selected: !_isCreatingNew,
                        onTap: () => setState(() {
                          _isCreatingNew = false;
                          _selectedContact = null;
                        }),
                      ),
                      const SizedBox(width: AuroraSpacing.space3),
                      _ModeChip(
                        label: 'Create new',
                        selected: _isCreatingNew,
                        onTap: () =>
                            setState(() => _isCreatingNew = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: AuroraSpacing.space7),
                ],

                // ── Link existing flow ──────────────────────────────────────
                if (!_isCreatingNew && !_isEditing) ...[
                  if (_selectedContact == null) ...[
                    // Contact picker list.
                    if (_loadingContacts)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: AuroraSpacing.space9),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (_availableContacts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(AuroraSpacing.space7),
                        decoration: BoxDecoration(
                          color: AuroraColors.ink.withValues(alpha: 0.05),
                          borderRadius:
                              BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          'No contacts yet. Go to Emergency Hub → Contacts to add some, or switch to "Create new".',
                          style: AuroraType.bodySm
                              .copyWith(color: AuroraColors.inkSecondary),
                        ),
                      )
                    else ...[
                      Text(
                        'Select a contact',
                        style: AuroraType.bodySm
                            .copyWith(color: AuroraColors.inkSecondary),
                      ),
                      const SizedBox(height: AuroraSpacing.space3),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _availableContacts.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final contact = _availableContacts[i];
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: AuroraSpacing.space1),
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  AuroraColors.ink.withValues(alpha: 0.1),
                              child: Text(
                                contact.name.isNotEmpty
                                    ? contact.name[0].toUpperCase()
                                    : '?',
                                style: AuroraType.label.copyWith(
                                    color: AuroraColors.ink),
                              ),
                            ),
                            title: Text(contact.name,
                                style: AuroraType.body),
                            subtitle: Text(
                              [
                                contact.category.categoryLabel,
                                if (contact.phonePrimary.isNotEmpty)
                                  contact.phonePrimary,
                              ].join(' · '),
                              style: AuroraType.bodySm
                                  .copyWith(color: AuroraColors.inkSecondary),
                            ),
                            trailing: const Icon(Icons.chevron_right,
                                size: 18, color: AuroraColors.inkTertiary),
                            onTap: () =>
                                setState(() => _selectedContact = contact),
                          );
                        },
                      ),
                    ],
                  ] else ...[
                    // Selected contact header + optional join-table fields.
                    GestureDetector(
                      onTap: () =>
                          setState(() => _selectedContact = null),
                      child: Container(
                        padding: const EdgeInsets.all(AuroraSpacing.space3),
                        decoration: BoxDecoration(
                          color: AuroraColors.ink.withValues(alpha: 0.06),
                          borderRadius:
                              BorderRadius.circular(8.0),
                          border: Border.all(
                              color:
                                  AuroraColors.ink.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  AuroraColors.ink.withValues(alpha: 0.15),
                              child: Text(
                                _selectedContact!.name.isNotEmpty
                                    ? _selectedContact!.name[0]
                                        .toUpperCase()
                                    : '?',
                                style: AuroraType.label.copyWith(
                                    color: AuroraColors.ink),
                              ),
                            ),
                            const SizedBox(width: AuroraSpacing.space3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_selectedContact!.name,
                                      style: AuroraType.body.copyWith(
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                    _selectedContact!.category.categoryLabel,
                                    style: AuroraType.bodySm.copyWith(
                                        color: AuroraColors.inkSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Change',
                              style: AuroraType.bodySm.copyWith(
                                  color: AuroraColors.ink),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AuroraSpacing.space7),
                    _buildJoinFields(),
                    const SizedBox(height: AuroraSpacing.space7),
                    _buildSaveButton(),
                    const SizedBox(height: AuroraSpacing.space9),
                  ],
                ],

                // ── Create new flow ─────────────────────────────────────────
                if (_isCreatingNew) ...[
                  _Label('Name'),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: _dec('Full name'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: AuroraSpacing.space3),
                  _Label('Phone (optional)'),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _dec('Phone number'),
                  ),
                  const SizedBox(height: AuroraSpacing.space3),
                  _buildJoinFields(),
                  const SizedBox(height: AuroraSpacing.space7),
                  _buildSaveButton(),
                  const SizedBox(height: AuroraSpacing.space9),
                ],

                // ── Edit flow ───────────────────────────────────────────────
                if (_isEditing) ...[
                  _Label('Name'),
                  TextFormField(
                    controller: _nameCtrl,
                    readOnly: true,
                    decoration: _dec('Full name'),
                  ),
                  const SizedBox(height: AuroraSpacing.space3),
                  _buildJoinFields(),
                  const SizedBox(height: AuroraSpacing.space7),
                  _buildSaveButton(),
                  const SizedBox(height: AuroraSpacing.space9),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Role, amounts, rating, notes — shared across create/edit/link flows.
  Widget _buildJoinFields() {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Label('Role (optional)'),
        if (isIOS)
          GestureDetector(
            onTap: _pickRoleIOS,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AuroraSpacing.space7,
                vertical: AuroraSpacing.space3,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AuroraColors.inkBorder),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _role != null
                          ? ContractorRoles.labelFor(_role!)
                          : 'Select role',
                      style: _role != null
                          ? AuroraType.body
                          : AuroraType.body
                              .copyWith(color: AuroraColors.inkTertiary),
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 20, color: AuroraColors.inkTertiary),
                ],
              ),
            ),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: _dec('Select role'),
            onChanged: (v) => setState(() => _role = v),
            items: [
              const DropdownMenuItem(value: null, child: Text('None')),
              ...ContractorRoles.all.map((r) =>
                  DropdownMenuItem(value: r, child: Text(ContractorRoles.labelFor(r)))),
            ],
          ),
        const SizedBox(height: AuroraSpacing.space3),
        _Label('Contract amount (optional)'),
        TextFormField(
          controller: _contractAmountCtrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: _dec('0.00'),
        ),
        const SizedBox(height: AuroraSpacing.space3),
        _Label('Amount paid (optional)'),
        TextFormField(
          controller: _amountPaidCtrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: _dec('0.00'),
        ),
        const SizedBox(height: AuroraSpacing.space3),
        _Label('Rating (optional)'),
        _StarRatingRow(
          rating: _rating,
          onChanged: (r) => setState(() => _rating = r),
        ),
        const SizedBox(height: AuroraSpacing.space3),
        _Label('Review notes (optional)'),
        TextFormField(
          controller: _reviewCtrl,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: _dec('Quality of work, communication…'),
        ),
      ],
    );
  }

  Widget _buildSaveButton() => SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: AuroraColors.coral,
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(_isEditing ? 'Save Changes' : 'Add'),
        ),
      );
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AuroraSpacing.space1),
        child: Text(text,
            style: AuroraType.bodySm
                .copyWith(color: AuroraColors.inkSecondary)),
      );
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AuroraSpacing.space3 + 4, vertical: AuroraSpacing.space1 + 2),
        decoration: BoxDecoration(
          color: selected ? AuroraColors.ink : AuroraColors.paper,
          borderRadius: BorderRadius.circular(999.0),
          border: Border.all(
            color: selected ? AuroraColors.ink : AuroraColors.inkBorder,
          ),
        ),
        child: Text(
          label,
          style: AuroraType.label.copyWith(
            color:
                selected ? Colors.white : AuroraColors.ink,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _StarRatingRow extends StatelessWidget {
  const _StarRatingRow({required this.rating, required this.onChanged});

  final int? rating;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(
          5,
          (i) => GestureDetector(
            onTap: () => onChanged(rating == i + 1 ? null : i + 1),
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                (rating != null && i < rating!)
                    ? Icons.star
                    : Icons.star_border,
                color: AuroraColors.yellow,
                size: 28,
              ),
            ),
          ),
        ),
        if (rating != null) ...[
          const SizedBox(width: AuroraSpacing.space1),
          Text('$rating/5', style: AuroraType.bodySm),
        ],
      ],
    );
  }
}
