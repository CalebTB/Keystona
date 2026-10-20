import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import 'upload_formatters.dart';
import 'upload_scan_edge.dart';

/// "Smart scan read 4 details. The ones edged in blue came from it..."
class UploadScanBanner extends StatelessWidget {
  const UploadScanBanner({super.key, required this.detailCount});

  final int detailCount;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Semantics(
      liveRegion: true,
      child: UploadScanEdge(
        active: true,
        borderRadius: AuroraRadius.lg,
        child: Container(
          padding: a.symmetric(
            horizontal: AuroraSpacing.space6,
            vertical: AuroraSpacing.space5,
          ),
          decoration: BoxDecoration(
            borderRadius: AuroraRadius.lg,
            border: Border.all(
              color: AuroraColors.inkBorder,
              width: AuroraBorders.regular,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.document_scanner_outlined,
                size: a.of(AuroraIconSizes.lg),
                color: AuroraColors.cobalt,
              ),
              SizedBox(width: a.of(AuroraSpacing.space4)),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: AuroraType.body.copyWith(
                      fontSize: AuroraType.chip.fontSize,
                    ),
                    children: [
                      TextSpan(
                        text: UploadFormatters.scanHeadline(detailCount),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(
                        text:
                            ' The ones edged in blue came from it — check '
                            'them before you save.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
