import 'package:flutter/material.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/theme/aurora_spacing.dart';

import '../models/project_budget_item.dart';
import '../../../core/theme/aurora_radius.dart';

/// Single budget line item row.
class BudgetItemCard extends StatelessWidget {
  const BudgetItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final ProjectBudgetItem item;
  final VoidCallback onTap;

  String _fmt(double v) => '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final hasActual = item.actualCost > 0;
    final isOver = hasActual && item.actualCost > item.estimatedCost;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 72.0),
        padding: const EdgeInsets.symmetric(
          horizontal: AuroraSpacing.space7,
          vertical: AuroraSpacing.space3 + 2,
        ),
        decoration: BoxDecoration(
          color: AuroraColors.paper,
          borderRadius: AuroraRadius.md,
          border: Border.all(color: AuroraColors.inkBorder),
        ),
        child: Row(
          children: [
            // Paid indicator dot.
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isPaid ? AuroraColors.lime : const Color(0xFFE0DFEA),
              ),
            ),
            const SizedBox(width: AuroraSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AuroraType.h3),
                  Text(
                    item.category.budgetCategoryLabel,
                    style: AuroraType.bodySm
                        .copyWith(color: AuroraColors.inkSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hasActual)
                  Text(
                    _fmt(item.actualCost),
                    style: AuroraType.h3.copyWith(
                      color: isOver ? AuroraColors.coral : AuroraColors.ink,
                    ),
                  )
                else
                  Text(
                    _fmt(item.estimatedCost),
                    style: AuroraType.body
                        .copyWith(color: AuroraColors.inkSecondary),
                  ),
                Text(
                  hasActual ? 'est. ${_fmt(item.estimatedCost)}' : 'estimated',
                  style: AuroraType.bodySm
                      .copyWith(color: AuroraColors.inkSecondary),
                ),
              ],
            ),
            const SizedBox(width: AuroraSpacing.space1),
            const Icon(Icons.chevron_right, color: AuroraColors.inkTertiary, size: 18),
          ],
        ),
      ),
    );
  }
}
