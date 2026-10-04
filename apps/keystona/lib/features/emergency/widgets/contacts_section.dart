import 'package:flutter/material.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../models/emergency_contact.dart';
import '../../../core/widgets/snackbar_service.dart';

/// Contacts preview section on the Emergency Hub main screen.
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
        Row(
          children: [
            Text(
              'Emergency Contacts',
              style: AuroraType.body.copyWith(fontWeight: FontWeight.w700, color: AuroraColors.ink),
            ),
            const Spacer(),
            if (totalCount > 0)
              GestureDetector(
                onTap: onSeeAll,
                child: Text(
                  'See all ($totalCount)',
                  style: AuroraType.bodySm.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AuroraColors.ink,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AuroraSpacing.space3),

        if (favorites.isEmpty)
          _EmptyContacts(onAdd: onAddContact)
        else ...[
          ...favorites.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: AuroraSpacing.space3),
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
        color: AuroraColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AuroraColors.inkBorder),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.space7,
        vertical: AuroraSpacing.space3,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AuroraColors.ink.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                contact.name.isNotEmpty
                    ? contact.name[0].toUpperCase()
                    : '?',
                style: AuroraType.body.copyWith(fontWeight: FontWeight.w700, color: AuroraColors.ink),
              ),
            ),
          ),
          const SizedBox(width: AuroraSpacing.space7),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: AuroraType.body.copyWith(fontWeight: FontWeight.w600, color: AuroraColors.ink),
                ),
                Text(
                  contact.is24x7
                      ? '${contact.category.categoryLabel} · 24/7'
                      : contact.category.categoryLabel,
                  style: AuroraType.bodySm.copyWith(
                    color: AuroraColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),

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
          color: AuroraColors.limeDeep.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.phone_outlined,
          size: 18,
          color: AuroraColors.limeDeep,
        ),
      ),
    );
  }

  Future<void> _call(BuildContext context) async {
    SnackbarService.showInfo(context, 'Calling $name — $phone');
  }
}

class _EmptyContacts extends StatelessWidget {
  const _EmptyContacts({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AuroraSpacing.space7),
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AuroraColors.inkBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.phone_outlined,
            size: 20,
            color: AuroraColors.inkSecondary,
          ),
          const SizedBox(width: AuroraSpacing.space3),
          Expanded(
            child: Text(
              'No emergency contacts yet',
              style: AuroraType.body.copyWith(
                color: AuroraColors.inkSecondary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: Text(
              '+ Add',
              style: AuroraType.bodySm.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AuroraColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
