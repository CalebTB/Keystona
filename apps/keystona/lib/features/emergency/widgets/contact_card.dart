import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/emergency_contact.dart';
import '../providers/contacts_list_provider.dart';

/// A 60px-content-height row card for a single [EmergencyContact].
///
/// Displays:
///   - Circle avatar with first initial
///   - Name (bold), category label, company name
///   - Favorite star toggle (calls updateContact)
///   - Phone call button (launches tel: URI, then increments times_used)
class ContactCard extends ConsumerWidget {
  const ContactCard({
    super.key,
    required this.contact,
    this.onTap,
  });

  final EmergencyContact contact;

  /// Optional tap callback — used by the list screen to navigate to edit form.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            // Circle avatar with first initial.
            _Avatar(name: contact.name, isFavorite: contact.isFavorite),
            const SizedBox(width: AppSizes.md),

            // Name + category + company.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    contact.name,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm),

            // Favorite star toggle.
            _FavoriteButton(
              isFavorite: contact.isFavorite,
              onToggle: () => _toggleFavorite(context, ref),
            ),
            const SizedBox(width: AppSizes.xs),

            // Phone call button.
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

    // Fire-and-forget: increment times_used after a successful call launch.
    // Non-fatal if it fails.
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
            ? AppColors.goldAccent.withValues(alpha: 0.15)
            : AppColors.deepNavy.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: AppTextStyles.labelLarge.copyWith(
            color: isFavorite ? AppColors.goldAccent : AppColors.deepNavy,
            fontWeight: FontWeight.w700,
          ),
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
        padding: const EdgeInsets.all(AppSizes.xs),
        child: Icon(
          isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 22,
          color: isFavorite ? AppColors.goldAccent : AppColors.gray400,
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
          color: AppColors.healthGood.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.phone_outlined,
          size: 18,
          color: AppColors.healthGood,
        ),
      ),
    );
  }
}
