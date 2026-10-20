import 'dart:async';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/document_scan.dart';
import '../services/document_scanner.dart';
import 'document_upload_services_provider.dart';

part 'scan_session_provider.g.dart';

/// The camera screen's state: pages so far, the capture mode and the flash.
class ScanSessionState {
  const ScanSessionState({
    this.pages = const [],
    this.smart = false,
    this.flash = false,
    this.edges = ScanEdgeStatus.searching,
    this.capturing = false,
    this.building = false,
    this.captureFailed = false,
  });

  final List<File> pages;

  /// Smart scan (premium) versus just the photo.
  final bool smart;
  final bool flash;
  final ScanEdgeStatus edges;
  final bool capturing;

  /// Combining pages into the final file.
  final bool building;

  /// The last capture threw; the screen says so once.
  final bool captureFailed;

  bool get hasPages => pages.isNotEmpty;
  bool get edgesFound => edges == ScanEdgeStatus.found;

  ScanSessionState copyWith({
    List<File>? pages,
    bool? smart,
    bool? flash,
    ScanEdgeStatus? edges,
    bool? capturing,
    bool? building,
    bool? captureFailed,
  }) => ScanSessionState(
    pages: pages ?? this.pages,
    smart: smart ?? this.smart,
    flash: flash ?? this.flash,
    edges: edges ?? this.edges,
    capturing: capturing ?? this.capturing,
    building: building ?? this.building,
    captureFailed: captureFailed ?? this.captureFailed,
  );
}

/// Drives one trip through the camera screen. Disposed when the screen closes.
@riverpod
class ScanSession extends _$ScanSession {
  @override
  ScanSessionState build({required bool smart}) {
    final scanner = ref.watch(documentScannerProvider);
    final sub = scanner.edgeStatus.listen(
      (edges) => state = state.copyWith(edges: edges),
    );
    ref.onDispose(sub.cancel);
    return ScanSessionState(smart: smart);
  }

  void toggleFlash() => state = state.copyWith(flash: !state.flash);

  void setSmart(bool smart) => state = state.copyWith(smart: smart);

  /// Takes one page. Ignored while another capture is running.
  Future<void> capture() async {
    if (state.capturing) return;
    final scanner = ref.read(documentScannerProvider);
    state = state.copyWith(capturing: true, captureFailed: false);
    try {
      final page = await scanner.capturePage(flash: state.flash);
      state = state.copyWith(
        capturing: false,
        pages: page == null ? state.pages : [...state.pages, page],
      );
    } catch (_) {
      state = state.copyWith(capturing: false, captureFailed: true);
    }
  }

  /// Combines the pages into the file the vault stores.
  Future<ScanOutcome> finish() async {
    final builder = ref.read(scanDocumentBuilderProvider);
    state = state.copyWith(building: true);
    try {
      return await builder.build(state.pages, smart: state.smart);
    } finally {
      state = state.copyWith(building: false);
    }
  }
}
