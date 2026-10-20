import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_c.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../item_copy.dart';

/// "4 of 4 photos on Free" with what Premium adds, and the cobalt Add button
/// at the right edge.
class ItemPhotoLimitCard extends StatelessWidget {
  const ItemPhotoLimitCard({
    super.key,
    required this.title,
    required this.note,
    required this.onAdd,
    this.busy = false,
  });

  final String title;
  final String note;
  final VoidCallback? onAdd;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.xl,
        border: Border.all(
          color: AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Padding(
        padding: a.all(AuroraSpacing.space6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AuroraType.h3),
                  SizedBox(height: a.of(AuroraSpacing.space1)),
                  Text(note, style: AuroraType.meta),
                ],
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space5)),
            AuroraPressable(
              onTap: busy ? null : onAdd,
              semanticLabel: ItemCopy.addPhotoSemantics,
              enforceTouchTarget: true,
              child: Container(
                constraints: BoxConstraints(
                  minHeight: a.of(AuroraHomeCSizes.addPillHeight),
                ),
                padding: a.symmetric(horizontal: AuroraSpacing.space7),
                decoration: BoxDecoration(
                  color: busy ? AuroraColors.inkDisabledFill : AuroraColors.cobalt,
                  borderRadius: AuroraRadius.full,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_camera_outlined,
                      size: a.of(AuroraIconSizes.sm),
                      color: AuroraColors.paper,
                    ),
                    SizedBox(width: a.of(AuroraSpacing.space2)),
                    Text(
                      ItemCopy.addPhoto,
                      style: AuroraType.button.copyWith(
                        color: AuroraColors.paper,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
