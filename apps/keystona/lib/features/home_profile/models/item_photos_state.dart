import 'item_photo.dart';

/// An item's photos with the signed link for each (the bucket is private).
class ItemPhotos {
  const ItemPhotos({this.photos = const [], this.urls = const {}});

  /// Oldest first.
  final List<ItemPhoto> photos;

  /// Signed URLs keyed by [ItemPhoto.filePath]. A photo whose link could not
  /// be made has none and shows the grid placeholder.
  final Map<String, String> urls;

  int get count => photos.length;

  String? urlOf(ItemPhoto photo) => urls[photo.filePath];

  ItemPhotos plus(ItemPhoto photo, String? url) => ItemPhotos(
    photos: [...photos, photo],
    urls: {...urls, photo.filePath: ?url},
  );

  ItemPhotos without(String id) => ItemPhotos(
    photos: [
      for (final p in photos)
        if (p.id != id) p,
    ],
    urls: urls,
  );
}
