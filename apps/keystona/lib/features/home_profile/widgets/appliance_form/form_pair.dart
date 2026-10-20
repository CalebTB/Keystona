import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_home_c.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';

/// Two fields side by side ("BRAND" and "MODEL"). At large text they stack,
/// so neither is squeezed.
class FormPair extends StatelessWidget {
  const FormPair({super.key, required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = a.of(AuroraSpacing.space5);
    if (a.textScale >= AuroraHomeCSizes.stackTextScale) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [left, SizedBox(height: gap), right],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        SizedBox(width: gap),
        Expanded(child: right),
      ],
    );
  }
}
