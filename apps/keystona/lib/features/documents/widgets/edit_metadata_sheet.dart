import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/aurora_docs_b.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/aurora/aurora_button.dart';
import '../../../core/widgets/aurora/aurora_select_field.dart';
import '../../../core/widgets/aurora/aurora_sheet.dart';
import '../../../core/widgets/aurora/aurora_text_field.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/document.dart';
import '../models/document_edit.dart';
import '../models/document_format.dart';
import '../models/document_tags.dart';
import '../providers/document_categories_provider.dart';
import 'upload/upload_tags_field.dart';

/// Sheet for editing a document's name, category, end date, notes and tags.
///
/// It does not know how a save is stored: [onSave] does that, and the sheet
/// closes with `true` once it succeeds.
class EditMetadataSheet extends ConsumerStatefulWidget {
  const EditMetadataSheet({
    super.key,
    required this.document,
    required this.onSave,
  });

  final Document document;
  final Future<void> Function(DocumentEdit edit) onSave;

  /// Longest allowed name and notes.
  static const int nameMaxLength = 120;
  static const int notesMaxLength = 500;

  /// Earliest and latest year the end-date picker offers.
  static const int firstYear = 2000;
  static const int lastYear = 2100;

  /// Presents the sheet. Resolves to `true` after a successful save.
  static Future<bool?> show(
    BuildContext context, {
    required Document document,
    required Future<void> Function(DocumentEdit edit) onSave,
  }) {
    return AuroraSheet.show<bool>(
      context,
      title: 'Edit document',
      height: AuroraSheetHeight.extra,
      child: EditMetadataSheet(document: document, onSave: onSave),
    );
  }

  @override
  ConsumerState<EditMetadataSheet> createState() => _EditMetadataSheetState();
}

class _EditMetadataSheetState extends ConsumerState<EditMetadataSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _notes;
  late String _categoryId;
  late List<String> _tags;
  DateTime? _expiration;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.document.name);
    _notes = TextEditingController(text: widget.document.notes ?? '');
    _categoryId = widget.document.categoryId;
    _tags = DocumentTags.of(widget.document);
    _expiration = widget.document.expirationDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? get _categoryName {
    final categories = ref.watch(documentCategoriesProvider).value ?? const [];
    for (final c in categories) {
      if (c.id == _categoryId) return c.name;
    }
    return widget.document.category?.name;
  }

  Future<void> _pickCategory() async {
    final categories = ref.read(documentCategoriesProvider).value ?? const [];
    if (categories.isEmpty) return;
    final index = await AuroraSheet.actionSheet(
      context,
      title: 'Category',
      actions: [for (final c in categories) AuroraSheetAction(label: c.name)],
    );
    if (index == null || !mounted) return;
    setState(() => _categoryId = categories[index].id);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiration ?? now,
      firstDate: DateTime(EditMetadataSheet.firstYear),
      lastDate: DateTime(EditMetadataSheet.lastYear),
    );
    if (picked == null || !mounted) return;
    setState(() => _expiration = picked);
  }

  bool _addTag(String raw) {
    final next = DocumentTags.adding(
      _tags,
      raw,
      max: AuroraUploadRules.maxTags,
      maxLength: AuroraUploadRules.maxTagLength,
    );
    if (next == null) return false;
    setState(() => _tags = next);
    return true;
  }

  void _removeTag(String tag) =>
      setState(() => _tags = [..._tags]..remove(tag));

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final notes = _notes.text.trim();
    final edit = DocumentEdit(
      name: _name.text.trim(),
      categoryId: _categoryId,
      tags: _tags,
      expirationDate: _expiration,
      notes: notes.isEmpty ? null : notes,
    );
    setState(() => _saving = true);
    try {
      await widget.onSave(edit);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarService.showError(context, "Couldn't save changes. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.formSection));
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuroraTextField(
              label: 'Name',
              controller: _name,
              required: true,
              maxLength: EditMetadataSheet.nameMaxLength,
              validator: Validators.required,
            ),
            gap,
            AuroraSelectField(
              label: 'Category',
              value: _categoryName,
              onTap: _pickCategory,
            ),
            gap,
            AuroraSelectField(
              label: 'End date',
              placeholder: 'No end date',
              value: _expiration == null
                  ? null
                  : DocumentFormat.date(_expiration!),
              onTap: _pickDate,
            ),
            if (_expiration != null)
              Align(
                alignment: Alignment.centerLeft,
                child: GhostButton(
                  label: 'Remove end date',
                  onPressed: () => setState(() => _expiration = null),
                ),
              ),
            gap,
            AuroraTextField(
              label: 'Notes',
              controller: _notes,
              maxLines: 4,
              maxLength: EditMetadataSheet.notesMaxLength,
            ),
            gap,
            UploadTagsField(
              tags: _tags,
              onAdd: _addTag,
              onRemove: _removeTag,
              enabled: !_saving,
            ),
            gap,
            SaveButton(
              label: 'Save',
              expand: true,
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
