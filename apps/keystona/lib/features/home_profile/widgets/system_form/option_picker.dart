import 'package:flutter/widgets.dart';

import '../../../../core/widgets/aurora/aurora_sheet.dart';

/// Opens an action sheet of [options] and returns the one tapped, or null when
/// cancelled. The sheet closes with its own context.
Future<T?> pickOption<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required String Function(T) labelOf,
}) async {
  final index = await AuroraSheet.actionSheet(
    context,
    title: title,
    actions: [for (final o in options) AuroraSheetAction(label: labelOf(o))],
  );
  return index == null ? null : options[index];
}
