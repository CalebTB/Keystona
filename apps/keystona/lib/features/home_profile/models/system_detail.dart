import 'system.dart';

/// Composite view-model for the System Detail screen: the system plus what
/// its photos say (count and the picture to show). Never persisted.
class SystemDetail {
  const SystemDetail({required this.system, required this.photos});

  final HomeSystem system;
  final SystemPhotoSummary photos;
}

/// An item's photos in brief: how many, and the hero picture.
class SystemPhotoSummary {
  const SystemPhotoSummary({
    this.count = 0,
    this.heroUrl,
    this.heroType,
  });

  static const SystemPhotoSummary none = SystemPhotoSummary();

  final int count;

  /// Signed URL of the newest photo, null when there is none or it could not
  /// be signed.
  final String? heroUrl;

  /// `photo_type` of the hero photo ("overview", "label"...).
  final String? heroType;
}
