import 'appliance.dart';
import 'item_photo.dart';

class ApplianceDetail {
  const ApplianceDetail({
    required this.appliance,
    required this.photos,
  });

  final Appliance appliance;
  final List<ItemPhoto> photos;
}
