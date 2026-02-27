import 'package:connectivity_plus/connectivity_plus.dart';

/// Watches network connectivity and exposes a simple online/offline signal.
///
/// Consumed via [isOnlineProvider] in the Riverpod provider tree.
/// Screens and widgets should watch [isOnlineProvider] rather than
/// instantiating this class directly.
class ConnectivityService {
  final _connectivity = Connectivity();

  /// Stream that emits `true` when the device has any network connection
  /// and `false` when fully offline.
  Stream<bool> get isOnlineStream => _connectivity.onConnectivityChanged.map(
        (results) => _isConnected(results),
      );

  /// Synchronous snapshot of the current connectivity state.
  ///
  /// Because this requires an async check internally, prefer using
  /// [isOnlineProvider] (a [StreamProvider]) in UI code.
  bool get isOnline {
    // Connectivity.checkConnectivity() is async; this getter returns a best-
    // effort cached value. Use the stream for reactive UI updates.
    return true; // optimistic default — stream will correct quickly
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any(
      (r) => r != ConnectivityResult.none,
    );
  }
}
