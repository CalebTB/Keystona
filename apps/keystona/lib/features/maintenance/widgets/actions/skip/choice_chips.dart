import 'package:flutter/material.dart';

import '../../../../../core/theme/aurora_scale.dart';
import '../../../../../core/theme/aurora_spacing.dart';
import '../../../../../core/theme/aurora_typography.dart';
import '../../../../../core/widgets/aurora/aurora_chip.dart';

/// A labelled row of single-choice chips (REMIND ME, WHO DID IT, WHEN).
/// Chips wrap onto a new line when they do not fit.
class ChoiceChips<T> extends StatelessWidget {
  const ChoiceChips({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<({T value, String label})> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AuroraType.label),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        Wrap(
          spacing: a.of(AuroraSpacing.space2),
          runSpacing: a.of(AuroraSpacing.space2),
          children: [
            for (final option in options)
              FilterPill(
                label: option.label,
                selected: option.value == selected,
                onTap: () => onSelected(option.value),
              ),
          ],
        ),
      ],
    );
  }
}
