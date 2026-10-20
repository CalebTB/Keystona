import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../providers/document_repositories_provider.dart';
import 'document_viewer_message.dart';

/// Scrollable PDF pages from the private bucket, on the ink media ground.
class DocumentPdfView extends ConsumerStatefulWidget {
  const DocumentPdfView({super.key, required this.filePath});

  final String filePath;

  @override
  ConsumerState<DocumentPdfView> createState() => _DocumentPdfViewState();
}

class _DocumentPdfViewState extends ConsumerState<DocumentPdfView> {
  late final PdfController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfController(
      document: PdfDocument.openData(
        ref.read(documentFilesRepositoryProvider).download(widget.filePath),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const loader = Center(
      child: CircularProgressIndicator(
        strokeWidth: AuroraBorders.spinnerStroke,
        color: AuroraColors.paper,
      ),
    );
    return PdfView(
      controller: _controller,
      scrollDirection: Axis.vertical,
      builders: PdfViewBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (_) => loader,
        pageLoaderBuilder: (_) => loader,
        errorBuilder: (_, _) => const DocumentViewerMessage(
          icon: Icons.error_outline,
          text: 'PDF preview unavailable',
        ),
      ),
    );
  }
}
