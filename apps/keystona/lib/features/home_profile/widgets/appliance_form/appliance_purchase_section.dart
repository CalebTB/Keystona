import 'package:flutter/material.dart';

import '../../../../core/widgets/aurora/aurora_button.dart';
import '../../../../core/widgets/aurora/aurora_form_section.dart';
import '../../../../core/widgets/aurora/aurora_text_field.dart';
import '../../../../core/widgets/aurora/aurora_toggle_row.dart';
import '../../appliance_copy.dart';
import '../../models/appliance_form_data.dart';
import '../../models/form_date.dart';
import 'form_pair.dart';

/// PURCHASE (optional): price, retailer, purchase date, and the warranty
/// switch with its provider, expiry and the link to the warranty in Docs.
class AppliancePurchaseSection extends StatelessWidget {
  const AppliancePurchaseSection({
    super.key,
    required this.price,
    required this.retailer,
    required this.purchaseDate,
    required this.hasWarranty,
    required this.onWarranty,
    required this.warrantyProvider,
    required this.warrantyExpires,
    required this.linkedDocName,
    required this.onLinkWarranty,
  });

  final TextEditingController price;
  final TextEditingController retailer;
  final TextEditingController purchaseDate;
  final bool hasWarranty;
  final ValueChanged<bool> onWarranty;
  final TextEditingController warrantyProvider;
  final TextEditingController warrantyExpires;

  /// The linked warranty document's name; null when none is linked.
  final String? linkedDocName;
  final VoidCallback onLinkWarranty;

  static String? _dateError(String? v) =>
      FormDate.isValidOrEmpty(v ?? '') ? null : ApplianceCopy.dateInvalid;

  @override
  Widget build(BuildContext context) {
    return AuroraFormSection(
      title: ApplianceCopy.purchase,
      isOptional: true,
      children: [
        FormPair(
          left: AuroraTextField(
            label: ApplianceCopy.price,
            controller: price,
            hintText: ApplianceCopy.priceHint,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              final t = (v ?? '').trim();
              return t.isEmpty || ApplianceFormData.parsePrice(t) != null
                  ? null
                  : ApplianceCopy.priceInvalid;
            },
          ),
          right: AuroraTextField(
            label: ApplianceCopy.retailer,
            controller: retailer,
            hintText: ApplianceCopy.retailerHint,
          ),
        ),
        AuroraTextField(
          label: ApplianceCopy.purchaseDate,
          controller: purchaseDate,
          hintText: ApplianceCopy.dateHint,
          keyboardType: TextInputType.datetime,
          validator: _dateError,
        ),
        AuroraToggleRow(
          label: ApplianceCopy.hasWarranty,
          helperText: ApplianceCopy.hasWarrantyHelper,
          value: hasWarranty,
          onChanged: onWarranty,
        ),
        if (hasWarranty) ...[
          FormPair(
            left: AuroraTextField(
              label: ApplianceCopy.warrantyProvider,
              controller: warrantyProvider,
            ),
            right: AuroraTextField(
              label: ApplianceCopy.warrantyExpires,
              controller: warrantyExpires,
              hintText: ApplianceCopy.dateHint,
              keyboardType: TextInputType.datetime,
              validator: _dateError,
            ),
          ),
          SecondaryButton(
            label: linkedDocName == null
                ? ApplianceCopy.linkWarranty
                : ApplianceCopy.warrantyLinked(linkedDocName!),
            onPressed: onLinkWarranty,
            expand: true,
          ),
        ],
      ],
    );
  }
}
