import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../../../core/widgets/aurora/aurora_sheet.dart';
import '../../../documents/providers/documents_provider.dart';
import '../../systems_copy.dart';

/// What the document picker returns: a document, or "none" (both null).
class DocumentChoice {
  const DocumentChoice({this.id, this.name});

  final String? id;
  final String? name;
}

/// Opens a list of the property's documents. Null when cancelled; a choice
/// with no id when "No document" was tapped. Closes with its own context.
Future<DocumentChoice?> pickDocument(BuildContext context) =>
    AuroraSheet.showAuto<DocumentChoice>(
      context,
      title: SystemsCopy.docPickerTitle,
      child: const _DocumentList(),
    );

class _DocumentList extends ConsumerWidget {
  const _DocumentList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aurora;
    final docs = ref.watch(documentsProvider).value ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Row(
          label: SystemsCopy.docPickerNone,
          onTap: () => Navigator.of(context).pop(const DocumentChoice()),
        ),
        if (docs.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: a.of(AuroraSpacing.space6)),
            child: Text(SystemsCopy.docPickerEmpty, style: AuroraType.body),
          ),
        for (final d in docs)
          _Row(
            label: d.name,
            onTap: () => Navigator.of(
              context,
            ).pop(DocumentChoice(id: d.id, name: d.name)),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: label,
      enforceTouchTarget: true,
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraSizes.minTouch),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AuroraType.rowTitle.copyWith(color: AuroraColors.ink),
        ),
      ),
    );
  }
}
