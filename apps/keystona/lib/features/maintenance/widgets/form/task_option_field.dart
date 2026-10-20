import 'package:flutter/material.dart';

import '../../../../core/widgets/aurora/aurora_select_field.dart';
import '../../../../core/widgets/aurora/aurora_sheet.dart';

/// A select field that opens an action sheet of [choices] (How often, Remind
/// me, Time, Difficulty).
class TaskOptionField<T> extends StatelessWidget {
  const TaskOptionField({
    super.key,
    required this.label,
    required this.sheetTitle,
    required this.choices,
    required this.value,
    required this.labelOf,
    required this.onChanged,
    this.required = false,
    this.helperText,
  });

  final String label;

  /// Title of the sheet the field opens.
  final String sheetTitle;
  final List<T> choices;
  final T value;
  final String Function(T value) labelOf;
  final ValueChanged<T> onChanged;
  final bool required;
  final String? helperText;

  Future<void> _open(BuildContext context) async {
    final index = await AuroraSheet.actionSheet(
      context,
      title: sheetTitle,
      actions: [for (final c in choices) AuroraSheetAction(label: labelOf(c))],
    );
    if (index != null) onChanged(choices[index]);
  }

  @override
  Widget build(BuildContext context) {
    return AuroraSelectField(
      label: label,
      required: required,
      value: labelOf(value),
      helperText: helperText,
      onTap: () => _open(context),
    );
  }
}
