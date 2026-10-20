import 'package:flutter/material.dart';

import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/widgets/aurora/aurora_field_chrome.dart';
import '../../../core/widgets/aurora/aurora_sheet.dart';
import '../categories_copy.dart';
import '../models/category_lists.dart';
import '../models/document_category.dart';
import 'categories/category_icon_picker.dart';
import 'categories/category_name_field.dart';

// Kept so existing imports of the icon catalog through this file still
// resolve; new code imports models/category_icons.dart directly.
export '../models/category_icons.dart' show CategoryIcons;

/// Renames (and re-icons) a custom category in a bottom sheet.
///
/// New categories are made inline on the categories screen, so this sheet only
/// edits.
abstract final class CategoryFormSheet {
  /// Shows the sheet for [category]. [onSave] writes the change and throws if
  /// it fails; the sheet closes on success and stays open on failure.
  static Future<void> show(
    BuildContext context, {
    required DocumentCategory category,
    required Future<void> Function(String name, String icon) onSave,
  }) {
    // The Save pill lives in the sheet's title row, outside the body, so the
    // body registers its submit handler here.
    final session = _EditSession();
    return AuroraSheet.showAuto<void>(
      context,
      title: CategoriesCopy.editTitle,
      confirmLabel: CategoriesCopy.save,
      onConfirm: () => session.submit?.call(),
      child: _EditBody(category: category, onSave: onSave, session: session),
    );
  }
}

class _EditSession {
  Future<void> Function()? submit;
}

class _EditBody extends StatefulWidget {
  const _EditBody({
    required this.category,
    required this.onSave,
    required this.session,
  });

  final DocumentCategory category;
  final Future<void> Function(String name, String icon) onSave;
  final _EditSession session;

  @override
  State<_EditBody> createState() => _EditBodyState();
}

class _EditBodyState extends State<_EditBody> {
  late final TextEditingController _name = TextEditingController(
    text: widget.category.name,
  );
  late String _icon = widget.category.icon;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    widget.session.submit = _submit;
  }

  @override
  void dispose() {
    widget.session.submit = null;
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    final text = _name.text.trim();
    if (text.isEmpty) {
      setState(() => _error = CategoriesCopy.nameRequired);
      return;
    }
    if (text.length > CategoryLists.maxNameLength) {
      setState(() => _error = CategoriesCopy.nameTooLong);
      return;
    }
    _saving = true;
    try {
      await widget.onSave(text, _icon);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _error = CategoriesCopy.saveFailed);
    } finally {
      _saving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Padding(
      padding: a.all(AuroraSpacing.space7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AuroraFieldLabel(
            label: CategoriesCopy.nameLabel,
            isRequired: true,
          ),
          SizedBox(height: a.of(AuroraSpacing.space2)),
          CategoryNameField(
            controller: _name,
            hintText: CategoriesCopy.namePlaceholder,
            maxLength: CategoryLists.maxNameLength,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            SizedBox(height: a.of(AuroraSpacing.space2)),
            AuroraFieldHelper(text: _error!, isError: true),
          ],
          SizedBox(height: a.of(AuroraSpacing.space7)),
          CategoryIconPicker(
            selected: _icon,
            onSelected: (key) => setState(() => _icon = key),
          ),
        ],
      ),
    );
  }
}
