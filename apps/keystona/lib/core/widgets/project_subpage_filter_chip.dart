import 'package:flutter/material.dart';

import '../theme/aurora_colors.dart';
import '../theme/aurora_typography.dart';

/// Reusable filter chip for project sub-pages (Documents, Budget, etc.).
///
/// Visually consistent: ink fill when selected, outlined when unselected.
/// Matches the chip style used across the Projects feature.
class ProjectSubpageFilterChip extends StatelessWidget {
  const ProjectSubpageFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AuroraColors.ink : AuroraColors.paper,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AuroraColors.ink : const Color(0xFFE0DFEA),
          ),
        ),
        child: Text(
          label,
          style: AuroraType.bodySm.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AuroraColors.inkSecondary,
          ),
        ),
      ),
    );
  }
}
