import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';

/// Empty state shown when the user has no emergency contacts yet.
///
/// Copy: "Add your emergency contacts"
/// Subtitle: "Save your plumbers, electricians, and other contractors
///            so they're ready when you need them."
class ContactsEmptyState extends StatelessWidget {
  const ContactsEmptyState({super.key, required this.onAddContact});

  final VoidCallback onAddContact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSizes.iconXl + AppSizes.xl,
              height: AppSizes.iconXl + AppSizes.xl,
              decoration: BoxDecoration(
                color: AppColors.deepNavy.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.contacts_outlined,
                size: AppSizes.iconXl,
                color: AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              'Add your emergency contacts',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Save your plumbers, electricians, and other contractors so they\'re ready when you need them.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.xl),
            FilledButton.icon(
              onPressed: onAddContact,
              icon: const Icon(Icons.add, size: AppSizes.iconSm),
              label: const Text('Add Contact'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.deepNavy,
                foregroundColor: AppColors.textInverse,
                minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
