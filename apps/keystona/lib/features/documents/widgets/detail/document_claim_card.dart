import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_c.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// "Start a claim": a cobalt-outlined card that calls the provider found in
/// the document.
class DocumentClaimCard extends StatelessWidget {
  const DocumentClaimCard({
    super.key,
    required this.detail,
    required this.onTap,
  });

  /// Uppercase second line: "NORTHLINE · 1-800-555-0142 · FROM PAGE 3".
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final circle = a.of(AuroraDocsCSizes.claimIconCircle);
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: 'Start a claim',
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraDocsCSizes.claimMinHeight),
        ),
        padding: a.symmetric(
          horizontal: AuroraSpacing.space6,
          vertical: AuroraSpacing.space5,
        ),
        decoration: BoxDecoration(
          borderRadius: AuroraRadius.xl,
          border: Border.all(
            color: AuroraColors.cobalt,
            width: AuroraBorders.emphasis,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: circle,
              height: circle,
              decoration: const BoxDecoration(
                color: AuroraColors.cobalt,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.phone_outlined,
                size: a.of(AuroraIconSizes.sm),
                color: AuroraColors.paper,
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space5)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start a claim', style: AuroraType.h3),
                  SizedBox(height: a.of(AuroraSpacing.space1)),
                  Text(detail, style: AuroraType.meta),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
