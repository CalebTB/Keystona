import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../appliance_copy.dart';
import '../../models/appliance_suggestion.dart';
import '../shared/dashed_suggestion_chip.dart';
import '../shared/mono_section_label.dart';

/// "OFTEN FORGOTTEN": dashed chips for appliances the home may not track yet.
class ApplianceSuggestions extends StatelessWidget {
  const ApplianceSuggestions({
    super.key,
    required this.suggestions,
    required this.onPick,
  });

  final List<ApplianceSuggestion> suggestions;
  final ValueChanged<ApplianceSuggestion> onPick;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MonoSectionLabel(ApplianceCopy.oftenForgotten),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        Wrap(
          spacing: a.of(AuroraSpacing.space2),
          runSpacing: a.of(AuroraSpacing.space2),
          children: [
            for (final s in suggestions)
              DashedSuggestionChip(label: s.name, onTap: () => onPick(s)),
          ],
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        Text(
          ApplianceCopy.suggestionNote,
          style: AuroraType.meta.copyWith(color: AuroraColors.inkHelper),
        ),
      ],
    );
  }
}
