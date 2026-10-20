import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_c.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../item_copy.dart';
import '../../models/item_photo_type.dart';
import '../shared/mono_section_label.dart';

/// "GOOD PHOTOS TO HAVE": a line per shot worth taking, with a lime check
/// once a photo of that type exists.
class ItemPhotoTips extends StatelessWidget {
  const ItemPhotoTips({super.key, required this.tips, required this.have});

  final List<ItemPhotoTip> tips;

  /// The types the item already has a photo of.
  final Set<ItemPhotoType> have;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MonoSectionLabel(ItemCopy.goodPhotos),
        SizedBox(height: a.of(AuroraSpacing.space4)),
        for (final tip in tips)
          Padding(
            padding: EdgeInsets.only(bottom: a.of(AuroraSpacing.space5)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Check(done: tip.type != null && have.contains(tip.type)),
                SizedBox(width: a.of(AuroraSpacing.space5)),
                Expanded(
                  child: Text(
                    tip.text,
                    style: AuroraType.bodyLg.copyWith(
                      color: AuroraColors.inkBody,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      width: a.of(AuroraHomeCSizes.tipCheck),
      height: a.of(AuroraHomeCSizes.tipCheck),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AuroraColors.lime : null,
        border: done
            ? null
            : Border.all(
                color: AuroraColors.inkInputBorder,
                width: AuroraBorders.regular,
              ),
      ),
      child: done
          ? Icon(
              Icons.check,
              size: a.of(AuroraIconSizes.xs),
              color: AuroraColors.olive,
            )
          : null,
    );
  }
}
