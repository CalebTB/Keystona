import 'appliance.dart';
import 'item_photo.dart';

class ApplianceDetail {
  const ApplianceDetail({
    required this.appliance,
    required this.photos,
    this.photoUrls = const {},
  });

  final Appliance appliance;
  final List<ItemPhoto> photos;
  /// Signed URLs keyed by [ItemPhoto.filePath]. Valid for 1 hour.
  final Map<String, String> photoUrls;
}
