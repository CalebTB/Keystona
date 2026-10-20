import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_a.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../../onboarding/models/onboarding_models.dart';

/// "Kind of home": the choices in two columns, one filled ink.
class KindOfHomeGrid extends StatelessWidget {
  const KindOfHomeGrid({
    super.key,
    required this.choices,
    required this.selected,
    required this.onChanged,
  });

  final List<HomeKind> choices;

  /// The stored value ("single_family"), or null / a value not on the list.
  final String? selected;
  final ValueChanged<String> onChanged;

  /// Choices per row.
  static const int columns = 2;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final rows = <Widget>[];
    for (var i = 0; i < choices.length; i += columns) {
      final row = choices.skip(i).take(columns).toList();
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: a.of(AuroraSpacing.space3),
            children: [
              for (var j = 0; j < columns; j++)
                Expanded(
                  child: j < row.length
                      ? _Choice(
                          label: row[j].label,
                          selected: row[j].value == selected,
                          onTap: () => onChanged(row[j].value),
                        )
                      : const SizedBox.shrink(),
                ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: a.of(AuroraSpacing.space3),
      children: rows,
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: label,
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraHomeASizes.choiceMin),
        ),
        padding: a.symmetric(
          horizontal: AuroraSpacing.space3,
          vertical: AuroraSpacing.space3,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AuroraColors.ink : AuroraColors.paper,
          borderRadius: AuroraRadius.md,
          border: Border.all(
            color: selected ? AuroraColors.ink : AuroraColors.inkInputBorder,
            width: selected ? AuroraBorders.emphasis : AuroraBorders.regular,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AuroraHomeAType.choice.copyWith(
            color: selected ? AuroraColors.paper : AuroraColors.inkBody,
          ),
        ),
      ),
    );
  }
}
