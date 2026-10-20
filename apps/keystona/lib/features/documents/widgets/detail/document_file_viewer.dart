import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../models/document.dart';
import 'document_image_view.dart';
import 'document_pdf_view.dart';
import 'document_viewer_message.dart';

/// Full-screen viewer for a document's file: PDF pages or a zoomable image.
///
/// Opened with [DocumentFileViewer.open]. Core PdfViewer / PhotoViewer screens
/// (kit 8.4, 8.5) are not built yet; swap this for them when they land.
class DocumentFileViewer extends StatelessWidget {
  const DocumentFileViewer({super.key, required this.document});

  final Document document;

  /// Pushes the viewer as a full-screen dialog route.
  static Future<void> open(BuildContext context, Document document) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => DocumentFileViewer(document: document),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mime = document.mimeType ?? '';
    return Scaffold(
      backgroundColor: AuroraColors.ink,
      appBar: AppBar(
        backgroundColor: AuroraColors.ink,
        foregroundColor: AuroraColors.paper,
        elevation: 0,
        title: Text(
          document.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AuroraType.sheetTitle.copyWith(color: AuroraColors.paper),
        ),
      ),
      body: mime.contains('pdf')
          ? DocumentPdfView(filePath: document.filePath)
          : mime.startsWith('image/')
              ? DocumentImageView(filePath: document.filePath)
              : const DocumentViewerMessage(
                  icon: Icons.insert_drive_file_outlined,
                  text: 'Preview not available',
                ),
    );
  }
}
