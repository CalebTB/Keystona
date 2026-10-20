import 'maintenance_task.dart';
import 'reminder_frequency.dart';

/// A suggested maintenance task returned by the generate-item-tasks function.
class SuggestedTask {
  const SuggestedTask({
    required this.name,
    required this.description,
    required this.category,
    required this.recurrence,
    required this.priority,
    required this.diyOrPro,
    required this.estimatedMinutes,
  });

  factory SuggestedTask.fromJson(Map<String, dynamic> json) {
    return SuggestedTask(
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      recurrence: json['recurrence'] as String? ?? 'annual',
      priority: json['priority'] as String? ?? 'medium',
      diyOrPro: json['diyOrPro'] as String? ?? 'diy',
      estimatedMinutes:
          (json['estimatedMinutes'] as num?)?.toInt() ?? defaultMinutes,
    );
  }

  /// Time to assume when the function does not say.
  static const int defaultMinutes = 30;

  final String name;
  final String description;
  final String category;
  final String recurrence;
  final String priority;
  final String diyOrPro;
  final int estimatedMinutes;

  RecurrenceType get recurrenceType => ReminderFrequency.parse(recurrence);
}
