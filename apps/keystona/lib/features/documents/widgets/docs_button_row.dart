import 'package:flutter/material.dart';

import '../../../core/theme/aurora_docs_a.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';

/// Two buttons side by side, stacking when the text is large so neither
/// button squeezes the other's label.
///
/// [primary] is the wider one; [secondary] keeps its natural width unless
/// [equalWidth] is set.
class DocsButtonRow extends StatelessWidget {
  const DocsButtonRow({
    super.key,
    required this.primary,
    required this.secondary,
    this.equalWidth = false,
    this.secondaryFirst = false,
  });

  final Widget primary;
  final Widget secondary;
  final bool equalWidth;

  /// Puts [secondary] before [primary] (the kit's "Keep it" / "Delete").
  final bool secondaryFirst;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = a.of(AuroraSpacing.space3);
    final stacked = a.textScale >= AuroraDocsA.stackTextScale;
    final first = secondaryFirst ? secondary : primary;
    final second = secondaryFirst ? primary : secondary;

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          primary,
          SizedBox(height: gap),
          secondary,
        ],
      );
    }
    return Row(
      children: [
        if (secondaryFirst && !equalWidth) first else Expanded(child: first),
        SizedBox(width: gap),
        if (!secondaryFirst && !equalWidth) second else Expanded(child: second),
      ],
    );
  }
}
