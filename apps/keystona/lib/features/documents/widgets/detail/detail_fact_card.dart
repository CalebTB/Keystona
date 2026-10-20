import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';

/// One label/value line in a [DetailFactCard].
class DetailFact {
  const DetailFact(this.label, this.value);

  final String label;
  final String value;
}

/// Bordered card of label/value rows separated by hairlines: "What it says"
/// and "File" on the detail screen. Long values wrap; nothing is clipped.
class DetailFactCard extends StatelessWidget {
  const DetailFactCard({super.key, required this.facts});

  final List<DetailFact> facts;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.xl,
        border: Border.all(
          color: AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: ClipRRect(
        borderRadius: AuroraRadius.xl,
        child: Column(
          children: [
            for (var i = 0; i < facts.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: AuroraBorders.hairline,
                  thickness: AuroraBorders.hairline,
                  color: AuroraColors.inkBorder,
                ),
              Padding(
                padding: a.symmetric(
                  horizontal: AuroraSpacing.space6,
                  vertical: AuroraSpacing.space5,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The label takes its natural width. A Flexible here
                    // would share the row 50/50 with the value and squeeze it
                    // into a half-width box.
                    Text(
                      facts[i].label.toUpperCase(),
                      style: AuroraType.label,
                    ),
                    SizedBox(width: a.of(AuroraSpacing.space5)),
                    Expanded(
                      child: Text(
                        facts[i].value,
                        textAlign: TextAlign.right,
                        style: AuroraType.buttonSm,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
