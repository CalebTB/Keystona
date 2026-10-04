import 'package:flutter/material.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';

/// Empty state shown when a document search returns no results.
///
/// Instructional variant (C) — Magnifying glass icon, 64px.
/// Copy: "No results found" / "Try a different search term or browse by category."
class DocumentSearchEmptyState extends StatelessWidget {
  const DocumentSearchEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AuroraSpacing.screenPadH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AuroraColors.inkTertiary,
            ),
            const SizedBox(height: AuroraSpacing.space5),
            Text(
              'No results found',
              style: AuroraType.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuroraSpacing.space3),
            Text(
              'Try a different search term or browse by category.',
              style: AuroraType.body.copyWith(color: AuroraColors.inkSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
