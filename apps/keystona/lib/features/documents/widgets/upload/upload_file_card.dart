import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_b.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import 'upload_formatters.dart';

/// The attached file: thumbnail, name, "PDF · 1.4 MB · JUST NOW", remove.
class UploadFileCard extends StatelessWidget {
  const UploadFileCard({
    super.key,
    required this.label,
    required this.mimeType,
    required this.sizeBytes,
    required this.onRemove,
    this.preview,
  });

  final String label;
  final String? mimeType;
  final int? sizeBytes;

  /// First page image; null shows a file glyph (a picked PDF).
  final File? preview;

  /// Null while saving, when the file can no longer be changed.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: a.all(AuroraSpacing.space5),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.xl,
        border: Border.all(
          color: AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Row(
        children: [
          _Thumbnail(preview: preview),
          SizedBox(width: a.of(AuroraSpacing.space6)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AuroraType.h3.copyWith(
                    fontSize: AuroraType.bodyLg.fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: a.of(AuroraSpacing.space1)),
                Text(
                  UploadFormatters.fileMeta(mimeType, sizeBytes),
                  style: AuroraType.meta,
                ),
              ],
            ),
          ),
          AuroraPressable(
            onTap: onRemove,
            semanticLabel: 'Remove file',
            enforceTouchTarget: true,
            child: Icon(
              Icons.close,
              size: a.of(AuroraIconSizes.md),
              color: AuroraColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.preview});

  final File? preview;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final radius = BorderRadius.circular(
      a.of(AuroraUploadSizes.fileThumbRadius),
    );
    final glyph = Icon(
      Icons.description_outlined,
      size: a.of(AuroraIconSizes.xl),
      color: AuroraColors.cobalt,
    );
    return Container(
      width: a.of(AuroraUploadSizes.fileThumbWidth),
      height: a.of(AuroraUploadSizes.fileThumbHeight),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: AuroraColors.cobaltBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: preview == null
          ? glyph
          : Image.file(
              preview!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              cacheWidth:
                  (a.of(AuroraUploadSizes.fileThumbWidth) *
                          MediaQuery.devicePixelRatioOf(context))
                      .round(),
              errorBuilder: (_, _, _) => glyph,
            ),
    );
  }
}
