import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/snackbar_service.dart';
import '../../../../services/providers/service_providers.dart';
import '../../models/scan_prefill.dart';
import '../../systems_copy.dart';

/// The one way into ScanFlow. Offline the scan cannot run, so it says so in a
/// snackbar instead of opening (Implementation Notes: Scan is dimmed offline).
abstract final class ScanEntry {
  /// Whether scanning is available right now.
  static bool isOnline(WidgetRef ref) =>
      ref.watch(isOnlineProvider).value ?? true;

  /// Opens ScanFlow for [kind], or null for the "what are you scanning" step.
  static void open(BuildContext context, WidgetRef ref, {ScanKind? kind}) {
    if (!(ref.read(isOnlineProvider).value ?? true)) {
      SnackbarService.showInfo(context, SystemsCopy.scanOffline);
      return;
    }
    context.push(AppRoutes.homeScan, extra: kind);
  }
}
