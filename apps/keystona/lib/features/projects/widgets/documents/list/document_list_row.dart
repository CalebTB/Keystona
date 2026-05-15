import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../models/project_document_link.dart';
import '../shared/document_link_type.dart';
import '../shared/file_type_icon_block.dart';
import '../shared/link_type_palette.dart';

/// A single document row in the vault list.
///
/// Tapping navigates to the document detail screen via [onTap].
/// Long-press triggers [onLongPress] (unlink).
class DocumentListRow extends StatelessWidget {
  const DocumentListRow({
    super.key,
    required this.link,
    required this.onTap,
    this.onLongPress,
  });

  final ProjectDocumentLink link;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final linkType = DocumentLinkType.fromString(link.linkType);
    final palette = LinkTypePalette.forType(linkType);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // File type icon block
            FileTypeIconBlock(mimeType: ''),
            const SizedBox(width: 12),

            // Middle content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: name + type badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          link.documentName,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Link-type tag pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: palette.background,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          linkType.displayName.toUpperCase(),
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

                  // Row 2: meta line
                  _MetaLine(link: link),
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

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.link});

  final ProjectDocumentLink link;

  @override
  Widget build(BuildContext context) {
    // The current model has no expirationDate — show category · linked date
    final category = link.documentTypeName ?? 'Document';
    final date = _formatDate(link.createdAt);

    return Text(
      '$category · $date',
      style: const TextStyle(
        fontFamily: 'IBMPlexMono',
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: AppColors.textSecondary,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
