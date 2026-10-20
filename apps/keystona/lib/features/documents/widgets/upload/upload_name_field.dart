import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_b.dart';
import '../../../../core/theme/aurora_typography.dart';
import 'upload_box_field.dart';

/// Document name: required, up to 120 characters.
class UploadNameField extends StatelessWidget {
  const UploadNameField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.edged,
    required this.enabled,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool edged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return UploadBoxField(
      label: 'Name',
      isRequired: true,
      edged: edged,
      child: TextField(
        controller: controller,
        enabled: enabled,
        onChanged: onChanged,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.next,
        inputFormatters: [
          LengthLimitingTextInputFormatter(AuroraUploadRules.maxNameLength),
        ],
        style: AuroraType.input,
        cursorColor: AuroraColors.cobalt,
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: 'Document name',
          hintStyle: AuroraType.input.copyWith(
            color: AuroraColors.inkPlaceholder,
          ),
        ),
      ),
    );
  }
}
