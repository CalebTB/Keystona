import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../models/document_category.dart';
import 'category_delete_panel.dart';
import 'category_row.dart';

/// The user's own categories in one bordered, reorderable list. The row being
/// deleted shows its confirmation panel underneath.
class CategoryListCard extends StatelessWidget {
  const CategoryListCard({
    super.key,
    required this.categories,
    required this.counts,
    required this.confirmingId,
    required this.moveTargets,
    required this.selectedMoveId,
    required this.onReorder,
    required this.onEdit,
    required this.onDelete,
    required this.onPickMove,
    required this.onKeep,
    required this.onConfirmDelete,
  });

  final List<DocumentCategory> categories;
  final Map<String, int> counts;

  /// Id of the category whose delete panel is open, if any.
  final String? confirmingId;
  final List<({String id, String name})> moveTargets;
  final String? selectedMoveId;

  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<DocumentCategory> onEdit;
  final ValueChanged<DocumentCategory> onDelete;
  final ValueChanged<String> onPickMove;
  final VoidCallback onKeep;
  final ValueChanged<DocumentCategory> onConfirmDelete;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.xl,
        border: Border.all(
          color: AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: ClipRRect(
        borderRadius: AuroraRadius.xl,
        child: ReorderableListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: categories.length,
          onReorder: onReorder,
          itemBuilder: (context, index) {
            final category = categories[index];
            final count = counts[category.id] ?? 0;
            return DecoratedBox(
              key: ValueKey(category.id),
              decoration: BoxDecoration(
                color: AuroraColors.paper,
                border: index == 0
                    ? null
                    : const Border(
                        top: BorderSide(
                          color: AuroraColors.inkBorder,
                          width: AuroraBorders.hairline,
                        ),
                      ),
              ),
              child: Column(
                children: [
                  CategoryRow(
                    index: index,
                    name: category.name,
                    iconKey: category.icon,
                    documentCount: count,
                    onEdit: () => onEdit(category),
                    onDelete: () => onDelete(category),
                  ),
                  if (confirmingId == category.id)
                    CategoryDeletePanel(
                      name: category.name,
                      documentCount: count,
                      moveTargets: moveTargets,
                      selectedMoveId: selectedMoveId,
                      onPickMove: onPickMove,
                      onKeep: onKeep,
                      onConfirm: () => onConfirmDelete(category),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
