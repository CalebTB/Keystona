import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_b.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// No file yet: Scan, Photos and Files side by side, and what is accepted.
class UploadAddFileTiles extends StatelessWidget {
  const UploadAddFileTiles({
    super.key,
    required this.onScan,
    required this.onPhotos,
    required this.onFiles,
  });

  final VoidCallback onScan;
  final VoidCallback onPhotos;
  final VoidCallback onFiles;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Tile(
                  icon: Icons.document_scanner_outlined,
                  label: 'Scan',
                  accent: true,
                  onTap: onScan,
                ),
              ),
              SizedBox(width: a.of(AuroraSpacing.space3)),
              Expanded(
                child: _Tile(
                  icon: Icons.image_outlined,
                  label: 'Photos',
                  onTap: onPhotos,
                ),
              ),
              SizedBox(width: a.of(AuroraSpacing.space3)),
              Expanded(
                child: _Tile(
                  icon: Icons.folder_outlined,
                  label: 'Files',
                  onTap: onFiles,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: a.of(AuroraSpacing.space5)),
        Text(
          'PDF, JPG, PNG OR HEIC · UP TO 25 MB · SCAN READS IT FOR YOU',
          style: AuroraType.helper,
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final bool accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final color = accent ? AuroraColors.coral : AuroraColors.ink;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraUploadSizes.sourceTileHeight),
        ),
        padding: a.symmetric(vertical: AuroraSpacing.space5),
        decoration: BoxDecoration(
          borderRadius: AuroraRadius.lg,
          border: Border.all(
            color: accent ? AuroraColors.coral : AuroraColors.inkBorderStrong,
            width: AuroraBorders.emphasis,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: a.of(AuroraIconSizes.xl), color: color),
            SizedBox(height: a.of(AuroraSpacing.space3)),
            Text(
              label,
              style: AuroraType.buttonSm.copyWith(color: AuroraColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}
