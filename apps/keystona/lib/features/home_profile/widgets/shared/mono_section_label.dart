import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_shared.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';

/// The 10 pt tracked section label above a card ("LIFESPAN", "HISTORY · 3"),
/// with an optional trailing note ("$5,189 SINCE 2021").
class MonoSectionLabel extends StatelessWidget {
  const MonoSectionLabel(
    this.text, {
    super.key,
    this.trailing,
    this.trailingColor,
  });

  final String text;
  final String? trailing;

  /// Defaults to the secondary ink.
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: a.of(AuroraHomeSizes.sectionLabelMin),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              text.toUpperCase(),
              style: AuroraType.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: a.of(AuroraSpacing.space3)),
            Flexible(
              child: Text(
                trailing!.toUpperCase(),
                textAlign: TextAlign.end,
                style: AuroraType.rowDate.copyWith(
                  color: trailingColor ?? AuroraColors.inkSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
