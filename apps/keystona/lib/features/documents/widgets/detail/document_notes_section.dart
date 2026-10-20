import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_docs_c.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_button.dart';
import '../shared/docs_section_header.dart';

/// "Notes": the owner's paragraph beside a cobalt rule, or a prompt to add
/// one.
class DocumentNotesSection extends StatelessWidget {
  const DocumentNotesSection({
    super.key,
    required this.notes,
    required this.onAdd,
  });

  final String? notes;

  /// Opens the edit sheet.
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final text = notes?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DocsSectionHeader(title: 'Notes'),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        if (text.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: GhostButton(label: 'Add a note', onPressed: onAdd),
          )
        else
          Container(
            padding: EdgeInsets.only(
              left: a.of(AuroraSpacing.space6),
              top: AuroraBorders.regular,
              bottom: AuroraBorders.regular,
            ),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: AuroraDocsCColors.noteRule,
                  width: AuroraDocsCSizes.noteRuleWidth,
                ),
              ),
            ),
            child: Text(text, style: AuroraDocsCType.notes),
          ),
      ],
    );
  }
}
