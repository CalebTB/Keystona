import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_a.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../docs_copy.dart';

/// Docs tab header: plan eyebrow, "Documents", an optional subtitle and, when
/// [onAdd] is given, the outlined "+" button.
class DocsHeader extends StatelessWidget {
  const DocsHeader({
    super.key,
    required this.eyebrow,
    this.subtitle,
    this.onAdd,
  });

  final String eyebrow;
  final String? subtitle;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow, style: AuroraType.label),
              SizedBox(height: a.of(AuroraSpacing.space2)),
              Text(DocsCopy.title, style: AuroraType.h1),
              if (subtitle != null) ...[
                SizedBox(height: a.of(AuroraSpacing.space2)),
                Text(subtitle!, style: AuroraDocsAType.subtitle),
              ],
            ],
          ),
        ),
        if (onAdd != null) ...[
          SizedBox(width: a.of(AuroraSpacing.space5)),
          _AddButton(onTap: onAdd!),
        ],
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: DocsCopy.addSemantics,
      child: Container(
        width: AuroraSizes.minTouch,
        height: AuroraSizes.minTouch,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AuroraColors.inkBorder,
            width: AuroraBorders.regular,
          ),
        ),
        child: Icon(
          Icons.add,
          size: a.of(AuroraIconSizes.md),
          color: AuroraColors.ink,
        ),
      ),
    );
  }
}
