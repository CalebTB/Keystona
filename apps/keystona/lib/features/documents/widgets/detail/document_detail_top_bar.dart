import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../shared/docs_back_link.dart';

/// Back to Docs on the left; Share and Edit on the right.
class DocumentDetailTopBar extends StatelessWidget {
  const DocumentDetailTopBar({
    super.key,
    required this.onBack,
    this.onShare,
    this.onEdit,
  });

  final VoidCallback onBack;

  /// Null hides Share (while the document is still loading or failed).
  final VoidCallback? onShare;

  /// Null hides Edit.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Row(
      children: [
        // Expanded (not Flexible + Spacer): those split the free space
        // equally and leave the back link's unused share empty, which pushed
        // Share and Edit toward the middle of the bar.
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: DocsBackLink(label: 'Docs', onTap: onBack),
          ),
        ),
        if (onShare != null)
          AuroraPressable(
            onTap: onShare,
            semanticLabel: 'Share',
            enforceTouchTarget: true,
            child: Icon(
              Icons.share_outlined,
              size: a.of(AuroraIconSizes.md),
              color: AuroraColors.ink,
            ),
          ),
        if (onEdit != null) ...[
          SizedBox(width: a.of(AuroraSpacing.space3)),
          AuroraPressable(
            onTap: onEdit,
            semanticLabel: 'Edit',
            enforceTouchTarget: true,
            child: Text('Edit', style: AuroraType.button),
          ),
        ],
      ],
    );
  }
}
