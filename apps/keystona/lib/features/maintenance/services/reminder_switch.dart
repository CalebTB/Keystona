/// The `maintenance_tasks` columns that say whether a reminder is on. Pure
/// Dart so every place that switches a reminder writes the same thing.
abstract final class ReminderSwitch {
  /// Columns for turning a reminder on or off.
  ///
  /// Off stamps `notifications_off_at` with [now] (UTC, ISO 8601) and keeps
  /// [reason] when there is one; on clears both.
  static Map<String, dynamic> columns({
    required bool enabled,
    String? reason,
    DateTime? now,
  }) {
    if (enabled) {
      return {
        'notifications_enabled': true,
        'notifications_off_at': null,
        'notifications_off_reason': null,
      };
    }
    final trimmed = reason?.trim();
    return {
      'notifications_enabled': false,
      'notifications_off_at': (now ?? DateTime.now()).toUtc().toIso8601String(),
      'notifications_off_reason': trimmed == null || trimmed.isEmpty
          ? null
          : trimmed,
    };
  }
}
