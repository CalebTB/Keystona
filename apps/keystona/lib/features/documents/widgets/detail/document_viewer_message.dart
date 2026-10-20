import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';

/// Centered icon and one line on the ink media ground ("Preview not
/// available").
class DocumentViewerMessage extends StatelessWidget {
  const DocumentViewerMessage({
    super.key,
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Center(
      child: Padding(
        padding: a.all(AuroraSpacing.space7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: a.of(AuroraIconSizes.xl),
              color: AuroraOnInk.secondary,
            ),
            SizedBox(height: a.of(AuroraSpacing.space3)),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AuroraType.body.copyWith(color: AuroraOnInk.secondary),
            ),
          ],
        ),
      ),
    );
  }
}
