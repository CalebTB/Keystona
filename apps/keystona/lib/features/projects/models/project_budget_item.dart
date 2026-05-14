// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_budget_item.freezed.dart';
part 'project_budget_item.g.dart';

/// Budget line item for a project.
@freezed
abstract class ProjectBudgetItem with _$ProjectBudgetItem {
  const factory ProjectBudgetItem({
    required String id,
    required String projectId,
    required String userId,
    required String name,
    required String category,
    @Default(0.0) double estimatedCost,
    @Default(0.0) double actualCost,
    @Default(false) bool isPaid,
    String? vendor,
    String? receiptDocumentId,
    String? phaseId,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _ProjectBudgetItem;

  factory ProjectBudgetItem.fromJson(Map<String, dynamic> json) =>
      _$ProjectBudgetItemFromJson(json);
}

// ── Budget summary (from RPC) ──────────────────────────────────────────────

/// Aggregate returned by `get_project_budget_summary`.
class BudgetSummary {
  const BudgetSummary({
    required this.estimatedTotal,
    required this.actualTotal,
    required this.remaining,
    required this.categoryBreakdown,
    this.overBudgetCount = 0,
    this.totalItems = 0,
  });

  final double estimatedTotal;
  final double actualTotal;
  final double remaining;
  final List<BudgetCategoryRow> categoryBreakdown;
  final int overBudgetCount;
  final int totalItems;

  bool get isOverBudget => actualTotal > estimatedTotal && estimatedTotal > 0;

  static BudgetSummary empty() => const BudgetSummary(
        estimatedTotal: 0,
        actualTotal: 0,
        remaining: 0,
        categoryBreakdown: [],
      );
}

class BudgetCategoryRow {
  const BudgetCategoryRow({
    required this.category,
    required this.estimated,
    required this.actual,
    this.lineItemCount = 0,
    this.pendingCount = 0,
  });

  final String category;
  final double estimated;
  final double actual;
  final int lineItemCount;
  final int pendingCount;
}

// ── Budget category helpers ───────────────────────────────────────────────

extension BudgetCategoryLabel on String {
  String get budgetCategoryLabel => switch (this) {
        'materials' => 'Materials',
        'labor' => 'Labor',
        'permits' => 'Permits',
        'fixtures' => 'Fixtures',
        'equipment_rental' => 'Equipment Rental',
        'design' => 'Design',
        'other' => 'Other',
        _ => this,
      };
}

abstract final class BudgetCategories {
  static const all = [
    'materials',
    'labor',
    'permits',
    'fixtures',
    'equipment_rental',
    'design',
    'other',
  ];
}
