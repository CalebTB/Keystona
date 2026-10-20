import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../models/system_template.dart';
import '../../systems_copy.dart';
import '../shared/dashed_suggestion_chip.dart';

/// "COMMON IN A 1998 HOME, NOT TRACKED YET": dashed chips that open Add system
/// filled in, and the caption under them.
class SystemSuggestions extends StatelessWidget {
  const SystemSuggestions({
    super.key,
    required this.yearBuilt,
    required this.templates,
    required this.onPick,
  });

  final int? yearBuilt;
  final List<SystemTemplate> templates;
  final ValueChanged<SystemTemplate> onPick;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(SystemsCopy.suggestionsTitle(yearBuilt), style: AuroraType.label),
        SizedBox(height: a.of(AuroraSpacing.space5)),
        Wrap(
          spacing: a.of(AuroraSpacing.space3),
          runSpacing: a.of(AuroraSpacing.space3),
          children: [
            for (final t in templates)
              DashedSuggestionChip(label: t.label, onTap: () => onPick(t)),
          ],
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        Text(SystemsCopy.suggestionsCaption, style: AuroraType.helper),
      ],
    );
  }
}
