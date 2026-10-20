import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_home_b.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_select_field.dart';
import '../../../../core/widgets/aurora/aurora_text_field.dart';
import '../../forms/system_form_controller.dart';
import '../../models/system.dart';
import '../../systems_copy.dart';
import 'option_picker.dart';

/// CATEGORY and NAME, the two required fields.
class SystemBasicsSection extends StatelessWidget {
  const SystemBasicsSection({super.key, required this.form});

  final SystemFormController form;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuroraSelectField(
          label: SystemsCopy.category,
          required: true,
          value: form.category.label,
          onTap: () async {
            final picked = await pickOption<SystemCategory>(
              context,
              title: SystemsCopy.categorySheet,
              options: SystemCategory.values,
              labelOf: (c) => c.label,
            );
            if (picked != null) form.setCategory(picked);
          },
        ),
        SizedBox(height: a.of(AuroraSpacing.space6)),
        AuroraTextField(
          label: SystemsCopy.nameLabel,
          controller: form.name,
          required: true,
          hintText: SystemsCopy.nameHint,
          helperText: SystemsCopy.nameHelper,
          maxLength: AuroraHomeBSizes.nameMaxLength,
        ),
      ],
    );
  }
}
