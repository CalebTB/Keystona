import 'dart:async';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/theme/aurora_docs_b.dart';
import '../models/document_ocr.dart';
import 'document_upload_services_provider.dart';

part 'scan_reading_provider.g.dart';

enum ScanReadingStatus { idle, reading, done, failed }

/// Progress of the reader on the pages just scanned.
class ScanReadingState {
  const ScanReadingState({
    this.status = ScanReadingStatus.idle,
    this.completed = 0,
    this.result = const OcrResult(),
  });

  final ScanReadingStatus status;

  /// Stages finished, 0 to [OcrStage.values.length].
  final int completed;

  /// What the finished stages found.
  final OcrResult result;

  static const int _full = 100;

  bool get isDone => status == ScanReadingStatus.done;

  /// [percent] as a 0.0 to 1.0 fraction for the bar.
  double get fraction => percent / _full;
  bool get isFailed => status == ScanReadingStatus.failed;

  /// Whole-number progress: each stage is a quarter, and the running stage
  /// counts a head start so the bar never sits still.
  int get percent {
    if (isDone) return _full;
    final base = (completed / OcrStage.values.length * _full).round();
    return (base + AuroraUploadRules.readingInFlightPercent).clamp(0, _full);
  }
}

/// Runs the reader and keeps its progress. Kept alive so "keep going in the
/// background" can finish after the camera screen closes; the new-document
/// form picks the result up when it lands.
@Riverpod(keepAlive: true)
class ScanReading extends _$ScanReading {
  StreamSubscription<OcrProgress>? _sub;
  List<File> _pages = const [];

  /// Bumped on every start so a stale run can never update newer state.
  int _run = 0;

  @override
  ScanReadingState build() {
    ref.onDispose(() => _sub?.cancel());
    return const ScanReadingState();
  }

  /// Starts reading [pages], replacing any run in progress.
  void start(List<File> pages) {
    _pages = pages;
    _sub?.cancel();
    final run = ++_run;
    state = const ScanReadingState(status: ScanReadingStatus.reading);
    try {
      _sub = ref
          .read(documentOcrServiceProvider)
          .read(pages)
          .listen(
            (progress) {
              if (run != _run) return;
              state = ScanReadingState(
                status: progress.isFinished
                    ? ScanReadingStatus.done
                    : ScanReadingStatus.reading,
                completed: progress.completed,
                result: progress.result,
              );
            },
            onError: (Object _) {
              if (run != _run) return;
              state = ScanReadingState(
                status: ScanReadingStatus.failed,
                completed: state.completed,
                result: state.result,
              );
            },
            onDone: () {
              if (run != _run || state.isFailed || state.isDone) return;
              state = ScanReadingState(
                status: ScanReadingStatus.done,
                completed: OcrStage.values.length,
                result: state.result,
              );
            },
          );
    } catch (_) {
      state = const ScanReadingState(status: ScanReadingStatus.failed);
    }
  }

  void retry() => start(_pages);

  /// Forgets the run, e.g. when the user chooses to fill the form in themselves.
  void reset() {
    _run++;
    _sub?.cancel();
    state = const ScanReadingState();
  }
}
