import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/aurora/aurora.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/emergency_contact.dart';
import '../providers/contacts_list_provider.dart';

class ContactFormScreen extends ConsumerStatefulWidget {
  const ContactFormScreen({super.key, this.existingContact});

  final EmergencyContact? existingContact;

  @override
  ConsumerState<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends ConsumerState<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _companyController;
  late final TextEditingController _phonePrimaryController;
  late final TextEditingController _phoneSecondaryController;
  late final TextEditingController _emailController;
  late final TextEditingController _availableHoursController;
  late final TextEditingController _notesController;

  late String _category;
  late bool _is24x7;
  late bool _isFavorite;
  bool _saving = false;
  bool _deleting = false;

  bool get _isEditing => widget.existingContact != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existingContact;
    _nameController = TextEditingController(text: c?.name ?? '');
    _companyController = TextEditingController(text: c?.companyName ?? '');
    _phonePrimaryController =
        TextEditingController(text: c?.phonePrimary ?? '');
    _phoneSecondaryController =
        TextEditingController(text: c?.phoneSecondary ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _availableHoursController =
        TextEditingController(text: c?.availableHours ?? '');
    _notesController = TextEditingController(text: c?.notes ?? '');

    _category = c?.category ?? 'plumber';
    _is24x7 = c?.is24x7 ?? false;
    _isFavorite = c?.isFavorite ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _phonePrimaryController.dispose();
    _phoneSecondaryController.dispose();
    _emailController.dispose();
    _availableHoursController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ── Category picker ───────────────────────────────────────────────────────

  Future<void> _pickCategory(BuildContext context) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      await _pickCategoryIOS(context);
    } else {
      await _pickCategoryAndroid(context);
    }
  }

  Future<void> _pickCategoryIOS(BuildContext context) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Material(
        type: MaterialType.transparency,
        child: CupertinoActionSheet(
          title: const Text('Contact Category'),
          actions: ContactCategories.all
              .map(
                (option) => CupertinoActionSheetAction(
                  onPressed: () {
                    setState(() => _category = option.value);
                    Navigator.of(ctx, rootNavigator: true).pop();
                  },
                  isDefaultAction: _category == option.value,
                  child: Text(option.label),
                ),
              )
              .toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
            isDestructiveAction: true,
            child: const Text('Cancel'),
          ),
        ),
      ),
    );
  }

  Future<void> _pickCategoryAndroid(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AuroraSpacing.space7),
              child: Text('Contact Category', style: AuroraType.h3),
            ),
            ...ContactCategories.all.map(
              (option) => ListTile(
                title: Text(option.label),
                trailing: _category == option.value
                    ? Icon(Icons.check, color: AuroraColors.cobalt)
                    : null,
                onTap: () {
                  setState(() => _category = option.value);
                  Navigator.of(ctx).pop();
                },
              ),
            ),
            const SizedBox(height: AuroraSpacing.space3),
          ],
        ),
      ),
    );
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = {
      'name': _nameController.text.trim(),
      'company_name': _companyController.text.trim().isEmpty
          ? null
          : _companyController.text.trim(),
      'category': _category,
      'phone_primary': _phonePrimaryController.text.trim(),
      'phone_secondary': _phoneSecondaryController.text.trim().isEmpty
          ? null
          : _phoneSecondaryController.text.trim(),
      'email': _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      'available_hours': _availableHoursController.text.trim().isEmpty
          ? null
          : _availableHoursController.text.trim(),
      'is_24x7': _is24x7,
      'is_favorite': _isFavorite,
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    };

    final notifier = ref.read(contactsListProvider.notifier);

    try {
      if (_isEditing) {
        await notifier.updateContact(widget.existingContact!.id, data);
      } else {
        await notifier.addContact(data);
      }
      if (!mounted) return;
      context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarService.showError(context, "Couldn't save contact. Try again.");
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _delete() async {
    if (!_isEditing) return;
    final confirmed = await _confirmDelete();
    if (!mounted) return;
    if (confirmed != true) return;

    setState(() => _deleting = true);
    final notifier = ref.read(contactsListProvider.notifier);

    try {
      await notifier.deleteContact(widget.existingContact!.id);
      if (!mounted) return;
      context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      SnackbarService.showError(context, "Couldn't delete contact. Try again.");
    }
  }

  Future<bool?> _confirmDelete() {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      return showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Delete Contact?'),
          content: const Text('This contact will be permanently removed.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Contact?'),
        content: const Text('This contact will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AuroraColors.coral),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return isIOS ? _buildIOS(context) : _buildAndroid(context);
  }

  Widget _buildIOS(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AuroraColors.paper,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AuroraColors.paper,
        middle: Text(_isEditing ? 'Edit Contact' : 'New Contact'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: const Text('Cancel'),
        ),
      ),
      child: SafeArea(
        child: _FormBody(
          formKey: _formKey,
          nameController: _nameController,
          companyController: _companyController,
          phonePrimaryController: _phonePrimaryController,
          phoneSecondaryController: _phoneSecondaryController,
          emailController: _emailController,
          availableHoursController: _availableHoursController,
          notesController: _notesController,
          category: _category,
          is24x7: _is24x7,
          isFavorite: _isFavorite,
          isEditing: _isEditing,
          saving: _saving,
          deleting: _deleting,
          onPickCategory: () => _pickCategory(context),
          onToggle24x7: (v) => setState(() => _is24x7 = v),
          onToggleFavorite: (v) => setState(() => _isFavorite = v),
          onDelete: _delete,
          onSave: _save,
        ),
      ),
    );
  }

  Widget _buildAndroid(BuildContext context) {
    return Scaffold(
      backgroundColor: AuroraColors.paper,
      appBar: AppBar(
        backgroundColor: AuroraColors.paper,
        scrolledUnderElevation: 0,
        title: Text(
          _isEditing ? 'Edit Contact' : 'New Contact',
          style: AuroraType.h3,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _FormBody(
        formKey: _formKey,
        nameController: _nameController,
        companyController: _companyController,
        phonePrimaryController: _phonePrimaryController,
        phoneSecondaryController: _phoneSecondaryController,
        emailController: _emailController,
        availableHoursController: _availableHoursController,
        notesController: _notesController,
        category: _category,
        is24x7: _is24x7,
        isFavorite: _isFavorite,
        isEditing: _isEditing,
        saving: _saving,
        deleting: _deleting,
        onPickCategory: () => _pickCategory(context),
        onToggle24x7: (v) => setState(() => _is24x7 = v),
        onToggleFavorite: (v) => setState(() => _isFavorite = v),
        onDelete: _delete,
        onSave: _save,
      ),
    );
  }
}

// ── Shared form body ──────────────────────────────────────────────────────────

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.formKey,
    required this.nameController,
    required this.companyController,
    required this.phonePrimaryController,
    required this.phoneSecondaryController,
    required this.emailController,
    required this.availableHoursController,
    required this.notesController,
    required this.category,
    required this.is24x7,
    required this.isFavorite,
    required this.isEditing,
    required this.saving,
    required this.deleting,
    required this.onPickCategory,
    required this.onToggle24x7,
    required this.onToggleFavorite,
    required this.onDelete,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController companyController;
  final TextEditingController phonePrimaryController;
  final TextEditingController phoneSecondaryController;
  final TextEditingController emailController;
  final TextEditingController availableHoursController;
  final TextEditingController notesController;
  final String category;
  final bool is24x7;
  final bool isFavorite;
  final bool isEditing;
  final bool saving;
  final bool deleting;
  final VoidCallback onPickCategory;
  final ValueChanged<bool> onToggle24x7;
  final ValueChanged<bool> onToggleFavorite;
  final VoidCallback onDelete;
  final VoidCallback onSave;

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
          // ── Basic Info ─────────────────────────────────────────────────────
          AuroraFormSection(
            title: 'Basic Info',
            children: [
              AuroraTextField(
                label: 'Name',
                required: true,
                controller: nameController,
                hintText: "e.g. Mike's Plumbing",
                keyboardType: TextInputType.name,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              AuroraTextField(
                label: 'Company',
                controller: companyController,
                hintText: 'Business name',
                keyboardType: TextInputType.name,
              ),
            ],
          ),

          // ── Category ───────────────────────────────────────────────────────
          AuroraFormSection(
            title: 'Category',
            children: [
              AuroraSelectField(
                label: 'Category',
                value: ContactCategories.labelFor(category),
                onTap: onPickCategory,
              ),
            ],
          ),

          // ── Contact Details ────────────────────────────────────────────────
          AuroraFormSection(
            title: 'Contact Details',
            children: [
              AuroraTextField(
                label: 'Primary Phone',
                required: true,
                controller: phonePrimaryController,
                hintText: 'e.g. (555) 867-5309',
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Primary phone is required'
                    : null,
              ),
              AuroraTextField(
                label: 'Secondary Phone',
                controller: phoneSecondaryController,
                hintText: 'Mobile, after-hours, etc.',
                keyboardType: TextInputType.phone,
              ),
              AuroraTextField(
                label: 'Email',
                controller: emailController,
                hintText: 'contact@example.com',
                keyboardType: TextInputType.emailAddress,
              ),
              AuroraTextField(
                label: 'Available Hours',
                controller: availableHoursController,
                hintText: 'e.g. M–F 8am–5pm',
              ),
            ],
          ),

          // ── Preferences ────────────────────────────────────────────────────
          AuroraFormSection(
            title: 'Preferences',
            children: [
              AuroraToggleRow(
                label: 'Available 24/7',
                value: is24x7,
                onChanged: onToggle24x7,
              ),
              AuroraToggleRow(
                label: 'Pin to favorites',
                value: isFavorite,
                onChanged: onToggleFavorite,
              ),
            ],
          ),

          // ── Notes ──────────────────────────────────────────────────────────
          AuroraFormSection(
            title: 'Notes',
            isOptional: true,
            children: [
              AuroraTextField(
                label: 'Notes',
                controller: notesController,
                hintText: 'Gate code, preferred contact method, etc.',
                maxLines: 4,
              ),
            ],
          ),

          const SizedBox(height: AuroraSpacing.space10),

          // ── Save CTA ───────────────────────────────────────────────────────
          SaveButton(
            label: isEditing ? 'Save Changes' : 'Add Contact',
            onPressed: saving ? null : onSave,
            loading: saving,
            expand: true,
          ),

          if (isEditing) ...[
            const SizedBox(height: AuroraSpacing.space3),
            GhostButton(
              label: deleting ? 'Deleting…' : 'Delete Contact',
              onPressed: deleting ? null : onDelete,
            ),
          ],

          const SizedBox(height: AuroraSpacing.space10),
        ],
      ),
    );
  }
}
