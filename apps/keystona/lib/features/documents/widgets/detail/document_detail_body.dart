import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/aurora_docs_c.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../models/coverage_info.dart';
import '../../models/document.dart';
import '../../models/document_renewal.dart';
import '../../providers/document_links_provider.dart';
import 'document_coverage_section.dart';
import 'document_detail_actions.dart';
import 'document_detail_header.dart';
import 'document_facts_section.dart';
import 'document_file_section.dart';
import 'document_linked_section.dart';
import 'document_notes_section.dart';
import 'document_tags_row.dart';
import 'document_preview_card.dart';
import 'document_replaced_note.dart';

/// The sections of a loaded document, in kit order. Pure composition: every
/// action is a callback the screen provides.
class DocumentDetailBody extends StatelessWidget {
  const DocumentDetailBody({
    super.key,
    required this.document,
    required this.onOpenFile,
    required this.onClaim,
    required this.onOpenLink,
    required this.onEdit,
    required this.onDownload,
    required this.onReplace,
    required this.onDelete,
  });

  final Document document;
  final VoidCallback onOpenFile;
  final ValueChanged<String> onClaim;
  final ValueChanged<DocumentLinkEntry> onOpenLink;
  final VoidCallback onEdit;
  final VoidCallback onDownload;
  final VoidCallback onReplace;

  /// Null while a delete is already running.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final replaced = DocumentRenewal.replacedAt(document.metadata) != null;
    final newerId = DocumentRenewal.replacedBy(document.metadata);
    final coverage = replaced ? null : CoverageInfo.of(document);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DocumentDetailHeader(document: document),
        SizedBox(height: a.of(AuroraDocsCSizes.sectionGap)),
        DocumentPreviewCard(document: document, onOpen: onOpenFile),
        if (replaced) ...[
          SizedBox(height: a.of(AuroraDocsCSizes.sectionGap)),
          DocumentReplacedNote(
            onOpenNewer: newerId == null
                ? null
                : () => context.push(
                    AppRoutes.documentDetail.replaceFirst(
                      ':documentId',
                      newerId,
                    ),
                  ),
          ),
        ] else if (coverage != null) ...[
          SizedBox(height: a.of(AuroraDocsCSizes.sectionGap)),
          DocumentCoverageSection(coverage: coverage),
        ],
        if (DocumentFactsSection.hasContent(document)) ...[
          SizedBox(height: a.of(AuroraDocsCSizes.sectionGap)),
          DocumentFactsSection(document: document, onClaim: onClaim),
        ],
        SizedBox(height: a.of(AuroraDocsCSizes.sectionGap)),
        DocumentLinkedSection(documentId: document.id, onOpen: onOpenLink),
        SizedBox(height: a.of(AuroraDocsCSizes.sectionGap)),
        DocumentNotesSection(notes: document.notes, onAdd: onEdit),
        if (DocumentTagsRow.tagsOf(document).isNotEmpty) ...[
          SizedBox(height: a.of(AuroraDocsCSizes.sectionGap)),
          DocumentTagsRow(tags: DocumentTagsRow.tagsOf(document)),
        ],
        SizedBox(height: a.of(AuroraDocsCSizes.sectionGap)),
        DocumentFileSection(document: document),
        SizedBox(height: a.of(AuroraDocsCSizes.sectionGap)),
        DocumentDetailActions(
          onDownload: onDownload,
          onReplace: onReplace,
          onDelete: onDelete,
        ),
      ],
    );
  }
}
