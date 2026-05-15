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
  const ProjectDocumentsScreen({
    super.key,
    required this.projectId,
    this.contractorId,
    this.contractorName,
  });

  final String projectId;
  final String? contractorId;
  final String? contractorName;

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
      data: (allLinks) {
        // Apply contractor filter if active.
        final contractorId = widget.contractorId;
        final links = contractorId != null
            ? allLinks.where((l) => l.contactId == contractorId).toList()
            : allLinks;

        if (allLinks.isEmpty) {
          return _EmptyState(onLink: _onLink);
        }

        if (contractorId != null && links.isEmpty) {
          return _ContractorEmptyState(
            contractorName: widget.contractorName ?? 'this contractor',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contractor filter banner
            if (contractorId != null)
              _ContractorBanner(name: widget.contractorName ?? 'Contractor'),

            // View toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: DocumentsViewToggle(
                activeView: _activeView,
                onViewChanged: (v) => setState(() => _activeView = v),
              ),
            ),

            // Active view
            Expanded(
              child: _activeView == 'list'
                  ? DocumentsVaultListView(
                      projectId: widget.projectId,
                      onLinkDocument: _onLink,
                      filterContactId: contractorId,
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

// ── Contractor filter banner ──────────────────────────────────────────────────

class _ContractorBanner extends StatelessWidget {
  const _ContractorBanner({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.deepNavy.withValues(alpha: 0.07),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 14, color: AppColors.deepNavy),
          const SizedBox(width: 6),
          Text(
            'Filtered by $name',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.deepNavy,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contractor empty state ────────────────────────────────────────────────────

class _ContractorEmptyState extends StatelessWidget {
  const _ContractorEmptyState({required this.contractorName});

  final String contractorName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppPadding.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_outlined,
                size: AppSizes.iconXl, color: AppColors.gray400),
            const SizedBox(height: AppSizes.md),
            Text(
              'No documents linked to $contractorName yet.',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Link a document and assign it to this contractor.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
