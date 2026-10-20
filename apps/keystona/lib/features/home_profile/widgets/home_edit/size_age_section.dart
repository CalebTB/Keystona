import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_select_field.dart';
import '../../../../core/widgets/aurora/aurora_text_field.dart';
import '../../../../core/widgets/aurora/aurora_toggle_row.dart';
import '../../edit/home_edit_form.dart';
import '../../home_edit_copy.dart';
import '../../home_profile_copy.dart';
import '../../home_profile_format.dart';
import '../shared/item_row_group.dart';
import '../shared/mono_section_label.dart';
import 'field_pair.dart';
import 'stepper_row.dart';

/// SIZE & AGE: year built, square feet, lot, garage, the three steppers (and
/// garage spaces when there is a garage) and the basement switch.
class SizeAgeSection extends StatelessWidget {
  const SizeAgeSection({
    super.key,
    required this.form,
    required this.onPickGarage,
  });

  final HomeEditForm form;
  final VoidCallback onPickGarage;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return ListenableBuilder(
      listenable: form,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: a.of(AuroraSpacing.space6),
        children: [
          const MonoSectionLabel(HomeEditCopy.sizeAge),
          FieldPair(
            children: [
              AuroraTextField(
                label: HomeEditCopy.yearBuilt,
                controller: form.year,
                keyboardType: TextInputType.number,
                helperText: form.yearHelp,
              ),
              AuroraTextField(
                label: HomeEditCopy.squareFeet,
                controller: form.sqft,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          FieldPair(
            children: [
              AuroraTextField(
                label: HomeEditCopy.lot,
                controller: form.lot,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              AuroraSelectField(
                label: HomeEditCopy.garage,
                value:
                    HomeProfileCopy.garageLabel(
                      form.garageType,
                      form.garageSpaces,
                    ) ??
                    HomeEditCopy.garageNone,
                onTap: onPickGarage,
              ),
            ],
          ),
          ItemRowGroup(
            children: [
              StepperRow(
                label: HomeEditCopy.bedrooms,
                value: form.bedrooms?.toString(),
                onMinus: () => form.stepBedrooms(-1),
                onPlus: () => form.stepBedrooms(1),
              ),
              StepperRow(
                label: HomeEditCopy.bathrooms,
                value: form.bathrooms == null
                    ? null
                    : HomeFormat.half(form.bathrooms!),
                onMinus: () => form.stepBathrooms(-1),
                onPlus: () => form.stepBathrooms(1),
              ),
              StepperRow(
                label: HomeEditCopy.stories,
                value: form.stories?.toString(),
                onMinus: () => form.stepStories(-1),
                onPlus: () => form.stepStories(1),
              ),
              if (form.garageType != null)
                StepperRow(
                  label: HomeEditCopy.garageSpaces,
                  value: form.garageSpaces?.toString(),
                  onMinus: () => form.stepGarageSpaces(-1),
                  onPlus: () => form.stepGarageSpaces(1),
                ),
            ],
          ),
          AuroraToggleRow(
            label: HomeEditCopy.basement,
            value: form.hasBasement,
            onChanged: form.setBasement,
          ),
        ],
      ),
    );
  }
}
