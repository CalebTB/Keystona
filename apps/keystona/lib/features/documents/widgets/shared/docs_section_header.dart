import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';

/// Uppercase mono eyebrow above a block, with an optional trailing widget
/// (a count, a "read by smart scan" tag).
class DocsSectionHeader extends StatelessWidget {
  const DocsSectionHeader({
    super.key,
    required this.title,
    this.color,
    this.bold = false,
    this.trailing,
  });

  final String title;

  /// Overrides the secondary ink color (urgent groups on Expiring).
  final Color? color;

  /// 700 weight, used by the colored group headers.
  final bool bold;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final style = AuroraType.label.copyWith(
      color: color ?? AuroraColors.inkSecondary,
      fontWeight: bold ? FontWeight.w700 : null,
    );
    // Flexible + spaceBetween, not Expanded + Flexible: that pair splits the
    // row evenly and leaves the trailing widget floating mid-row.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Semantics(
            header: true,
            child: Text(title.toUpperCase(), style: style),
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: a.of(AuroraSpacing.space3)),
          Flexible(child: trailing!),
        ],
      ],
    );
  }
}
