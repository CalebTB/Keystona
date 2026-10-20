import 'package:flutter/material.dart';

import '../../../../../core/theme/aurora_colors.dart';
import '../../../../../core/theme/aurora_radius.dart';
import '../../../../../core/theme/aurora_scale.dart';
import '../../../../../core/theme/aurora_sizes.dart';
import '../../../../../core/theme/aurora_spacing.dart';
import '../../../../../core/theme/aurora_tasks_a.dart';
import '../../../../../core/widgets/aurora/aurora_pressable.dart';

/// One radio card of the skip sheet: a title and what choosing it does.
class SkipReasonCard extends StatelessWidget {
  const SkipReasonCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: '$title. $subtitle',
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraSizes.minTouch),
        ),
        padding: a.all(AuroraSpacing.space6),
        decoration: BoxDecoration(
          borderRadius: AuroraRadius.xl,
          border: Border.all(
            color: selected ? AuroraColors.ink : AuroraColors.inkTileBorder,
            width: selected
                ? AuroraTasksA.radioBorderOn
                : AuroraBorders.regular,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Radio(selected: selected),
            SizedBox(width: a.of(AuroraSpacing.space5)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AuroraTasksAType.reasonTitle),
                  SizedBox(height: a.of(AuroraSpacing.space1)),
                  Text(subtitle, style: AuroraTasksAType.reasonSub),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      width: a.of(AuroraTasksA.radio),
      height: a.of(AuroraTasksA.radio),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AuroraColors.ink : AuroraColors.inkCheckBorder,
          width: selected ? AuroraTasksA.radioBorderOn : AuroraBorders.emphasis,
        ),
      ),
      child: selected
          ? Container(
              width: a.of(AuroraTasksA.radioDot),
              height: a.of(AuroraTasksA.radioDot),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AuroraColors.ink,
              ),
            )
          : null,
    );
  }
}
