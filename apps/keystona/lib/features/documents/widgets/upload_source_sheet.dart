import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/aurora/aurora_sheet.dart';
import '../../../core/widgets/upgrade_sheet.dart';
import '../../../services/providers/service_providers.dart';
import '../providers/document_flow.dart';
import '../providers/document_upload_provider.dart';
import 'upload/add_from_sheet_body.dart';
import 'upload/upload_source_actions.dart';

/// The "Add a document" sheet (kit: DocAddFrom).
///
/// [show] resolves once the user has picked something or backed out;
/// [onFilePicked] runs when a file is ready, and the caller then opens the
/// new-document form.
abstract final class UploadSourceSheet {
  static const UpgradeSheetConfig _smartScanUpgrade = UpgradeSheetConfig(
    headline: 'Unlock Smart scan',
    reason:
        'Smart scan reads your document and fills in the name, dates and '
        'what it belongs to.',
    features: [
      'Smart scan fills in the details for you',
      'Unlimited document storage',
      'Full-text search across all docs',
    ],
    triggerKey: 'smart_scan',
  );

  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required VoidCallback onFilePicked,
  }) async {
    // A new flow starts clean, whatever the last one left behind.
    DocumentFlow.reset(ref);
    // Captured before any await: ref is invalid once the sheet unmounts.
    final actions = UploadSourceActions(
      ref.read(documentUploadProvider.notifier),
    );
    final isPremium = ref.read(isPremiumProvider);

    final source = await AuroraSheet.showAuto<UploadSource>(
      context,
      child: const AddFromSheetBody(),
    );
    if (source == null || !context.mounted) return;

    if (await _run(source, context, actions, isPremium: isPremium)) {
      onFilePicked();
    }
  }

  /// Carries out [source]; true when a file is ready for the form.
  static Future<bool> _run(
    UploadSource source,
    BuildContext context,
    UploadSourceActions actions, {
    required bool isPremium,
  }) {
    switch (source) {
      case UploadSource.photo:
        return actions.fromCamera(context, smart: isPremium);
      case UploadSource.library:
        return actions.fromLibrary(context);
      case UploadSource.file:
        return actions.fromFiles(context);
      case UploadSource.smartScan:
        return isPremium
            ? actions.fromCamera(context, smart: true)
            : _offerUpgrade(context);
    }
  }

  static Future<bool> _offerUpgrade(BuildContext context) async {
    await UpgradeSheet.show(context, config: _smartScanUpgrade);
    return false;
  }
}
