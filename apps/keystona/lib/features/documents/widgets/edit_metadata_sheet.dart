import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/document.dart';
import '../providers/document_categories_provider.dart';
import '../providers/document_detail_provider.dart';

/// Bottom sheet for editing a document's mutable metadata fields.
///
/// Editable fields: name, category, expiration date, notes.
///
/// Call [EditMetadataSheet.show] to present the sheet. Returns [true] when
/// the user saves successfully, [false] when they cancel.
class EditMetadataSheet extends ConsumerStatefulWidget {
  const EditMetadataSheet({super.key, required this.document});

  final Document document;

  /// Presents the edit metadata sheet and returns the save result.
  static Future<bool?> show(BuildContext context, Document document) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      builder: (_) => EditMetadataSheet(document: document),
    );
  }

  @override
  ConsumerState<EditMetadataSheet> createState() => _EditMetadataSheetState();
}

class _EditMetadataSheetState extends ConsumerState<EditMetadataSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  String? _selectedCategoryId;
  DateTime? _expirationDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.document.name);
    _notesController = TextEditingController(text: widget.document.notes ?? '');
    _selectedCategoryId = widget.document.categoryId;
    _expirationDate = widget.document.expirationDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      SnackbarService.showError(context, 'Document name cannot be empty.');
      return;
    }

    setState(() => _saving = true);

    try {
      await ref.read(documentDetailProvider(widget.document.id).notifier).updateDocument({
        'name': name,
        'category_id': _selectedCategoryId,
        'expiration_date': _expirationDate?.toIso8601String(),
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        SnackbarService.showError(context, "Couldn't save changes. Try again.");
      }
    }
  }

  Future<void> _pickDate() async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      await _pickDateIOS();
    } else {
      await _pickDateAndroid();
    }
  }

  Future<void> _pickDateIOS() async {
    DateTime picked = _expirationDate ?? DateTime.now().add(const Duration(days: 365));
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: AppColors.surface,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                ),
                CupertinoButton(
                  child: const Text('Done'),
                  onPressed: () {
                    setState(() => _expirationDate = picked);
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: picked,
                onDateTimeChanged: (dt) => picked = dt,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateAndroid() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.deepNavy),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expirationDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(documentCategoriesProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.md,
        AppSizes.md,
        AppSizes.xl + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar.
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),

          Text('Edit Document', style: AppTextStyles.h3),
          const SizedBox(height: AppSizes.lg),

          // Name field.
          _FieldLabel(label: 'Name'),
          const SizedBox(height: AppSizes.xs),
          TextField(
            controller: _nameController,
            decoration: _inputDecoration('Document name'),
            textCapitalization: TextCapitalization.words,
            maxLength: 120,
          ),
          const SizedBox(height: AppSizes.md),

          // Category picker.
          _FieldLabel(label: 'Category'),
          const SizedBox(height: AppSizes.xs),
          categoriesState.when(
            loading: () => const SizedBox(height: AppSizes.inputHeight),
            error: (e, s) => const SizedBox.shrink(),
            data: (categories) => DropdownButtonFormField<String>(
              initialValue: _selectedCategoryId,
              decoration: _inputDecoration('Select category'),
              dropdownColor: AppColors.surface,
              items: categories
                  .map(
                    (cat) => DropdownMenuItem<String>(
                      value: cat.id,
                      child: Text(cat.name, style: AppTextStyles.bodyMedium),
                    ),
                  )
                  .toList(),
              onChanged: (id) => setState(() => _selectedCategoryId = id),
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // Expiration date picker.
          _FieldLabel(label: 'Expiration date'),
          const SizedBox(height: AppSizes.xs),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              height: AppSizes.inputHeight,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _expirationDate != null
                        ? DateFormat('MMM d, yyyy').format(_expirationDate!)
                        : 'No expiration date',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _expirationDate != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      if (_expirationDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _expirationDate = null),
                          child: const Icon(
                            Icons.close,
                            size: AppSizes.iconSm,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      const SizedBox(width: AppSizes.sm),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: AppSizes.iconSm,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // Notes field.
          _FieldLabel(label: 'Notes'),
          const SizedBox(height: AppSizes.xs),
          TextField(
            controller: _notesController,
            decoration: _inputDecoration('Optional notes'),
            maxLines: 3,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppSizes.lg),

          // Save button.
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.deepNavy,
              disabledBackgroundColor: AppColors.gray300,
              minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textInverse,
                    ),
                  )
                : Text(
                    'Save Changes',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.textInverse,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.md,
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
        borderSide: const BorderSide(color: AppColors.deepNavy, width: 2),
      ),
      counterText: '',
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
    );
  }
}
