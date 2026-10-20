import 'package:flutter/widgets.dart';

import '../../../../core/widgets/snackbar_service.dart';
import '../../models/task_log_draft.dart';
import '../../providers/task_detail_provider.dart';

/// The snackbar that follows a saved log: "Done and logged" with Undo.
abstract final class TaskLogUndo {
  /// [notifier] is captured before the Log screen was pushed, so Undo still
  /// works after the screens that were on top have gone.
  static void show(
    BuildContext context, {
    required TaskDetailNotifier notifier,
    required CompletionReceipt receipt,
    String? subtitle,
  }) {
    SnackbarService.showUndo(
      context,
      message: 'Done and logged',
      subtitle: subtitle,
      onUndo: () async {
        try {
          await notifier.undoCompletion(receipt);
        } catch (_) {
          if (context.mounted) {
            SnackbarService.showError(context, "Couldn't undo. Try again.");
          }
        }
      },
    );
  }
}
