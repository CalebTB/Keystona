import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../models/project_document_link.dart';
import '../shared/document_link_type.dart';
import '../shared/file_type_icon_block.dart';
import '../shared/link_type_palette.dart';

/// Groups linked project documents by their link type (Permits, Contracts, etc.).
///
/// Replaces the PlaceholderScreen rendered when `_activeView == 'byType'` in
/// [ProjectDocumentsScreen].
class DocumentsByTypeView extends StatelessWidget {
  const DocumentsByTypeView({
    super.key,
    required this.links,
    required this.projectName,
    required this.onDocumentTap,
    required this.onLinkDocument,
  });

  final List<ProjectDocumentLink> links;
  final String projectName;

  /// Called when the user taps a document card.
  final void Function(ProjectDocumentLink link) onDocumentTap;

  /// Called when the user taps the dashed "Link a document" card.
  final VoidCallback onLinkDocument;

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Guard: if empty, show a lightweight inline state (screen normally handles
    // the true empty state, but guard prevents rendering crashes).
    if (links.isEmpty) {
      return const _EmptyGuard();
    }

    // Group links by type in DocumentLinkTypes.all order.
    final grouped = <DocumentLinkType, List<ProjectDocumentLink>>{};
    for (final type in DocumentLinkType.values) {
      final items =
          links.where((l) => l.linkType == type.name).toList();
      if (items.isNotEmpty) {
        grouped[type] = items;
      }
    }

    // Build sections in the canonical order defined by DocumentLinkTypes.all.
    final orderedTypes = DocumentLinkTypes.all
        .map((entry) => DocumentLinkType.fromString(entry.value))
        .where(grouped.containsKey)
        .toList();

    final eyebrowLabel = projectName.isNotEmpty
        ? '${projectName.toUpperCase()} · ${links.length} DOCUMENT${links.length == 1 ? '' : 'S'}'
        : '${links.length} DOCUMENT${links.length == 1 ? '' : 'S'}';

    return CustomScrollView(
      slivers: [
        // ── 1. Eyebrow + heading ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Eyebrow row
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7A8C56),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      eyebrowLabel,
                      style: const TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        height: 1.2,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // H1
                Text(
                  'By purpose.',
                  style: GoogleFonts.fraunces(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                    height: 1.05,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // ── 2. Sections ───────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList.builder(
            itemCount: _itemCount(orderedTypes, grouped),
            itemBuilder: (context, index) =>
                _buildItem(context, index, orderedTypes, grouped),
          ),
        ),
      ],
    );
  }

  // ── Section list helpers ─────────────────────────────────────────────────────

  /// Total item count across all sections (header + cards + spacers).
  int _itemCount(
    List<DocumentLinkType> orderedTypes,
    Map<DocumentLinkType, List<ProjectDocumentLink>> grouped,
  ) {
    int count = 0;
    for (int s = 0; s < orderedTypes.length; s++) {
      final type = orderedTypes[s];
      final items = grouped[type]!;
      // 1 header + N cards + (N-1 gaps between cards) + (1 inter-section gap, if not last)
      count += 1 + items.length + (items.length - 1);
      if (s < orderedTypes.length - 1) count += 1; // inter-section spacer
    }
    // Dashed add card with top margin (counted as 2: margin spacer + card)
    count += 2;
    return count;
  }

  /// Maps a flat index to the correct widget (section header, card, gap, or
  /// the trailing "Link a document" card).
  Widget _buildItem(
    BuildContext context,
    int index,
    List<DocumentLinkType> orderedTypes,
    Map<DocumentLinkType, List<ProjectDocumentLink>> grouped,
  ) {
    int cursor = 0;

    for (int s = 0; s < orderedTypes.length; s++) {
      final type = orderedTypes[s];
      final items = grouped[type]!;
      final isLastSection = s == orderedTypes.length - 1;

      // Section header
      if (index == cursor) {
        return _SectionHeader(type: type, count: items.length);
      }
      cursor++;

      // Cards with inter-card gaps
      for (int i = 0; i < items.length; i++) {
        if (index == cursor) {
          return _DocumentCard(
            link: items[i],
            type: type,
            onTap: () => onDocumentTap(items[i]),
          );
        }
        cursor++;

        // Gap between cards (not after last card)
        if (i < items.length - 1) {
          if (index == cursor) return const SizedBox(height: 8);
          cursor++;
        }
      }

      // Inter-section gap (not after last section)
      if (!isLastSection) {
        if (index == cursor) return const SizedBox(height: 6);
        cursor++;
      }
    }

    // Trailing "Link a document" card
    if (index == cursor) return const SizedBox(height: 16);
    cursor++;

    // The dashed card itself
    return _DashedLinkCard(onTap: onLinkDocument);
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.type, required this.count});

  final DocumentLinkType type;
  final int count;

  static IconData _iconFor(DocumentLinkType type) => switch (type) {
        DocumentLinkType.receipt => Icons.receipt_long_outlined,
        DocumentLinkType.permit => Icons.assignment_outlined,
        DocumentLinkType.contract => Icons.description_outlined,
        DocumentLinkType.invoice => Icons.request_quote_outlined,
        DocumentLinkType.warranty => Icons.verified_outlined,
        DocumentLinkType.general => Icons.folder_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final palette = LinkTypePalette.forType(type);
    final docLabel = count == 1 ? '1 doc' : '$count docs';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(
            _iconFor(type),
            size: 18,
            color: palette.foreground,
          ),
          const SizedBox(width: 8),
          Text(
            type.pluralName,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            docLabel,
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Document card ──────────────────────────────────────────────────────────────

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.link,
    required this.type,
    required this.onTap,
  });

  final ProjectDocumentLink link;
  final DocumentLinkType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = LinkTypePalette.forType(type);
    final formattedDate =
        DateFormat('MMM d, yyyy').format(link.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // File type icon block
            FileTypeIconBlock(mimeType: link.documentTypeName ?? ''),
            const SizedBox(width: 12),

            // Name + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: name + type badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          link.documentName.isNotEmpty
                              ? link.documentName
                              : 'Untitled document',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Link type badge pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: palette.background,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          type.displayName.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: palette.foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Row 2: linked date
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Chevron
            const Icon(
              Icons.chevron_right,
              size: 14,
              color: AppColors.gray400,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dashed "Link a document" card ──────────────────────────────────────────────

class _DashedLinkCard extends StatelessWidget {
  const _DashedLinkCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.gray400,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
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
        ),
      ),
    );
  }
}

// ── Empty guard ────────────────────────────────────────────────────────────────

class _EmptyGuard extends StatelessWidget {
  const _EmptyGuard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.folder_outlined,
            size: 48,
            color: AppColors.gray400,
          ),
          const SizedBox(height: 12),
          Text(
            'No documents linked yet',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Link a document from your vault to get started.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.gray400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
