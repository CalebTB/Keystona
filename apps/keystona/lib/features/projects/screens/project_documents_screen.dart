import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/placeholder_screen.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../providers/project_documents_provider.dart';
import '../widgets/document_link_picker_sheet.dart';
import '../widgets/documents/list/documents_list_skeleton.dart';
import '../widgets/documents/list/documents_vault_list_view.dart';
import '../widgets/documents/shared/documents_view_toggle.dart';

/// Documents sub-page for a single project.
///
/// Route: /projects/:projectId/documents
///
/// Wrapper that owns:
///   - View toggle state ('list' | 'byType')
///   - Link/unlink mutations (forwarded to [projectDocumentsProvider])
///   - Conditional ContractorFilterBanner
///     note: contractor query-param integration deferred; add when GoRouter
///     extra-params API is confirmed for this route.
///
/// Renders [DocumentsVaultListView] for 'list' view,
/// [PlaceholderScreen] for 'byType' (spec not yet written).
class ProjectDocumentsScreen extends ConsumerStatefulWidget {
  const ProjectDocumentsScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<ProjectDocumentsScreen> createState() =>
      _ProjectDocumentsScreenState();
}

class _ProjectDocumentsScreenState
    extends ConsumerState<ProjectDocumentsScreen> {
  /// 'list' | 'byType'
  String _activeView = 'list';

  // ── Link document ─────────────────────────────────────────────────────────

  Future<void> _onLink() async {
    final result = await showDocumentLinkPickerSheet(context);
    if (result == null) return;
    if (!mounted) return;

    final notifier =
        ref.read(projectDocumentsProvider(widget.projectId).notifier);
    try {
      await notifier.linkDocument(
        documentId: result.documentId,
        linkType: result.linkType,
      );
      if (!mounted) return;
      SnackbarService.showSuccess(context, 'Document linked.');
    } catch (_) {
      if (!mounted) return;
      SnackbarService.showError(context, 'Could not link document.');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final asyncLinks =
        ref.watch(projectDocumentsProvider(widget.projectId));
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    final body = asyncLinks.when(
      loading: () => const DocumentsListSkeleton(),
      error: (_, _) => _ErrorState(
        onRetry: () =>
            ref.invalidate(projectDocumentsProvider(widget.projectId)),
      ),
      data: (links) {
        if (links.isEmpty) {
          return _EmptyState(onLink: _onLink);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // View toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: DocumentsViewToggle(
                activeView: _activeView,
                onViewChanged: (v) => setState(() => _activeView = v),
              ),
            ),

            // note: ContractorFilterBanner deferred — needs contractor query
            // param passed via GoRouter extras; add when route is updated.

            // Active view
            Expanded(
              child: _activeView == 'list'
                  ? DocumentsVaultListView(
                      projectId: widget.projectId,
                      onLinkDocument: _onLink,
                    )
                  : const PlaceholderScreen(name: 'By Type View'),
            ),
          ],
        );
      },
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Documents'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _onLink,
            child: const Icon(CupertinoIcons.add),
          ),
        ),
        child: SafeArea(bottom: false, child: body),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: body,
      floatingActionButton: asyncLinks.value?.isNotEmpty == true
          ? FloatingActionButton(
              onPressed: _onLink,
              backgroundColor: AppColors.deepNavy,
              child: const Icon(Icons.link, color: Colors.white),
            )
          : null,
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
            const Icon(
              Icons.link_outlined,
              size: AppSizes.iconXl,
              color: AppColors.gray400,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'Link your project documents',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
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
            const Icon(
              Icons.error_outline,
              size: AppSizes.iconXl,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              "Couldn't load documents",
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.lg),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.deepNavy,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
