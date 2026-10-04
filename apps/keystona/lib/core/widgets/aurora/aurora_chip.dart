import 'package:flutter/material.dart';

import '../../theme/aurora_colors.dart';
import '../../theme/aurora_radius.dart';
import '../../theme/aurora_typography.dart';

/// Status chip — JetBrains Mono, 9px, uppercase, 4px radius.
///
/// Text is ALWAYS rendered uppercase — call [label.toUpperCase()] is done
/// internally. Background + text color come from the status pair:
///
///   Overdue:   coralDim bg / coralDeep text
///   Due soon:  yellowDim bg / yellowDeep text
///   Scheduled: cobaltDim bg / cobaltDeep text
///   Done:      limeDim bg / limeDeep text
///
/// Pass [background] and [foreground] directly for custom states.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  // ── Named constructors for common states ────────────────────────────────────

  const StatusChip.overdue({super.key, required this.label})
      : background = AuroraColors.coralDim,
        foreground = AuroraColors.coralDeep;

  const StatusChip.dueSoon({super.key, required this.label})
      : background = AuroraColors.yellowDim,
        foreground = AuroraColors.yellowDeep;

  const StatusChip.scheduled({super.key, required this.label})
      : background = AuroraColors.cobaltDim,
        foreground = AuroraColors.cobaltDeep;

  const StatusChip.done({super.key, required this.label})
      : background = AuroraColors.limeDim,
        foreground = AuroraColors.limeDeep;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AuroraRadius.xs,
      ),
      child: Text(
        label.toUpperCase(),
        style: AuroraType.labelSm.copyWith(color: foreground),
      ),
    );
  }
}

/// Filter pill — default: paper bg + inkBorder; active: ink bg + white text.
///
/// Displays an optional count number in mono after the label.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AuroraColors.ink : AuroraColors.paper;
    final fg = selected ? Colors.white : AuroraColors.ink;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AuroraRadius.full,
          border: selected
              ? null
              : Border.all(color: AuroraColors.inkBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: fg,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
