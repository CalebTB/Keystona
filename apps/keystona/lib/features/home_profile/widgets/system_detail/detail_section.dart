import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../shared/mono_section_label.dart';

/// A labeled block of the detail screen: the section label, then [child].
class DetailSection extends StatelessWidget {
  const DetailSection({
    super.key,
    required this.label,
    required this.child,
    this.trailing,
  });

  final String label;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Padding(
      padding: EdgeInsets.only(top: a.of(AuroraSpacing.space10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MonoSectionLabel(label, trailing: trailing),
          SizedBox(height: a.of(AuroraSpacing.space5)),
          child,
        ],
      ),
    );
  }
}
