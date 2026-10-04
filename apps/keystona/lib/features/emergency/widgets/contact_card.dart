import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/emergency_contact.dart';
import '../providers/contacts_list_provider.dart';

/// A 60px-content-height row card for a single [EmergencyContact].
class ContactCard extends ConsumerWidget {
  const ContactCard({
    super.key,
    required this.contact,
    this.onTap,
  });

  final EmergencyContact contact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            _Avatar(name: contact.name, isFavorite: contact.isFavorite),
            const SizedBox(width: AuroraSpacing.space7),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    contact.name,
                    style: AuroraType.body.copyWith(fontWeight: FontWeight.w700, color: AuroraColors.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle,
                    style: AuroraType.bodySm.copyWith(
                      color: AuroraColors.inkSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AuroraSpacing.space3),

            _FavoriteButton(
              isFavorite: contact.isFavorite,
              onToggle: () => _toggleFavorite(context, ref),
            ),
            const SizedBox(width: AuroraSpacing.space1),

            _PhoneButton(
              phone: contact.phonePrimary,
              onCall: () => _call(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  String get _subtitle {
    final label = contact.category.categoryLabel;
    if (contact.companyName != null && contact.companyName!.isNotEmpty) {
      return '$label · ${contact.companyName}';
    }
    return label;
  }

  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(contactsListProvider.notifier);
    try {
      await notifier.updateContact(contact.id, {
        'is_favorite': !contact.isFavorite,
      });
    } catch (_) {
      if (context.mounted) {
        SnackbarService.showError(
          context,
          "Couldn't update favorite. Try again.",
        );
      }
    }
  }

  Future<void> _call(BuildContext context, WidgetRef ref) async {
    final uri = Uri(scheme: 'tel', path: contact.phonePrimary);
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        SnackbarService.showError(context, "Couldn't open phone dialer.");
      }
      return;
    }

    unawaited(
      ref
          .read(contactsListProvider.notifier)
          .updateContact(contact.id, {
            'times_used': contact.timesUsed + 1,
          })
          .catchError((_) {}),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.isFavorite});
  final String name;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isFavorite
            ? AuroraColors.yellow.withValues(alpha: 0.15)
            : AuroraColors.ink.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: AuroraType.body.copyWith(fontWeight: FontWeight.w700, color: isFavorite ? AuroraColors.yellowDeep : AuroraColors.ink),
        ),
      ),
    );
  }
}

// ── Favorite button ───────────────────────────────────────────────────────────

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.isFavorite,
    required this.onToggle,
  });
  final bool isFavorite;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(AuroraSpacing.space1),
        child: Icon(
          isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 22,
          color: isFavorite ? AuroraColors.yellow : AuroraColors.inkSecondary,
        ),
      ),
    );
  }
}

// ── Phone button ──────────────────────────────────────────────────────────────

class _PhoneButton extends StatelessWidget {
  const _PhoneButton({required this.phone, required this.onCall});
  final String phone;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCall,
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
}
