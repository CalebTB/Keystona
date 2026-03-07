import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/emergency_contact.dart';
import '../providers/contacts_list_provider.dart';
import '../widgets/contact_card.dart';
import '../widgets/contacts_empty_state.dart';
import '../widgets/contacts_list_skeleton.dart';

/// Full contact list screen — accessible from the Emergency Hub "See all" link.
///
/// Adaptive layout:
///   iOS  → CupertinoPageScaffold + CupertinoSliverNavigationBar + Stack FAB
///   Android → Scaffold + SliverAppBar + floatingActionButton
///
/// Features:
///   - Skeleton loading on frame 1
///   - Pull-to-refresh
///   - Swipe-to-delete with confirmation
///   - FAB navigates to [ContactFormScreen] in create mode
///   - Tap on card navigates to [ContactFormScreen] in edit mode
class ContactsListScreen extends ConsumerWidget {
  const ContactsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return isIOS ? const _IOSLayout() : const _AndroidLayout();
  }
}

// ── iOS layout ────────────────────────────────────────────────────────────────

class _IOSLayout extends ConsumerWidget {
  const _IOSLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              const CupertinoSliverNavigationBar(
                largeTitle: Text('Contacts'),
              ),
              CupertinoSliverRefreshControl(
                onRefresh: () =>
                    ref.read(contactsListProvider.notifier).refresh(),
              ),
              const _ContactsSliver(),
              // Extra bottom padding so FAB doesn't overlap the last card.
              const SliverToBoxAdapter(child: SizedBox(height: 88)),
            ],
          ),
          const Positioned(
            right: AppSizes.lg,
            bottom: AppSizes.xl,
            child: _AddContactFAB(),
          ),
        ],
      ),
    );
  }
}

// ── Android layout ────────────────────────────────────────────────────────────

class _AndroidLayout extends ConsumerWidget {
  const _AndroidLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      floatingActionButton: const _AddContactFAB(),
      body: RefreshIndicator(
        color: AppColors.deepNavy,
        onRefresh: () => ref.read(contactsListProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text('Contacts', style: AppTextStyles.h3),
              floating: true,
              backgroundColor: AppColors.warmOffWhite,
              scrolledUnderElevation: 0,
              elevation: 0,
            ),
            const _ContactsSliver(),
            const SliverToBoxAdapter(child: SizedBox(height: AppSizes.xl)),
          ],
        ),
      ),
    );
  }
}

// ── Content sliver ────────────────────────────────────────────────────────────

class _ContactsSliver extends ConsumerWidget {
  const _ContactsSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsListProvider);

    return contactsAsync.when(
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: ContactsListSkeleton(),
      ),
      error: (error, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorView(
          message: "Couldn't load contacts.",
          onRetry: () => ref.read(contactsListProvider.notifier).refresh(),
        ),
      ),
      data: (contacts) => contacts.isEmpty
          ? SliverFillRemaining(
              hasScrollBody: false,
              child: ContactsEmptyState(
                onAddContact: () =>
                    context.push(AppRoutes.emergencyContactsAdd),
              ),
            )
          : SliverPadding(
              padding: AppPadding.screen,
              sliver: SliverList.builder(
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppSizes.sm),
                    child: _DismissibleContactCard(
                      contact: contact,
                      onTap: () => context.push(
                        AppRoutes.emergencyContactsAdd,
                        extra: contact,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ── Dismissible wrapper ───────────────────────────────────────────────────────

class _DismissibleContactCard extends ConsumerWidget {
  const _DismissibleContactCard({
    required this.contact,
    required this.onTap,
  });

  final EmergencyContact contact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(contact.id),
      direction: DismissDirection.endToStart,
      background: _DeleteBackground(),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => _delete(context, ref),
      child: ContactCard(contact: contact, onTap: onTap),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      return showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Delete Contact?'),
          content: Text(
            'Remove ${contact.name} from your contacts? This cannot be undone.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    } else {
      return showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Contact?'),
          content: Text(
            'Remove ${contact.name} from your contacts? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(contactsListProvider.notifier);
    try {
      await notifier.deleteContact(contact.id);
      if (context.mounted) {
        SnackbarService.showSuccess(context, '${contact.name} removed.');
      }
    } catch (_) {
      if (context.mounted) {
        SnackbarService.showError(
          context,
          "Couldn't delete contact. Try again.",
        );
      }
    }
  }
}

class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: const Icon(
        Icons.delete_outline,
        color: AppColors.textInverse,
        size: AppSizes.iconMd,
      ),
    );
  }
}

// ── FAB ───────────────────────────────────────────────────────────────────────

class _AddContactFAB extends StatelessWidget {
  const _AddContactFAB();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => context.push(AppRoutes.emergencyContactsAdd),
      backgroundColor: AppColors.deepNavy,
      foregroundColor: AppColors.textInverse,
      child: const Icon(Icons.add),
    );
  }
}
