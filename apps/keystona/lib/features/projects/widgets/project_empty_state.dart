import 'package:flutter/material.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_radius.dart';


/// Empty state for the Projects tab — Pattern B: Showcase.
///
/// Shows two ghosted example project cards (50% opacity, non-interactive)
/// and a CTA button. Copy matches Empty States Catalog §2.4 exactly.
class ProjectEmptyState extends StatelessWidget {
  const ProjectEmptyState({super.key, required this.onCreateProject});

  final VoidCallback onCreateProject;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AuroraSpacing.screenPadH),
      child: Column(
        children: [
          const SizedBox(height: AuroraSpacing.space10),
          Text(
            'Organize renovations with phases, budgets, and before/after photos',
            style: AuroraType.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AuroraSpacing.space3),
          Text(
            'Track every project from planning to completion.',
            style: AuroraType.body.copyWith(
              color: AuroraColors.inkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AuroraSpacing.space10),

          // ── Ghosted example cards ──────────────────────────────────────
          Opacity(
            opacity: 0.5,
            child: Column(
              children: [
                _ExampleProjectCard(
                  emoji: '🛁',
                  name: 'Bathroom Renovation',
                  phases: 'Planning → Demo → Build',
                  progressFraction: 0.62,
                  progressLabel: '62%',
                  budget: '\$12,500',
                  status: 'In Progress',
                ),
                const SizedBox(height: AuroraSpacing.space3),
                _ExampleProjectCard(
                  emoji: '🪵',
                  name: 'Deck Build',
                  phases: 'Design → Permit → Build',
                  progressFraction: 0.28,
                  progressLabel: '28%',
                  budget: '\$8,200',
                  status: 'Planning',
                ),
              ],
            ),
          ),

          const SizedBox(height: AuroraSpacing.space10),
          FilledButton(
            onPressed: onCreateProject,
            style: FilledButton.styleFrom(
              backgroundColor: AuroraColors.yellow,
              foregroundColor: AuroraColors.paper,
              padding: const EdgeInsets.symmetric(
                horizontal: AuroraSpacing.space10,
                vertical: AuroraSpacing.space7,
              ),
            ),
            child: const Text('+ Start a Project'),
          ),
          const SizedBox(height: AuroraSpacing.space10),
        ],
      ),
    );
  }
}

class _ExampleProjectCard extends StatelessWidget {
  const _ExampleProjectCard({
    required this.emoji,
    required this.name,
    required this.phases,
    required this.progressFraction,
    required this.progressLabel,
    required this.budget,
    required this.status,
  });

  final String emoji;
  final String name;
  final String phases;
  final double progressFraction;
  final String progressLabel;
  final String budget;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AuroraSpacing.space7),
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.md,
        border: Border.all(color: const Color(0xFFEEEDF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: AuroraSpacing.space3),
              Expanded(
                child: Text(name, style: AuroraType.bodyLg.copyWith(fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AuroraSpacing.space3,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AuroraColors.ink.withValues(alpha: 0.1),
                  borderRadius:
                      AuroraRadius.full,
                ),
                child: Text(
                  status,
                  style: AuroraType.label.copyWith(
                    color: AuroraColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AuroraSpacing.space1),
          Text(
            phases,
            style: AuroraType.bodySm.copyWith(
              color: AuroraColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AuroraSpacing.space3),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      AuroraRadius.full,
                  child: LinearProgressIndicator(
                    value: progressFraction,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFEEEDF2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AuroraColors.ink),
                  ),
                ),
              ),
              const SizedBox(width: AuroraSpacing.space3),
              Text(
                progressLabel,
                style: AuroraType.label.copyWith(
                  color: AuroraColors.inkSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AuroraSpacing.space1),
          Text(
            'Budget: $budget',
            style: AuroraType.bodySm.copyWith(
              color: AuroraColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
