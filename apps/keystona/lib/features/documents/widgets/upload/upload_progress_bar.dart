import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_b.dart';
import '../../../../core/theme/aurora_scale.dart';

/// Thin cobalt bar under the header while the file uploads.
class UploadProgressBar extends StatelessWidget {
  const UploadProgressBar({super.key, required this.progress});

  /// 0.0 to 1.0.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Semantics(
      label: 'Saving',
      value: NumberFormat.percentPattern().format(progress),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: a.of(AuroraUploadSizes.progressHeight),
        color: AuroraColors.cobalt,
        backgroundColor: AuroraColors.inkBorder,
      ),
    );
  }
}
