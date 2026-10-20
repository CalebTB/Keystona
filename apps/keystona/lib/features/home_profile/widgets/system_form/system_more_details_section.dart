import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/aurora_home_b.dart';
import '../../../../core/widgets/aurora/aurora_button.dart';
import '../../../../core/widgets/aurora/aurora_form_section.dart';
import '../../../../core/widgets/aurora/aurora_select_field.dart';
import '../../../../core/widgets/aurora/aurora_text_field.dart';
import '../../forms/system_form_controller.dart';
import '../../models/system.dart';
import '../../systems_copy.dart';
import '../service/document_picker.dart';
import 'option_picker.dart';

/// Edit mode only: what the kit's Add form leaves out (location, installer,
/// price, status, specifications, warranty, notes).
class SystemMoreDetailsSection extends StatelessWidget {
  const SystemMoreDetailsSection({super.key, required this.form});

  final SystemFormController form;

  Future<void> _pickExpiry(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: form.warrantyExpiration ?? now,
      firstDate: DateTime(now.year - 30),
      lastDate: DateTime(now.year + 30),
    );
    if (picked != null) form.setWarrantyExpiration(picked);
  }

  @override
  Widget build(BuildContext context) {
    final ends = form.warrantyExpiration;
    return AuroraFormSection(
      title: SystemsCopy.sectionMore,
      isOptional: true,
      children: [
        AuroraTextField(
          label: SystemsCopy.location,
          controller: form.location,
          hintText: SystemsCopy.locationHint,
          maxLength: AuroraHomeBSizes.fieldMaxLength,
        ),
        AuroraTextField(
          label: SystemsCopy.installer,
          controller: form.installer,
          maxLength: AuroraHomeBSizes.fieldMaxLength,
        ),
        AuroraTextField(
          label: SystemsCopy.price,
          controller: form.price,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          helperText: form.priceInvalid ? SystemsCopy.priceInvalid : null,
        ),
        AuroraSelectField(
          label: SystemsCopy.status,
          value: form.status.label,
          onTap: () async {
            final picked = await pickOption<ItemStatus>(
              context,
              title: SystemsCopy.statusSheet,
              options: ItemStatus.values,
              labelOf: (s) => s.label,
            );
            if (picked != null) form.setStatus(picked);
          },
        ),
        AuroraTextField(
          label: SystemsCopy.fuel,
          controller: form.fuel,
          maxLength: AuroraHomeBSizes.fieldMaxLength,
        ),
        AuroraTextField(
          label: SystemsCopy.output,
          controller: form.output,
          maxLength: AuroraHomeBSizes.fieldMaxLength,
        ),
        AuroraTextField(
          label: SystemsCopy.filter,
          controller: form.filter,
          maxLength: AuroraHomeBSizes.fieldMaxLength,
        ),
        AuroraTextField(
          label: SystemsCopy.warrantyProvider,
          controller: form.warrantyProvider,
          maxLength: AuroraHomeBSizes.fieldMaxLength,
        ),
        AuroraSelectField(
          label: SystemsCopy.warrantyExpires,
          value: ends == null ? null : DateFormat.yMMMd().format(ends),
          placeholder: SystemsCopy.warrantyPick,
          onTap: () => _pickExpiry(context),
        ),
        if (ends != null)
          Align(
            alignment: Alignment.centerLeft,
            child: GhostButton(
              label: SystemsCopy.warrantyClear,
              onPressed: () => form.setWarrantyExpiration(null),
            ),
          ),
        AuroraSelectField(
          label: SystemsCopy.warrantyDoc,
          value: form.warrantyDocId == null
              ? null
              : (form.warrantyDocName ?? SystemsCopy.warrantyDefaultTitle),
          placeholder: SystemsCopy.warrantyDocNone,
          onTap: () async {
            final choice = await pickDocument(context);
            if (choice != null) form.setWarrantyDoc(choice.id, choice.name);
          },
        ),
        AuroraTextField(
          label: SystemsCopy.notes,
          controller: form.notes,
          maxLines: 5,
          maxLength: AuroraHomeBSizes.noteMaxLength,
        ),
      ],
    );
  }
}
