import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_select_field.dart';
import '../../../../core/widgets/aurora/aurora_text_field.dart';
import '../../appliance_copy.dart';
import '../../models/appliance.dart';

/// The two required fields at the top of the form: category and name.
class ApplianceIdentitySection extends StatelessWidget {
  const ApplianceIdentitySection({
    super.key,
    required this.category,
    required this.name,
    required this.onPickCategory,
  });

  final ApplianceCategory category;
  final TextEditingController name;
  final VoidCallback onPickCategory;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuroraSelectField(
          label: ApplianceCopy.category,
          required: true,
          value: category.label,
          onTap: onPickCategory,
        ),
        SizedBox(height: a.of(AuroraSpacing.space7)),
        AuroraTextField(
          label: ApplianceCopy.name,
          controller: name,
          required: true,
          helperText: ApplianceCopy.nameHint,
          validator: (v) =>
              (v ?? '').trim().isEmpty ? ApplianceCopy.nameRequired : null,
        ),
      ],
    );
  }
}
