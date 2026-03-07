import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_photo.freezed.dart';
part 'item_photo.g.dart';

/// A photo attached to a system or appliance, stored in the `item_photos` table.
///
/// Polymorphic: either [systemId] or [applianceId] is non-null (never both).
@freezed
abstract class ItemPhoto with _$ItemPhoto {
  const factory ItemPhoto({
    required String id,
    required String userId,

    /// Non-null when this photo belongs to a system.
    String? systemId,

    /// Non-null when this photo belongs to an appliance.
    String? applianceId,

    /// Storage path in the `item-photos` bucket.
    required String filePath,

    /// Optional thumbnail path in the `item-photos` bucket.
    String? thumbnailPath,

    /// Photo type — one of: overview, model_label, location, condition,
    /// maintenance, other.
    @Default('overview') String photoType,

    /// Optional user caption.
    String? caption,

    required DateTime createdAt,
  }) = _ItemPhoto;

  factory ItemPhoto.fromJson(Map<String, dynamic> json) =>
      _$ItemPhotoFromJson(json);
}
