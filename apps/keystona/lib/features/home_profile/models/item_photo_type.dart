import 'item_ref.dart';

/// What a photo of a system or appliance shows: the kit's UNIT, LABEL,
/// FILTER and REPAIR tags. Stored in `item_photos.photo_type` (free text).
enum ItemPhotoType {
  unit('unit', 'UNIT'),
  label('label', 'LABEL'),
  filter('filter', 'FILTER'),
  repair('repair', 'REPAIR');

  const ItemPhotoType(this.value, this.tag);

  /// The text stored in the database.
  final String value;

  /// The tag on the photo.
  final String tag;

  /// The type for a stored [value]. Photos saved before the kit's tags read
  /// as the nearest one: overview, location and other are the unit,
  /// model_label the label, maintenance the filter and condition a repair.
  static ItemPhotoType fromValue(String? value) => switch (value) {
    'label' || 'model_label' => label,
    'filter' || 'maintenance' => filter,
    'repair' || 'condition' => repair,
    _ => unit,
  };
}

/// One "good photo to have" line: what to shoot, and the type that ticks it
/// off once a photo of that type exists (none for the ones that never tick).
class ItemPhotoTip {
  const ItemPhotoTip(this.text, {this.type});

  final String text;
  final ItemPhotoType? type;
}

/// The "GOOD PHOTOS TO HAVE" list for a kind of item.
abstract final class ItemPhotoGuidance {
  static const List<ItemPhotoTip> system = [
    ItemPhotoTip(
      'The rating label — model and serial in one shot',
      type: ItemPhotoType.label,
    ),
    ItemPhotoTip(
      'The whole unit with space around it',
      type: ItemPhotoType.unit,
    ),
    ItemPhotoTip(
      'Where the filter goes, with the size showing',
      type: ItemPhotoType.filter,
    ),
    ItemPhotoTip('The shutoff switch or valve nearby'),
  ];

  static const List<ItemPhotoTip> appliance = [
    ItemPhotoTip(
      'The model and serial sticker — both in one shot',
      type: ItemPhotoType.label,
    ),
    ItemPhotoTip(
      'The whole appliance with space around it',
      type: ItemPhotoType.unit,
    ),
    ItemPhotoTip(
      'The filter or drain, with the part number showing',
      type: ItemPhotoType.filter,
    ),
    ItemPhotoTip('The shutoff valve or plug nearby'),
  ];

  static List<ItemPhotoTip> forKind(ItemKind kind) =>
      kind == ItemKind.system ? system : appliance;
}
