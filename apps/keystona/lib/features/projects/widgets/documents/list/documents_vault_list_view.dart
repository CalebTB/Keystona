import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../models/project_document_link.dart';
import '../../../providers/project_documents_provider.dart';
import '../shared/document_link_type.dart';
import 'document_list_row.dart';
import 'documents_list_filter_chips.dart';
import 'documents_summary_banner.dart';

/// Full vault list view for linked project documents.
///
/// Contains eyebrow + heading, summary banner, filter chips, and row list.
/// Reads from [projectDocumentsProvider]. State (active filter, expiring toggle)
/// is owned by this widget.
class DocumentsVaultListView extends ConsumerStatefulWidget {
  const DocumentsVaultListView({
    super.key,
    required this.projectId,
    required this.onLinkDocument,
    this.filterContactId,
  });

  final String projectId;
  final VoidCallback onLinkDocument;

  /// When set, only rows with a matching [ProjectDocumentLink.contactId] are shown.
  final String? filterContactId;

  @override
  ConsumerState<DocumentsVaultListView> createState() =>
      _DocumentsVaultListViewState();
}

class _DocumentsVaultListViewState
    extends ConsumerState<DocumentsVaultListView> {
  DocumentLinkType? _activeFilter;
  bool _showExpiringOnly = false;

  @override
  Widget build(BuildContext context) {
    final asyncLinks =
        ref.watch(projectDocumentsProvider(widget.projectId));

    return asyncLinks.when(
      loading: () => const _LoadingIndicator(),
      error: (_, _) => const SizedBox.shrink(), // parent handles error state
      data: (links) => _buildContent(links),
    );
  }

  Widget _buildContent(List<ProjectDocumentLink> links) {
    // Apply contractor filter first (from screen-level param).
    final base = widget.filterContactId != null
        ? links.where((l) => l.contactId == widget.filterContactId).toList()
        : links;

    // Show empty state immediately when contractor filter yields nothing.
    if (widget.filterContactId != null && base.isEmpty) {
      return _ContractorNoDocsState(
        onRefresh: () => ref
            .read(projectDocumentsProvider(widget.projectId).notifier)
            .refresh(),
      );
    }

    // Apply link-type chip filter on top.
    var filtered = _activeFilter == null
        ? base
        : base.where((l) => l.linkType == _activeFilter!.name).toList();

    // Expiring filter (no expirationDate on current model — no-op)
    // note: implement when model gains expirationDate field

    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(projectDocumentsProvider(widget.projectId).notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Eyebrow
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF7A8C56), // olive
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'linked from vault',
                        style: TextStyle(
                          fontFamily: 'IBMPlexMono',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Heading: "Paper trail"
                  Text(
                    'Paper trail',
                    style: GoogleFonts.fraunces(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Summary banner
                  DocumentsSummaryBanner(
                    links: links,
                    showExpiringOnly: _showExpiringOnly,
                    onExpiringToggle: () =>
                        setState(() => _showExpiringOnly = !_showExpiringOnly),
                  ),

                  // Filter chips
                  DocumentsListFilterChips(
                    links: links,
                    activeFilter: _activeFilter,
                    onFilterChanged: (t) =>
                        setState(() => _activeFilter = t),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Document rows
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: filtered.isEmpty
                ? SliverToBoxAdapter(
                    child: _NoFilterResults(
                      onClear: () =>
                          setState(() => _activeFilter = null),
                    ),
                  )
                : SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 6),
                    itemBuilder: (ctx, i) {
                      final link = filtered[i];
                      return DocumentListRow(
                        link: link,
                        onTap: () => ctx.push(
                          AppRoutes.documentDetail.replaceFirst(
                            ':documentId',
                            link.documentId,
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Add dashed card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: GestureDetector(
                onTap: widget.onLinkDocument,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.gray400,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                  child: _DashedBorderCard(onTap: widget.onLinkDocument),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small loading indicator while vault reloads on filter change.
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

/// Shown when filter chips produce 0 results.
class _NoFilterResults extends StatelessWidget {
  const _NoFilterResults({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.filter_list_off,
            size: AppSizes.iconXl,
            color: AppColors.gray400,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'No documents match this filter',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizes.sm),
          TextButton(
            onPressed: onClear,
            child: Text(
              'Clear filter',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.deepNavy),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when a contractor filter is active but that contractor has no linked docs.
class _ContractorNoDocsState extends StatelessWidget {
  const _ContractorNoDocsState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 48,
                    color: AppColors.gray400,
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'No documents linked to this contractor yet.',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    'Link a document and assign it to this contractor to see it here.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.gray400),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed "Link a document" add card — visually distinct from regular rows.
class _DashedBorderCard extends StatelessWidget {
  const _DashedBorderCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.link_outlined,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          'Link a document',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
