import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/maintenance_task.dart';
import 'task_filter_provider.dart';

part 'maintenance_tasks_provider.g.dart';

// ── Main data provider ────────────────────────────────────────────────────────

/// Loads all non-deleted maintenance tasks for the authenticated user's property.
///
/// The provider fetches tasks with nested system names to avoid N+1 queries.
/// Filtering, sorting, and section grouping are all performed client-side by
/// [filteredTasksProvider].
///
/// Extension points for downstream issues:
/// - [completeTask] — stub, implemented by issue #32 (Complete Task)
/// - [skipTask]     — stub, implemented by issue #32 (Skip Task)
/// - [softDelete]   — stub, implemented by issue #33 (Delete Task)
@riverpod
class MaintenanceTasksNotifier extends _$MaintenanceTasksNotifier {
  @override
  Future<List<MaintenanceTask>> build() => _fetchTasks();

  // ── Public interface ──────────────────────────────────────────────────────

  /// Refetches tasks from Supabase and replaces the current list.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchTasks);
  }

  /// [#32] Marks a task as completed and inserts a quick [TaskCompletion] row.
  ///
  /// Used by the Task Detail screen for one-tap quick complete. The detailed
  /// completion flow (photos, notes, cost) is handled by issue #33.
  Future<void> completeTask(String taskId) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return;

    final tasks = state.value ?? [];
    final matching = tasks.where((t) => t.id == taskId);
    if (matching.isEmpty) return;
    final task = matching.first;

    final today = DateTime.now().toIso8601String().split('T')[0];

    await SupabaseService.client.from('task_completions').insert({
      'task_id': taskId,
      'user_id': user.id,
      'property_id': task.propertyId,
      'completed_date': today,
      'completed_by': 'diy',
    });

    await SupabaseService.client
        .from('maintenance_tasks')
        .update({'status': 'completed'})
        .eq('id', taskId);

    if (task.recurrence != RecurrenceType.none) {
      await SupabaseService.client.functions.invoke(
        'schedule-next-task',
        body: {'task_id': taskId},
      );
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchTasks);
  }

  /// [#32] Skips a task with an optional [reason].
  Future<void> skipTask(String taskId, {String? reason}) async {
    final tasks = state.value ?? [];
    final matching = tasks.where((t) => t.id == taskId);
    if (matching.isEmpty) return;
    final task = matching.first;

    await SupabaseService.client
        .from('maintenance_tasks')
        .update({
          'status': 'skipped',
          if (reason != null && reason.isNotEmpty) 'skip_reason': reason,
        })
        .eq('id', taskId);

    if (task.recurrence != RecurrenceType.none) {
      await SupabaseService.client.functions.invoke(
        'schedule-next-task',
        body: {'task_id': taskId},
      );
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchTasks);
  }

  /// Creates a new custom task for the user's property.
  ///
  /// [fields] must include all required columns: `name`, `category`,
  /// `due_date`, `task_origin`, `property_id`, `user_id`.
  /// Optional columns: `description`, `recurrence`, `priority`,
  /// `difficulty`, `diy_or_pro`, `estimated_minutes`, `tools_needed`,
  /// `supplies_needed`, `linked_system_id`, `linked_appliance_id`.
  Future<void> addTask(Map<String, dynamic> fields) async {
    await SupabaseService.client.from('maintenance_tasks').insert(fields);
    await refresh();
  }

  /// Updates mutable fields on an existing task.
  ///
  /// Only pass the fields that have changed. The `updated_at` trigger
  /// on the DB handles the timestamp automatically.
  Future<void> updateTask(String taskId, Map<String, dynamic> fields) async {
    await SupabaseService.client
        .from('maintenance_tasks')
        .update(fields)
        .eq('id', taskId);
    await refresh();
  }

  /// [#33] Soft-deletes a task (sets deleted_at).
  Future<void> softDelete(String taskId) async {
    throw UnimplementedError('softDelete() implemented by issue #33');
  }

  /// Generates maintenance tasks from templates directly via DB queries.
  ///
  /// Mirrors the logic of the `generate-maintenance-tasks` Edge Function but
  /// runs client-side using the authenticated Supabase client — no JWT
  /// gateway required. Idempotent: no-ops if template tasks already exist.
  Future<void> generateFromTemplates() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return;

    // Fetch property.
    final propertyRow = await SupabaseService.client
        .from('properties')
        .select('id, climate_zone')
        .eq('user_id', user.id)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (propertyRow == null) return;

    final propertyId = propertyRow['id'] as String;
    final climateZone = propertyRow['climate_zone'] as int?;

    // Idempotency: skip if template tasks already exist.
    final existing = await SupabaseService.client
        .from('maintenance_tasks')
        .select('id')
        .eq('property_id', propertyId)
        .not('template_id', 'is', null)
        .isFilter('deleted_at', null);
    if (existing.isNotEmpty) return;

    // Fetch active templates.
    final templates = await SupabaseService.client
        .from('maintenance_task_templates')
        .select(
          'id, name, description, instructions, category, season, recurrence, '
          'default_month, difficulty, diy_or_pro, priority, estimated_minutes, '
          'tools_needed, supplies_needed, climate_zones',
        )
        .eq('is_active', true);

    // Filter by climate zone (null zones = applies to all).
    final filtered = climateZone != null
        ? templates.where((t) {
            final zones = t['climate_zones'] as List?;
            return zones == null || zones.contains(climateZone);
          }).toList()
        : templates;

    if (filtered.isEmpty) return;

    // Build task rows with computed due dates.
    final now = DateTime.now().toUtc();
    final taskRows = filtered.map<Map<String, dynamic>>((t) {
      return {
        'property_id': propertyId,
        'user_id': user.id,
        'template_id': t['id'],
        'task_origin': 'system_generated',
        'name': t['name'],
        'description': t['description'],
        'instructions': t['instructions'],
        'category': t['category'],
        'linked_system_id': null,
        'linked_appliance_id': null,
        'due_date': _computeDueDate(t, now),
        'recurrence': t['recurrence'],
        'season': t['season'],
        'climate_adjusted': climateZone != null,
        'status': 'scheduled',
        'difficulty': t['difficulty'],
        'diy_or_pro': t['diy_or_pro'],
        'priority': t['priority'],
        'estimated_minutes': t['estimated_minutes'],
        'tools_needed': t['tools_needed'] ?? <dynamic>[],
        'supplies_needed': t['supplies_needed'] ?? <dynamic>[],
        'reminder_days_before': 7,
        'notifications_enabled': true,
      };
    }).toList();

    await SupabaseService.client.from('maintenance_tasks').insert(taskRows);
    await refresh();
  }

  /// Computes the initial due date for a template task, matching the
  /// TypeScript logic in the `generate-maintenance-tasks` Edge Function.
  String _computeDueDate(Map<String, dynamic> template, DateTime now) {
    final currentMonth = now.month;
    final currentYear = now.year;
    final recurrence = template['recurrence'] as String? ?? 'none';
    final season = template['season'] as String?;
    final defaultMonth = template['default_month'] as int?;

    // Monthly with no season → due the 1st of next month.
    if (recurrence == 'monthly' && season == null) {
      final next = DateTime.utc(currentYear, currentMonth + 1, 1);
      return '${next.year}-${next.month.toString().padLeft(2, '0')}-01';
    }

    const seasonMonths = {
      'spring': 4,
      'summer': 7,
      'fall': 10,
      'winter': 12,
    };

    final targetMonth = defaultMonth ??
        (season != null ? seasonMonths[season] : null) ??
        currentMonth;

    final targetYear =
        targetMonth < currentMonth ? currentYear + 1 : currentYear;

    return '$targetYear-${targetMonth.toString().padLeft(2, '0')}-01';
  }

  // ── Private fetch ─────────────────────────────────────────────────────────

  Future<List<MaintenanceTask>> _fetchTasks() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return [];

    // Fetch the user's primary property.
    final propertyRow = await SupabaseService.client
        .from('properties')
        .select('id')
        .eq('user_id', user.id)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (propertyRow == null) return [];
    final propertyId = propertyRow['id'] as String;

    // Fetch tasks with nested system name to avoid N+1.
    // Includes tools_needed and supplies_needed for edit pre-population (#34)
    // and detail display (#32).
    final rows = await SupabaseService.client
        .from('maintenance_tasks')
        .select(
          'id, property_id, user_id, template_id, task_origin, name, '
          'description, instructions, category, due_date, recurrence, season, '
          'climate_adjusted, status, difficulty, diy_or_pro, priority, '
          'estimated_minutes, tools_needed, supplies_needed, '
          'linked_system_id, linked_appliance_id, '
          'created_at, updated_at, '
          'systems(id, name)',
        )
        .eq('property_id', propertyId)
        .isFilter('deleted_at', null)
        .order('due_date', ascending: true);

    return rows.map(_rowToTask).toList();
  }

  MaintenanceTask _rowToTask(Map<String, dynamic> row) {
    // Extract nested system name before parsing the model.
    final systemRow = row['systems'] as Map<String, dynamic>?;
    final systemName = systemRow?['name'] as String?;

    // Remove the nested object so fromJson doesn't choke on it.
    final cleaned = Map<String, dynamic>.from(row)..remove('systems');

    return MaintenanceTask.fromJson(cleaned).copyWith(
      linkedSystemName: systemName,
    );
  }
}

// ── Derived — filtered + sorted task list ─────────────────────────────────────

/// Returns the filtered and sorted task list by combining
/// [maintenanceTasksProvider] data with [taskFilterProvider] state.
///
/// This is a synchronous derived provider — it never triggers a network call.
/// The Maintenance screen watches this provider for its display list.
@riverpod
List<MaintenanceTask> filteredTasks(Ref ref) {
  final tasksAsync = ref.watch(maintenanceTasksProvider);
  final filter = ref.watch(taskFilterProvider);

  final tasks = tasksAsync.value ?? [];

  final now = DateTime.now().toLocal();
  final todayMidnight = DateTime(now.year, now.month, now.day);
  final weekEnd = todayMidnight.add(const Duration(days: 7));

  // Explicit typing avoids dynamic inference when Ref is unparameterized.
  final TaskStatusFilter? statusFilter = filter.statusFilter;
  final TaskSortOrder sortOrder = filter.sortOrder;

  final List<MaintenanceTask> filtered;
  if (statusFilter == TaskStatusFilter.overdue) {
    filtered = tasks.where((t) => _isOverdue(t, todayMidnight)).toList();
  } else if (statusFilter == TaskStatusFilter.dueSoon) {
    filtered = tasks.where((t) => _isDueSoon(t, todayMidnight, weekEnd)).toList();
  } else if (statusFilter == TaskStatusFilter.upcoming) {
    filtered = tasks.where((t) => _isUpcoming(t, weekEnd)).toList();
  } else if (statusFilter == TaskStatusFilter.completed) {
    filtered = tasks
        .where(
          (t) =>
              t.status == TaskStatus.completed ||
              t.status == TaskStatus.skipped,
        )
        .toList();
  } else {
    // null → All
    filtered = tasks.where((t) => t.status != TaskStatus.skipped).toList();
  }

  filtered.sort((a, b) {
    if (sortOrder == TaskSortOrder.priorityDesc) {
      return b.priority.sortOrder.compareTo(a.priority.sortOrder);
    } else if (sortOrder == TaskSortOrder.nameAsc) {
      return a.name.compareTo(b.name);
    }
    return a.dueDate.compareTo(b.dueDate); // dueDateAsc (default)
  });

  return filtered;
}

// ── Date helpers (module-private) ─────────────────────────────────────────────

bool _isOverdue(MaintenanceTask t, DateTime todayMidnight) {
  if (t.status == TaskStatus.completed || t.status == TaskStatus.skipped) {
    return false;
  }
  return t.status == TaskStatus.overdue ||
      t.dueDate.toLocal().isBefore(todayMidnight);
}

bool _isDueSoon(
  MaintenanceTask t,
  DateTime todayMidnight,
  DateTime weekEnd,
) {
  if (t.status == TaskStatus.completed || t.status == TaskStatus.skipped) {
    return false;
  }
  if (_isOverdue(t, todayMidnight)) return false;
  final due = t.dueDate.toLocal();
  return !due.isBefore(todayMidnight) && due.isBefore(weekEnd);
}

bool _isUpcoming(MaintenanceTask t, DateTime weekEnd) {
  if (t.status == TaskStatus.completed || t.status == TaskStatus.skipped) {
    return false;
  }
  return !t.dueDate.toLocal().isBefore(weekEnd);
}
