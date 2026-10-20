import 'package:flutter/material.dart';

import '../../../../core/widgets/aurora/aurora_form_section.dart';
import '../../../../core/widgets/aurora/aurora_select_field.dart';
import '../../../../core/widgets/aurora/aurora_text_field.dart';
import '../../appliance_copy.dart';
import '../../models/appliance.dart';

/// MORE DETAILS, shown when editing: what the Add form leaves out. Where it
/// is, its status, the expected life in years and notes.
class ApplianceMoreDetailsSection extends StatelessWidget {
  const ApplianceMoreDetailsSection({
    super.key,
    required this.location,
    required this.status,
    required this.onPickStatus,
    required this.lifespan,
    required this.notes,
  });

  final TextEditingController location;
  final ItemStatus status;
  final VoidCallback onPickStatus;
  final TextEditingController lifespan;
  final TextEditingController notes;

  @override
  Widget build(BuildContext context) {
    return AuroraFormSection(
      title: ApplianceCopy.moreDetails,
      isOptional: true,
      children: [
        AuroraTextField(
          label: ApplianceCopy.location,
          controller: location,
          hintText: ApplianceCopy.locationHint,
        ),
        AuroraSelectField(
          label: ApplianceCopy.status,
          value: status.label,
          onTap: onPickStatus,
        ),
        AuroraTextField(
          label: ApplianceCopy.expectedLife,
          controller: lifespan,
          helperText: ApplianceCopy.expectedLifeHelper,
          keyboardType: TextInputType.number,
          validator: (v) {
            final t = (v ?? '').trim();
            return t.isEmpty || int.tryParse(t) != null
                ? null
                : ApplianceCopy.priceInvalid;
          },
        ),
        AuroraTextField(
          label: ApplianceCopy.notes,
          controller: notes,
          maxLines: 4,
        ),
      ],
    );
  }
}
