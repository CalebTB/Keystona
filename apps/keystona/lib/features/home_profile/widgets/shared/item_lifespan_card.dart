import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_shared.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../lifespan/lifespan_reading.dart';
import 'lifespan_bar.dart';

/// The detail "LIFESPAN" card: "5½ yrs old" with "OF ~15 YRS EXPECTED", the
/// bar with its aging tick, the start and replace lines, and a closing
/// sentence ([body]).
class ItemLifespanCard extends StatelessWidget {
  const ItemLifespanCard({
    super.key,
    required this.reading,
    this.startLabel,
    this.replaceLabel,
    this.body,
  });

  final LifespanReading reading;

  /// "INSTALLED MAR 2021" or "BOUGHT DEC 2023".
  final String? startLabel;

  /// Defaults to "REPLACE AROUND {year}" when the reading has a year.
  final String? replaceLabel;

  /// The sentence under the bar. Build it with a bold span for the years left.
  final InlineSpan? body;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final age = reading.ageLabel;
    final replace =
        replaceLabel ??
        (reading.replaceYear == null
            ? null
            : 'REPLACE AROUND ${reading.replaceYear}');
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.xl,
        border: Border.all(
          color: AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Padding(
        padding: a.all(AuroraSpacing.space7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: age.isEmpty ? '—' : age,
                          style: AuroraHomeType.lifespanBig,
                        ),
                        if (age.isNotEmpty)
                          TextSpan(
                            text: ' old',
                            style: AuroraHomeType.lifespanOld,
                          ),
                      ],
                    ),
                  ),
                ),
                if (reading.lifeLabel.isNotEmpty) ...[
                  SizedBox(width: a.of(AuroraSpacing.space4)),
                  Flexible(
                    child: Text(
                      'OF ${reading.lifeLabel} EXPECTED'.toUpperCase(),
                      textAlign: TextAlign.end,
                      style: AuroraType.meta,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: a.of(AuroraSpacing.space5)),
            LifespanBar(reading: reading, large: true, showTick: true),
            if (startLabel != null || replace != null) ...[
              SizedBox(height: a.of(AuroraSpacing.space5)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      (startLabel ?? '').toUpperCase(),
                      style: AuroraType.meta,
                    ),
                  ),
                  SizedBox(width: a.of(AuroraSpacing.space3)),
                  Flexible(
                    child: Text(
                      (replace ?? '').toUpperCase(),
                      textAlign: TextAlign.end,
                      style: AuroraType.meta,
                    ),
                  ),
                ],
              ),
            ],
            if (body != null) ...[
              SizedBox(height: a.of(AuroraSpacing.space5)),
              const Divider(
                height: AuroraBorders.hairline,
                thickness: AuroraBorders.hairline,
                color: AuroraColors.inkBorder,
              ),
              SizedBox(height: a.of(AuroraSpacing.space5)),
              Text.rich(body!, style: AuroraHomeType.lifespanBody),
            ],
          ],
        ),
      ),
    );
  }
}
