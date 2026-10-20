import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_c.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../models/document.dart';
import '../../providers/document_repositories_provider.dart';

/// The document on graph paper, with a page tag and an Open pill.
///
/// Shows the stored thumbnail when there is one; otherwise a placeholder page.
class DocumentPreviewCard extends ConsumerWidget {
  const DocumentPreviewCard({
    super.key,
    required this.document,
    required this.onOpen,
  });

  final Document document;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aurora;
    final path = document.thumbnailPath;
    final thumbnail = path == null
        ? null
        : ref.watch(documentThumbnailUrlProvider(path)).value;
    final pages = document.pageCount;

    return AspectRatio(
      aspectRatio: AuroraDocsCSizes.previewAspect,
      child: AuroraPressable(
        onTap: onOpen,
        semanticLabel: pages == null
            ? 'Open the document'
            : 'Open the document, page 1 of $pages',
        child: ClipRRect(
          borderRadius: AuroraRadius.xl,
          child: DecoratedBox(
            // Painted over the content so the paper never covers the outline.
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: AuroraRadius.xl,
              border: Border.all(
                color: AuroraColors.cobaltBorder,
                width: AuroraBorders.regular,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _GridPainter(a.of(AuroraDocsCSizes.previewGridCell)),
                ),
                Positioned(
                  top: a.of(AuroraDocsCSizes.previewPaperTop),
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: FractionallySizedBox(
                    widthFactor: AuroraDocsCSizes.previewPaperWidthFactor,
                    child: _Paper(thumbnailUrl: thumbnail),
                  ),
                ),
                Positioned(
                  left: a.of(AuroraDocsCSizes.previewCornerInset),
                  right: a.of(AuroraDocsCSizes.previewCornerInset),
                  bottom: a.of(AuroraDocsCSizes.previewCornerInset),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Expanded, not Flexible + Spacer: those split the row
                      // evenly and left the Open pill hanging mid-card.
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: pages == null
                              ? const SizedBox.shrink()
                              : _PageTag(pages: pages),
                        ),
                      ),
                      const _OpenPill(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter(this.cell);

  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AuroraDocsCColors.previewGrid
      ..strokeWidth = AuroraBorders.regular;
    for (var x = 0.0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.cell != cell;
}

class _Paper extends StatelessWidget {
  const _Paper({required this.thumbnailUrl});

  final String? thumbnailUrl;

  /// Widths of the placeholder text lines, as fractions of the page width.
  /// Title lines are darker; the rest are body text.
  static const List<({double share, bool title})> _lines = [
    (share: 0.55, title: true),
    (share: 0, title: false),
    (share: 0.92, title: false),
    (share: 0.88, title: false),
    (share: 0.95, title: false),
    (share: 0.70, title: false),
    (share: 0, title: false),
    (share: 0.40, title: true),
    (share: 0.90, title: false),
    (share: 0.86, title: false),
    (share: 0.93, title: false),
    (share: 0.64, title: false),
  ];

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final url = thumbnailUrl;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.xs,
        boxShadow: const [
          BoxShadow(
            color: AuroraColors.inkTrackOff,
            blurRadius: AuroraSpacing.space8,
            offset: Offset(0, AuroraSpacing.space2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AuroraRadius.xs,
        child: url != null
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorWidget: (_, _, _) => const SizedBox.shrink(),
              )
            : ExcludeSemantics(
                child: Padding(
                  padding: a.symmetric(
                    horizontal: AuroraDocsCSizes.previewPaperPadH,
                    vertical: AuroraDocsCSizes.previewPaperPadV,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final line in _lines) ...[
                        if (line.share == 0)
                          SizedBox(height: a.of(AuroraDocsCSizes.previewLineGap))
                        else
                          FractionallySizedBox(
                            widthFactor: line.share,
                            child: Container(
                              height: a.of(
                                line.title
                                    ? AuroraDocsCSizes.previewTitleLine
                                    : AuroraDocsCSizes.previewTextLine,
                              ),
                              decoration: BoxDecoration(
                                color: line.title
                                    ? AuroraColors.inkCheckBorder
                                    : AuroraColors.inkBorder,
                                borderRadius: AuroraRadius.xs,
                              ),
                            ),
                          ),
                        SizedBox(height: a.of(AuroraDocsCSizes.previewLineSpacing)),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _PageTag extends StatelessWidget {
  const _PageTag({required this.pages});

  final int pages;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.full,
        border: Border.all(
          color: AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Padding(
        padding: a.symmetric(
          horizontal: AuroraSpacing.space3,
          vertical: AuroraSpacing.space1,
        ),
        child: Text(
          'PAGE 1 OF $pages',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AuroraType.labelSm.copyWith(
            fontWeight: FontWeight.w700,
            color: AuroraColors.inkSubtle,
          ),
        ),
      ),
    );
  }
}

class _OpenPill extends StatelessWidget {
  const _OpenPill();

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      constraints: BoxConstraints(
        minHeight: a.of(AuroraDocsCSizes.openPillHeight),
      ),
      padding: a.symmetric(horizontal: AuroraDocsCSizes.openPillPadH),
      decoration: const BoxDecoration(
        color: AuroraColors.ink,
        borderRadius: AuroraRadius.full,
      ),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(
          'Open',
          style: AuroraType.buttonSm.copyWith(color: AuroraColors.paper),
        ),
      ),
    );
  }
}
