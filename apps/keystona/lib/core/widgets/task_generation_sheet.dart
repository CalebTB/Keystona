import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/maintenance/models/suggested_task.dart';
import '../../features/maintenance/providers/maintenance_tasks_provider.dart';
import '../../features/maintenance/providers/reminders_providers.dart';
import '../../features/maintenance/widgets/review/task_review_sheet.dart';
import '../../services/supabase_service.dart';
import '../theme/aurora_tasks_c.dart';
import 'aurora/aurora_sheet.dart';

export '../../features/maintenance/models/suggested_task.dart'
    show SuggestedTask;

/// Fires the edge function and returns suggested tasks.
///
/// Call this as soon as the user confirms the scan ("Fill Form") so the result
/// is ready — or nearly ready — by the time they tap Save.
Future<List<SuggestedTask>> prefetchItemTasks({
  required String itemName,
  required String brand,
  required String category,
  required String formType,
}) async {
  try {
    final session = SupabaseService.client.auth.currentSession;
    if (session == null) return [];

    final response = await SupabaseService.client.functions
        .invoke(
          'generate-item-tasks',
          body: {
            'name': itemName,
            'brand': brand,
            'category': category,
            'formType': formType,
          },
          headers: {'Authorization': 'Bearer ${session.accessToken}'},
        )
        .timeout(AuroraTasksCDurations.suggestionTimeout, onTimeout: () => throw Exception('timeout'));

    if (response.data == null) return [];
    final list = response.data is List
        ? response.data as List
        : jsonDecode(response.data.toString()) as List;
    return list
        .map((e) => SuggestedTask.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  } catch (_) {
    return [];
  }
}

/// Shows Review your reminders for a scanned item. No blocking dialog: the
/// suggestions are awaited silently. If [prefetchedFuture] resolves in time
/// the sheet appears at once; if it times out or fails the call returns false
/// silently.
///
/// Returns true when reminders were added.
Future<bool> showTaskGenerationSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String itemName,
  required String brand,
  required String category,
  required String formType,
  String? linkedSystemId,
  String? linkedApplianceId,
  required String propertyId,
  Future<List<SuggestedTask>>? prefetchedFuture,
}) async {
  // Taken before the await: the widget may unmount while suggestions load.
  final repository = ref.read(generatedTasksRepositoryProvider);
  final container = ProviderScope.containerOf(context);

  List<SuggestedTask> tasks = [];
  try {
    tasks =
        await (prefetchedFuture ??
                prefetchItemTasks(
                  itemName: itemName,
                  brand: brand,
                  category: category,
                  formType: formType,
                ))
            .timeout(AuroraTasksCDurations.suggestionTimeout, onTimeout: () => []);
  } catch (_) {
    tasks = [];
  }

  if (!context.mounted || tasks.isEmpty) return false;

  final added = await AuroraSheet.show<bool>(
    context,
    height: AuroraSheetHeight.extra,
    child: TaskReviewSheet(
      tasks: tasks,
      itemName: itemName,
      onConfirm: (selected) async {
        await repository.addAll(
          tasks: selected,
          propertyId: propertyId,
          linkedSystemId: linkedSystemId,
          linkedApplianceId: linkedApplianceId,
        );
        // Invalidating is safe even when these providers are disposed.
        container
          ..invalidate(maintenanceTasksProvider)
          ..invalidate(remindersProvider);
      },
    ),
  );
  return added == true;
}
