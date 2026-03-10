import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../emergency/models/emergency_contact.dart';
import '../../emergency/providers/emergency_hub_provider.dart';
import '../models/project_contractor.dart';
import '../providers/project_contractors_provider.dart';

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
                    style: TextStyle(
                      color: _role == r
                          ? AppColors.goldAccent
                          : AppColors.textPrimary,
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
            AppTextStyles.bodyMedium.copyWith(color: AppColors.gray400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: AppPadding.screen,
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
                    margin: const EdgeInsets.only(bottom: AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.gray300,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                    ),
                  ),
                ),

                Text(
                  _isEditing ? 'Edit Contractor' : 'Add Contractor',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: AppSizes.md),

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
                      const SizedBox(width: AppSizes.sm),
                      _ModeChip(
                        label: 'Create new',
                        selected: _isCreatingNew,
                        onTap: () =>
                            setState(() => _isCreatingNew = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                ],

                // ── Link existing flow ──────────────────────────────────────
                if (!_isCreatingNew && !_isEditing) ...[
                  if (_selectedContact == null) ...[
                    // Contact picker list.
                    if (_loadingContacts)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSizes.lg),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_availableContacts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppSizes.md),
                        decoration: BoxDecoration(
                          color: AppColors.deepNavy.withValues(alpha: 0.05),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: Text(
                          'No contacts yet. Go to Emergency Hub → Contacts to add some, or switch to "Create new".',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      )
                    else ...[
                      Text(
                        'Select a contact',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSizes.sm),
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
                                horizontal: AppSizes.xs),
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  AppColors.deepNavy.withValues(alpha: 0.1),
                              child: Text(
                                contact.name.isNotEmpty
                                    ? contact.name[0].toUpperCase()
                                    : '?',
                                style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.deepNavy),
                              ),
                            ),
                            title: Text(contact.name,
                                style: AppTextStyles.bodyMedium),
                            subtitle: Text(
                              [
                                contact.category.categoryLabel,
                                if (contact.phonePrimary.isNotEmpty)
                                  contact.phonePrimary,
                              ].join(' · '),
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                            trailing: const Icon(Icons.chevron_right,
                                size: 18, color: AppColors.gray400),
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
                        padding: const EdgeInsets.all(AppSizes.sm),
                        decoration: BoxDecoration(
                          color: AppColors.deepNavy.withValues(alpha: 0.06),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                          border: Border.all(
                              color:
                                  AppColors.deepNavy.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  AppColors.deepNavy.withValues(alpha: 0.15),
                              child: Text(
                                _selectedContact!.name.isNotEmpty
                                    ? _selectedContact!.name[0]
                                        .toUpperCase()
                                    : '?',
                                style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.deepNavy),
                              ),
                            ),
                            const SizedBox(width: AppSizes.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_selectedContact!.name,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                    _selectedContact!.category.categoryLabel,
                                    style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Change',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.deepNavy),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    _buildJoinFields(),
                    const SizedBox(height: AppSizes.md),
                    _buildSaveButton(),
                    const SizedBox(height: AppSizes.lg),
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
                  const SizedBox(height: AppSizes.sm),
                  _Label('Phone (optional)'),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _dec('Phone number'),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  _buildJoinFields(),
                  const SizedBox(height: AppSizes.md),
                  _buildSaveButton(),
                  const SizedBox(height: AppSizes.lg),
                ],

                // ── Edit flow ───────────────────────────────────────────────
                if (_isEditing) ...[
                  _Label('Name'),
                  TextFormField(
                    controller: _nameCtrl,
                    readOnly: true,
                    decoration: _dec('Full name'),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  _buildJoinFields(),
                  const SizedBox(height: AppSizes.md),
                  _buildSaveButton(),
                  const SizedBox(height: AppSizes.lg),
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
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _role != null
                          ? ContractorRoles.labelFor(_role!)
                          : 'Select role',
                      style: _role != null
                          ? AppTextStyles.bodyMedium
                          : AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.gray400),
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 20, color: AppColors.gray400),
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
        const SizedBox(height: AppSizes.sm),
        _Label('Contract amount (optional)'),
        TextFormField(
          controller: _contractAmountCtrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: _dec('0.00'),
        ),
        const SizedBox(height: AppSizes.sm),
        _Label('Amount paid (optional)'),
        TextFormField(
          controller: _amountPaidCtrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: _dec('0.00'),
        ),
        const SizedBox(height: AppSizes.sm),
        _Label('Rating (optional)'),
        _StarRatingRow(
          rating: _rating,
          onChanged: (r) => setState(() => _rating = r),
        ),
        const SizedBox(height: AppSizes.sm),
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
            backgroundColor: AppColors.deepNavy,
            padding: AppPadding.button,
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
        padding: const EdgeInsets.only(bottom: AppSizes.xs),
        child: Text(text,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary)),
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
            horizontal: AppSizes.sm + 4, vertical: AppSizes.xs + 2),
        decoration: BoxDecoration(
          color: selected ? AppColors.deepNavy : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: selected ? AppColors.deepNavy : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color:
                selected ? AppColors.textInverse : AppColors.textPrimary,
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
                color: AppColors.goldAccent,
                size: 28,
              ),
            ),
          ),
        ),
        if (rating != null) ...[
          const SizedBox(width: AppSizes.xs),
          Text('$rating/5', style: AppTextStyles.bodySmall),
        ],
      ],
    );
  }
}
