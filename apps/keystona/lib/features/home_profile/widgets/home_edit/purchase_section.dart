import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_select_field.dart';
import '../../../../core/widgets/aurora/aurora_text_field.dart';
import '../../edit/home_edit_form.dart';
import '../../home_edit_copy.dart';
import '../../home_profile_format.dart';
import '../shared/mono_section_label.dart';
import 'field_pair.dart';

/// "WHEN YOU BOUGHT IT": the month and year, and the price. Optional, and
/// only the owner sees it.
class PurchaseSection extends StatelessWidget {
  const PurchaseSection({
    super.key,
    required this.form,
    required this.onPickDate,
  });

  final HomeEditForm form;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return ListenableBuilder(
      listenable: form,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: a.of(AuroraSpacing.space6),
        children: [
          const MonoSectionLabel(
            HomeEditCopy.bought,
            trailing: HomeEditCopy.boughtNote,
          ),
          FieldPair(
            children: [
              AuroraSelectField(
                label: HomeEditCopy.date,
                value: form.purchaseDate == null
                    ? null
                    : HomeFormat.monthYear(form.purchaseDate!),
                placeholder: HomeEditCopy.garageUnset,
                onTap: onPickDate,
              ),
              AuroraTextField(
                label: HomeEditCopy.price,
                controller: form.price,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
