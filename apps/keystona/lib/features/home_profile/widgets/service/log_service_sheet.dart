import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/aurora/aurora_sheet.dart';
import '../../../../core/widgets/snackbar_service.dart';
import '../../models/item_ref.dart';
import '../../models/item_service_entry.dart';
import '../../providers/item_service_log_provider.dart';
import '../../systems_copy.dart';
import 'log_service_body.dart';

/// The kit's "Log a repair or service" sheet, for systems and appliances.
///
/// Saves through `itemServiceLogProvider(item)` (add, or edit when [editing]
/// is given), says so in a snackbar and returns true. Cancelling returns
/// false. The sheet closes with its own context.
abstract final class LogServiceSheet {
  static Future<bool> show(
    BuildContext context,
    WidgetRef ref,
    ItemRef item, {
    ItemServiceEntry? editing,
  }) async {
    // The family is auto-disposed: hold it open for as long as the sheet is.
    final hold = ref.listenManual(itemServiceLogProvider(item), (_, _) {});
    final notifier = ref.read(itemServiceLogProvider(item).notifier);
    try {
      final saved = await AuroraSheet.show<bool>(
        context,
        height: AuroraSheetHeight.extra,
        title: editing == null
            ? SystemsCopy.logTitle
            : SystemsCopy.logEditTitle,
        child: LogServiceBody(
          editing: editing,
          onSave: (draft) => editing == null
              ? notifier.add(draft)
              : notifier.edit(editing, draft),
        ),
      );
      if (saved != true) return false;
      if (context.mounted) {
        SnackbarService.showSuccess(
          context,
          editing == null ? SystemsCopy.logSaved : SystemsCopy.logUpdated,
        );
      }
      return true;
    } finally {
      hold.close();
    }
  }
}
