import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../../services/label_scanner_service.dart';
import '../../../services/providers/service_providers.dart';
import '../models/scan_prefill.dart';
import '../providers/appliances_provider.dart';
import '../providers/scan_providers.dart';
import '../providers/systems_provider.dart';
import '../systems_copy.dart';
import '../widgets/scan/scan_camera_view.dart';
import '../widgets/scan/scan_choose_panel.dart';

/// ScanFlow (kit: ScanFlow). Route: `/home/scan`.
///
/// With no [initialKind] it asks "What are you scanning?"; with one it goes
/// straight to the label view. A photo of the label is read by the scan-label
/// function and "Review details" opens the matching Add form filled in.
class ScanFlowScreen extends ConsumerStatefulWidget {
  const ScanFlowScreen({super.key, this.initialKind});

  /// Reads a route's `extra`: a [ScanKind] or nothing.
  factory ScanFlowScreen.fromExtra(Object? extra) =>
      ScanFlowScreen(initialKind: extra is ScanKind ? extra : null);

  final ScanKind? initialKind;

  @override
  ConsumerState<ScanFlowScreen> createState() => _ScanFlowScreenState();
}

class _ScanFlowScreenState extends ConsumerState<ScanFlowScreen> {
  ScanKind? _kind;
  bool _reading = false;
  ScanPrefill? _read;
  String? _failure;

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
  }

  bool get _isSystem => _kind == ScanKind.system;

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _back() {
    // Came in through the chooser: go back to it. Otherwise leave.
    if (widget.initialKind == null) {
      setState(() {
        _kind = null;
        _read = null;
        _failure = null;
      });
    } else {
      _close();
    }
  }

  void _choose(ScanKind kind) => setState(() {
    _kind = kind;
    _read = null;
    _failure = null;
  });

  void _typeItIn() {
    if (_isSystem || _kind == null) {
      context.pushReplacement(AppRoutes.homeSystemsAdd);
    } else {
      context.pushReplacement(
        AppRoutes.homeAppliancesAdd,
        extra: const ItemFormArgs(),
      );
    }
  }

  void _review() {
    final prefill = _read;
    if (prefill == null) return;
    context.pushReplacement(
      prefill.kind == ScanKind.system
          ? AppRoutes.homeSystemsAdd
          : AppRoutes.homeAppliancesAdd,
      extra: ItemFormArgs(prefill: prefill),
    );
  }

  Future<void> _shoot() async {
    final kind = _kind;
    if (kind == null) return;
    if (!(ref.read(isOnlineProvider).value ?? true)) {
      SnackbarService.showInfo(context, SystemsCopy.scanOffline);
      return;
    }
    // Taken before the awaits: the screen may close while the camera is open.
    final capture = ref.read(photoSourceProvider);
    final reader = ref.read(labelReaderProvider);
    final XFile? photo;
    try {
      photo = await capture(ImageSource.camera);
    } catch (_) {
      if (mounted) SnackbarService.showError(context, SystemsCopy.scanFailed);
      return;
    }
    if (photo == null || !mounted) return;
    setState(() {
      _reading = true;
      _failure = null;
    });
    try {
      final LabelScanResult result = await reader(
        photo,
        isAppliance: kind == ScanKind.appliance,
      );
      if (!mounted) return;
      if (result.isEmpty) {
        setState(() {
          _reading = false;
          _failure = SystemsCopy.scanNothing;
        });
        SnackbarService.showWarning(context, SystemsCopy.scanNothing);
        return;
      }
      setState(() {
        _reading = false;
        _read = ScanPrefill(kind: kind, result: result, photo: photo!);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _reading = false;
        _failure = SystemsCopy.scanFailed;
      });
      SnackbarService.showError(context, SystemsCopy.scanFailed);
    }
  }

  String get _hint {
    if (_reading) return SystemsCopy.scanReading;
    final read = _read;
    if (read != null) return SystemsCopy.scanFound(read.result.fieldCount);
    return _failure ??
        (_isSystem ? SystemsCopy.scanHintSystem : SystemsCopy.scanHintAppliance);
  }

  @override
  Widget build(BuildContext context) {
    final kind = _kind;
    if (kind == null) {
      final systems = ref.watch(systemsProvider).value?.length;
      final appliances = ref.watch(appliancesProvider).value?.length;
      return Scaffold(
        backgroundColor: AuroraColors.scrim,
        body: Align(
          alignment: Alignment.bottomCenter,
          child: SingleChildScrollView(
            child: ScanChoosePanel(
              systemCount: systems,
              applianceCount: appliances,
              onSystem: () => _choose(ScanKind.system),
              onAppliance: () => _choose(ScanKind.appliance),
              onByHand: _typeItIn,
              onClose: _close,
            ),
          ),
        ),
      );
    }
    final online = ref.watch(isOnlineProvider).value ?? true;
    return Scaffold(
      backgroundColor: AuroraColors.ink,
      body: ScanCameraView(
        kind: kind,
        hint: _hint,
        found: _read != null,
        busy: _reading,
        online: online,
        onBack: _back,
        onKind: _choose,
        onShutter: _shoot,
        onReview: _review,
        onTypeItIn: _typeItIn,
      ),
    );
  }
}
