import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'task_filter_provider.g.dart';

// ── Filter models ─────────────────────────────────────────────────────────────

/// Which subset of tasks to display.
enum TaskStatusFilter {
  overdue,
  dueSoon,
  upcoming,
  completed,
}

/// Sort order for the task list.
enum TaskSortOrder {
  /// Soonest due first (default).
  dueDateAsc,

  /// Critical first, then high, medium, low.
  priorityDesc,

  /// Alphabetical A–Z.
  nameAsc,
}

/// Immutable snapshot of the active filter + sort state.
class TaskFilter {
  const TaskFilter({
    this.statusFilter,
    this.sortOrder = TaskSortOrder.dueDateAsc,
  });

  /// Null means "All" — no status filter applied.
  final TaskStatusFilter? statusFilter;
  final TaskSortOrder sortOrder;

  TaskFilter copyWith({
    TaskStatusFilter? statusFilter,
    bool clearStatusFilter = false,
    TaskSortOrder? sortOrder,
  }) {
    return TaskFilter(
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// Manages the active filter and sort order for the Maintenance screen.
///
/// Separate from [MaintenanceTasksNotifier] so filter changes never trigger
/// a refetch — they only re-sort/re-filter the in-memory list via
/// [filteredTasksProvider] in maintenance_tasks_provider.dart.
@riverpod
class TaskFilterNotifier extends _$TaskFilterNotifier {
  @override
  TaskFilter build() => const TaskFilter();

  void setStatusFilter(TaskStatusFilter? filter) {
    state = state.copyWith(
      statusFilter: filter,
      clearStatusFilter: filter == null,
    );
  }

  void setSortOrder(TaskSortOrder order) {
    state = state.copyWith(sortOrder: order);
  }
}
