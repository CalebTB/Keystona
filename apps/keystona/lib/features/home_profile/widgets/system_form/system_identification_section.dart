import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_b.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_form_section.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../forms/system_form_controller.dart';
import '../../systems_copy.dart';
import 'scan_text_field.dart';

/// IDENTIFICATION: brand and model side by side, then the serial number.
/// Fields the scan filled carry the cobalt edge until they are edited.
class SystemIdentificationSection extends StatelessWidget {
  const SystemIdentificationSection({
    super.key,
    required this.form,
    required this.onRescan,
  });

  final SystemFormController form;

  /// The camera icon on the serial field; null hides it (edit mode).
  final VoidCallback? onRescan;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraFormSection(
      title: SystemsCopy.sectionIdentification,
      isOptional: true,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ScanTextField(
                label: SystemsCopy.brand,
                controller: form.brand,
                fromScan: form.brandFromScan(),
                maxLength: AuroraHomeBSizes.fieldMaxLength,
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space4)),
            Expanded(
              child: ScanTextField(
                label: SystemsCopy.model,
                controller: form.model,
                fromScan: form.modelFromScan(),
                maxLength: AuroraHomeBSizes.fieldMaxLength,
              ),
            ),
          ],
        ),
        ScanTextField(
          label: SystemsCopy.serial,
          controller: form.serial,
          fromScan: form.serialFromScan(),
          helperText: SystemsCopy.serialHelper,
          maxLength: AuroraHomeBSizes.fieldMaxLength,
          suffix: onRescan == null
              ? null
              : AuroraPressable(
                  onTap: onRescan,
                  semanticLabel: SystemsCopy.serialScan,
                  enforceTouchTarget: true,
                  child: Icon(
                    Icons.qr_code_scanner,
                    size: a.of(AuroraIconSizes.lg),
                    color: AuroraColors.coral,
                  ),
                ),
        ),
      ],
    );
  }
}
