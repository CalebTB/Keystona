/// Column lists for `maintenance_tasks` and its children. One place, so a
/// column added to the model is added to every query that builds one.
/// Never `SELECT *`; every name here exists in the database.
abstract final class TaskColumns {
  /// The columns of [MaintenanceTask].
  static const String task =
      'id, property_id, user_id, template_id, task_origin, name, '
      'description, instructions, category, due_date, recurrence, '
      'recurrence_interval_years, season, climate_adjusted, status, '
      'difficulty, diy_or_pro, priority, estimated_minutes, estimated_cost, '
      'notes, tools_needed, supplies_needed, linked_system_id, '
      'linked_appliance_id, notifications_enabled, notifications_off_at, '
      'notifications_off_reason, tags, skip_reason, created_at, updated_at';

  /// The columns of [TaskCompletion].
  static const String completion =
      'id, task_id, user_id, property_id, completed_date, completed_by, '
      'contractor_name, contractor_company, contractor_phone, service_cost, '
      'materials_cost, time_spent_minutes, notes, linked_document_ids, '
      'findings, log_to_item_history, due_date, created_at';

  /// The columns of [TaskSkip].
  static const String skip = 'id, task_id, skipped_on, due_date, reason';
}
