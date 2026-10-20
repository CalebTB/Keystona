import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../providers/document_links_provider.dart';
import '../shared/docs_section_header.dart';
import 'document_linked_tile.dart';

/// "Linked to": the systems, appliances and projects tied to this document.
///
/// Hidden while loading, on error, and when nothing is linked: it is
/// secondary information and never blocks the page.
class DocumentLinkedSection extends ConsumerWidget {
  const DocumentLinkedSection({
    super.key,
    required this.documentId,
    required this.onOpen,
  });

  final String documentId;
  final ValueChanged<DocumentLinkEntry> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(documentLinksProvider(documentId)).value;
    if (links == null || links.isEmpty) return const SizedBox.shrink();

    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DocsSectionHeader(title: 'Linked to'),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        for (var i = 0; i < links.length; i++) ...[
          if (i > 0) SizedBox(height: a.of(AuroraSpacing.space3)),
          DocumentLinkedTile(entry: links[i], onTap: () => onOpen(links[i])),
        ],
      ],
    );
  }
}
