import 'package:flutter/material.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';





class AppliancesEmptyState extends StatelessWidget {
  const AppliancesEmptyState({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AuroraSpacing.screenPadH),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.kitchen_outlined,
              size: 120,
              color: AuroraColors.ink.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AuroraSpacing.space7),
            Text(
              'Add your appliances',
              style: AuroraType.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuroraSpacing.space3),
            Text(
              'Track your refrigerator, washer, dishwasher, and other appliances to stay on top of warranties and maintenance.',
              style: AuroraType.body
                  .copyWith(color: AuroraColors.inkSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuroraSpacing.space8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AuroraColors.ink,
                foregroundColor: AuroraColors.paper,
                padding: const EdgeInsets.symmetric(
                  horizontal: AuroraSpacing.space7,
                  vertical: AuroraSpacing.space5,
                ),
              ),
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add First Appliance'),
            ),
          ],
        ),
      ),
    );
  }
}
