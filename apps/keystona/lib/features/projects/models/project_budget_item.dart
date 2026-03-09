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
    required double estimatedCost,
    required double actualCost,
    required bool isPaid,
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
  });

  final double estimatedTotal;
  final double actualTotal;
  final double remaining;
  final List<BudgetCategoryRow> categoryBreakdown;

  bool get isOverBudget => actualTotal > estimatedTotal && estimatedTotal > 0;

  factory BudgetSummary.fromRpc(Map<String, dynamic> json) {
    final breakdown = (json['category_breakdown'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(BudgetCategoryRow.fromRpc)
        .toList();
    return BudgetSummary(
      estimatedTotal: (json['estimated_total'] as num?)?.toDouble() ?? 0,
      actualTotal: (json['actual_total'] as num?)?.toDouble() ?? 0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0,
      categoryBreakdown: breakdown,
    );
  }

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
  });

  final String category;
  final double estimated;
  final double actual;

  factory BudgetCategoryRow.fromRpc(Map<String, dynamic> json) =>
      BudgetCategoryRow(
        category: json['category'] as String,
        estimated: (json['estimated'] as num?)?.toDouble() ?? 0,
        actual: (json['actual'] as num?)?.toDouble() ?? 0,
      );
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
