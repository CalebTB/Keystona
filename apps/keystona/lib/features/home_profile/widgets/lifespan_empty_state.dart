import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';

import '../../../core/router/app_router.dart';




/// Empty state for the Lifespan screen when the user has no systems.
///
/// Pattern A — Motivational (Combined).
/// Copy matches Empty States Catalog §3.3 exactly.
class LifespanEmptyState extends StatelessWidget {
  const LifespanEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AuroraSpacing.screenPadH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 120px icon — Deep Navy.
            Icon(
              Icons.home_repair_service_outlined,
              size: 120,
              color: AuroraColors.ink,
            ),
            const SizedBox(height: AuroraSpacing.space7),
            Text(
              'Add your home\'s systems',
              style: AuroraType.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuroraSpacing.space3),
            Text(
              'Systems are the major components of your home — HVAC, plumbing, '
              'electrical, roofing, and more. Adding them unlocks personalized '
              'maintenance tasks and lifespan tracking.',
              style: AuroraType.body.copyWith(
                color: AuroraColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuroraSpacing.space8),
            FilledButton(
              onPressed: () => context.push(AppRoutes.homeSystemsAdd),
              style: FilledButton.styleFrom(
                backgroundColor: AuroraColors.yellow,
                foregroundColor: AuroraColors.paper,
                padding: const EdgeInsets.symmetric(
                  horizontal: AuroraSpacing.space8,
                  vertical: AuroraSpacing.space5,
                ),
              ),
              child: const Text('+ Add First System'),
            ),
          ],
        ),
      ),
    );
  }
}
