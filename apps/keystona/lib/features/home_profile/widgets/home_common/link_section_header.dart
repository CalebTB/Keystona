import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_home_a.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// A tracked section label with a cobalt link at the right ("NEXT 5 YEARS" and
/// "How long things last", "THE PROPERTY" and "Edit"). The link is a 44 pt
/// target.
class LinkSectionHeader extends StatelessWidget {
  const LinkSectionHeader({
    super.key,
    required this.title,
    required this.linkLabel,
    required this.onLink,
  });

  final String title;
  final String linkLabel;
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title.toUpperCase(),
            style: AuroraType.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: a.of(AuroraSpacing.space3)),
        Flexible(
          child: AuroraPressable(
            onTap: onLink,
            semanticLabel: linkLabel,
            enforceTouchTarget: true,
            child: Text(
              linkLabel,
              textAlign: TextAlign.end,
              style: AuroraHomeAType.link,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
