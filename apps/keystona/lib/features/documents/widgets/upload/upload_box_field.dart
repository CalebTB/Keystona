import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_field_chrome.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import 'upload_scan_edge.dart';

/// A labelled field box that can carry the smart scan edge. Tappable when
/// [onTap] is set (select-style fields), otherwise it just hosts [child]
/// (an input).
class UploadBoxField extends StatelessWidget {
  const UploadBoxField({
    super.key,
    required this.label,
    required this.child,
    this.isRequired = false,
    this.edged = false,
    this.active = false,
    this.onTap,
    this.semanticLabel,
    this.helper,
  });

  final String label;
  final bool isRequired;

  /// Show the smart scan edge.
  final bool edged;

  /// Cobalt border: focused, or the picker it opens is showing.
  final bool active;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? helper;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    Widget box = UploadScanEdge(
      active: edged,
      child: AuroraFieldBox(active: active, child: child),
    );
    if (onTap != null) {
      box = AuroraPressable(
        onTap: onTap,
        semanticLabel: semanticLabel ?? label,
        child: box,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AuroraFieldLabel(label: label, isRequired: isRequired),
        SizedBox(height: a.of(AuroraSpacing.space2)),
        box,
        if (helper != null) ...[
          SizedBox(height: a.of(AuroraSpacing.space2)),
          AuroraFieldHelper(text: helper!),
        ],
      ],
    );
  }
}
