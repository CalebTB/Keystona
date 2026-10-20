import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_a.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_button.dart';
import '../../../../core/widgets/aurora/aurora_chip.dart';
import '../../categories_copy.dart';
import '../docs_button_row.dart';

/// The inline "Delete “Solar panels”?" confirmation under a category row:
/// where its documents go, then Keep it or Delete & move.
class CategoryDeletePanel extends StatelessWidget {
  const CategoryDeletePanel({
    super.key,
    required this.name,
    required this.documentCount,
    required this.moveTargets,
    required this.selectedMoveId,
    required this.onPickMove,
    required this.onKeep,
    required this.onConfirm,
  });

  final String name;
  final int documentCount;

  /// The categories documents can move to: (id, name).
  final List<({String id, String name})> moveTargets;
  final String? selectedMoveId;
  final ValueChanged<String> onPickMove;
  final VoidCallback onKeep;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final hasDocuments = documentCount > 0;
    return Container(
      margin: EdgeInsets.fromLTRB(
        a.of(AuroraSpacing.space5),
        0,
        a.of(AuroraSpacing.space5),
        a.of(AuroraSpacing.space5),
      ),
      padding: a.all(AuroraSpacing.space6),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.lg,
        border: Border.all(
          color: AuroraColors.coral,
          width: AuroraBorders.emphasis,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            CategoriesCopy.deleteTitle(name),
            style: AuroraDocsAType.confirmTitle,
          ),
          SizedBox(height: a.of(AuroraSpacing.space4)),
          Text(
            CategoriesCopy.moveBody(documentCount),
            style: AuroraDocsAType.confirmBody,
          ),
          if (hasDocuments) ...[
            SizedBox(height: a.of(AuroraSpacing.space4)),
            Wrap(
              spacing: a.of(AuroraSpacing.space2),
              runSpacing: a.of(AuroraSpacing.space2),
              children: [
                for (final target in moveTargets)
                  FilterPill(
                    label: target.name,
                    selected: target.id == selectedMoveId,
                    onTap: () => onPickMove(target.id),
                  ),
              ],
            ),
          ],
          SizedBox(height: a.of(AuroraSpacing.space4)),
          DocsButtonRow(
            equalWidth: true,
            secondaryFirst: true,
            secondary: SecondaryButton(
              label: CategoriesCopy.keepIt,
              onPressed: onKeep,
              expand: true,
            ),
            primary: PrimaryButton(
              label: hasDocuments
                  ? CategoriesCopy.deleteAndMove
                  : CategoriesCopy.deleteOnly,
              onPressed: onConfirm,
              expand: true,
              tone: AuroraButtonTone.coral,
            ),
          ),
        ],
      ),
    );
  }
}
