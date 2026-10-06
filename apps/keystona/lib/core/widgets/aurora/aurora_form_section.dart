import 'package:flutter/material.dart';

import '../../theme/aurora_colors.dart';
import '../../theme/aurora_radius.dart';
import '../../theme/aurora_scale.dart';
import '../../theme/aurora_sizes.dart';
import '../../theme/aurora_spacing.dart';
import '../../theme/aurora_typography.dart';

/// A labeled form section: cobalt dot, ink 10/600 uppercase title, optional
/// OPTIONAL tag on the right, then its children 14 pt apart.
///
/// Sections are separated by 26 pt (applied as top padding).
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
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.space6));
    return Padding(
      padding: EdgeInsets.only(top: a.of(AuroraSpacing.formSection)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: a.of(AuroraSizes.sectionDot),
                height: a.of(AuroraSizes.sectionDot),
                decoration: const BoxDecoration(
                  color: AuroraColors.cobalt,
                  borderRadius: AuroraRadius.full,
                ),
              ),
              SizedBox(width: a.of(AuroraSpacing.space2)),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title.toUpperCase(),
                    style: AuroraType.sectionTitle,
                  ),
                ),
              ),
              if (isOptional) ...[
                SizedBox(width: a.of(AuroraSpacing.space3)),
                Text('OPTIONAL', style: AuroraType.label),
              ],
            ],
          ),
          for (final child in children) ...[gap, child],
        ],
      ),
    );
  }
}
