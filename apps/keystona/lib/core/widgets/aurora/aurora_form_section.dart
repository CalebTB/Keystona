import 'package:flutter/material.dart';

import '../../theme/aurora_colors.dart';
import '../../theme/aurora_spacing.dart';
import '../../theme/aurora_typography.dart';

/// A labeled form section with a cobalt dot eyebrow and optional OPTIONAL tag.
///
/// Renders: [● TITLE]  [OPTIONAL?]
/// followed by its children with space3 (8px) gaps between them.
///
/// Outer top padding is space8 (20px) so sections breathe on a form screen.
class AuroraFormSection extends StatelessWidget {
  const AuroraFormSection({
    super.key,
    required this.title,
    required this.children,
    this.isOptional = false,
  });

  final String title;
  final bool isOptional;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AuroraSpacing.space8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Eyebrow header ────────────────────────────────────────────────
          Row(
            children: [
              // Cobalt 7×7 dot — signals this is an action/form surface.
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AuroraColors.cobalt,
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: AuroraType.label.copyWith(
                  color: AuroraColors.inkSecondary,
                ),
              ),
              if (isOptional) ...[
                const Spacer(),
                Text(
                  'OPTIONAL',
                  style: AuroraType.labelSm.copyWith(
                    color: AuroraColors.inkTertiary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AuroraSpacing.space3),
          // ── Fields with uniform gap ───────────────────────────────────────
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const SizedBox(height: AuroraSpacing.space3),
          ],
        ],
      ),
    );
  }
}
