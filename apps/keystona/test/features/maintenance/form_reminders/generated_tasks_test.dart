import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/maintenance/models/maintenance_task.dart';
import 'package:keystona/features/maintenance/models/suggested_task.dart';
import 'package:keystona/features/maintenance/repositories/generated_tasks_repository.dart';

void main() {
  final now = DateTime(2026, 10, 19);

  test('first due is one period out, as YYYY-MM-DD', () {
    String due(RecurrenceType r) =>
        SupabaseGeneratedTasksRepository.firstDue(r, now);
    expect(due(RecurrenceType.monthly), '2026-11-19');
    expect(due(RecurrenceType.quarterly), '2027-01-19');
    expect(due(RecurrenceType.biannual), '2027-04-19');
    expect(due(RecurrenceType.annual), '2027-10-19');
    expect(due(RecurrenceType.none), '2026-11-19');
  });

  test('suggestions parse numbers that arrive as doubles and fall back', () {
    final t = SuggestedTask.fromJson({
      'name': 'Flush',
      'estimatedMinutes': 13.0,
      'recurrence': 'quarterly',
    });
    expect(t.estimatedMinutes, 13);
    expect(t.recurrenceType, RecurrenceType.quarterly);
    expect(t.category, 'General');
    expect(t.diyOrPro, 'diy');
    expect(
      SuggestedTask.fromJson({'name': 'x'}).estimatedMinutes,
      SuggestedTask.defaultMinutes,
    );
  });
}
