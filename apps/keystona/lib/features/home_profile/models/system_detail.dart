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
    this.photoUrls = const {},
  });

  final HomeSystem system;
  final List<ItemPhoto> photos;
  /// Signed URLs keyed by [ItemPhoto.filePath]. Valid for 1 hour.
  final Map<String, String> photoUrls;
}
