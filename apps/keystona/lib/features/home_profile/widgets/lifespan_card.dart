import 'package:flutter/material.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';




import '../models/system_lifespan_entry.dart';
import '../../../core/theme/aurora_radius.dart';

/// Card displaying lifespan data for a single system.
///
/// Layout:
///   - Name + health status chip (row)
///   - Color-coded progress bar (full width)
///   - Age label (left) + years-remaining label (right)
///   - Estimated replacement cost (if available)
class LifespanCard extends StatelessWidget {
  const LifespanCard({super.key, required this.entry});

  final SystemLifespanEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AuroraSpacing.space5),
      decoration: BoxDecoration(
        color: entry.isEndOfLife ? AuroraColors.coralDim : AuroraColors.paper,
        borderRadius: AuroraRadius.lg,
        border: Border.all(
          color: entry.isEndOfLife
              ? AuroraColors.coral.withValues(alpha: 0.20)
              : AuroraColors.inkBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Name + health chip ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.name,
                  style: AuroraType.bodyLg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AuroraSpacing.space3),
              _HealthChip(entry: entry),
            ],
          ),
          const SizedBox(height: AuroraSpacing.space3),

          // ── Progress bar ────────────────────────────────────────────────
          _LifespanBar(entry: entry),
          const SizedBox(height: AuroraSpacing.space1),

          // ── Age / years remaining ───────────────────────────────────────
          Row(
            children: [
              Text(
                _ageLabel(entry),
                style: AuroraType.bodySm.copyWith(
                  color: AuroraColors.inkSecondary,
                ),
              ),
              const Spacer(),
              if (!entry.isUnknown)
                Text(
                  _yearsRemainingLabel(entry),
                  style: AuroraType.bodySm.copyWith(
                    color: entry.isEndOfLife
                        ? AuroraColors.coral
                        : AuroraColors.inkSecondary,
                  ),
                ),
            ],
          ),

          // ── Replacement cost ────────────────────────────────────────────
          if (entry.estimatedReplacementCost != null) ...[
            const SizedBox(height: AuroraSpacing.space1),
            Text(
              'Est. replacement: \$${_formatCost(entry.estimatedReplacementCost!)}',
              style: AuroraType.bodySm.copyWith(
                color: AuroraColors.inkSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _ageLabel(SystemLifespanEntry e) {
    if (e.ageYears == null) return 'Unknown age';
    final years = e.ageYears!.toStringAsFixed(1);
    return '$years yrs old';
  }

  String _yearsRemainingLabel(SystemLifespanEntry e) {
    if (e.isEndOfLife) return 'Past expected lifespan';
    final min = e.yearsUntilReplacementMin;
    final max = e.yearsUntilReplacementMax;
    if (min == null || max == null) return '';
    if (min.round() == max.round()) {
      return '~${min.round()} yrs remaining';
    }
    return '${min.round()}–${max.round()} yrs remaining';
  }

  String _formatCost(double cost) {
    if (cost >= 1000) {
      return '${(cost / 1000).toStringAsFixed(1)}k';
    }
    return cost.toStringAsFixed(0);
  }
}

// ── Progress bar ─────────────────────────────────────────────────────────────

class _LifespanBar extends StatelessWidget {
  const _LifespanBar({required this.entry});

  final SystemLifespanEntry entry;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AuroraRadius.full,
      child: LinearProgressIndicator(
        value: entry.isUnknown ? 0.0 : entry.barFraction,
        minHeight: 8,
        backgroundColor: AuroraColors.inkBorder,
        valueColor: AlwaysStoppedAnimation<Color>(
          entry.isUnknown ? AuroraColors.inkBorder : entry.healthColor,
        ),
      ),
    );
  }
}

// ── Health chip ───────────────────────────────────────────────────────────────

class _HealthChip extends StatelessWidget {
  const _HealthChip({required this.entry});

  final SystemLifespanEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.space3,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: entry.healthColor.withValues(alpha: 0.12),
        borderRadius: AuroraRadius.full,
      ),
      child: Text(
        entry.healthLabel,
        style: AuroraType.labelSm.copyWith(color: entry.healthColor),
      ),
    );
  }
}
