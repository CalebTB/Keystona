import 'package:flutter/widgets.dart';

import '../../../../../core/widgets/aurora/aurora_sheet.dart';
import '../../../models/maintenance_task.dart';
import '../../../models/quick_done_result.dart';
import 'quick_done_body.dart';

/// The "Nice — it's done" sheet (TaskDoneQuick).
abstract final class QuickDoneSheet {
  /// Resolves to what the user chose, or null when the sheet was dismissed
  /// (which keeps the task done with the default details).
  static Future<QuickDoneResult?> show(
    BuildContext context, {
    required MaintenanceTask task,
    required DateTime today,
  }) {
    return AuroraSheet.show<QuickDoneResult>(
      context,
      height: AuroraSheetHeight.tall,
      child: QuickDoneBody(task: task, today: today),
    );
  }
}
