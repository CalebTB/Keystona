import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_b.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../models/document_upload_state.dart';
import 'upload_box_field.dart';

/// "Linked to": the system or appliance this document belongs to.
class UploadLinkField extends StatelessWidget {
  const UploadLinkField({
    super.key,
    required this.link,
    required this.edged,
    required this.onTap,
  });

  final UploadLink? link;
  final bool edged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final current = link;
    return UploadBoxField(
      label: 'Linked to',
      edged: edged,
      onTap: onTap,
      semanticLabel: current == null
          ? 'Linked to, none'
          : 'Linked to, ${current.name}',
      helper: 'Its detail page will list this document',
      child: current == null
          ? Row(
              children: [
                Expanded(
                  child: Text(
                    'A system or appliance',
                    style: AuroraType.input.copyWith(
                      color: AuroraColors.inkPlaceholder,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: a.of(AuroraIconSizes.sm),
                  color: AuroraColors.inkHelper,
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: a.of(AuroraUploadSizes.linkIconTile),
                  height: a.of(AuroraUploadSizes.linkIconTile),
                  decoration: BoxDecoration(
                    borderRadius: AuroraRadius.tile,
                    border: Border.all(
                      color: AuroraColors.inkTileBorder,
                      width: AuroraBorders.regular,
                    ),
                  ),
                  child: Icon(
                    current.isAppliance
                        ? Icons.kitchen_outlined
                        : Icons.settings_outlined,
                    size: a.of(AuroraIconSizes.md),
                    color: AuroraColors.ink,
                  ),
                ),
                SizedBox(width: a.of(AuroraSpacing.space5)),
                Expanded(
                  child: Padding(
                    padding: a.symmetric(vertical: AuroraSpacing.space3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          current.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AuroraType.h3.copyWith(
                            fontSize: AuroraType.bodyLg.fontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (current.detail != null)
                          Text(
                            current.detail!.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AuroraType.meta,
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: a.of(AuroraSpacing.space3)),
                Text(
                  'Change',
                  style: AuroraType.buttonSm.copyWith(
                    color: AuroraColors.inkSecondary,
                  ),
                ),
              ],
            ),
    );
  }
}
