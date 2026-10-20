import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_field_chrome.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../task_form_copy.dart';

/// The picked first-due date; tapping it opens the date picker.
class TaskDateField extends StatelessWidget {
  const TaskDateField({super.key, required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final text = DateFormat('EEEE, MMM d, y').format(date);
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: '${TaskFormCopy.datePickerLabel}, $text',
      child: AuroraFieldBox(
        child: Row(
          children: [
            Expanded(child: Text(text, style: AuroraType.input)),
            SizedBox(width: a.of(AuroraSpacing.space3)),
            Icon(
              CupertinoIcons.calendar,
              size: a.of(AuroraIconSizes.md),
              color: AuroraColors.inkHelper,
            ),
          ],
        ),
      ),
    );
  }
}
