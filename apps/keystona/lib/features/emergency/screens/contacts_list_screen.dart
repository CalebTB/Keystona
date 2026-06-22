import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/emergency_contact.dart';
import '../providers/contacts_list_provider.dart';
import '../widgets/contact_card.dart';
import '../widgets/contacts_empty_state.dart';
import '../widgets/contacts_list_skeleton.dart';

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
              const SliverToBoxAdapter(child: SizedBox(height: 88)),
            ],
          ),
          Positioned(
            right: AuroraSpacing.space9,
            bottom: AuroraSpacing.space10,
            child: const _AddContactFAB(),
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
      backgroundColor: AuroraColors.paper,
      floatingActionButton: const _AddContactFAB(),
      body: RefreshIndicator(
        color: AuroraColors.ink,
        onRefresh: () => ref.read(contactsListProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text('Contacts', style: AuroraType.h3),
              floating: true,
              backgroundColor: AuroraColors.paper,
              scrolledUnderElevation: 0,
              elevation: 0,
            ),
            const _ContactsSliver(),
            const SliverToBoxAdapter(
                child: SizedBox(height: AuroraSpacing.space10)),
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
      error: (_, _) => SliverFillRemaining(
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
              padding: const EdgeInsets.all(AuroraSpacing.screenPadH),
              sliver: SliverList.builder(
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: AuroraSpacing.space3),
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
                foregroundColor: AuroraColors.coral,
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
      padding: const EdgeInsets.only(right: AuroraSpacing.space9),
      decoration: BoxDecoration(
        color: AuroraColors.coral,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.delete_outline,
        color: Colors.white,
        size: 24,
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
      backgroundColor: AuroraColors.ink,
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
    );
  }
}
