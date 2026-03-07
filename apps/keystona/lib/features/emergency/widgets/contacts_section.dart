import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/emergency_contact.dart';

/// Contacts preview section on the Emergency Hub main screen.
///
/// Shows up to 3 favorite contacts with tap-to-call.
/// Full contact list + CRUD implemented by [#46 Emergency Contacts].
class ContactsSection extends StatelessWidget {
  const ContactsSection({
    super.key,
    required this.favorites,
    required this.totalCount,
    required this.onSeeAll,
    required this.onAddContact,
  });

  final List<EmergencyContact> favorites;
  final int totalCount;
  final VoidCallback onSeeAll;
  final VoidCallback onAddContact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header.
        Row(
          children: [
            Text(
              'Emergency Contacts',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (totalCount > 0)
              GestureDetector(
                onTap: onSeeAll,
                child: Text(
                  'See all ($totalCount)',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.deepNavy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),

        if (favorites.isEmpty)
          _EmptyContacts(onAdd: onAddContact)
        else ...[
          ...favorites.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                child: _ContactRow(contact: c),
              )),
        ],
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.contact});
  final EmergencyContact contact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      child: Row(
        children: [
          // Avatar circle with initial.
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.deepNavy.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                contact.name.isNotEmpty
                    ? contact.name[0].toUpperCase()
                    : '?',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.deepNavy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.md),

          // Name + category.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  contact.is24x7
                      ? '${contact.category.categoryLabel} · 24/7'
                      : contact.category.categoryLabel,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Call button.
          _CallButton(phone: contact.phonePrimary, name: contact.name),
        ],
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.phone, required this.name});
  final String phone;
  final String name;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _call(context),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.healthGood.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.phone_outlined,
          size: 18,
          color: AppColors.healthGood,
        ),
      ),
    );
  }

  Future<void> _call(BuildContext context) async {
    // [#46] Full tap-to-call with url_launcher implemented in Emergency Contacts.
    // For now, show a placeholder snackbar.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling $name — $phone')),
    );
  }
}

class _EmptyContacts extends StatelessWidget {
  const _EmptyContacts({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.phone_outlined,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              'No emergency contacts yet',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: Text(
              '+ Add',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.deepNavy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
