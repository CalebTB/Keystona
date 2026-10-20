import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../providers/document_repositories_provider.dart';
import 'document_viewer_message.dart';

/// Pinch-to-zoom image from the private bucket, on the ink media ground.
class DocumentImageView extends ConsumerStatefulWidget {
  const DocumentImageView({super.key, required this.filePath});

  final String filePath;

  /// How far past "fills the screen" the image can be zoomed.
  static const double maxZoom = 4;

  @override
  ConsumerState<DocumentImageView> createState() => _DocumentImageViewState();
}

class _DocumentImageViewState extends ConsumerState<DocumentImageView> {
  late final Future<String?> _url;

  @override
  void initState() {
    super.initState();
    _url = ref.read(documentFilesRepositoryProvider).signedUrl(widget.filePath);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _url,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: AuroraBorders.spinnerStroke,
              color: AuroraColors.paper,
            ),
          );
        }
        final url = snapshot.data;
        if (snapshot.hasError || url == null) {
          return const DocumentViewerMessage(
            icon: Icons.error_outline,
            text: 'Preview unavailable',
          );
        }
        return PhotoView(
          imageProvider: CachedNetworkImageProvider(url),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * DocumentImageView.maxZoom,
          backgroundDecoration: const BoxDecoration(color: AuroraColors.ink),
        );
      },
    );
  }
}
