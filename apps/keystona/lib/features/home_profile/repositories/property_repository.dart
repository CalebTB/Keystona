import '../models/property.dart';
import '../models/property_edits.dart';

/// Reads and writes the signed-in user's property for the Home profile
/// screens.
abstract interface class PropertyRepository {
  /// The user's property, or null when none exists yet.
  Future<Property?> fetchProperty();

  /// A signed URL for a cover photo path, null when it cannot be signed.
  Future<String?> signedPhotoUrl(String path);

  /// Uploads [PropertyEdits.newPhoto] when there is one, then updates the
  /// property row.
  Future<void> save(String propertyId, PropertyEdits edits);
}
