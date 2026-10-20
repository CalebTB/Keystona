import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_docs_c.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../models/document_tags.dart';
import '../../models/coverage_info.dart';
import '../../models/document.dart';
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
    final coverage = CoverageInfo.of(document);
    final tags = DocumentTags.of(document);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DocumentDetailHeader(document: document),
        SizedBox(height: a.of(AuroraDocsCSizes.sectionGap)),
        DocumentPreviewCard(document: document, onOpen: onOpenFile),
        if (coverage != null) ...[
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
        if (tags.isNotEmpty) ...[
          SizedBox(height: a.of(AuroraDocsCSizes.sectionGap)),
          DocumentTagsRow(tags: tags),
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
