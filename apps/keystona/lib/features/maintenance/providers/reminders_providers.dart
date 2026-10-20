import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/maintenance_task.dart';
import '../models/reminder_item.dart';
import '../repositories/generated_tasks_repository.dart';
import '../repositories/reminders_repository.dart';
import 'maintenance_tasks_provider.dart';

part 'reminders_providers.g.dart';

/// Data-access seams for the reminder screens. Tests override them.
@riverpod
RemindersRepository remindersRepository(Ref ref) =>
    SupabaseRemindersRepository(SupabaseService.client);

@riverpod
GeneratedTasksRepository generatedTasksRepository(Ref ref) =>
    SupabaseGeneratedTasksRepository(SupabaseService.client);

/// Every reminder for the home, on or off. The three reminder screens read
/// their slice of it. Changes show at once and are written behind; a failed
/// write puts the row back and rethrows so the screen can say so.
@riverpod
class RemindersNotifier extends _$RemindersNotifier {
  @override
  Future<RemindersData> build() =>
      ref.watch(remindersRepositoryProvider).fetch();

  RemindersRepository get _repository => ref.read(remindersRepositoryProvider);

  /// Other screens list tasks: have them re-read after a change. Safe when
  /// the Tasks provider was never built.
  void _refreshTasks() => ref.invalidate(maintenanceTasksProvider);

  /// Turns a reminder on or off. Turning one off records when (now, or
  /// [offAt] when Undo puts back an earlier time) and [reason] when there is
  /// one; turning it on clears both in the database.
  Future<void> setEnabled(
    String id, {
    required bool enabled,
    String? reason,
    DateTime? offAt,
  }) async {
    final before = state.value;
    if (before == null) return;
    final previous = before.items.firstWhere((i) => i.id == id);
    state = AsyncData(
      before.mapItem(
        id,
        (i) => enabled
            ? i.copyWith(enabled: true)
            : i.copyWith(
                enabled: false,
                offAt: offAt ?? DateTime.now().toUtc(),
                offReason: reason,
              ),
      ),
    );
    try {
      await _repository.setEnabled(
        id,
        enabled: enabled,
        reason: reason,
        offAt: offAt,
      );
      _refreshTasks();
    } catch (_) {
      _restore((d) => d.mapItem(id, (_) => previous));
      rethrow;
    }
  }

  /// "Turn all on".
  Future<void> turnAllOn(Iterable<String> ids) async {
    final before = state.value;
    if (before == null) return;
    final off = [
      for (final i in before.items)
        if (ids.contains(i.id) && !i.enabled) i.id,
    ];
    if (off.isEmpty) return;
    state = AsyncData(
      RemindersData(
        items: [
          for (final i in before.items)
            off.contains(i.id) ? i.copyWith(enabled: true) : i,
        ],
        addressLine: before.addressLine,
        climateZone: before.climateZone,
      ),
    );
    try {
      await _repository.setManyEnabled(off, enabled: true);
      _refreshTasks();
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
  }

  Future<void> setRecurrence(String id, RecurrenceType recurrence) async {
    final before = state.value;
    if (before == null) return;
    final previous = before.items.firstWhere((i) => i.id == id);
    state = AsyncData(
      before.mapItem(
        id,
        (i) => i.copyWith(recurrence: recurrence, clearInterval: true),
      ),
    );
    try {
      await _repository.setRecurrence(id, recurrence);
      _refreshTasks();
    } catch (_) {
      _restore((d) => d.mapItem(id, (_) => previous));
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    final before = state.value;
    if (before == null) return;
    state = AsyncData(before.withoutItem(id));
    try {
      await _repository.delete(id);
      _refreshTasks();
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
  }

  void _restore(RemindersData Function(RemindersData current) undo) {
    final current = state.value;
    if (current != null) state = AsyncData(undo(current));
  }
}
