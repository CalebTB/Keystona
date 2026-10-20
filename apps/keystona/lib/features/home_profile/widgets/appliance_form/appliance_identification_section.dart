import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/widgets/aurora/aurora_form_section.dart';
import '../../../../core/widgets/aurora/aurora_text_field.dart';
import '../../appliance_copy.dart';
import '../shared/scan_field_box.dart';
import 'form_pair.dart';

/// IDENTIFICATION (optional): brand, model, serial number and color. A field
/// whose key is in [fromScan] wears the cobalt "came from the label" edge.
class ApplianceIdentificationSection extends StatelessWidget {
  const ApplianceIdentificationSection({
    super.key,
    required this.brand,
    required this.model,
    required this.serial,
    required this.color,
    required this.fromScan,
  });

  final TextEditingController brand;
  final TextEditingController model;
  final TextEditingController serial;
  final TextEditingController color;

  /// Keys among `brand`, `model`, `serial` still holding the scanned value.
  final Set<String> fromScan;

  static const String brandKey = 'brand';
  static const String modelKey = 'model';
  static const String serialKey = 'serial';

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraFormSection(
      title: ApplianceCopy.identification,
      isOptional: true,
      children: [
        FormPair(
          left: ScanFieldBox(
            fromScan: fromScan.contains(brandKey),
            child: AuroraTextField(
              label: ApplianceCopy.brand,
              controller: brand,
            ),
          ),
          right: ScanFieldBox(
            fromScan: fromScan.contains(modelKey),
            child: AuroraTextField(
              label: ApplianceCopy.model,
              controller: model,
            ),
          ),
        ),
        ScanFieldBox(
          fromScan: fromScan.contains(serialKey),
          child: AuroraTextField(
            label: ApplianceCopy.serial,
            controller: serial,
            suffix: Icon(
              Icons.qr_code_scanner,
              size: a.of(AuroraIconSizes.sm),
              color: AuroraColors.coral,
            ),
          ),
        ),
        AuroraTextField(
          label: ApplianceCopy.color,
          controller: color,
          hintText: ApplianceCopy.colorHint,
        ),
      ],
    );
  }
}
