import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/project_document_link.dart';
import '../providers/project_documents_provider.dart';
import '../widgets/document_link_picker_sheet.dart';
import '../widgets/linked_documents_skeleton.dart';

/// Linked documents for a single project, grouped by link type.
///
/// Route: /projects/:projectId/documents
class ProjectDocumentsScreen extends ConsumerWidget {
  const ProjectDocumentsScreen({super.key, required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLinks = ref.watch(projectDocumentsProvider(projectId));
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    Future<void> onLink() async {
      final result = await showDocumentLinkPickerSheet(context);
      if (result == null) return;
      if (!context.mounted) return;
      try {
        await ref
            .read(projectDocumentsProvider(projectId).notifier)
            .linkDocument(
              documentId: result.documentId,
              linkType: result.linkType,
            );
        if (!context.mounted) return;
        SnackbarService.showSuccess(context, 'Document linked.');
      } catch (_) {
        if (!context.mounted) return;
        SnackbarService.showError(context, 'Could not link document.');
      }
    }

    final body = asyncLinks.when(
      loading: () => const LinkedDocumentsSkeleton(),
      error: (_, _) => _ErrorState(
        onRetry: () => ref.invalidate(projectDocumentsProvider(projectId)),
      ),
      data: (links) => links.isEmpty
          ? _EmptyState(onLink: onLink)
          : _LinkedList(links: links, projectId: projectId),
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Documents'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onLink,
            child: const Icon(CupertinoIcons.add),
          ),
        ),
        child: SafeArea(bottom: false, child: body),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: onLink,
        backgroundColor: AppColors.deepNavy,
        child: const Icon(Icons.link, color: Colors.white),
      ),
    );
  }
}

// ── Linked list ───────────────────────────────────────────────────────────────

class _LinkedList extends ConsumerWidget {
  const _LinkedList({required this.links, required this.projectId});
  final List<ProjectDocumentLink> links;
  final String projectId;

  Future<void> _unlink(
      BuildContext context, WidgetRef ref, ProjectDocumentLink link) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    bool confirmed = false;

    if (isIOS) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (dlg) => CupertinoAlertDialog(
          title: const Text('Unlink Document'),
          content: Text(
              'Remove "${link.documentName}" from this project? The document stays in your vault.'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(dlg).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                confirmed = true;
                Navigator.of(dlg).pop();
              },
              child: const Text('Unlink'),
            ),
          ],
        ),
      );
    } else {
      confirmed = await showDialog<bool>(
            context: context,
            builder: (dlg) => AlertDialog(
              title: const Text('Unlink Document'),
              content: Text(
                  'Remove "${link.documentName}" from this project?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dlg).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dlg).pop(true),
                  child: Text('Unlink',
                      style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          ) ??
          false;
    }

    if (!confirmed || !context.mounted) return;

    try {
      await ref
          .read(projectDocumentsProvider(projectId).notifier)
          .unlinkDocument(link.id);
      if (!context.mounted) return;
      SnackbarService.showSuccess(context, 'Document unlinked.');
    } catch (_) {
      if (!context.mounted) return;
      SnackbarService.showError(context, 'Could not unlink document.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Group by link type in the defined order.
    final grouped = <String, List<ProjectDocumentLink>>{};
    for (final link in links) {
      grouped.putIfAbsent(link.linkType, () => []).add(link);
    }

    final entries = DocumentLinkTypes.all
        .where((t) => grouped.containsKey(t.value))
        .map((t) => (type: t, links: grouped[t.value]!))
        .toList();

    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(projectDocumentsProvider(projectId).notifier).refresh(),
      child: ListView.builder(
        padding: AppPadding.screen,
        itemCount: entries.length,
        itemBuilder: (ctx, gi) {
          final entry = entries[gi];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (gi > 0) const SizedBox(height: AppSizes.md),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                child: Text(
                  entry.type.label,
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
              ...entry.links.map((link) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppSizes.sm),
                    child: Dismissible(
                      key: ValueKey(link.id),
                      direction: DismissDirection.endToStart,
                      background: _UnlinkBackground(),
                      confirmDismiss: (_) async {
                        await _unlink(ctx, ref, link);
                        return false;
                      },
                      child: _DocumentLinkCard(link: link),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _DocumentLinkCard extends StatelessWidget {
  const _DocumentLinkCard({required this.link});
  final ProjectDocumentLink link;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.documentDetail.replaceFirst(':documentId', link.documentId),
      ),
      child: Container(
      constraints:
          const BoxConstraints(minHeight: AppSizes.cardMinHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.deepNavy.withValues(alpha: 0.08),
              borderRadius:
                  BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: const Icon(Icons.description_outlined,
                color: AppColors.deepNavy, size: 20),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  link.documentName,
                  style: AppTextStyles.bodyMediumSemibold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (link.documentTypeName != null)
                  Text(
                    link.documentTypeName!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.xs),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.xs + 2, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.deepNavy.withValues(alpha: 0.08),
              borderRadius:
                  BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Text(
              DocumentLinkTypes.labelFor(link.linkType),
              style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.deepNavy, fontSize: 10),
            ),
          ),
        ],
      ),
    ));
  }
}

class _UnlinkBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: const Icon(Icons.link_off, color: Colors.white),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onLink});
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppPadding.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_outlined,
                size: AppSizes.iconXl, color: AppColors.gray400),
            const SizedBox(height: AppSizes.md),
            Text('Link your project documents',
                style: AppTextStyles.h3, textAlign: TextAlign.center),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Attach receipts, permits, contracts, and more from your Document Vault.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.xl),
            FilledButton(
              onPressed: onLink,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.deepNavy,
                padding: AppPadding.button,
              ),
              child: const Text('+ Link Document'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppPadding.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: AppSizes.iconXl, color: AppColors.error),
            const SizedBox(height: AppSizes.md),
            Text("Couldn't load documents",
                style: AppTextStyles.h3, textAlign: TextAlign.center),
            const SizedBox(height: AppSizes.lg),
            FilledButton(
              onPressed: onRetry,
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.deepNavy),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
