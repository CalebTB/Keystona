import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../maintenance/widgets/reminders/reminders_back_link.dart';

/// The top row of an item screen: the back link with the parent's name at
/// the left and an optional [trailing] action ([ItemTopBarAction]) at the
/// right edge.
class ItemTopBar extends StatelessWidget {
  const ItemTopBar({
    super.key,
    required this.backLabel,
    required this.onBack,
    this.trailing,
  });

  final String backLabel;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: RemindersBackLink(label: backLabel, onTap: onBack),
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: a.of(AuroraSpacing.space3)),
          trailing!,
        ],
      ],
    );
  }
}
