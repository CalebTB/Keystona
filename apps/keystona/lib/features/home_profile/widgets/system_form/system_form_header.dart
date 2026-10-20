import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../maintenance/widgets/reminders/reminders_back_link.dart';
import '../../systems_copy.dart';

/// The back link, the eyebrow with its cobalt dot and the heading.
class SystemFormHeader extends StatelessWidget {
  const SystemFormHeader({
    super.key,
    required this.backLabel,
    required this.onBack,
    required this.eyebrow,
    required this.title,
  });

  final String backLabel;
  final VoidCallback onBack;
  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: RemindersBackLink(label: backLabel, onTap: onBack),
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        Row(
          children: [
            Container(
              width: a.of(AuroraSpacing.space2),
              height: a.of(AuroraSpacing.space2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AuroraColors.cobalt,
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space2)),
            Flexible(child: Text(eyebrow, style: AuroraType.label)),
          ],
        ),
        SizedBox(height: a.of(AuroraSpacing.space2)),
        Semantics(header: true, child: Text(title, style: AuroraType.h1)),
      ],
    );
  }
}

/// Re-export for tests: the back label for edit mode is the system's name.
String systemFormBackLabel({required bool editing, String? name}) =>
    editing ? (name ?? SystemsCopy.systemsBack) : SystemsCopy.formBackScan;
