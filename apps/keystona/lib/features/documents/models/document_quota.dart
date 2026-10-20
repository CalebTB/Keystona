import '../../subscription/providers/subscription_provider.dart';

/// The free plan's document limit. Every place that checks or shows it goes
/// through here, so the gate and every "N OF 25" label agree. Every live
/// (not deleted) document counts.
abstract final class DocumentQuota {
  /// Whether [used] documents leave no room for another one.
  static bool isFull(int used) => used >= kFreeDocumentLimit;
}
