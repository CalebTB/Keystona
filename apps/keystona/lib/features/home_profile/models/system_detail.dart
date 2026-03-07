import 'item_photo.dart';
import 'system.dart';

/// Composite view-model for the System Detail screen.
///
/// Assembled in [SystemDetailNotifier._fetchDetail] — never persisted,
/// so no Freezed / JSON needed. Same pattern as [TaskDetail] from Phase 2.
class SystemDetail {
  const SystemDetail({
    required this.system,
    required this.photos,
  });

  /// The full system record.
  final HomeSystem system;

  /// Photos attached to this system, ordered by [ItemPhoto.createdAt] desc.
  final List<ItemPhoto> photos;
}
