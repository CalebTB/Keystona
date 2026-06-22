import 'package:flutter/material.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';

class InsuranceEmptyState extends StatelessWidget {
  const InsuranceEmptyState({super.key, this.onAddPolicy});

  final VoidCallback? onAddPolicy;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AuroraSpacing.space10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 80,
              color: AuroraColors.inkSecondary,
            ),
            const SizedBox(height: AuroraSpacing.space7),
            Text(
              'No insurance info yet',
              style: AuroraType.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuroraSpacing.space3),
            Text(
              'Add your policy number and claims phone for quick access during emergencies.',
              style: AuroraType.body.copyWith(
                color: AuroraColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAddPolicy != null) ...[
              const SizedBox(height: AuroraSpacing.space9),
              GestureDetector(
                onTap: onAddPolicy,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AuroraSpacing.space9,
                    vertical: AuroraSpacing.space3,
                  ),
                  decoration: BoxDecoration(
                    color: AuroraColors.ink,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Add Policy',
                    style: AuroraType.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
