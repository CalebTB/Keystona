import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/aurora_motion.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/snackbar_service.dart';
import '../../docs_copy.dart';

/// Delete with a safety net: confirm, remove, leave the screen, then offer
/// Undo for ten seconds.
///
/// The screen's notifier is gone by the time Undo is tapped, so [restore]
/// must not depend on it.
abstract final class DocumentDeleteFlow {
  static Future<void> run(
    BuildContext context, {
    required Future<void> Function() delete,
    required Future<void> Function() restore,
  }) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete this document?',
      message: 'It leaves your vault. You can undo right after.',
      confirmLabel: 'Delete document',
      onConfirm: () {},
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await delete();
    } catch (_) {
      if (context.mounted) {
        SnackbarService.showError(context, "Couldn't delete document. Try again.");
      }
      return;
    }
    if (!context.mounted) return;

    SnackbarService.showUndo(
      context,
      message: 'Document deleted',
      subtitle: DocsCopy.deleteUndoHint,
      duration: AuroraDurations.undoDelete,
      // The screen is gone when Undo is tapped, so there is no context left
      // to toast on: the document simply reappears in the list. A failure
      // surfaces through the global error handler.
      onUndo: () => restore(),
    );
    context.pop();
  }
}
