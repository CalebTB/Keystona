import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_text_field.dart';
import '../../edit/home_edit_form.dart';
import '../../home_edit_copy.dart';
import '../shared/mono_section_label.dart';
import 'field_pair.dart';

/// ADDRESS: street, then city, state and ZIP.
class AddressSection extends StatelessWidget {
  const AddressSection({super.key, required this.form});

  final HomeEditForm form;

  /// City, state and ZIP share a row 1.4 : 0.7 : 1.
  static const List<int> _flexes = [14, 7, 10];

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return ListenableBuilder(
      listenable: form,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: a.of(AuroraSpacing.space6),
        children: [
          const MonoSectionLabel(HomeEditCopy.address),
          AuroraTextField(
            label: HomeEditCopy.street,
            controller: form.street,
            required: true,
            keyboardType: TextInputType.streetAddress,
          ),
          FieldPair(
            flexes: _flexes,
            children: [
              AuroraTextField(label: HomeEditCopy.city, controller: form.city),
              AuroraTextField(
                label: HomeEditCopy.state,
                controller: form.state,
                helperText: form.stateHelp,
              ),
              AuroraTextField(
                label: HomeEditCopy.zip,
                controller: form.zip,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
