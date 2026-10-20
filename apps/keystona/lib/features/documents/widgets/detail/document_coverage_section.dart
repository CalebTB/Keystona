import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../models/coverage_info.dart';
import '../shared/docs_section_header.dart';
import 'document_coverage_card.dart';

/// "Coverage" eyebrow above the [DocumentCoverageCard].
class DocumentCoverageSection extends StatelessWidget {
  const DocumentCoverageSection({super.key, required this.coverage});

  final CoverageInfo coverage;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DocsSectionHeader(title: 'Coverage'),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        DocumentCoverageCard(coverage: coverage),
      ],
    );
  }
}
