import 'package:flutter/material.dart';

import '../../theme/aurora_colors.dart';
import '../../theme/aurora_radius.dart';
import '../../theme/aurora_scale.dart';
import '../../theme/aurora_sizes.dart';
import '../../theme/aurora_spacing.dart';
import '../../theme/aurora_typography.dart';

/// Internal pieces shared by the Aurora form fields (not exported from the
/// barrel): the uppercase label above, the helper line below, and the bordered
/// 12 pt-radius container.
class AuroraFieldLabel extends StatelessWidget {
  const AuroraFieldLabel({
    super.key,
    required this.label,
    required this.isRequired,
  });

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: label.toUpperCase(),
        style: AuroraType.label,
        children: [
          if (isRequired)
            TextSpan(
              text: ' *',
              style: AuroraType.label.copyWith(
                color: AuroraColors.coral,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class AuroraFieldHelper extends StatelessWidget {
  const AuroraFieldHelper({super.key, required this.text, this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AuroraType.helper.copyWith(
        color: isError ? AuroraColors.coral : AuroraColors.inkHelper,
      ),
    );
  }
}

/// The bordered box around a field's value.
class AuroraFieldBox extends StatelessWidget {
  const AuroraFieldBox({
    super.key,
    required this.child,
    this.active = false,
    this.error = false,
    this.padding,
  });

  final Widget child;

  /// Focused or expanded: cobalt 1.5 pt border.
  final bool active;
  final bool error;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final Color border = error
        ? AuroraColors.coral
        : active
            ? AuroraColors.cobalt
            : AuroraColors.inkInputBorder;
    return Container(
      constraints: BoxConstraints(minHeight: a.minControl(AuroraSizes.inputHeight)),
      padding: padding ?? a.symmetric(horizontal: AuroraSpacing.space6),
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.md,
        border: Border.all(
          color: border,
          width: active || error ? AuroraBorders.emphasis : AuroraBorders.regular,
        ),
      ),
      child: child,
    );
  }
}
