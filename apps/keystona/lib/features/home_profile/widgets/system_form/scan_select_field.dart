import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_field_chrome.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../shared/scan_field_box.dart';

/// A tappable select whose box carries the "from scan" edge. Looks like
/// `AuroraSelectField`; the caller opens the picker in [onTap].
class ScanSelectField extends StatelessWidget {
  const ScanSelectField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.onTap,
    required this.fromScan,
    this.value,
  });

  /// Empty text keeps the row height without a visible label.
  final String label;
  final String placeholder;
  final String? value;
  final bool fromScan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final has = value != null && value!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AuroraFieldLabel(
          label: label.isEmpty ? ' ' : label,
          isRequired: false,
        ),
        SizedBox(height: a.of(AuroraSpacing.space2)),
        ScanFieldBox(
          fromScan: fromScan,
          child: AuroraPressable(
            onTap: onTap,
            semanticLabel: has ? '$label, $value' : '$label, $placeholder',
            child: AuroraFieldBox(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      has ? value! : placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AuroraType.input.copyWith(
                        color: has
                            ? AuroraColors.ink
                            : AuroraColors.inkPlaceholder,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: a.of(AuroraIconSizes.sm),
                    color: AuroraColors.inkHelper,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
