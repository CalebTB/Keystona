import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_button.dart';

/// The bar under the Review scroll: a hairline above one full-width
/// "Looks good — keep N" button.
class ReviewFooter extends StatelessWidget {
  const ReviewFooter({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;

  /// Null while there is nothing to keep.
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: EdgeInsets.fromLTRB(
        a.of(AuroraSpacing.screenPadH),
        a.of(AuroraSpacing.space5),
        a.of(AuroraSpacing.screenPadH),
        a.of(AuroraSpacing.space5),
      ),
      decoration: const BoxDecoration(
        color: AuroraColors.paper,
        border: Border(
          top: BorderSide(
            color: AuroraColors.inkBorder,
            width: AuroraBorders.hairline,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: a.contentMaxWidth),
            child: PrimaryButton(
              label: label,
              expand: true,
              large: true,
              loading: loading,
              onPressed: onPressed,
            ),
          ),
        ),
      ),
    );
  }
}
