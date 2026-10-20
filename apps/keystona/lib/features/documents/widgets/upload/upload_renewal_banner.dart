import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../docs_copy.dart';

/// "Renewing Homeowners insurance policy": which document this form renews,
/// and that saving replaces the old file.
class UploadRenewalBanner extends StatelessWidget {
  const UploadRenewalBanner({super.key, required this.documentName});

  /// The document being replaced.
  final String documentName;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Semantics(
      container: true,
      label: DocsCopy.renewing(documentName),
      child: ExcludeSemantics(
        child: Container(
          padding: a.symmetric(
            horizontal: AuroraSpacing.space6,
            vertical: AuroraSpacing.space5,
          ),
          decoration: BoxDecoration(
            borderRadius: AuroraRadius.lg,
            border: Border.all(
              color: AuroraColors.cobaltBorder,
              width: AuroraBorders.regular,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.autorenew,
                size: a.of(AuroraIconSizes.lg),
                color: AuroraColors.cobalt,
              ),
              SizedBox(width: a.of(AuroraSpacing.space4)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DocsCopy.renewing(documentName),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AuroraType.h3,
                    ),
                    SizedBox(height: a.of(AuroraSpacing.space1)),
                    Text(DocsCopy.renewalReplacesFile, style: AuroraType.meta),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
