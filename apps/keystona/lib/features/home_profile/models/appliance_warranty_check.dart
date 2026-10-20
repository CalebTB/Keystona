import '../../maintenance/models/maintenance_task.dart';
import '../../maintenance/models/task_schedule.dart';
import '../../maintenance/repositories/task_form_repository.dart';
import 'appliance.dart';

/// The "Add a check before Dec 9" one-off task an appliance offers while its
/// warranty is about to end. Pure Dart: the rules and the task's columns.
abstract final class ApplianceWarrantyCheck {
  /// Marks the task so the appliance can tell it already has one.
  static const String tag = 'warranty-check';

  /// The callout shows when the warranty ends within this many days.
  static const int soonDays = 90;

  /// The check is due this many days before the warranty ends.
  static const int leadDays = 14;

  /// Whole days from [today] to [expires]; negative once it has ended.
  static int daysLeft(DateTime expires, DateTime today) =>
      TaskSchedule.dayOf(expires).difference(TaskSchedule.dayOf(today)).inDays;

  /// True while the warranty is still running and ends within [soonDays].
  static bool endsSoon(DateTime? expires, DateTime today) {
    if (expires == null) return false;
    final left = daysLeft(expires, today);
    return left >= 0 && left <= soonDays;
  }

  /// When the check is due: [leadDays] before the warranty ends, or today
  /// when that is already past.
  static DateTime dueDate(DateTime expires, DateTime today) {
    final end = TaskSchedule.dayOf(expires);
    final lead = DateTime(end.year, end.month, end.day - leadDays);
    final now = TaskSchedule.dayOf(today);
    return lead.isBefore(now) ? now : lead;
  }

  /// The open check task of [applianceId], if there is one.
  static MaintenanceTask? existing(
    Iterable<MaintenanceTask> tasks,
    String applianceId,
  ) {
    for (final t in tasks) {
      if (t.linkedApplianceId == applianceId &&
          t.tags.contains(tag) &&
          TaskSchedule.isOpen(t)) {
        return t;
      }
    }
    return null;
  }

  /// The columns of the new task. Includes `user_id` and `property_id`, which
  /// the table needs.
  static Map<String, dynamic> fields(Appliance appliance, DateTime due) => {
    'name': 'Check the ${appliance.name.toLowerCase()} before the warranty ends',
    'category': SupabaseTaskFormRepository.applianceCategory,
    'due_date': TaskSchedule.dateColumn(due),
    'task_origin': TaskOrigin.oneTime.value,
    'property_id': appliance.propertyId,
    'user_id': appliance.userId,
    'linked_appliance_id': appliance.id,
    'tags': [tag],
  };
}
