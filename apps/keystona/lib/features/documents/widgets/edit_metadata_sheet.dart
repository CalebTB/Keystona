import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
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
      backgroundColor: AuroraColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
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
        color: AuroraColors.paper,
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
          colorScheme: const ColorScheme.light(primary: AuroraColors.ink),
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
        AuroraSpacing.space5,
        AuroraSpacing.space5,
        AuroraSpacing.space5,
        AuroraSpacing.space8 + bottomInset,
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
              decoration: const BoxDecoration(
                color: AuroraColors.inkBorder,
                borderRadius: AuroraRadius.full,
              ),
            ),
          ),
          const SizedBox(height: AuroraSpacing.space5),

          Text('Edit Document', style: AuroraType.h3),
          const SizedBox(height: AuroraSpacing.space7),

          // Name field.
          _FieldLabel(label: 'Name'),
          const SizedBox(height: AuroraSpacing.space1),
          TextField(
            controller: _nameController,
            decoration: _inputDecoration('Document name'),
            textCapitalization: TextCapitalization.words,
            maxLength: 120,
          ),
          const SizedBox(height: AuroraSpacing.space5),

          // Category picker.
          _FieldLabel(label: 'Category'),
          const SizedBox(height: AuroraSpacing.space1),
          categoriesState.when(
            loading: () => const SizedBox(height: 48),
            error: (e, s) => const SizedBox.shrink(),
            data: (categories) => DropdownButtonFormField<String>(
              initialValue: _selectedCategoryId,
              decoration: _inputDecoration('Select category'),
              dropdownColor: AuroraColors.paper,
              items: categories
                  .map(
                    (cat) => DropdownMenuItem<String>(
                      value: cat.id,
                      child: Text(cat.name, style: AuroraType.body),
                    ),
                  )
                  .toList(),
              onChanged: (id) => setState(() => _selectedCategoryId = id),
            ),
          ),
          const SizedBox(height: AuroraSpacing.space5),

          // Expiration date picker.
          _FieldLabel(label: 'Expiration date'),
          const SizedBox(height: AuroraSpacing.space1),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: AuroraSpacing.space5),
              decoration: BoxDecoration(
                border: Border.all(color: AuroraColors.inkBorder),
                borderRadius: AuroraRadius.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _expirationDate != null
                        ? DateFormat('MMM d, yyyy').format(_expirationDate!)
                        : 'No expiration date',
                    style: AuroraType.body.copyWith(
                      color: _expirationDate != null
                          ? AuroraColors.ink
                          : AuroraColors.inkSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      if (_expirationDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _expirationDate = null),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: AuroraColors.inkSecondary,
                          ),
                        ),
                      const SizedBox(width: AuroraSpacing.space3),
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AuroraColors.inkSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AuroraSpacing.space5),

          // Notes field.
          _FieldLabel(label: 'Notes'),
          const SizedBox(height: AuroraSpacing.space1),
          TextField(
            controller: _notesController,
            decoration: _inputDecoration('Optional notes'),
            maxLines: 3,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AuroraSpacing.space7),

          // Save button.
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AuroraColors.coral,
              disabledBackgroundColor: AuroraColors.inkBorder,
              minimumSize: const Size.fromHeight(56),
              shape: const RoundedRectangleBorder(
                borderRadius: AuroraRadius.sm,
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Save Changes',
                    style: AuroraType.bodyLg.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
      hintStyle: AuroraType.body.copyWith(color: AuroraColors.inkSecondary),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.space5,
        vertical: AuroraSpacing.space5,
      ),
      border: OutlineInputBorder(
        borderRadius: AuroraRadius.sm,
        borderSide: const BorderSide(color: AuroraColors.inkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AuroraRadius.sm,
        borderSide: const BorderSide(color: AuroraColors.inkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AuroraRadius.sm,
        borderSide: const BorderSide(color: AuroraColors.ink, width: 2),
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
      label.toUpperCase(),
      style: AuroraType.label.copyWith(color: AuroraColors.inkSecondary),
    );
  }
}
