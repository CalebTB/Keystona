import 'package:flutter/cupertino.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_card.dart';
import '../../docs_copy.dart';

/// Shown on a replaced document instead of the coverage card: it was replaced
/// by a newer copy and is kept for claims history, with a link to the newer
/// copy when its id is known.
class DocumentReplacedNote extends StatelessWidget {
  const DocumentReplacedNote({super.key, this.onOpenNewer});

  /// Opens the newer document. Null when it is not known.
  final VoidCallback? onOpenNewer;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final onOpen = onOpenNewer;
    return AuroraCard(
      onTap: onOpen,
      padding: a.symmetric(
        horizontal: AuroraSpacing.space6,
        vertical: AuroraSpacing.space5,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DocsCopy.replacedNote,
                  style: AuroraType.body.copyWith(color: AuroraColors.inkBody),
                ),
                if (onOpen != null) ...[
                  SizedBox(height: a.of(AuroraSpacing.space3)),
                  Text(
                    DocsCopy.seeNewerCopy,
                    style: AuroraType.button.copyWith(
                      color: AuroraColors.cobaltDeep,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onOpen != null) ...[
            SizedBox(width: a.of(AuroraSpacing.space3)),
            Icon(
              CupertinoIcons.chevron_right,
              size: a.of(AuroraIconSizes.sm),
              color: AuroraColors.inkPlaceholder,
            ),
          ],
        ],
      ),
    );
  }
}
