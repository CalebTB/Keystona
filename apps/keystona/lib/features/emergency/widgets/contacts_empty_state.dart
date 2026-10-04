import 'package:flutter/material.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/theme/aurora_radius.dart';

/// Empty state shown when the user has no emergency contacts yet.
class ContactsEmptyState extends StatelessWidget {
  const ContactsEmptyState({super.key, required this.onAddContact});

  final VoidCallback onAddContact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AuroraSpacing.space10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AuroraColors.ink.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.contacts_outlined,
                size: 40,
                color: AuroraColors.ink,
              ),
            ),
            const SizedBox(height: AuroraSpacing.space9),
            Text(
              'Add your emergency contacts',
              style: AuroraType.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuroraSpacing.space3),
            Text(
              'Save your plumbers, electricians, and other contractors so they\'re ready when you need them.',
              style: AuroraType.body.copyWith(
                color: AuroraColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuroraSpacing.space10),
            GestureDetector(
              onTap: onAddContact,
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: AuroraColors.ink,
                  borderRadius: AuroraRadius.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, size: 16, color: AuroraColors.paper),
                    const SizedBox(width: 6),
                    Text(
                      'Add Contact',
                      style: AuroraType.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AuroraColors.paper,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
