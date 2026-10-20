import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_home_a.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';

/// Two or three form fields side by side, weighted by [flexes]. When the row
/// is too narrow for the text size they stack instead, so nothing clips.
class FieldPair extends StatelessWidget {
  const FieldPair({
    super.key,
    required this.children,
    this.flexes = const [1, 1],
  });

  final List<Widget> children;
  final List<int> flexes;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = a.of(AuroraSpacing.space3);
    return LayoutBuilder(
      builder: (context, box) {
        final stack =
            box.maxWidth / a.textScale <
            a.of(AuroraHomeASizes.sideBySidePerField) * children.length;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: a.of(AuroraSpacing.space6),
            children: children,
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: gap,
          children: [
            for (var i = 0; i < children.length; i++)
              Expanded(flex: flexes[i], child: children[i]),
          ],
        );
      },
    );
  }
}
