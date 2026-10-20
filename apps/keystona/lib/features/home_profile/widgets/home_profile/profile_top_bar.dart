import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../home_common/home_back_link.dart';

/// "‹ Home" at the left and "Edit" at the right, both 44 pt targets. [onEdit]
/// null hides Edit (no property to edit).
class ProfileTopBar extends StatelessWidget {
  const ProfileTopBar({
    super.key,
    required this.backLabel,
    required this.onBack,
    this.editLabel,
    this.onEdit,
  });

  final String backLabel;
  final VoidCallback onBack;
  final String? editLabel;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: HomeBackLink(label: backLabel, onTap: onBack)),
        if (onEdit != null && editLabel != null)
          Flexible(
            child: AuroraPressable(
              onTap: onEdit,
              semanticLabel: editLabel,
              enforceTouchTarget: true,
              child: Text(
                editLabel!,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AuroraType.button,
              ),
            ),
          ),
      ],
    );
  }
}
