import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/emergency_contact.dart';
import '../providers/contacts_list_provider.dart';

/// Create or edit an [EmergencyContact].
///
/// - Create mode: pass [existingContact] = null.
/// - Edit mode:   pass [existingContact]. All fields are pre-populated.
///
/// Uses [ConsumerStatefulWidget] for Riverpod ref access + local form state.
class ContactFormScreen extends ConsumerStatefulWidget {
  const ContactFormScreen({super.key, this.existingContact});

  /// The contact to edit, or null when creating a new contact.
  final EmergencyContact? existingContact;

  @override
  ConsumerState<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends ConsumerState<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Controllers ───────────────────────────────────────────────────────────

  late final TextEditingController _nameController;
  late final TextEditingController _companyController;
  late final TextEditingController _phonePrimaryController;
  late final TextEditingController _phoneSecondaryController;
  late final TextEditingController _emailController;
  late final TextEditingController _availableHoursController;
  late final TextEditingController _notesController;

  // ── Local state ───────────────────────────────────────────────────────────

  late String _category;
  late bool _is24x7;
  late bool _isFavorite;
  bool _saving = false;
  bool _deleting = false;

  // ── Helpers ───────────────────────────────────────────────────────────────

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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Text('Contact Category', style: AppTextStyles.h4),
            ),
            ...ContactCategories.all.map(
              (option) => ListTile(
                title: Text(option.label),
                trailing: _category == option.value
                    ? const Icon(
                        Icons.check,
                        color: AppColors.deepNavy,
                      )
                    : null,
                onTap: () {
                  setState(() => _category = option.value);
                  Navigator.of(ctx).pop();
                },
              ),
            ),
            const SizedBox(height: AppSizes.sm),
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
      // Pop twice: dismiss the form, return to the contacts list.
      context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      SnackbarService.showError(
        context,
        "Couldn't delete contact. Try again.",
      );
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
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
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

  // ── iOS scaffold ──────────────────────────────────────────────────────────

  Widget _buildIOS(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_isEditing ? 'Edit Contact' : 'New Contact'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: const Text('Cancel'),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _saving ? null : _save,
          child: _saving
              ? const CupertinoActivityIndicator()
              : Text(
                  'Save',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.deepNavy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
          deleting: _deleting,
          onPickCategory: () => _pickCategory(context),
          onToggle24x7: (v) => setState(() => _is24x7 = v),
          onToggleFavorite: (v) => setState(() => _isFavorite = v),
          onDelete: _delete,
        ),
      ),
    );
  }

  // ── Android scaffold ──────────────────────────────────────────────────────

  Widget _buildAndroid(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      appBar: AppBar(
        backgroundColor: AppColors.warmOffWhite,
        scrolledUnderElevation: 0,
        title: Text(
          _isEditing ? 'Edit Contact' : 'New Contact',
          style: AppTextStyles.h3,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.deepNavy,
                    ),
                  ),
          ),
        ],
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
        deleting: _deleting,
        onPickCategory: () => _pickCategory(context),
        onToggle24x7: (v) => setState(() => _is24x7 = v),
        onToggleFavorite: (v) => setState(() => _isFavorite = v),
        onDelete: _delete,
      ),
    );
  }
}

// ── Shared form body ──────────────────────────────────────────────────────────

/// Platform-agnostic form content shared between the iOS and Android scaffolds.
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
    required this.deleting,
    required this.onPickCategory,
    required this.onToggle24x7,
    required this.onToggleFavorite,
    required this.onDelete,
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
  final bool deleting;
  final VoidCallback onPickCategory;
  final ValueChanged<bool> onToggle24x7;
  final ValueChanged<bool> onToggleFavorite;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: AppPadding.screen,
        children: [
          // ── Name ──────────────────────────────────────────────────────────
          _SectionLabel(label: 'Name *'),
          _InputField(
            controller: nameController,
            hint: "e.g. Mike's Plumbing",
            keyboardType: TextInputType.name,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: AppSizes.md),

          // ── Company ───────────────────────────────────────────────────────
          _SectionLabel(label: 'Company'),
          _InputField(
            controller: companyController,
            hint: 'Business name (optional)',
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: AppSizes.md),

          // ── Category ──────────────────────────────────────────────────────
          _SectionLabel(label: 'Category'),
          _CategorySelector(
            currentCategory: category,
            onTap: onPickCategory,
          ),
          const SizedBox(height: AppSizes.md),

          // ── Primary phone ─────────────────────────────────────────────────
          _SectionLabel(label: 'Primary Phone *'),
          _InputField(
            controller: phonePrimaryController,
            hint: 'e.g. (555) 867-5309',
            keyboardType: TextInputType.phone,
            validator: (v) =>
                (v == null || v.trim().isEmpty)
                    ? 'Primary phone is required'
                    : null,
          ),
          const SizedBox(height: AppSizes.md),

          // ── Secondary phone ───────────────────────────────────────────────
          _SectionLabel(label: 'Secondary Phone'),
          _InputField(
            controller: phoneSecondaryController,
            hint: 'Mobile, after-hours, etc. (optional)',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppSizes.md),

          // ── Email ─────────────────────────────────────────────────────────
          _SectionLabel(label: 'Email'),
          _InputField(
            controller: emailController,
            hint: 'contact@example.com (optional)',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppSizes.md),

          // ── Available hours ───────────────────────────────────────────────
          _SectionLabel(label: 'Available Hours'),
          _InputField(
            controller: availableHoursController,
            hint: 'e.g. M–F 8am–5pm (optional)',
          ),
          const SizedBox(height: AppSizes.md),

          // ── 24/7 toggle ───────────────────────────────────────────────────
          _ToggleRow(
            label: 'Available 24/7',
            value: is24x7,
            onChanged: onToggle24x7,
          ),
          const SizedBox(height: AppSizes.sm),

          // ── Favorite toggle ───────────────────────────────────────────────
          _ToggleRow(
            label: 'Pin to favorites',
            value: isFavorite,
            onChanged: onToggleFavorite,
          ),
          const SizedBox(height: AppSizes.md),

          // ── Notes ─────────────────────────────────────────────────────────
          _SectionLabel(label: 'Notes'),
          _InputField(
            controller: notesController,
            hint: 'Gate code, preferred contact method, etc. (optional)',
            minLines: 3,
            maxLines: 6,
          ),

          // ── Delete button (edit mode only) ────────────────────────────────
          if (isEditing) ...[
            const SizedBox(height: AppSizes.xl),
            _DeleteButton(deleting: deleting, onDelete: onDelete),
          ],

          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }
}

// ── Sub-components ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.xs),
      child: Text(
        label,
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.validator,
    this.minLines,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final int? minLines;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      validator: validator,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textDisabled,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm + AppSizes.xs,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.deepNavy, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.currentCategory,
    required this.onTap,
  });

  final String currentCategory;
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
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                ContactCategories.labelFor(currentCategory),
                style: AppTextStyles.bodyMedium,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: AppSizes.iconMd,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTextStyles.bodyMedium),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.deepNavy,
            activeTrackColor: AppColors.deepNavy.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.deleting, required this.onDelete});
  final bool deleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: deleting ? null : onDelete,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error),
        minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
      ),
      child: deleting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.error,
              ),
            )
          : Text(
              'Delete Contact',
              style: AppTextStyles.button.copyWith(color: AppColors.error),
            ),
    );
  }
}
