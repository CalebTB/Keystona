import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/aurora_docs_b.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../../core/widgets/upgrade_sheet.dart';
import '../../../services/providers/service_providers.dart';
import '../models/document_scan.dart';
import '../providers/document_upload_services_provider.dart';
import '../providers/scan_reading_provider.dart';
import '../providers/scan_session_provider.dart';
import '../widgets/upload/camera/camera_controls.dart';
import '../widgets/upload/camera/camera_frame_guides.dart';
import '../widgets/upload/camera/camera_hint_pill.dart';
import '../widgets/upload/camera/camera_mode_toggle.dart';
import '../widgets/upload/camera/camera_top_bar.dart';
import '../widgets/upload/camera/document_reading_card.dart';

/// Camera scan (kit: DocCamera) with the "reading your document" card on top
/// of it (kit: DocReading).
///
/// Pops a [ScanFlowResult], or null when the user closes the camera.
class DocumentCameraScreen extends ConsumerStatefulWidget {
  const DocumentCameraScreen({super.key, required this.startSmart});

  /// Open in smart scan mode. Plain mode when the user is not premium.
  final bool startSmart;

  @override
  ConsumerState<DocumentCameraScreen> createState() =>
      _DocumentCameraScreenState();
}

class _DocumentCameraScreenState extends ConsumerState<DocumentCameraScreen> {
  /// The reading card is up.
  bool _reading = false;

  static const UpgradeSheetConfig _upgrade = UpgradeSheetConfig(
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

  ScanSession get _session =>
      ref.read(scanSessionProvider(smart: widget.startSmart).notifier);

  Future<void> _setSmart(bool smart) async {
    if (smart && !ref.read(isPremiumProvider)) {
      await UpgradeSheet.show(context, config: _upgrade);
      return;
    }
    _session.setSmart(smart);
  }

  Future<void> _onDone() async {
    final state = ref.read(scanSessionProvider(smart: widget.startSmart));
    if (!state.smart) return _finish(found: false);
    setState(() => _reading = true);
    ref.read(scanReadingProvider.notifier).start(state.pages);
  }

  /// Combines the pages and closes the camera. [found] hands over what the
  /// reader found; otherwise the form fills in later, or not at all.
  Future<void> _finish({required bool found}) async {
    final reading = ref.read(scanReadingProvider);
    try {
      final outcome = await _session.finish();
      if (!mounted) return;
      Navigator.of(context).pop(
        ScanFlowResult(
          outcome: outcome,
          found: found && reading.isDone ? reading.result : null,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      SnackbarService.showError(
        context,
        "Couldn't save those pages. Try again.",
      );
    }
  }

  void _close() {
    if (_reading) ref.read(scanReadingProvider.notifier).reset();
    Navigator.of(context).pop();
  }

  void _skipReading() {
    ref.read(scanReadingProvider.notifier).reset();
    _finish(found: false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = scanSessionProvider(smart: widget.startSmart);
    ref.listen(provider.select((s) => s.captureFailed), (_, failed) {
      if (failed) {
        SnackbarService.showError(
          context,
          "Couldn't take that picture. Try again.",
        );
      }
    });
    final session = ref.watch(provider);
    final scanner = ref.watch(documentScannerProvider);
    final ready = scanner.detectsEdges && session.edgesFound;

    return Scaffold(
      backgroundColor: AuroraCameraColors.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1,
                colors: [
                  AuroraCameraColors.glowCenter,
                  AuroraCameraColors.glowEdge,
                ],
              ),
            ),
          ),
          ?scanner.buildPreview(context),
          _CameraBody(
            session: session,
            ready: ready,
            onClose: _close,
            onFlash: _session.toggleFlash,
            onSmartChanged: _setSmart,
            onShoot: _session.capture,
            onDone: _onDone,
          ),
          if (_reading)
            _ReadingLayer(
              pageCount: session.pages.length,
              onCheck: () => _finish(found: true),
              onBackground: () => _finish(found: false),
              onSkip: _skipReading,
            ),
        ],
      ),
    );
  }
}

class _CameraBody extends StatelessWidget {
  const _CameraBody({
    required this.session,
    required this.ready,
    required this.onClose,
    required this.onFlash,
    required this.onSmartChanged,
    required this.onShoot,
    required this.onDone,
  });

  final ScanSessionState session;
  final bool ready;
  final VoidCallback onClose;
  final VoidCallback onFlash;
  final ValueChanged<bool> onSmartChanged;
  final VoidCallback onShoot;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final width = MediaQuery.sizeOf(context).width;
    final frameWidth = width * AuroraCameraSizes.frameWidthFraction;
    return SafeArea(
      child: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: a.symmetric(
                horizontal: AuroraSpacing.space7,
                vertical: AuroraSpacing.space5,
              ),
              child: Column(
                children: [
                  CameraTopBar(
                    smart: session.smart,
                    pageNumber: session.pages.length + 1,
                    flash: session.flash,
                    onClose: onClose,
                    onFlash: onFlash,
                  ),
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        child: SizedBox(
                          width: frameWidth,
                          height: frameWidth / AuroraCameraSizes.frameAspect,
                          child: CameraFrameGuides(ready: ready),
                        ),
                      ),
                    ),
                  ),
                  CameraHintPill(ready: ready),
                  SizedBox(height: a.of(AuroraSpacing.space10)),
                  CameraModeToggle(
                    smart: session.smart,
                    onChanged: onSmartChanged,
                  ),
                  SizedBox(height: a.of(AuroraSpacing.space8)),
                  CameraControls(
                    pages: session.pages,
                    busy: session.capturing || session.building,
                    onShoot: onShoot,
                    onDone: onDone,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dim layer plus the reading card, centred and scrollable on short screens.
class _ReadingLayer extends ConsumerWidget {
  const _ReadingLayer({
    required this.pageCount,
    required this.onCheck,
    required this.onBackground,
    required this.onSkip,
  });

  final int pageCount;
  final VoidCallback onCheck;
  final VoidCallback onBackground;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aurora;
    final reading = ref.watch(scanReadingProvider);
    return ColoredBox(
      color: AuroraCameraColors.readingScrim,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: a.all(AuroraSpacing.space7),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: a.contentMaxWidth),
              child: DocumentReadingCard(
                reading: reading,
                pageCount: pageCount,
                onCheck: onCheck,
                onBackground: onBackground,
                onRetry: ref.read(scanReadingProvider.notifier).retry,
                onSkip: onSkip,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
